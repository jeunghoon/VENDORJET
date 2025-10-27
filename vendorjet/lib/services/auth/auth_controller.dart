import 'package:flutter/foundation.dart';
import 'auth_service.dart';

// 인증 상태를 관리하는 컨트롤러(ChangeNotifier):
// - 앱 시작 시 로그인 상태 로드
// - 로그인/로그아웃 처리 및 UI 갱신 알림
class AuthController extends ChangeNotifier {
  final AuthService service;

  bool _loading = true;
  bool _signedIn = false;
  String? _email;

  AuthController(this.service);

  bool get loading => _loading;
  bool get signedIn => _signedIn;
  String? get email => _email;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    await service.init();
    _signedIn = await service.isSignedIn();
    _email = service.currentEmail;
    _loading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    final ok = await service.signIn(email, password);
    _signedIn = ok;
    if (ok) _email = email;
    notifyListeners();
    return ok;
  }

  Future<void> signOut() async {
    await service.signOut();
    _signedIn = false;
    _email = null;
    notifyListeners();
  }
}

