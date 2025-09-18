class AuthSession {
  static String? adminToken;

  static void clear() {
    adminToken = null;
  }

  static Map<String, String> withAuth(Map<String, String> headers) {
    final token = adminToken;
    if (token == null || token.isEmpty) return headers;
    return <String, String>{
      ...headers,
      'Authorization': 'Bearer $token',
      'X-Admin-Token': token,
      'x-admin-token': token,
    };
  }
}
