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

  Future<AdminOverview> fetchOverview() async {
    final response = await _client
        .get(
          _buildUri("/api/admin/dashboard/overview"),
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
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/dashboard/calls",
            {
              "page": page,
              "limit": limit,
              "userId": userId,
              "start": start,
              "end": end,
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
    String? type,
    String? userId,
    DateTime? start,
    DateTime? end,
  }) async {
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/wallet-ledger",
            {
              "page": page,
              "limit": limit,
              "type": type,
              "userId": userId,
              "start": start,
              "end": end,
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
  }) async {
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/referrals/pending",
            {
              "page": page,
              "limit": limit,
              "userId": userId,
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
    final response = await _client
        .get(
          _buildUri("/api/admin/users/$userId"),
          headers: _authHeaders(),
        )
        .timeout(_timeout);
    final body = _handleResponse(response);
    await _touchLastActivity();
    return AdminUserDetail.fromJson(body);
  }

  Future<PaginatedResult<AdminWalletEntry>> fetchUserWalletLedger(
    String userId, {
    int page = 1,
    int limit = 20,
    String? type,
  }) async {
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/users/$userId/wallet-ledger",
            {
              "page": page,
              "limit": limit,
              "type": type,
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
    final response = await _client
        .get(
          _buildUri(
            "/api/admin/users/$userId/referrals",
            {
              "page": page,
              "limit": limit,
              "status": status,
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
    final response = await _client
        .patch(
          _buildUri("/api/auth/admin/referrals/$entryId/status"),
          headers: _authHeaders(const {"Content-Type": "application/json"}),
          body: jsonEncode({"status": status}),
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
