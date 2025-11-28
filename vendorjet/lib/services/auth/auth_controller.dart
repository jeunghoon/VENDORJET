import 'package:flutter/foundation.dart';

import '../../models/tenant.dart';
import 'api_auth_service.dart';
import 'auth_service.dart';

/// 인증/테넌트 상태를 관리하는 ChangeNotifier
class AuthController extends ChangeNotifier {
  final AuthService service;

  bool _loading = true;
  bool _signedIn = false;
  bool _pendingApproval = false;
  String? _email;
  String? _userType;
  List<Tenant> _tenants = const [];

  AuthController(this.service);

  bool get loading => _loading;
  bool get signedIn => _signedIn;
  bool get pendingApproval => _pendingApproval;
  String? get email => _email;
  String? get userType => _userType;
  bool get isBuyer => (_userType ?? 'wholesale') == 'retail';
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
      _userType = service is ApiAuthService ? (service as ApiAuthService).userType : null;
      _tenants = _signedIn ? await service.fetchTenants() : const [];
      _pendingApproval = _signedIn && (service.memberships.isEmpty || service.currentTenant == null);
    } catch (_) {
      _signedIn = false;
      _email = null;
      _tenants = const [];
      _pendingApproval = false;
    }
    _loading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    final ok = await service.signIn(email, password);
    _signedIn = ok;
    if (ok) {
      _email = service.currentEmail;
      _userType = service is ApiAuthService ? (service as ApiAuthService).userType : null;
      _tenants = await service.fetchTenants();
      _pendingApproval = service.memberships.isEmpty || service.currentTenant == null;
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
    bool isNew = true,
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
        isNew: isNew,
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
    String buyerSegment = '',
    String name = '',
    String phone = '',
    required String email,
    required String password,
    String attachmentUrl = '',
    String role = 'staff',
    bool isNewBuyerCompany = true,
  }) async {
    if (service is ApiAuthService) {
      return await (service as ApiAuthService).registerBuyer(
        sellerCompanyName: sellerCompanyName,
        buyerCompanyName: buyerCompanyName,
        buyerAddress: buyerAddress,
        buyerSegment: buyerSegment,
        name: name,
        phone: phone,
        email: email,
        password: password,
        attachmentUrl: attachmentUrl,
        role: role,
        isNewBuyerCompany: isNewBuyerCompany,
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
    _userType = null;
    _tenants = const [];
    _pendingApproval = false;
    notifyListeners();
  }

  Future<void> requestPasswordReset(String email) async {
    await service.requestPasswordReset(email);
  }
}
