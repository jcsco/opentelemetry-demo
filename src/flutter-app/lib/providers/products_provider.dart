import 'package:flutter/foundation.dart';

import '../gateways/api_gateway.dart';
import '../models/product.dart';

/// Caches the product catalog so both the Products tab and the Cart tab (for
/// joining cart items with product names) share a single fetch.
class ProductsProvider extends ChangeNotifier {
  List<Product> products = [];
  bool isLoading = false;
  Object? error;

  Future<void> loadProducts() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      products = await apiGateway.listProducts();
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
