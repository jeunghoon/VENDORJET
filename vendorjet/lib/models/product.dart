enum ProductCategory {
  beverages,
  snacks,
  household,
  fashion,
  electronics,
}

class Product {
  final String id;
  final String sku;
  final String name;
  final int variantsCount;
  final double price; // 기본 가격(샘플)
  final ProductCategory category;
  final bool lowStock;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.variantsCount,
    required this.price,
    required this.category,
    this.lowStock = false,
    this.imageUrl,
  });
}
