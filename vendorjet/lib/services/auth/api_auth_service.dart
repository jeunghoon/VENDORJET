import 'package:shared_preferences/shared_preferences.dart';

import '../../models/tenant.dart';
import '../api/api_client.dart';
import 'auth_service.dart';

/// 로컬 API 서버 연동 버전
class ApiAuthService implements AuthService {
  static const _kToken = 'api_auth_token';
  static const _kEmail = 'api_auth_email';
  static const _kTenant = 'api_auth_tenant';

  SharedPreferences? _prefs;
  String? _email;
  String? _currentTenantId;
  List<TenantMembership> _memberships = const [];
  List<Tenant> _tenants = const [];

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    ApiClient.token = _prefs?.getString(_kToken);
    _email = _prefs?.getString(_kEmail);
    _currentTenantId = _prefs?.getString(_kTenant);
    ApiClient.tenantId = _currentTenantId;
    if (ApiClient.token != null) {
      try {
        _tenants = await fetchTenants();
      } catch (_) {
        // 토큰 만료 등은 무시
      }
    }
  }

  @override
  Future<bool> signIn(String email, String password) async {
    try {
      final resp = await ApiClient.post('/auth/login', body: {
        'email': email,
        'password': password,
      }) as Map<String, dynamic>;
      final token = resp['token'] as String?;
      if (token == null) return false;
      ApiClient.token = token;
      _email = email.toLowerCase();
      _memberships = (resp['memberships'] as List<dynamic>? ?? [])
          .map((m) => TenantMembership(
                tenantId: m['tenantId'] as String,
                role: _roleFromString(m['role'] as String?),
              ))
          .toList();
      _currentTenantId = _memberships.isNotEmpty ? _memberships.first.tenantId : null;
      ApiClient.tenantId = _currentTenantId;
      _tenants = await fetchTenants();
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final resp = await ApiClient.get('/auth/profile') as Map<String, dynamic>;
      return resp;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateProfile({
    String? email,
    String? phone,
    String? address,
    String? name,
    String? password,
  }) async {
    final body = <String, String>{};
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (body.isEmpty) return true;
    try {
      await ApiClient.patch('/auth/profile', body: body);
      if (email != null && email.isNotEmpty) _email = email.toLowerCase();
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      await ApiClient.delete('/auth/profile');
      await signOut();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    ApiClient.token = null;
    _email = null;
    _currentTenantId = null;
    _memberships = const [];
    _tenants = const [];
    await _prefs?.remove(_kToken);
    await _prefs?.remove(_kEmail);
    await _prefs?.remove(_kTenant);
  }

  @override
  Future<bool> isSignedIn() async => ApiClient.token != null;

  @override
  String? get currentEmail => _email;

  @override
  Tenant? get currentTenant {
    if (_currentTenantId == null) return _tenants.isNotEmpty ? _tenants.first : null;
    return _tenants.firstWhere(
      (t) => t.id == _currentTenantId,
      orElse: () => _tenants.isNotEmpty ? _tenants.first : Tenant(id: '', name: '', createdAt: DateTime.now()),
    );
  }

  @override
  TenantMemberRole? get currentRole {
    final tId = _currentTenantId;
    if (tId == null) return null;
    return _memberships
        .firstWhere(
          (m) => m.tenantId == tId,
          orElse: () => _memberships.isNotEmpty ? _memberships.first : TenantMembership(tenantId: '', role: TenantMemberRole.staff),
        )
        .role;
  }

  @override
  List<TenantMembership> get memberships => List.unmodifiable(_memberships);

  @override
  Future<List<Tenant>> fetchTenants() async {
    try {
      final resp = await ApiClient.get('/auth/tenants') as List<dynamic>;
      final tenants = resp
          .map((e) => Tenant(
                id: e['id'] as String,
                name: e['name'] as String,
                phone: (e['phone'] as String?) ?? '',
                address: (e['address'] as String?) ?? '',
                type: _typeFromString(e['type'] as String?),
                createdAt: DateTime.tryParse((e['createdAt'] ?? '') as String? ?? '') ?? DateTime.now(),
              ))
          .toList();
      _tenants = tenants;
      return tenants;
    } catch (_) {
      _tenants = const [];
      return _tenants;
    }
  }

  @override
  Future<bool> switchTenant(String tenantId) async {
    final allowed = _memberships.any((m) => m.tenantId == tenantId);
    if (!allowed) return false;
    _currentTenantId = tenantId;
    ApiClient.tenantId = tenantId;
    await _persist();
    return true;
  }

  @override
  Future<bool> registerTenant({
    required String tenantName,
    required String email,
    required String password,
  }) async {
    return await registerSeller(
      companyName: tenantName,
      email: email,
      password: password,
    );
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
    try {
      final resp = await ApiClient.post('/auth/register', body: {
        'companyName': companyName,
        'companyAddress': companyAddress,
        'companyPhone': companyPhone,
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'role': role,
      }) as Map<String, dynamic>;
      final token = resp['token'] as String?;
      // 신규 테넌트는 201 + token, 기존 테넌트는 202(pending)로 token이 없을 수 있음
      if (token == null) {
        final status = resp['status'] as String?;
        return status == 'pending';
      }
      ApiClient.token = token;
      _email = email.toLowerCase();
      _memberships = (resp['memberships'] as List<dynamic>? ?? [])
          .map((m) => TenantMembership(
                tenantId: m['tenantId'] as String,
                role: _roleFromString(m['role'] as String?),
              ))
          .toList();
      _currentTenantId = _memberships.isNotEmpty ? _memberships.first.tenantId : null;
      _tenants = await fetchTenants();
      await _persist();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> registerBuyer({
    required String sellerCompanyName,
    required String buyerCompanyName,
    String buyerAddress = '',
    String name = '',
    String phone = '',
    required String email,
    required String password,
    String attachmentUrl = '',
    String role = 'staff',
  }) async {
    try {
      await ApiClient.post('/auth/register-buyer', body: {
        'sellerCompanyName': sellerCompanyName,
        'buyerCompanyName': buyerCompanyName,
        'buyerAddress': buyerAddress,
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
        'attachmentUrl': attachmentUrl,
        'role': role,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> inviteMember({
    required String email,
    required TenantMemberRole role,
  }) async {
    // 서버 미구현: no-op
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    // 서버 미구현: no-op
  }

  Future<bool> createTenantForUser({
    required String userId,
    required String name,
    String phone = '',
    String address = '',
  }) async {
    try {
      await ApiClient.post('/admin/tenants', body: {
        'userId': userId,
        'name': name,
        'phone': phone,
        'address': address,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateTenant({
    required String tenantId,
    String? name,
    String? phone,
    String? address,
  }) async {
    final body = <String, String>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (body.isEmpty) return true;
    try {
      await ApiClient.patch('/admin/tenants/$tenantId', body: body);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTenant(String tenantId) async {
    try {
      await ApiClient.delete('/admin/tenants/$tenantId');
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _persist() async {
    await _prefs?.setString(_kEmail, _email ?? '');
    if (_currentTenantId != null) {
      await _prefs?.setString(_kTenant, _currentTenantId!);
    }
    if (ApiClient.token != null) {
      await _prefs?.setString(_kToken, ApiClient.token!);
    }
  }

  TenantMemberRole _roleFromString(String? value) {
    switch (value) {
      case 'owner':
        return TenantMemberRole.owner;
      case 'manager':
        return TenantMemberRole.manager;
      default:
        return TenantMemberRole.staff;
    }
  }

  TenantType _typeFromString(String? value) {
    switch (value) {
      case 'seller':
        return TenantType.seller;
      case 'buyer':
        return TenantType.buyer;
      default:
        return TenantType.unknown;
    }
  }
}
