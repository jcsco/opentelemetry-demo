import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/checkout_form.dart';
import '../widgets/empty_cart.dart';

/// Ported from the react-native-app's `app/(tabs)/cart.tsx`: the cart list
/// and the checkout form live on the same screen, there is no separate
/// "go to checkout" step.
class CartScreen extends StatefulWidget {
  final VoidCallback onOrderComplete;

  const CartScreen({super.key, required this.onOrderComplete});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadCart();
      context.read<ProductsProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final productsProvider = context.watch<ProductsProvider>();

    if (cartProvider.isLoading && cartProvider.cart.items.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (cartProvider.cart.items.isEmpty) {
      return const Scaffold(body: EmptyCart());
    }

    final rows = cartProvider.joinWithProducts(productsProvider.products);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final row in rows)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(row.product?.name ?? row.cartItem.productId),
                  ),
                  Text(
                    '${row.cartItem.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.addToCartGreen,
                foregroundColor: Colors.white,
              ),
              onPressed: _onEmptyCart,
              child: const Text('Empty Cart'),
            ),
          ),
          const SizedBox(height: 24),
          CheckoutForm(onSubmit: _onPlaceOrder),
        ],
      ),
    );
  }

  Future<void> _onEmptyCart() async {
    await context.read<CartProvider>().emptyCart();
    Fluttertoast.showToast(msg: 'Your cart was emptied');
  }

  Future<void> _onPlaceOrder(CheckoutFormData data) async {
    try {
      await context.read<CartProvider>().placeOrder(
            email: data.email,
            address: data.toAddress(),
            creditCard: data.toCreditCard(),
          );
      await Fluttertoast.showToast(
        msg: "Your order is Complete! We've sent you a confirmation email.",
      );
      widget.onOrderComplete();
    } catch (e) {
      await Fluttertoast.showToast(
        msg: 'Order failed. Something went wrong. Please try again.',
      );
    }
  }
}
