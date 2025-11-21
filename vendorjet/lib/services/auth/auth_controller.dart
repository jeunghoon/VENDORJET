import 'package:flutter/foundation.dart';

import '../../models/tenant.dart';
import 'api_auth_service.dart';
import 'auth_service.dart';

/// 인증/테넌트 상태를 관리하는 ChangeNotifier
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

  ApiAuthService? get _api => service is ApiAuthService ? service as ApiAuthService : null;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      await service.init();
      _signedIn = await service.isSignedIn();
      _email = service.currentEmail;
      _tenants = _signedIn ? await service.fetchTenants() : const [];
    } catch (_) {
      _signedIn = false;
      _email = null;
      _tenants = const [];
    }
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

  Future<bool> registerSeller({
    required String companyName,
    String companyAddress = '',
    String companyPhone = '',
    String name = '',
    String phone = '',
    required String email,
    required String password,
    String role = 'staff',
  }) async {
    if (service is ApiAuthService) {
      final ok = await (service as ApiAuthService).registerSeller(
        companyName: companyName,
        companyAddress: companyAddress,
        companyPhone: companyPhone,
        name: name,
        phone: phone,
        email: email,
        password: password,
        role: role,
      );
      if (ok) {
        // pending 가입 등 토큰이 없을 수 있으니, 토큰이 있을 때만 테넌트 목록 요청
        if (await service.isSignedIn()) {
          _tenants = await service.fetchTenants();
        }
        notifyListeners();
      }
      return ok;
    }
    return registerTenant(tenantName: companyName, email: email, password: password);
  }

  Future<bool> registerBuyer({
    required String sellerCompanyName,
    required String buyerCompanyName,
    String buyerAddress = '',
    String name = '',
    String phone = '',
    required String email,
    String attachmentUrl = '',
    String role = 'staff',
  }) async {
    if (service is ApiAuthService) {
      return await (service as ApiAuthService).registerBuyer(
        sellerCompanyName: sellerCompanyName,
        buyerCompanyName: buyerCompanyName,
        buyerAddress: buyerAddress,
        name: name,
        phone: phone,
        email: email,
        attachmentUrl: attachmentUrl,
        role: role,
      );
    }
    return false;
  }

  Future<void> inviteMember({
    required String email,
    required TenantMemberRole role,
  }) async {
    await service.inviteMember(email: email, role: role);
    notifyListeners();
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    return await _api?.fetchProfile();
  }

  Future<bool> updateProfile({
    String? email,
    String? phone,
    String? address,
    String? name,
    String? password,
  }) async {
    final ok = await _api?.updateProfile(
          email: email,
          phone: phone,
          address: address,
          name: name,
          password: password,
        ) ??
        false;
    if (ok) {
      _email = service.currentEmail;
      notifyListeners();
    }
    return ok;
  }

  Future<bool> deleteAccount() async {
    final ok = await _api?.deleteAccount() ?? false;
    if (ok) {
      _signedIn = false;
      _email = null;
      _tenants = const [];
      notifyListeners();
    }
    return ok;
  }

  Future<bool> createTenantForCurrentUser({
    required String name,
    String phone = '',
    String address = '',
  }) async {
    final profile = await fetchProfile();
    final userId = profile?['id'] as String?;
    if (userId == null) return false;
    final ok = await _api?.createTenantForUser(
          userId: userId,
          name: name,
          phone: phone,
          address: address,
        ) ??
        false;
    if (ok) {
      _tenants = await service.fetchTenants();
      notifyListeners();
    }
    return ok;
  }

  Future<bool> updateTenant({
    required String tenantId,
    String? name,
    String? phone,
    String? address,
  }) async {
    final ok = await _api?.updateTenant(
          tenantId: tenantId,
          name: name,
          phone: phone,
          address: address,
        ) ??
        false;
    if (ok) {
      _tenants = await service.fetchTenants();
      notifyListeners();
    }
    return ok;
  }

  Future<bool> deleteTenant(String tenantId) async {
    final ok = await _api?.deleteTenant(tenantId) ?? false;
    if (ok) {
      _tenants = await service.fetchTenants();
      notifyListeners();
    }
    return ok;
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

  Future<void> requestPasswordReset(String email) async {
    await service.requestPasswordReset(email);
  }
}
