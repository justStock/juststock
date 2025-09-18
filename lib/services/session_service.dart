import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  final String token;
  final String name;
  final String mobile;

  const AuthSession({
    required this.token,
    required this.name,
    required this.mobile,
  });

  bool get isValid => token.trim().isNotEmpty && mobile.trim().isNotEmpty;
}

class SessionService {
  static const _tokenKey = 'auth_token';
  static const _nameKey = 'auth_name';
  static const _mobileKey = 'auth_mobile';

  static Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token.trim());
    await prefs.setString(_nameKey, session.name.trim());
    await prefs.setString(_mobileKey, session.mobile.trim());
  }

  static Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString(_tokenKey) ?? '').trim();
    final name = (prefs.getString(_nameKey) ?? '').trim();
    final mobile = (prefs.getString(_mobileKey) ?? '').trim();
    if (token.trim().isEmpty || mobile.trim().isEmpty) {
      return null;
    }
    return AuthSession(token: token, name: name, mobile: mobile);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_mobileKey);
  }
}
