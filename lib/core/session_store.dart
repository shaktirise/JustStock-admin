import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'admin_token';
  static const _nameKey = 'admin_name';
  static const _mobileKey = 'admin_mobile';
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
    required String mobile,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_mobileKey, mobile);
  }

  static Future<String?> loadAdminName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<String?> loadAdminMobile() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_mobileKey);
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
    await prefs.remove(_mobileKey);
    await prefs.remove(_lastActivityKey);
  }
}