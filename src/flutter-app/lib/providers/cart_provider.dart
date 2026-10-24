import 'package:flutter/foundation.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

import '../gateways/api_gateway.dart';
import '../gateways/session_gateway.dart';
import '../models/cart.dart';
import '../models/checkout.dart';
import '../models/product.dart';

/// Holds cart state shared between the Products and Cart tabs, mirroring the
/// react-native-app's `Cart.provider.tsx`: a `getCart` fetch plus `addItem`,
/// `emptyCart` and `placeOrder` mutations that all refresh the cart
/// afterwards. Currency is hard-coded to USD, matching the original app.
class CartProvider extends ChangeNotifier {
  Cart cart = Cart.empty;
  bool isLoading = false;
  Object? error;

  Future<void> loadCart() async {
    isLoading = true;
    notifyListeners();
    try {
      cart = await apiGateway.getCart();
      error = null;
    } catch (e) {
      error = e;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addItem(String productId, {int quantity = 1}) async {
    await apiGateway.addCartItem(
      CartItem(productId: productId, quantity: quantity),
    );
    await SplunkRum.instance.customTracking.trackCustomEvent(
      name: 'cart_item_added',
      attributes: MutableAttributes(
        attributes: {
          'product.id': MutableAttributeString(value: productId),
          'product.quantity': MutableAttributeInt(value: quantity),
        },
      ),
    );
    await loadCart();
  }

  Future<void> emptyCart() async {
    await apiGateway.emptyCart();
    await loadCart();
  }

  Future<OrderResult> placeOrder({
    required String email,
    required Address address,
    required CreditCardInfo creditCard,
  }) async {
    final userId = await sessionGateway.getUserId();
    final result = await apiGateway.placeOrder(
      PlaceOrderRequest(
        userId: userId,
        userCurrency: 'USD',
        address: address,
        email: email,
        creditCard: creditCard,
      ),
    );
    await loadCart();
    await SplunkRum.instance.customTracking.trackCustomEvent(
      name: 'order_placed',
      attributes: MutableAttributes(
        attributes: {
          'order.id': MutableAttributeString(value: result.orderId),
          'order.item_count': MutableAttributeInt(value: result.items.length),
        },
      ),
    );
    return result;
  }

  /// Joins cart items with full product details so the Cart screen can show
  /// product names without the caller needing a separate product lookup.
  List<ProductCartItem> joinWithProducts(List<Product> products) {
    final productsById = {for (final p in products) p.id: p};
    return cart.items
        .map(
          (item) => ProductCartItem(
            cartItem: item,
            product: productsById[item.productId],
          ),
        )
        .toList();
  }
}
