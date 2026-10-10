import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../gateways/settings.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../telemetry.dart';

/// The only setting in the react-native-app is the "Frontend Proxy URL",
/// letting the user point API calls (and trace export) at a different
/// backend. Ported from `app/(tabs)/settings.tsx` + `components/Setting.tsx`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _controller = TextEditingController();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    getFrontendProxyUrl().then((value) {
      setState(() {
        _controller.text = value;
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Frontend Proxy URL:'),
            const SizedBox(height: 8),
            if (_loading)
              const Text('Fetching current value...')
            else ...[
              TextField(controller: _controller),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: _onApply,
                  child: const Text('Apply'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _onApply() async {
    final value = _controller.text;
    final productsProvider = context.read<ProductsProvider>();
    final cartProvider = context.read<CartProvider>();

    await setFrontendProxyUrl(value);
    await productsProvider.loadProducts();
    await cartProvider.loadCart();
    await reconfigureTelemetry(value);
    await Fluttertoast.showToast(msg: 'Frontend Proxy URL applied');
  }
}
