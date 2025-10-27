class Product {
  final String id;
  final String sku;
  final String name;
  final int variantsCount;
  final double price; // 기본 가격(데모)
  final String? imageUrl;

  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.variantsCount,
    required this.price,
    this.imageUrl,
  });
}

