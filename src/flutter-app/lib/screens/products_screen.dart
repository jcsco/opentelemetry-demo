import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/product_card.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<ProductsProvider>().loadProducts(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = context.watch<ProductsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: RefreshIndicator(
        onRefresh: () => context.read<ProductsProvider>().loadProducts(),
        child: _buildBody(productsProvider),
      ),
    );
  }

  Widget _buildBody(ProductsProvider productsProvider) {
    if (productsProvider.isLoading && productsProvider.products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (productsProvider.products.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              productsProvider.error != null
                  ? 'Failed to load products: ${productsProvider.error}'
                  : 'No products found, make sure the backend services for '
                      'the OpenTelemetry demo are running',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: productsProvider.products.length,
      itemBuilder: (context, index) {
        final product = productsProvider.products[index];
        return ProductCard(
          product: product,
          onAddToCart: () => _onAddToCart(product.id),
        );
      },
    );
  }

  Future<void> _onAddToCart(String productId) async {
    await context.read<CartProvider>().addItem(productId);
    Fluttertoast.showToast(msg: 'This item has been added to your cart');
  }
}
