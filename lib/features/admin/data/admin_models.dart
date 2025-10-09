import "package:flutter/foundation.dart";

@immutable
class AdminOverview {
  const AdminOverview({
    required this.stats,
    required this.recentCalls,
    required this.recentTopUps,
    required this.recentWithdrawals,
    required this.leaderboardEntries,
    this.raw = const {},
  });

  final AdminOverviewStats stats;
  final List<AdminCallRecord> recentCalls;
  final List<AdminWalletEntry> recentTopUps;
  final List<AdminWalletEntry> recentWithdrawals;
  final List<AdminLeaderboardEntry> leaderboardEntries;
  final Map<String, dynamic> raw;

  factory AdminOverview.fromJson(Map<String, dynamic> json) {
    final root = _unwrapResponse(json);
    final statsSource =
        _asMap(root["stats"]) ?? _asMap(root["overview"]) ?? root;
    return AdminOverview(
      stats: AdminOverviewStats.fromJson(statsSource),
      recentCalls: _mapList(
        root["recentCalls"] ??
            root["recentPurchases"] ??
            root["calls"] ??
            root["recent_call"],
        AdminCallRecord.fromJson,
      ),
      recentTopUps: _mapList(
        root["recentTopUps"] ??
            root["topups"] ??
            root["recentTopups"] ??
            root["topUps"] ??
            root["top_ups"],
        AdminWalletEntry.fromJson,
      ),
      recentWithdrawals: _mapList(
        root["recentWithdrawals"] ??
            root["withdrawals"] ??
            root["recentWithdrawal"],
        AdminWalletEntry.fromJson,
      ),
      leaderboardEntries: _mapList(
        root["leaderboard"] ?? root["leaders"] ?? root["topPerformers"],
        AdminLeaderboardEntry.fromJson,
      ),
      raw: root,
    );
  }
}

@immutable
class AdminOverviewStats {
  const AdminOverviewStats({
    required this.totalSignups,
    required this.activeUsers,
    required this.totalWalletBalance,
    required this.pendingReferralBalance,
    this.totalRevenue,
    this.recentPayouts,
    this.additional = const {},
  });

  final int totalSignups;
  final int activeUsers;
  final double totalWalletBalance;
  final double pendingReferralBalance;
  final double? totalRevenue;
  final double? recentPayouts;
  final Map<String, dynamic> additional;

