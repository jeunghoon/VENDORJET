import 'package:shared_preferences/shared_preferences.dart';

import '../../models/tenant.dart';

/// 인증 서비스 계약: 향후 Firebase/백엔드 구현과 교체 가능하도록 정의
abstract class AuthService {
  Future<void> init();
  Future<bool> signIn(String email, String password);
  Future<void> signOut();
  Future<bool> isSignedIn();
  String? get currentEmail;
  Tenant? get currentTenant;
  TenantMemberRole? get currentRole;
  List<TenantMembership> get memberships;
  Future<List<Tenant>> fetchTenants();
  Future<bool> switchTenant(String tenantId);
  Future<bool> registerTenant({
    required String tenantName,
    required String email,
    required String password,
  });
  Future<void> inviteMember({
    required String email,
    required TenantMemberRole role,
  });
  Future<void> requestPasswordReset(String email);
}

/// 간단한 목업 인증 서비스: SharedPreferences에 로그인 상태/이메일 저장 + 메모리 내 테넌시 시뮬
class MockAuthService implements AuthService {
  static const _kSignedIn = 'auth_signed_in';
  static const _kEmail = 'auth_email';
  static const _kTenant = 'auth_tenant';

  SharedPreferences? _prefs;
  String? _email;
  String? _currentTenantId;

  final List<Tenant> _tenants = [
    Tenant(
      id: 't_acme',
      name: 'Acme Wholesale',
      createdAt: DateTime(2021, 4, 7),
    ),
    Tenant(
      id: 't_nova',
      name: 'Nova Distribution',
      createdAt: DateTime(2022, 9, 12),
    ),
  ];
  final Map<String, _MockUser> _users = {};

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _email = _prefs!.getString(_kEmail);
    _currentTenantId = _prefs!.getString(_kTenant);
    _seedUsers();
  }

  @override
  Future<bool> signIn(String email, String password) async {
    final normalized = email.toLowerCase().trim();
    final user = _users[normalized];
    if (user == null || user.password != password) {
      return false;
    }
    _email = normalized;
    final currentMembership = user.memberships.isNotEmpty
        ? user.memberships.first
        : null;
    _currentTenantId = currentMembership?.tenantId;
    await _prefs?.setBool(_kSignedIn, true);
    await _prefs?.setString(_kEmail, normalized);
    if (_currentTenantId != null) {
      await _prefs?.setString(_kTenant, _currentTenantId!);
    }
    return true;
  }

  @override
  Future<void> signOut() async {
    _email = null;
    _currentTenantId = null;
    await _prefs?.remove(_kSignedIn);
    await _prefs?.remove(_kEmail);
    await _prefs?.remove(_kTenant);
  }

  @override
  Future<bool> isSignedIn() async {
    return _prefs?.getBool(_kSignedIn) ?? false;
  }

  @override
  String? get currentEmail => _email;

  @override
  Tenant? get currentTenant => _tenants.firstWhere(
    (tenant) => tenant.id == _currentTenantId,
    orElse: () => _currentTenantFallback,
  );

  Tenant get _currentTenantFallback => _tenants.first;

  @override
  TenantMemberRole? get currentRole {
    final email = _email;
    if (email == null) return null;
    final user = _users[email];
    if (user == null || _currentTenantId == null) return null;
    return user.memberships
        .firstWhere(
          (m) => m.tenantId == _currentTenantId,
          orElse: () => user.memberships.first,
        )
        .role;
  }

  @override
  List<TenantMembership> get memberships {
    final email = _email;
    if (email == null) return const [];
    return List.unmodifiable(_users[email]?.memberships ?? const []);
  }

  @override
  Future<List<Tenant>> fetchTenants() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return List.unmodifiable(_tenants);
  }

  @override
  Future<bool> switchTenant(String tenantId) async {
    final allowed = memberships.any((m) => m.tenantId == tenantId);
    if (!allowed) return false;
    _currentTenantId = tenantId;
    await _prefs?.setString(_kTenant, tenantId);
    return true;
  }

  @override
  Future<bool> registerTenant({
    required String tenantName,
    required String email,
    required String password,
  }) async {
    if (tenantName.trim().isEmpty || email.isEmpty || password.length < 6) {
      return false;
    }
    final normalized = email.toLowerCase();
    if (_users.containsKey(normalized)) {
      return false;
    }
    final safeName = tenantName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '',
    );
    final tenantId = 't_${safeName}_${DateTime.now().millisecondsSinceEpoch}';
    final tenant = Tenant(
      id: tenantId,
      name: tenantName.trim(),
      createdAt: DateTime.now(),
    );
    _tenants.add(tenant);
    _users[normalized] = _MockUser(
      email: normalized,
      password: password,
      memberships: [
        TenantMembership(tenantId: tenantId, role: TenantMemberRole.owner),
      ],
    );
    return true;
  }

  @override
  Future<void> inviteMember({
    required String email,
    required TenantMemberRole role,
  }) async {
    final tenantId = _currentTenantId;
    if (tenantId == null) return;
    final normalized = email.toLowerCase();
    final user = _users.putIfAbsent(
      normalized,
      () => _MockUser(email: normalized, password: 'changeme', memberships: []),
    );
    final exists = user.memberships.any((m) => m.tenantId == tenantId);
    if (!exists) {
      user.memberships.add(TenantMembership(tenantId: tenantId, role: role));
    }
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  void _seedUsers() {
    if (_users.isNotEmpty) return;
    _users.addAll({
      'alex@vendorjet.com': _MockUser(
        email: 'alex@vendorjet.com',
        password: 'welcome1',
        memberships: [
          TenantMembership(tenantId: 't_acme', role: TenantMemberRole.owner),
          TenantMembership(tenantId: 't_nova', role: TenantMemberRole.manager),
        ],
      ),
      'morgan@vendorjet.com': _MockUser(
        email: 'morgan@vendorjet.com',
        password: 'welcome1',
        memberships: [
          TenantMembership(tenantId: 't_acme', role: TenantMemberRole.staff),
        ],
      ),
      'jamie@vendorjet.com': _MockUser(
        email: 'jamie@vendorjet.com',
        password: 'welcome1',
        memberships: [
          TenantMembership(tenantId: 't_nova', role: TenantMemberRole.manager),
        ],
      ),
    });
  }
}

class _MockUser {
  final String email;
  final String password;
  final List<TenantMembership> memberships;

  _MockUser({
    required this.email,
    required this.password,
    required this.memberships,
  });
}
