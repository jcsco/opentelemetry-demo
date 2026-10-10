import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

import '../gateways/settings.dart';
import '../native/crash_simulator.dart';
import '../providers/cart_provider.dart';
import '../providers/products_provider.dart';
import '../widgets/action_button.dart';

/// Ported from `app/(tabs)/settings.tsx`: the "Frontend Proxy URL" setting
/// (via `components/Setting.tsx`), plus the "Crash & ANR Testing" section
/// added to deliberately trigger each kind of failure Splunk RUM is supposed
/// to catch, so Digital Experience Analytics reporting can be verified
/// end-to-end.
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
            const SizedBox(height: 24),
            Text(
              'Crash & ANR Testing',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionButton(
                  label: 'Simulate Handled Error',
                  onPressed: _onSimulateHandledError,
                ),
                ActionButton(
                  label: 'Simulate Fatal Error',
                  confirmMessage:
                      'This throws an unhandled error outside Flutter\'s '
                      'normal error zone. It is reported as fatal, but '
                      'unlike a native crash it does not necessarily '
                      'terminate the process.',
                  onPressed: _onSimulateFatalError,
                ),
                ActionButton(
                  label: 'Simulate Native Crash',
                  confirmMessage:
                      'This terminates the app with a real native crash.',
                  onPressed: CrashSimulator.triggerNativeCrash,
                ),
                if (Platform.isAndroid)
                  ActionButton(
                    label: 'Simulate ANR',
                    confirmMessage:
                        'This blocks the UI thread for ~6 seconds to '
                        'trigger a real ANR.',
                    onPressed: CrashSimulator.triggerAnr,
                  ),
              ],
            ),
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
    await Fluttertoast.showToast(msg: 'Frontend Proxy URL applied');
  }

  Future<void> _onSimulateHandledError() async {
    await SplunkRum.instance.customTracking.trackError(
      Exception('Simulated handled error from Settings'),
      handled: true,
    );
  }

  Future<void> _onSimulateFatalError() async {
    // Thrown outside any try/catch and off the current call stack, so it
    // reaches the top-level uncaught-error handler Splunk's crash module
    // installs instead of being caught by a widget's own error boundary -
    // the Dart/Flutter equivalent of the react-native-app's
    // `global.ErrorUtils.reportFatalError`.
    Future.delayed(Duration.zero, () {
      throw Exception('Simulated fatal error from Settings');
    });
  }
}
