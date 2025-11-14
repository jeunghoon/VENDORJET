enum CustomerTier { platinum, gold, silver }

class Customer {
  final String id;
  final String name;
  final String contactName;
  final String email;
  final CustomerTier tier;
  final DateTime createdAt;
  final String segment;

  const Customer({
    required this.id,
    required this.name,
    required this.contactName,
    required this.email,
    required this.tier,
    required this.createdAt,
    this.segment = '',
  });

  Customer copyWith({
    String? id,
    String? name,
    String? contactName,
    String? email,
    CustomerTier? tier,
    DateTime? createdAt,
    String? segment,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      contactName: contactName ?? this.contactName,
      email: email ?? this.email,
      tier: tier ?? this.tier,
      createdAt: createdAt ?? this.createdAt,
      segment: segment ?? this.segment,
    );
  }
}
