enum TenantMemberRole { owner, manager, staff }

class Tenant {
  final String id;
  final String name;
  final DateTime createdAt;

  const Tenant({required this.id, required this.name, required this.createdAt});
}

class TenantMembership {
  final String tenantId;
  final TenantMemberRole role;

  const TenantMembership({required this.tenantId, required this.role});
}
