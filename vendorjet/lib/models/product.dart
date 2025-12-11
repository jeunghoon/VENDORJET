enum ProductTag { featured, discounted, newArrival }

class ProductPackaging {
  final String packType; // inner/carton/pallet 등
  final double? lengthCm;
  final double? widthCm;
  final double? heightCm;
  final double? volumeCbm; // 미입력 시 길이*너비*높이/1e6 계산
  final double? netWeightKg;
  final double? grossWeightKg;
  final int? unitsPerPack;
  final String? barcode;

  const ProductPackaging({
    required this.packType,
    this.lengthCm,
    this.widthCm,
    this.heightCm,
    this.volumeCbm,
    this.netWeightKg,
    this.grossWeightKg,
    this.unitsPerPack,
    this.barcode,
  });

  double? get computedCbm {
    if (volumeCbm != null) return volumeCbm;
    if (lengthCm == null || widthCm == null || heightCm == null) return null;
    return (lengthCm! * widthCm! * heightCm!) / 1000000;
  }

  Map<String, dynamic> toJson() => {
        'packType': packType,
        'lengthCm': lengthCm,
        'widthCm': widthCm,
        'heightCm': heightCm,
        'volumeCbm': volumeCbm,
        'netWeightKg': netWeightKg,
        'grossWeightKg': grossWeightKg,
        'unitsPerPack': unitsPerPack,
        'barcode': barcode,
      };
}

class ProductTradeTerm {
  final String incoterm; // FOB/CIF/EXW 등
  final String currency; // USD/KRW 등
  final double price; // 표시용 단가 (minor 단위 환산 전)
  final String? portOfLoading;
  final String? portOfDischarge;
  final double? freight;
  final double? insurance;
  final int? leadTimeDays;
  final int? minOrderQty;
  final String? moqUnit;

  const ProductTradeTerm({
    required this.incoterm,
    required this.currency,
    required this.price,
    this.portOfLoading,
    this.portOfDischarge,
    this.freight,
    this.insurance,
    this.leadTimeDays,
    this.minOrderQty,
    this.moqUnit,
  });

  Map<String, dynamic> toJson() => {
        'incoterm': incoterm,
        'currency': currency,
        'price': price,
        'portOfLoading': portOfLoading,
        'portOfDischarge': portOfDischarge,
        'freight': freight,
        'insurance': insurance,
        'leadTimeDays': leadTimeDays,
        'minOrderQty': minOrderQty,
        'moqUnit': moqUnit,
      };
}

class ProductEta {
  final DateTime? etd;
  final DateTime? eta;
  final String? vessel;
  final String? voyageNo;
  final String? status;
  final String? note;

  const ProductEta({
    this.etd,
    this.eta,
    this.vessel,
    this.voyageNo,
    this.status,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'etd': etd?.toIso8601String(),
        'eta': eta?.toIso8601String(),
        'vessel': vessel,
        'voyageNo': voyageNo,
        'status': status,
        'note': note,
      };
}

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

  // 무역/패키징 확장 필드
  final String? hsCode;
  final String? originCountry;
  final String? uom;
  final String? incoterm;
  final bool isPerishable;
  final ProductPackaging? packaging;
  final ProductTradeTerm? tradeTerm;
  final ProductEta? eta;

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
    this.hsCode,
    this.originCountry,
    this.uom,
    this.incoterm,
    this.isPerishable = false,
    this.packaging,
    this.tradeTerm,
    this.eta,
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
    String? hsCode,
    String? originCountry,
    String? uom,
    String? incoterm,
    bool? isPerishable,
    ProductPackaging? packaging,
    ProductTradeTerm? tradeTerm,
    ProductEta? eta,
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
      hsCode: hsCode ?? this.hsCode,
      originCountry: originCountry ?? this.originCountry,
      uom: uom ?? this.uom,
      incoterm: incoterm ?? this.incoterm,
      isPerishable: isPerishable ?? this.isPerishable,
      packaging: packaging ?? this.packaging,
      tradeTerm: tradeTerm ?? this.tradeTerm,
      eta: eta ?? this.eta,
    );
  }
}
