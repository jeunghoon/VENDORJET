import 'package:shared_preferences/shared_preferences.dart';

import '../../models/tenant.dart';
import '../api/api_client.dart';
import 'auth_service.dart';
import 'buyer_reconnect_result.dart';

/// 로컬 API 서버 연동 버전
class ApiAuthService implements AuthService {
  static const _kToken = 'api_auth_token';
  static const _kEmail = 'api_auth_email';
  static const _kTenant = 'api_auth_tenant';
  static const _kUserType = 'api_user_type';
  static const _kPrimaryTenant = 'api_primary_tenant';
  static const _kLanguage = 'api_language';

  SharedPreferences? _prefs;
  String? _email;
  String? _currentTenantId;
  String? _userType;
  String? _primaryTenantId;
  String? _languageCode;
  List<TenantMembership> _memberships = const [];
  List<Tenant> _tenants = const [];

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    ApiClient.token = _prefs?.getString(_kToken);
    _email = _prefs?.getString(_kEmail);
    _currentTenantId = _prefs?.getString(_kTenant);
    _userType = _prefs?.getString(_kUserType);
    _primaryTenantId = _prefs?.getString(_kPrimaryTenant);
    _languageCode = _prefs?.getString(_kLanguage);
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
      final resp =
          await ApiClient.post(
                '/auth/login',
                body: {'email': email, 'password': password},
              )
              as Map<String, dynamic>;
      final token = resp['token'] as String?;
      if (token == null) return false;
      ApiClient.token = token;
      _email = email.toLowerCase();
      final userMap = (resp['user'] as Map<String, dynamic>?) ?? {};
      _userType = userMap['userType'] as String?;
      _languageCode = (userMap['language'] as String?)?.isNotEmpty == true
          ? (userMap['language'] as String)
          : _languageCode;
      _primaryTenantId = userMap['primaryTenantId'] as String?;
      _memberships = (resp['memberships'] as List<dynamic>? ?? [])
          .map(
            (m) => TenantMembership(
              tenantId: m['tenantId'] as String,
              role: _roleFromString(m['role'] as String?),
            ),
          )
          .toList();
      _currentTenantId = _memberships.isNotEmpty
          ? _memberships.first.tenantId
          : null;
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
    String? name,
    String? password,
    String? language,
    String? primaryTenantId,
  }) async {
    final body = <String, String>{};
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (language != null && language.isNotEmpty) body['language'] = language;
    if (primaryTenantId != null && primaryTenantId.isNotEmpty) {
      body['primaryTenantId'] = primaryTenantId;
    }
    if (body.isEmpty) return true;
    try {
      await ApiClient.patch('/auth/profile', body: body);
      if (email != null && email.isNotEmpty) _email = email.toLowerCase();
      if (primaryTenantId != null && primaryTenantId.isNotEmpty) {
        _primaryTenantId = primaryTenantId;
      }
      if (language != null && language.isNotEmpty) {
        _languageCode = language;
      }
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
    _userType = null;
    _primaryTenantId = null;
    _languageCode = null;
    _memberships = const [];
    _tenants = const [];
    await _prefs?.remove(_kToken);
    await _prefs?.remove(_kEmail);
    await _prefs?.remove(_kTenant);
    await _prefs?.remove(_kUserType);
    await _prefs?.remove(_kPrimaryTenant);
    await _prefs?.remove(_kLanguage);
  }

  @override
  Future<bool> isSignedIn() async => ApiClient.token != null;

  @override
  String? get currentEmail => _email;

  String? get userType => _userType;
  String? get primaryTenantId => _primaryTenantId;
  String? get languageCode => _languageCode;

  @override
  Tenant? get currentTenant {
    if (_currentTenantId == null) {
      return _tenants.isNotEmpty ? _tenants.first : null;
    }
    return _tenants.firstWhere(
      (t) => t.id == _currentTenantId,
      orElse: () => _tenants.isNotEmpty
          ? _tenants.first
          : Tenant(id: '', name: '', createdAt: DateTime.now()),
    );
  }

  @override
  TenantMemberRole? get currentRole {
    final tId = _currentTenantId;
    if (tId == null) return null;
    return _memberships
        .firstWhere(
          (m) => m.tenantId == tId,
          orElse: () => _memberships.isNotEmpty
              ? _memberships.first
              : TenantMembership(tenantId: '', role: TenantMemberRole.staff),
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
          .map(
            (e) {
              final rawType =
                  (e['type'] as String?) ??
                  (e['tenantType'] as String?) ??
                  (e['tenant_type'] as String?);
              final rawPrimary = e['isPrimary'] ?? e['is_primary'];
              final isPrimary = switch (rawPrimary) {
                bool b => b,
                num n => n != 0,
                String s => s == '1' || s.toLowerCase() == 'true',
                _ => false,
              };
              return Tenant(
                id: e['id'] as String,
                name: e['name'] as String,
                phone: (e['phone'] as String?) ?? '',
                address: (e['address'] as String?) ?? '',
                type: _typeFromString(rawType),
                representative: (e['representative'] as String?) ?? '',
                isPrimary: isPrimary || ((e['id'] as String?) == _primaryTenantId),
                createdAt:
                    DateTime.tryParse(
                      (e['createdAt'] as String?) ??
                          (e['created_at'] as String?) ??
                          '',
                    ) ??
                    DateTime.now(),
              );
            },
          )
          .toList();
      _tenants = tenants;
      return tenants;
    } catch (_) {
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
      isNew: true,
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
    bool isNew = true,
  }) async {
    try {
      final resp =
          await ApiClient.post(
                '/auth/register',
                body: {
                  'companyName': companyName,
                  'companyAddress': companyAddress,
                  'companyPhone': companyPhone,
                  'name': name,
                  'phone': phone,
                  'email': email,
                  'password': password,
                  'role': role,
                  'mode': isNew ? 'new' : 'existing',
                },
              )
              as Map<String, dynamic>;
      final token = resp['token'] as String?;
      // 신규 테넌트는 201 + token, 기존 테넌트는 202(pending)로 token이 없을 수 있음
      if (token == null) {
        final status = resp['status'] as String?;
        return status == 'pending';
      }
      ApiClient.token = token;
      _email = email.toLowerCase();
      _memberships = (resp['memberships'] as List<dynamic>? ?? [])
          .map(
            (m) => TenantMembership(
              tenantId: m['tenantId'] as String,
              role: _roleFromString(m['role'] as String?),
            ),
          )
          .toList();
      _currentTenantId = _memberships.isNotEmpty
          ? _memberships.first.tenantId
          : null;
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
    String buyerSegment = '',
    String name = '',
    String phone = '',
    required String email,
    required String password,
    String attachmentUrl = '',
    String role = 'staff',
    bool isNewBuyerCompany = true,
  }) async {
    try {
      await ApiClient.post(
        '/auth/register-buyer',
        body: {
          'sellerCompanyName': sellerCompanyName,
          'buyerCompanyName': buyerCompanyName,
          'buyerAddress': buyerAddress,
          'buyerSegment': buyerSegment,
          'name': name,
          'phone': phone,
          'email': email,
          'password': password,
          'attachmentUrl': attachmentUrl,
          'role': role,
          'mode': isNewBuyerCompany ? 'new' : 'existing',
        },
      );
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
    String representative = '',
  }) async {
    try {
      await ApiClient.post(
        '/admin/tenants',
        body: {
          'userId': userId,
          'name': name,
          'phone': phone,
          'address': address,
          'representative': representative,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<BuyerReconnectResult> requestBuyerReconnect({
    required String sellerCompanyName,
    required String buyerCompanyName,
    String buyerAddress = '',
    String buyerSegment = '',
    String contactName = '',
    String contactPhone = '',
    String attachmentUrl = '',
  }) async {
    try {
      final resp = await ApiClient.post(
        '/auth/buyer/reapply',
        body: {
          'sellerCompanyName': sellerCompanyName,
          'buyerCompanyName': buyerCompanyName,
          'buyerAddress': buyerAddress,
          'buyerSegment': buyerSegment,
          'name': contactName,
          'phone': contactPhone,
          'attachmentUrl': attachmentUrl,
        },
      ) as Map<String, dynamic>;
      final message = (resp['message'] as String?) ?? 'pending approval';
      return BuyerReconnectResult.success(message: message);
    } on ApiClientException catch (err) {
      final message = _extractErrorMessage(err.body);
      final normalized = message.toLowerCase();
      final pendingExists =
          normalized.contains('pending request') ||
          normalized.contains('request already pending');
      final alreadyConnected =
          normalized.contains('already connected') ||
          normalized.contains('company already connected') ||
          normalized.contains('connection already exists');
      return BuyerReconnectResult.failure(
        message: message,
        pendingExists: pendingExists,
        alreadyConnected: alreadyConnected,
      );
    } catch (_) {
      return const BuyerReconnectResult.failure();
    }
  }

  Future<bool> updateTenant({
    required String tenantId,
    String? name,
    String? phone,
    String? address,
    String? representative,
  }) async {
    final body = <String, String>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    if (address != null && address.isNotEmpty) body['address'] = address;
    if (representative != null && representative.isNotEmpty) {
      body['representative'] = representative;
    }
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

  Future<List<TenantMemberDetail>> fetchTenantMembers(String tenantId) async {
    try {
      final resp =
          await ApiClient.get(
            '/auth/members',
            query: {'tenantId': tenantId},
          ) as List<dynamic>;
      return resp
          .map(
            (raw) => TenantMemberDetail(
              id: (raw['userId'] as String?) ?? '',
              name: (raw['name'] as String?) ?? '',
              email: (raw['email'] as String?) ?? '',
              phone: (raw['phone'] as String?) ?? '',
              role: _roleFromString(raw['role'] as String?),
              status: (raw['status'] as String?) ?? 'approved',
              positionId: ((raw['positionId'] ?? raw['position_id']) as String?)?.toString(),
              positionTitle:
                  ((raw['positionTitle'] ?? raw['customTitle']) as String?)?.toString(),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> updateTenantMemberRole({
    required String tenantId,
    required String memberId,
    required TenantMemberRole role,
  }) async {
    try {
      await ApiClient.patch(
        '/auth/members/$memberId',
        body: {
          'tenantId': tenantId,
          'role': _roleToString(role),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<TenantPosition>> fetchTenantPositions(String tenantId) async {
    try {
      final resp =
          await ApiClient.get(
            '/auth/positions',
            query: {'tenantId': tenantId},
          ) as List<dynamic>;
      return resp
          .map(
            (raw) => TenantPosition(
              id: (raw['id'] as String?) ?? '',
              tenantId: (raw['tenantId'] as String?) ?? tenantId,
              title: (raw['title'] as String?) ?? '',
              tier: tenantPositionTierFromString(raw['tier'] as String?),
              sortOrder: (raw['sortOrder'] as int?) ?? (raw['sort_order'] as int?) ?? 0,
              isLocked: (raw['isLocked'] as bool?) ??
                  (((raw['is_locked'] as num?) ?? 0) == 1),
            ),
          )
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<TenantPosition?> createTenantPosition({
    required String tenantId,
    required String title,
    required TenantPositionTier tier,
  }) async {
    try {
      final resp = await ApiClient.post(
        '/auth/positions',
        body: {
          'tenantId': tenantId,
          'title': title,
          'hierarchy': _tierToString(tier),
        },
      ) as Map<String, dynamic>;
      return TenantPosition(
        id: (resp['id'] as String?) ?? '',
        tenantId: (resp['tenantId'] as String?) ?? tenantId,
        title: (resp['title'] as String?) ?? title,
        tier: tenantPositionTierFromString(resp['tier'] as String? ?? _tierToString(tier)),
        sortOrder: (resp['sortOrder'] as int?) ?? 0,
        isLocked: (resp['isLocked'] as bool?) ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateTenantPosition({
    required String tenantId,
    required String positionId,
    required String title,
    required TenantPositionTier tier,
  }) async {
    try {
      await ApiClient.patch(
        '/auth/positions/$positionId',
        body: {
          'tenantId': tenantId,
          'title': title,
          'hierarchy': _tierToString(tier),
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteTenantPosition({
    required String tenantId,
    required String positionId,
  }) async {
    try {
      await ApiClient.delete(
        '/auth/positions/$positionId',
        query: {'tenantId': tenantId},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> assignMemberPosition({
    required String tenantId,
    required String memberId,
    String? positionId,
  }) async {
    try {
      await ApiClient.patch(
        '/auth/member-positions/$memberId',
        body: {
          'tenantId': tenantId,
          'positionId': positionId ?? '',
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _tierToString(TenantPositionTier tier) {
    switch (tier) {
      case TenantPositionTier.owner:
        return 'owner';
      case TenantPositionTier.manager:
        return 'manager';
      case TenantPositionTier.pending:
        return 'pending';
      case TenantPositionTier.staff:
        return 'staff';
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
    if (_userType != null) {
      await _prefs?.setString(_kUserType, _userType!);
    }
    if (_primaryTenantId != null) {
      await _prefs?.setString(_kPrimaryTenant, _primaryTenantId!);
    } else {
      await _prefs?.remove(_kPrimaryTenant);
    }
    if (_languageCode != null && _languageCode!.isNotEmpty) {
      await _prefs?.setString(_kLanguage, _languageCode!);
    } else {
      await _prefs?.remove(_kLanguage);
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
    switch (value?.toLowerCase()) {
      case 'seller':
        return TenantType.seller;
      case 'buyer':
        return TenantType.buyer;
      default:
        return TenantType.unknown;
    }
  }

  String _roleToString(TenantMemberRole role) {
    switch (role) {
      case TenantMemberRole.owner:
        return 'owner';
      case TenantMemberRole.manager:
        return 'manager';
      case TenantMemberRole.staff:
        return 'staff';
    }
  }

  String _extractErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final value = body['error'] ?? body['message'];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    } else if (body is String && body.isNotEmpty) {
      return body;
    }
    return 'unknown error';
  }
}
