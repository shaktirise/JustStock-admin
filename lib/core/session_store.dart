import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'admin_token';
  static const _nameKey = 'admin_name';
  static const _emailKey = 'admin_email';
  static const _legacyMobileKey = 'admin_mobile';
  static const _lastActivityKey = 'last_activity_ms';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveAdminProfile({
    required String name,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    await prefs.remove(_legacyMobileKey);
  }

  static Future<String?> loadAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> loadAdminEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ??
        prefs.getString(_legacyMobileKey);
  }

  static Future<void> touchLastActivityNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActivityKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<int?> loadLastActivityMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastActivityKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_legacyMobileKey);
    await prefs.remove(_lastActivityKey);
  }
}
