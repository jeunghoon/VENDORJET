import 'package:shared_preferences/shared_preferences.dart';

// 인증 서비스 인터페이스: 실제(Firebase/서버) 또는 목업 구현을 교체 가능하게 하는 계약
abstract class AuthService {
  Future<void> init();
  Future<bool> signIn(String email, String password);
  Future<void> signOut();
  Future<bool> isSignedIn();
  String? get currentEmail;
}

// 간단한 목업 인증 서비스: SharedPreferences로 로그인 상태/이메일 보관
class MockAuthService implements AuthService {
  static const _kSignedIn = 'auth_signed_in';
  static const _kEmail = 'auth_email';

  SharedPreferences? _prefs;
  String? _email;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _email = _prefs!.getString(_kEmail);
  }

  @override
  Future<bool> signIn(String email, String password) async {
    // 매우 단순한 유효성(데모용): 실제 환경에서는 서버/Firebase로 교체
    if (email.isEmpty || !email.contains('@') || password.length < 4) {
      return false;
    }
    _email = email;
    await _prefs?.setBool(_kSignedIn, true);
    await _prefs?.setString(_kEmail, email);
    return true;
  }

  @override
  Future<void> signOut() async {
    _email = null;
    await _prefs?.remove(_kSignedIn);
    await _prefs?.remove(_kEmail);
  }

  @override
  Future<bool> isSignedIn() async {
    return _prefs?.getBool(_kSignedIn) ?? false;
  }

  @override
  String? get currentEmail => _email;
}