  factory AdminOverviewStats.fromJson(Map<String, dynamic> json) {
    return AdminOverviewStats(
      totalSignups: _readInt(json, const [
        "totalSignups",
        "signups",
        "total_users",
        "totalUsers",
        "signUps",
      ]),
      activeUsers: _readInt(json, const [
        "activeUsers",
        "actives",
        "active_users",
        "active_users_count",
      ]),
      totalWalletBalance: _readDouble(json, const [
        "walletTotal",
        "walletBalance",
        "totalWalletBalance",
        "wallet",
        "wallet_total",
      ]),
      pendingReferralBalance: _readDouble(json, const [
        "referralBalance",
        "referralsPending",
        "pendingReferral",
        "pending_referrals",
      ]),
      totalRevenue: _readDoubleOrNull(json, const [
        "totalRevenue",
        "revenue",
        "total_revenue",
      ]),
      recentPayouts: _readDoubleOrNull(json, const [
        "recentPayouts",
        "payouts",
        "recent_payouts",
      ]),
      additional: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

@immutable
class AdminCallRecord {
  const AdminCallRecord({
    required this.id,
    this.user,
    this.planName,
    this.amount,
    this.currency,
    this.status,
    this.channel,
    this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  final String id;
  final AdminUserReference? user;
  final String? planName;
  final double? amount;
  final String? currency;
  final String? status;
  final String? channel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  factory AdminCallRecord.fromJson(Map<String, dynamic> json) {
    final userSource =
        _asMap(json["user"]) ?? _asMap(json["owner"]) ?? _extractUser(json);
    final plan = _asMap(json["plan"]);
    final planName = plan != null
        ? _readStringOrNull(
            plan,
            const [
              "name",
              "title",
              "plan",
            ],
          )
        : null;

    return AdminCallRecord(
      id: _readString(json, const ["id", "_id", "callId", "orderId"]),
      user: userSource != null ? AdminUserReference.fromJson(userSource) : null,
      planName: planName ??
          _readStringOrNull(
            json,
            const [
              "plan",
              "planName",
              "segment",
              "product",
            ],
          ),
      amount: _readDoubleOrNull(json, const [
        "amount",
        "price",
        "total",
        "payableAmount",
      ]),
      currency: _readStringOrNull(json, const [
        "currency",
        "currencyCode",
      ]),
      status: _readStringOrNull(json, const [
        "status",
        "state",
        "paymentStatus",
      ]),
      channel: _readStringOrNull(json, const [
        "channel",
        "source",
        "platform",
      ]),
      createdAt: _readDateTime(json, const [
        "createdAt",
        "created_at",
        "purchasedAt",
        "timestamp",
        "orderedAt",
      ]),
      updatedAt: _readDateTime(json, const [
        "updatedAt",
        "updated_at",
        "modifiedAt",
      ]),
      metadata: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

@immutable
class AdminWalletEntry {
  const AdminWalletEntry({
    required this.id,
    required this.amount,
    required this.isCredit,
    this.type,
    this.status,
    this.description,
    this.user,
    this.createdAt,
    this.updatedAt,
    this.balanceAfter,
    this.metadata = const {},
  });

  final String id;
  final double amount;
  final bool isCredit;
  final String? type;
  final String? status;
  final String? description;
  final AdminUserReference? user;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double? balanceAfter;
  final Map<String, dynamic> metadata;

  factory AdminWalletEntry.fromJson(Map<String, dynamic> json) {
    final userSource =
        _asMap(json["user"]) ?? _asMap(json["owner"]) ?? _extractUser(json);
    final type = _readStringOrNull(json, const [
      "type",
      "entryType",
      "category",
      "transactionType",
    ]);
    final rawAmount = _readDoubleOrNull(json, const [
      "amount",
      "value",
      "delta",
    ]);
    final isCredit = _readBool(json, const [
          "isCredit",
          "credit",
          "is_credit",
        ]) ??
        (rawAmount != null ? rawAmount >= 0 : null) ??
        (type != null
            ? type.toLowerCase().contains("credit") ||
                type.toLowerCase().contains("topup")
            : false);
    return AdminWalletEntry(
      id: _readString(json, const ["id", "_id", "entryId", "transactionId"]),
      amount: rawAmount ?? 0,
      isCredit: isCredit,
      type: type,
      status: _readStringOrNull(json, const [
        "status",
        "state",
        "entryStatus",
      ]),
      description: _readStringOrNull(json, const [
        "description",
        "note",
        "narration",
        "details",
      ]),
      user: userSource != null ? AdminUserReference.fromJson(userSource) : null,
      createdAt: _readDateTime(json, const [
        "createdAt",
        "created_at",
        "timestamp",
        "date",
        "performedAt",
      ]),
      updatedAt: _readDateTime(json, const [
        "updatedAt",
        "updated_at",
        "modifiedAt",
      ]),
      balanceAfter: _readDoubleOrNull(json, const [
        "balance",
        "walletBalance",
        "balanceAfter",
      ]),
      metadata: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

@immutable
class AdminLeaderboardEntry {
  const AdminLeaderboardEntry({
    required this.rank,
    required this.total,
    this.metricLabel,
    this.user,
    this.metadata = const {},
  });

  final int rank;
  final double total;
  final String? metricLabel;
  final AdminUserReference? user;
  final Map<String, dynamic> metadata;

  factory AdminLeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final userSource =
        _asMap(json["user"]) ?? _asMap(json["member"]) ?? _extractUser(json);
    return AdminLeaderboardEntry(
      rank: _readInt(json, const [
        "rank",
        "position",
        "index",
      ]),
      total: _readDouble(json, const [
        "total",
        "amount",
        "value",
        "score",
      ]),
      metricLabel: _readStringOrNull(json, const [
        "label",
        "metric",
        "type",
      ]),
      user: userSource != null ? AdminUserReference.fromJson(userSource) : null,
      metadata: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

@immutable
class AdminUserReference {
  const AdminUserReference({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.username,
    this.role,
    this.avatarUrl,
    this.metadata = const {},
  });

  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? username;
  final String? role;
  final String? avatarUrl;
  final Map<String, dynamic> metadata;

  factory AdminUserReference.fromJson(Map<String, dynamic> json) {
    return AdminUserReference(
      id: _readString(json, const ["id", "_id", "userId"]),
      name: _readStringOrNull(json, const [
        "name",
        "fullName",
        "displayName",
        "firstName",
      ]),
      email: _readStringOrNull(json, const ["email", "mail"]),
      phone: _readStringOrNull(json, const [
        "phone",
        "mobile",
        "contact",
      ]),
      username: _readStringOrNull(json, const [
        "username",
        "handle",
        "userName",
      ]),
      role: _readStringOrNull(json, const ["role", "userRole"]),
      avatarUrl: _readStringOrNull(json, const [
        "avatar",
        "avatarUrl",
        "photo",
      ]),
      metadata: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

@immutable
class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    this.totalPages,
    this.raw = const {},
  });

  final List<T> items;
  final int page;
  final int limit;
  final int total;
  final int? totalPages;
  final Map<String, dynamic> raw;
}

PaginatedResult<T> buildPaginatedResult<T>(
  dynamic payload,
  T Function(Map<String, dynamic> json) mapper,
) {
  final root = _unwrapResponse(_asMap(payload) ?? const {});
  final itemsSource = root["items"] ??
      root["data"] ??
      root["records"] ??
      root["results"] ??
      root["rows"];
  final items = _mapList(itemsSource, mapper);
  final meta = _asMap(root["meta"]) ??
      _asMap(root["pagination"]) ??
      _asMap(root["page"]);
  final page = _readInt(meta ?? root, const [
    "page",
    "currentPage",
    "current_page",
    "pageIndex",
  ]);
  final limit = _readInt(meta ?? root, const [
    "limit",
    "pageSize",
    "perPage",
    "per_page",
  ]);
  final total = _readInt(meta ?? root, const [
    "total",
    "totalItems",
    "total_items",
    "count",
    "totalCount",
  ]);
  final totalPages = _readIntOrNull(meta ?? root, const [
    "pages",
    "totalPages",
    "total_pages",
    "pageCount",
  ]);

  return PaginatedResult<T>(
    items: items,
    page: page,
    limit: limit,
    total: total,
    totalPages: totalPages,
    raw: root,
  );
}

@immutable
class AdminUserSummary {
  const AdminUserSummary({
    required this.reference,
    this.role,
    this.walletBalance,
    this.pendingReferral,
    this.totalReferralPaid,
    this.totalCalls,
    this.createdAt,
    this.lastActiveAt,
    this.metadata = const {},
  });

  final AdminUserReference reference;
  final String? role;
  final double? walletBalance;
  final double? pendingReferral;
  final double? totalReferralPaid;
  final int? totalCalls;
  final DateTime? createdAt;
  final DateTime? lastActiveAt;
  final Map<String, dynamic> metadata;

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    final userSource = _asMap(json["user"]) ?? json;
    final reference = AdminUserReference.fromJson(userSource);
    return AdminUserSummary(
      reference: reference,
      role: _readStringOrNull(json, const ["role", "userRole"]) ??
          reference.role,
      walletBalance: _readDoubleOrNull(json, const [
        "walletBalance",
        "wallet",
        "wallet_total",
        "wallet_total_balance",
      ]),
      pendingReferral: _readDoubleOrNull(json, const [
        "pendingReferral",
        "pendingReferralBalance",
        "pending_referral",
      ]),
      totalReferralPaid: _readDoubleOrNull(json, const [
        "referralPaid",
        "totalReferralPaid",
        "paidReferral",
      ]),
      totalCalls: _readIntOrNull(json, const [
        "totalCalls",
        "calls",
        "purchases",
      ]),
      createdAt: _readDateTime(json, const [
        "createdAt",
        "created_at",
        "joinedAt",
        "registeredAt",
      ]),
      lastActiveAt: _readDateTime(json, const [
        "lastActiveAt",
        "last_active_at",
        "lastLogin",
      ]),
      metadata: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

@immutable
class AdminUserDetail {
  const AdminUserDetail({
    required this.summary,
    required this.wallet,
    required this.referralStats,
    required this.recentCalls,
    required this.recentLedger,
    required this.referralHistory,
    this.metadata = const {},
  });

  final AdminUserSummary summary;
  final AdminWalletSnapshot wallet;
  final AdminReferralStats referralStats;
  final List<AdminCallRecord> recentCalls;
  final List<AdminWalletEntry> recentLedger;
  final List<AdminReferralEntry> referralHistory;
  final Map<String, dynamic> metadata;

  factory AdminUserDetail.fromJson(Map<String, dynamic> json) {
    final root = _unwrapResponse(json);
    final summarySource =
        _asMap(root["user"]) ?? _asMap(root["summary"]) ?? root;
    final summary = AdminUserSummary.fromJson(summarySource);
    return AdminUserDetail(
      summary: summary,
      wallet: AdminWalletSnapshot.fromJson(
        _asMap(root["wallet"]) ?? root,
      ),
      referralStats: AdminReferralStats.fromJson(
        _asMap(root["referrals"]) ?? root,
      ),
      recentCalls: _mapList(
        root["recentCalls"] ??
            root["purchases"] ??
            root["calls"] ??
            root["recentPurchases"],
        AdminCallRecord.fromJson,
      ),
      recentLedger: _mapList(
        root["recentLedger"] ??
            root["walletLedger"] ??
            root["ledger"] ??
            root["walletEntries"],
        AdminWalletEntry.fromJson,
      ),
      referralHistory: _mapList(
        root["referralHistory"] ??
            root["referrals"] ??
            root["referralLedger"] ??
            root["referralEntries"],
        AdminReferralEntry.fromJson,
      ),
      metadata: root,
    );
  }
}

@immutable
class AdminWalletSnapshot {
  const AdminWalletSnapshot({
    required this.available,
    required this.locked,
    required this.pending,
    this.totalTopUps,
    this.totalWithdrawals,
    this.metadata = const {},
  });

  final double available;
  final double locked;
  final double pending;
  final double? totalTopUps;
  final double? totalWithdrawals;
  final Map<String, dynamic> metadata;

  factory AdminWalletSnapshot.fromJson(Map<String, dynamic> json) {
    return AdminWalletSnapshot(
      available: _readDouble(json, const [
        "available",
        "balance",
        "walletBalance",
      ]),
      locked: _readDouble(json, const [
        "locked",
        "hold",
        "lockedBalance",
      ], defaultValue: 0),
      pending: _readDouble(json, const [
        "pending",
        "pendingBalance",
      ], defaultValue: 0),
      totalTopUps: _readDoubleOrNull(json, const [
        "totalTopUps",
        "topups",
        "topUps",
      ]),
      totalWithdrawals: _readDoubleOrNull(json, const [
        "totalWithdrawals",
        "withdrawals",
      ]),
      metadata: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

@immutable
class AdminReferralStats {
  const AdminReferralStats({
    required this.pending,
    required this.paid,
    required this.cancelled,
    required this.total,
    this.metadata = const {},
  });

  final double pending;
  final double paid;
  final double cancelled;
  final double total;
  final Map<String, dynamic> metadata;

  factory AdminReferralStats.fromJson(Map<String, dynamic> json) {
    final pending = _readDouble(json, const [
      "pending",
      "pendingAmount",
      "pendingReferral",
    ], defaultValue: 0);
    final paid = _readDouble(json, const [
      "paid",
      "paidAmount",
      "referralPaid",
    ], defaultValue: 0);
    final cancelled = _readDouble(json, const [
      "cancelled",
      "cancelledAmount",
      "referralCancelled",
    ], defaultValue: 0);
    final total = _readDouble(json, const [
      "total",
      "totalAmount",
      "referralTotal",
    ], defaultValue: pending + paid + cancelled);
    return AdminReferralStats(
      pending: pending,
      paid: paid,
      cancelled: cancelled,
      total: total,
      metadata: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

@immutable
class AdminReferralEntry {
  const AdminReferralEntry({
    required this.id,
    required this.amount,
    required this.status,
    this.user,
    this.sourceUser,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  final String id;
  final double amount;
  final String status;
  final AdminUserReference? user;
  final AdminUserReference? sourceUser;
  final String? description;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  factory AdminReferralEntry.fromJson(Map<String, dynamic> json) {
    final userSource =
        _asMap(json["user"]) ?? _asMap(json["beneficiary"]) ?? _extractUser(json);
    final sourceUser = _asMap(json["source"]) ??
        _asMap(json["referrer"]) ??
        _asMap(json["from"]);
    return AdminReferralEntry(
      id: _readString(json, const ["id", "_id", "entryId"]),
      amount: _readDouble(json, const [
        "amount",
        "value",
        "referralAmount",
      ]),
      status: _readString(json, const [
        "status",
        "state",
        "referralStatus",
      ]),
      user: userSource != null ? AdminUserReference.fromJson(userSource) : null,
      sourceUser:
          sourceUser != null ? AdminUserReference.fromJson(sourceUser) : null,
      description: _readStringOrNull(json, const [
        "description",
        "note",
        "details",
      ]),
      createdAt: _readDateTime(json, const [
        "createdAt",
        "created_at",
        "timestamp",
      ]),
      updatedAt: _readDateTime(json, const [
        "updatedAt",
        "updated_at",
      ]),
      metadata: Map<String, dynamic>.unmodifiable(json),
    );
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.details});

  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() =>
      "ApiException(statusCode: $statusCode, message: $message, details: $details)";
}

Map<String, dynamic> _unwrapResponse(Map<String, dynamic> source) {
  final data = source["data"];
  if (data is Map<String, dynamic>) {
    return data;
  }
  if (data is List) {
    return <String, dynamic>{
      "items": data,
      ...source,
    };
  }
  return source;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map<String, dynamic>(
      (key, dynamic value) => MapEntry("$key", value),
    );
  }
  return null;
}

List<T> _mapList<T>(
  dynamic value,
  T Function(Map<String, dynamic> json) builder,
) {
  if (value is List) {
    final results = <T>[];
    for (final item in value) {
      final map = _asMap(item);
      if (map != null) {
        results.add(builder(map));
      }
    }
    return List<T>.unmodifiable(results);
  }
  final map = _asMap(value);
  if (map != null) {
    return List<T>.unmodifiable([builder(map)]);
  }
  return const [];
}

int _readInt(
  Map<String, dynamic> source,
  List<String> keys, {
  int defaultValue = 0,
}) {
  for (final key in keys) {
    final value = source[key];
    final parsed = _tryParseInt(value);
    if (parsed != null) return parsed;
  }
  return defaultValue;
}

int? _readIntOrNull(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    final parsed = _tryParseInt(value);
    if (parsed != null) return parsed;
  }
  return null;
}

double _readDouble(
  Map<String, dynamic> source,
  List<String> keys, {
  double defaultValue = 0,
}) {
  for (final key in keys) {
    final value = source[key];
    final parsed = _tryParseDouble(value);
    if (parsed != null) return parsed;
  }
  return defaultValue;
}

double? _readDoubleOrNull(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    final parsed = _tryParseDouble(value);
    if (parsed != null) return parsed;
  }
  return null;
}

String _readString(
  Map<String, dynamic> source,
  List<String> keys, {
  String defaultValue = "",
}) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return defaultValue;
}

String? _readStringOrNull(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

bool? _readBool(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == "true" ||
          normalized == "yes" ||
          normalized == "1" ||
          normalized == "credit") {
        return true;
      }
      if (normalized == "false" ||
          normalized == "no" ||
          normalized == "0" ||
          normalized == "debit") {
        return false;
      }
    }
    if (value is num) {
      if (value == 1) return true;
      if (value == 0) return false;
    }
  }
  return null;
}

DateTime? _readDateTime(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    final parsed = _tryParseDateTime(value);
    if (parsed != null) return parsed;
  }
  return null;
}

int? _tryParseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

double? _tryParseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) {
    final normalized = value.replaceAll(RegExp(r"[^0-9\\.,-]"), "");
    final parsed = double.tryParse(normalized.replaceAll(",", ""));
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _tryParseDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is int) {
    if (value > 9999999999) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
          .toLocal();
    }
    return DateTime.fromMillisecondsSinceEpoch(value * 1000, isUtc: true)
        .toLocal();
  }
  if (value is String && value.trim().isNotEmpty) {
    final trimmed = value.trim();
    try {
      return DateTime.parse(trimmed).toLocal();
    } catch (_) {
      final normalized = trimmed.replaceAll("T", " ");
      try {
        return DateTime.parse(normalized).toLocal();
      } catch (_) {}
    }
  }
  return null;
}

Map<String, dynamic>? _extractUser(Map<String, dynamic> json) {
  for (final key in ["userId", "user_id", "uid"]) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return {"id": value};
    }
  }
  return null;
}
