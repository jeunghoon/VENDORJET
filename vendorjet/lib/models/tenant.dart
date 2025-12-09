enum TenantMemberRole { owner, manager, staff }

enum TenantType { seller, buyer, unknown }

class Tenant {
  final String id;
  final String name;
  final DateTime createdAt;
  final String phone;
  final String address;
  final TenantType type;
  final String representative;
  final bool isPrimary;

  const Tenant({
    required this.id,
    required this.name,
    required this.createdAt,
    this.phone = '',
    this.address = '',
    this.type = TenantType.unknown,
    this.representative = '',
    this.isPrimary = false,
  });
}

class TenantMembership {
  final String tenantId;
  final TenantMemberRole role;

  const TenantMembership({required this.tenantId, required this.role});
}

class TenantMemberDetail {
  final String id;
  final String name;
  final String email;
  final String phone;
  final TenantMemberRole role;
  final String status;

  const TenantMemberDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
}
