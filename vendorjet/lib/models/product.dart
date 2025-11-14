enum ProductTag { featured, discounted, newArrival }

class Product {
  final String id;
  final String sku;
  final String name;
  final int variantsCount;
  final double price;
  final List<String> categories; // 최대 3단계
  final Set<ProductTag> tags;
  final bool lowStock;
  final String? imageUrl;

  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.variantsCount,
    required this.price,
    required this.categories,
    this.tags = const {},
    this.lowStock = false,
    this.imageUrl,
  });

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    int? variantsCount,
    double? price,
    List<String>? categories,
    Set<ProductTag>? tags,
    bool? lowStock,
    String? imageUrl,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      variantsCount: variantsCount ?? this.variantsCount,
      price: price ?? this.price,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      lowStock: lowStock ?? this.lowStock,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
