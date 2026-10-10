// Basic smoke test: the root shell renders the three-tab navigation with
// the Products screen visible by default. Network calls (product list, cart)
// are expected to fail in this offline test environment; the providers
// surface that as an error state rather than throwing, so the shell still
// renders.

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('renders the three-tab navigation shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    // main() normally loads this from the .env asset via installTelemetry(),
    // which this test doesn't call.
    dotenv.loadFromString(envString: 'FRONTEND_PROXY_PORT=8080');

    await tester.pumpWidget(const AstronomyShopApp());
    await tester.pump();

    expect(find.text('Products'), findsWidgets);
    expect(find.text('Cart'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });
}
