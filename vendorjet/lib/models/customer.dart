enum CustomerTier { platinum, gold, silver }

class Customer {
  final String id;
  final String name;
  final String contactName;
  final String email;
  final String phone;
  final String address;
  final CustomerTier tier;
  final DateTime createdAt;
  final String segment;
  final String status;

  const Customer({
    required this.id,
    required this.name,
    required this.contactName,
    required this.email,
    this.phone = '',
    this.address = '',
    required this.tier,
    required this.createdAt,
    this.segment = '',
    this.status = '',
  });

  Customer copyWith({
    String? id,
    String? name,
    String? contactName,
    String? email,
    String? phone,
    String? address,
    CustomerTier? tier,
    DateTime? createdAt,
    String? segment,
    String? status,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
      segment: segment ?? this.segment,
      status: status ?? this.status,
    );
  }

  bool get isWithdrawn => status == 'withdrawn';
}
