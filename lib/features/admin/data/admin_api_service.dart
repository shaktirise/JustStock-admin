import "dart:convert";

import "package:http/http.dart" as http;

import "../../../core/auth_session.dart";
import "../../../core/http_client.dart" as http_client;
import "../../../core/session_store.dart";
import "admin_models.dart";

class AdminApiService {
  AdminApiService({
    http.Client? client,
    String baseUrl = _defaultBaseUrl,
    Duration timeout = const Duration(seconds: 20),
  })  : _client = client ?? http_client.buildHttpClient(),
        _ownsClient = client == null,
        baseUrl = _sanitizeBaseUrl(baseUrl),
        _timeout = timeout;

  static const String _defaultBaseUrl =
      "https://backend-server-11f5.onrender.com";

  final http.Client _client;
  final bool _ownsClient;
  final Duration _timeout;

  final String baseUrl;

  Future<AdminOverview> fetchOverview({
    DateTime? from,
    DateTime? to,
    String? userId,
  }) async {
    // Use an all-time wide window unless a range is provided
    final defaultFrom = DateTime.utc(1970, 1, 1);
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/dashboard/overview",
            {
              "from": from ?? defaultFrom,
              if (to != null) "to": to,
              if (userId != null && userId.isNotEmpty) "userId": userId,
            },
          ),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final body = _handleResponse(response);
    await _touchLastActivity();
    return AdminOverview.fromJson(body);
  }

  Future<PaginatedResult<AdminCallRecord>> fetchCalls({
    int page = 1,
    int limit = 20,
    String? userId,
    DateTime? start,
    DateTime? end,
  }) async {
    final defaultStart = DateTime.utc(1970, 1, 1);
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/dashboard/calls",
            {
              "page": page,
              "limit": limit,
              if (userId != null && userId.isNotEmpty) "userId": userId,
              // If no explicit range, use all-time for non-zero totals in UI
              "start": start ?? defaultStart,
              if (end != null) "end": end,
            },
          ),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final body = _handleResponse(response);
    await _touchLastActivity();
    return buildPaginatedResult(
      body,
      AdminCallRecord.fromJson,
    );
  }

  Future<PaginatedResult<AdminWalletEntry>> fetchWalletLedger({
    int page = 1,
    int limit = 20,
    String? types,
    String? userId,
    DateTime? from,
    DateTime? to,
  }) async {
    final defaultFrom = DateTime.utc(1970, 1, 1);
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/wallet-ledger",
            {
              "page": page,
              // API expects pageSize
              "pageSize": limit,
              if (types != null && types.isNotEmpty) "types": types,
              if (userId != null && userId.isNotEmpty) "userId": userId,
              "from": from ?? defaultFrom,
              if (to != null) "to": to,
            },
          ),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final body = _handleResponse(response);
    await _touchLastActivity();
    return buildPaginatedResult(
      body,
      AdminWalletEntry.fromJson,
    );
  }

  Future<PaginatedResult<AdminReferralEntry>> fetchPendingReferrals({
    int page = 1,
    int limit = 20,
    String? userId,
    DateTime? from,
    DateTime? to,
  }) async {
    // Use the new commissions feed (better status/level tracking)
    final defaultFrom = DateTime.utc(1970, 1, 1);
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/commissions",
            {
              "page": page,
              "pageSize": limit,
              "status": "PENDING",
              if (userId != null && userId.isNotEmpty) "userId": userId,
              "from": from ?? defaultFrom,
              if (to != null) "to": to,
            },
          ),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final body = _handleResponse(response);
    await _touchLastActivity();
    return buildPaginatedResult(
      body,
      AdminReferralEntry.fromJson,
    );
  }

  Future<PaginatedResult<AdminUserSummary>> fetchUsers({
    int page = 1,
    int limit = 20,
    String? role,
    String? search,
  }) async {
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/users",
            {
              "page": page,
              "limit": limit,
              "role": role,
              "search": search,
            },
          ),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final body = _handleResponse(response);
    await _touchLastActivity();
    return buildPaginatedResult(
      body,
      AdminUserSummary.fromJson,
    );
  }

  Future<AdminUserDetail> fetchUserProfile(String userId) async {
    // Fetch basic profile + recents
    final profileResp = await _client
        .get(
          _buildUri("/api/admin/users/$userId"),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final profile = _handleResponse(profileResp);

    // Fetch wallet/referral aggregates from the summary endpoint
    final defaultFrom = DateTime.utc(1970, 1, 1);
    final summaryResp = await _client
        .get(
          _buildUri(
            "/api/admin/users/$userId/summary",
            {
              "from": defaultFrom,
              // keep 'to' empty for open-ended; server uses now
              "depth": 3,
            },
          ),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final summary = _handleResponse(summaryResp);

    // Prepare wallet snapshot from summary
    Map<String, dynamic> walletSrc;
    final w = summary["wallet"];
    if (w is Map<String, dynamic>) {
      walletSrc = w;
    } else if (w is Map) {
      walletSrc = w.map<String, dynamic>((key, dynamic value) => MapEntry("$key", value));
    } else {
      walletSrc = Map<String, dynamic>.from(summary);
    }
    final wallet = <String, dynamic>{
      // map availableRupees -> available
      "available": walletSrc["availableRupees"] ?? walletSrc["walletBalanceRupees"] ??
          walletSrc["available"],
      // defaults for optional fields
      "locked": walletSrc["lockedRupees"] ?? walletSrc["locked"] ?? 0,
      "pending": walletSrc["pendingRupees"] ?? walletSrc["pending"] ?? 0,
    };

    // Aggregate commissions by level into totals
    double pending = 0, released = 0, reversed = 0;
    final cbl = summary["commissionsByLevel"];
    if (cbl is Map) {
      for (final value in cbl.values) {
        if (value is Map) {
          pending += _readCommissionAmount(value["pending"]);
          released += _readCommissionAmount(value["released"]) +
              _readCommissionAmount(value["paid"]);
          reversed += _readCommissionAmount(value["reversed"]) +
              _readCommissionAmount(value["cancelled"]);
        }
      }
    } else if (cbl is List) {
      for (final item in cbl) {
        if (item is Map) {
          pending += _readCommissionAmount(item["pending"]);
          released += _readCommissionAmount(item["released"]) +
              _readCommissionAmount(item["paid"]);
          reversed += _readCommissionAmount(item["reversed"]) +
              _readCommissionAmount(item["cancelled"]);
        }
      }
    }
    final referralsAgg = <String, dynamic>{
      "pending": pending,
      "paid": released,
      "cancelled": reversed,
      "total": pending + released + reversed,
    };

    // Referral counts per level
    final referralCounts = _extractReferralCounts(summary);

    // Merge into a single payload that AdminUserDetail can parse
    final merged = <String, dynamic>{
      ...profile,
      "wallet": wallet,
      "referrals": referralsAgg,
      if (referralCounts.isNotEmpty) "referralCounts": referralCounts,
    };
    await _touchLastActivity();
    return AdminUserDetail.fromJson(merged);
  }

  Future<PaginatedResult<AdminWalletEntry>> fetchUserWalletLedger(
    String userId, {
    int page = 1,
    int limit = 20,
    String? types,
    DateTime? from,
    DateTime? to,
  }) async {
    final defaultFrom = DateTime.utc(1970, 1, 1);
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/users/$userId/wallet-ledger",
            {
              "page": page,
              "pageSize": limit,
              if (types != null && types.isNotEmpty) "types": types,
              "from": from ?? defaultFrom,
              if (to != null) "to": to,
            },
          ),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final body = _handleResponse(response);
    await _touchLastActivity();
    return buildPaginatedResult(
      body,
      AdminWalletEntry.fromJson,
    );
  }

  Future<PaginatedResult<AdminReferralEntry>> fetchUserReferrals(
    String userId, {
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    // Use commissions feed filtered by user for full history
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/commissions",
            {
              "page": page,
              "pageSize": limit,
              "userId": userId,
              if (status != null && status.isNotEmpty) "status": status.toUpperCase(),
              "from": DateTime.utc(1970, 1, 1),
            },
          ),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final body = _handleResponse(response);
    await _touchLastActivity();
    return buildPaginatedResult(
      body,
      AdminReferralEntry.fromJson,
    );
  }

  Future<void> resetUserPassword({
    required String userId,
    required String newPassword,
  }) async {
    final response = await _client
        .patch(
          _buildUri("/api/admin/users/$userId/password"),
          headers: _authHeaders(const {"Content-Type": "application/json"}),
          body: jsonEncode({"newPassword": newPassword}),
        )
        .timeout(_timeout);
    _handleResponse(response);
    await _touchLastActivity();
  }

  Future<void> updateReferralStatus({
    required String entryId,
    required String status,
  }) async {
    // Map UI statuses to server statuses
    final normalized = status.toLowerCase();
    final serverStatus =
        normalized == "paid" ? "RELEASED" : (normalized == "cancelled" ? "REVERSED" : status);
    final response = await _client
        .patch(
          _buildUri("/api/admin/commissions/$entryId"),
          headers: _authHeaders(const {"Content-Type": "application/json"}),
          body: jsonEncode({"status": serverStatus}),
        )
        .timeout(_timeout);
    _handleResponse(response);
    await _touchLastActivity();
  }

  void dispose() {
    if (_ownsClient) {
      try {
        _client.close();
      } catch (_) {}
    }
  }

  Uri _buildUri(
    String path, [
    Map<String, dynamic>? queryParameters,
  ]) {
    final normalizedPath = path.startsWith("/") ? path : "/$path";
    final uri = Uri.parse("$baseUrl$normalizedPath");
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final query = <String, String>{};
    queryParameters.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.trim().isEmpty) return;
      if (value is DateTime) {
        query[key] = value.toUtc().toIso8601String();
      } else {
        query[key] = value.toString();
      }
    });
    return uri.replace(queryParameters: query);
  }

  Map<String, String> _authHeaders([Map<String, String>? headers]) {
    final baseHeaders = <String, String>{
      "Accept": "application/json",
      if (headers != null) ...headers,
    };
    return AuthSession.withAuth(baseHeaders);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final parsed = _parseJson(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return parsed;
    }
    final message = _extractMessage(parsed) ??
        "Request failed (HTTP ${response.statusCode}).";
    throw ApiException(
      message,
      statusCode: response.statusCode,
      details: parsed,
    );
  }

  Map<String, dynamic> _parseJson(String body) {
    if (body.isEmpty) {
      return const {};
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is List) {
        return {"data": decoded};
      }
      return {"value": decoded};
    } catch (_) {
      return {"raw": body};
    }
  }

  String? _extractMessage(Map<String, dynamic> payload) {
    for (final key in const [
      "message",
      "msg",
      "error",
      "detail",
      "status",
      "reason",
    ]) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> _touchLastActivity() async {
    try {
      await SessionStore.touchLastActivityNow();
    } catch (_) {}
  }

  static String _sanitizeBaseUrl(String baseUrl) {
    if (baseUrl.endsWith("/")) {
      return baseUrl.substring(0, baseUrl.length - 1);
    }
    return baseUrl;
  }
}

double _readCommissionAmount(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  if (value is Map) {
    final v = value["amountRupees"] ?? value["rupees"] ?? value["amount"];
    if (v is num) return v.toDouble();
  }
  return 0;
}

Map<String, dynamic> _extractReferralCounts(Map<String, dynamic> summary) {
  final referrals = summary["referrals"];
  Map<String, dynamic>? countsMap;
  if (referrals is Map) {
    final c = referrals["counts"];
    if (c is Map<String, dynamic>) {
      countsMap = c;
    } else if (c is Map) {
      countsMap = c.map<String, dynamic>((k, dynamic v) => MapEntry("$k", v));
    }
  }
  return countsMap ?? const <String, dynamic>{};
}
