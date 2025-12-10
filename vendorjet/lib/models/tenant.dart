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
  final String? positionId;
  final String? positionTitle;

  const TenantMemberDetail({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.positionId,
    this.positionTitle,
  });

  bool get isApproved => status.toLowerCase() == 'approved';
}

class TenantPosition {
  final String id;
  final String tenantId;
  final String title;
  final TenantPositionTier tier;
  final int sortOrder;
  final bool isLocked;

  const TenantPosition({
    required this.id,
    required this.tenantId,
    required this.title,
    required this.tier,
    required this.sortOrder,
    required this.isLocked,
  });
}

enum TenantPositionTier { owner, manager, staff, pending }

TenantPositionTier tenantPositionTierFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'owner':
      return TenantPositionTier.owner;
    case 'manager':
      return TenantPositionTier.manager;
    case 'pending':
      return TenantPositionTier.pending;
    case 'staff':
    default:
      return TenantPositionTier.staff;
  }
}
