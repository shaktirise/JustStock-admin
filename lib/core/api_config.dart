class AdminApiConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'ADMIN_API_BASE_URL',
    defaultValue: 'https://backend-server-11f5.onrender.com',
  );

  static String get _baseWithoutSlash => apiBaseUrl.endsWith('/')
      ? apiBaseUrl.substring(0, apiBaseUrl.length - 1)
      : apiBaseUrl;

  static Uri buildUri(String path, [Map<String, dynamic>? query]) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$_baseWithoutSlash$normalizedPath');
    if (query == null || query.isEmpty) return uri;
    final qp = <String, String>{};
    query.forEach((k, v) {
      if (v == null) return;
      qp[k] = v is DateTime ? v.toUtc().toIso8601String() : v.toString();
    });
    return uri.replace(queryParameters: qp);
  }
}

