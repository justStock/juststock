import 'package:shared_preferences/shared_preferences.dart';

class AuthSession {
  final String token;
  final String name;
  final String mobile;
  final bool termsAccepted;

  const AuthSession({
    required this.token,
    required this.name,
    required this.mobile,
    required this.termsAccepted,
  });

  bool get isValid => token.trim().isNotEmpty && mobile.trim().isNotEmpty;

  AuthSession copyWith({
    String? token,
    String? name,
    String? mobile,
    bool? termsAccepted,
  }) {
    return AuthSession(
      token: token ?? this.token,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      termsAccepted: termsAccepted ?? this.termsAccepted,
    );
  }
}

class SessionService {
  static const _tokenKey = 'auth_token';
  static const _nameKey = 'auth_name';
  static const _mobileKey = 'auth_mobile';
  static const _termsAcceptedKey = 'auth_terms_accepted';

  static Future<void> saveSession(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, session.token.trim());
    await prefs.setString(_nameKey, session.name.trim());
    await prefs.setString(_mobileKey, session.mobile.trim());
    await prefs.setBool(_termsAcceptedKey, session.termsAccepted);
  }

  static Future<AuthSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = (prefs.getString(_tokenKey) ?? '').trim();
    final name = (prefs.getString(_nameKey) ?? '').trim();
    final mobile = (prefs.getString(_mobileKey) ?? '').trim();
    final termsAccepted = prefs.getBool(_termsAcceptedKey) ?? false;
    if (token.trim().isEmpty || mobile.trim().isEmpty) {
      return null;
    }
    return AuthSession(
      token: token,
      name: name,
      mobile: mobile,
      termsAccepted: termsAccepted,
    );
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_mobileKey);
    await prefs.remove(_termsAcceptedKey);
  }
}
