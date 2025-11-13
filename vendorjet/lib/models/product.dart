enum ProductCategory { beverages, snacks, household, fashion, electronics }

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

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    int? variantsCount,
    double? price,
    ProductCategory? category,
    bool? lowStock,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      variantsCount: variantsCount ?? this.variantsCount,
      price: price ?? this.price,
      category: category ?? this.category,
      lowStock: lowStock ?? this.lowStock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
