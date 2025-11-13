import 'package:flutter/foundation.dart';

import '../../models/tenant.dart';
import 'auth_service.dart';

/// 인증/테넌시 상태를 관리하는 ChangeNotifier
class AuthController extends ChangeNotifier {
  final AuthService service;

  bool _loading = true;
  bool _signedIn = false;
  String? _email;
  List<Tenant> _tenants = const [];

  AuthController(this.service);

  bool get loading => _loading;
  bool get signedIn => _signedIn;
  String? get email => _email;
  Tenant? get tenant => service.currentTenant;
  TenantMemberRole? get role => service.currentRole;
  List<TenantMembership> get memberships => service.memberships;
  List<Tenant> get tenants => _tenants;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    await service.init();
    _signedIn = await service.isSignedIn();
    _email = service.currentEmail;
    _tenants = await service.fetchTenants();
    _loading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    final ok = await service.signIn(email, password);
    _signedIn = ok;
    if (ok) {
      _email = service.currentEmail;
      _tenants = await service.fetchTenants();
    }
    notifyListeners();
    return ok;
  }

  Future<bool> registerTenant({
    required String tenantName,
    required String email,
    required String password,
  }) async {
    final ok = await service.registerTenant(
      tenantName: tenantName,
      email: email,
      password: password,
    );
    if (ok) {
      _tenants = await service.fetchTenants();
      notifyListeners();
    }
    return ok;
  }

  Future<void> requestPasswordReset(String email) async {
    await service.requestPasswordReset(email);
  }

  Future<void> inviteMember({
    required String email,
    required TenantMemberRole role,
  }) async {
    await service.inviteMember(email: email, role: role);
    notifyListeners();
  }

  Future<bool> switchTenant(String tenantId) async {
    final ok = await service.switchTenant(tenantId);
    if (ok) notifyListeners();
    return ok;
  }

  Future<void> refreshTenants() async {
    _tenants = await service.fetchTenants();
    notifyListeners();
  }

  Future<void> signOut() async {
    await service.signOut();
    _signedIn = false;
    _email = null;
    notifyListeners();
  }
}
