import 'package:flutter/foundation.dart';

import '../../models/order.dart';
import '../../models/product.dart';

/// 주문/대시보드 데이터 새로고침을 다른 페이지에 전달하는 단순 버스
class DataRefreshCoordinator extends ChangeNotifier {
  int _ordersVersion = 0;
  int _productsVersion = 0;
  int _customersVersion = 0;
  Order? _lastUpdatedOrder;
  Product? _lastUpdatedProduct;

  int get ordersVersion => _ordersVersion;
  int get productsVersion => _productsVersion;
  int get customersVersion => _customersVersion;
  Order? get lastUpdatedOrder => _lastUpdatedOrder;
  Product? get lastUpdatedProduct => _lastUpdatedProduct;

  void notifyOrderChanged(Order order) {
    _ordersVersion++;
    _lastUpdatedOrder = order;
    notifyListeners();
  }

  void notifyProductChanged(Product product) {
    _productsVersion++;
    _lastUpdatedProduct = product;
    notifyListeners();
  }

  void notifyCustomerChanged() {
    _customersVersion++;
    notifyListeners();
  }
}
