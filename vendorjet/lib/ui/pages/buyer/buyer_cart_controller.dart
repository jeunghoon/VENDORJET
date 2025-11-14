import 'package:flutter/foundation.dart';
import 'package:vendorjet/models/product.dart';

class BuyerCartItem {
  final Product product;
  final int quantity;

  const BuyerCartItem({
    required this.product,
    required this.quantity,
  });

  double get lineTotal => product.price * quantity;

  BuyerCartItem copyWith({int? quantity}) {
    return BuyerCartItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class BuyerCartController extends ChangeNotifier {
  final Map<String, BuyerCartItem> _items = {};

  List<BuyerCartItem> get items =>
      _items.values.toList()..sort((a, b) => a.product.name.compareTo(b.product.name));

  bool get isEmpty => _items.isEmpty;

  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalAmount => double.parse(
        _items.values.fold<double>(0, (sum, item) => sum + item.lineTotal).toStringAsFixed(2),
      );

  void add(Product product) {
    addWithQuantity(product, 1);
  }

  void addWithQuantity(Product product, int quantity) {
    final normalized = quantity < 1 ? 1 : quantity;
    final existing = _items[product.id];
    final nextQty = (existing?.quantity ?? 0) + normalized;
    _items[product.id] = BuyerCartItem(product: product, quantity: nextQty.clamp(1, 999));
    notifyListeners();
  }

  void setQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId] = _items[productId]!.copyWith(quantity: quantity.clamp(1, 999));
    }
    notifyListeners();
  }

  void remove(String productId) {
    if (_items.remove(productId) != null) {
      notifyListeners();
    }
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }
}
