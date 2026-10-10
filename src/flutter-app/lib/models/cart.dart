import 'product.dart';

class CartItem {
  final String productId;
  final int quantity;

  const CartItem({required this.productId, required this.quantity});

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        quantity: (json['quantity'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'quantity': quantity,
      };
}

class Cart {
  final String userId;
  final List<CartItem> items;

  const Cart({required this.userId, required this.items});

  static const empty = Cart(userId: '', items: []);

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        userId: json['userId'] as String? ?? '',
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => CartItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  int get totalQuantity =>
      items.fold(0, (sum, item) => sum + item.quantity);
}

/// A cart item joined client-side with its [Product] details, so the UI can
/// show the product name without a separate lookup on every render.
class ProductCartItem {
  final CartItem cartItem;
  final Product? product;

  const ProductCartItem({required this.cartItem, required this.product});
}
