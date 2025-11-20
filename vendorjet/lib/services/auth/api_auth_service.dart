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
    if (ApiClient.token != null) {
      try {
        _tenants = await fetchTenants();
      } catch (_) {
        // 토큰 만료 시 무시
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
      _tenants = await fetchTenants();
      await _persist();
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
                createdAt: DateTime.now(),
              ))
          .toList();
      _tenants = tenants;
      return tenants;
    } catch (_) {
      // 비로그인 또는 토큰 오류일 경우 빈 목록 반환
      _tenants = const [];
      return _tenants;
    }
  }

  @override
  Future<bool> switchTenant(String tenantId) async {
    final allowed = _memberships.any((m) => m.tenantId == tenantId);
    if (!allowed) return false;
    _currentTenantId = tenantId;
    await _persist();
    return true;
  }

  @override
  Future<bool> registerTenant({
    required String tenantName,
    required String email,
    required String password,
  }) async {
    // 새로운 판매자 가입은 /auth/register 사용 (companyName으로 전달)
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
      if (token == null) {
        // 승인 대기 상태일 수 있음
        return false;
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
        'attachmentUrl': attachmentUrl,
        'role': role,
      });
      return true; // 승인 대기
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
}
