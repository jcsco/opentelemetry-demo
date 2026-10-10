import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

import '../models/cart.dart';
import '../models/checkout.dart';
import '../models/product.dart';
import 'session_gateway.dart';
import 'settings.dart';

/// All backend calls go through the demo's frontend reverse-proxy, exactly
/// like the react-native-app and the web frontend. The base URL is whatever
/// is currently configured in Settings (see `gateways/settings.dart`), so it
/// is re-resolved on every call.
const _basePath = '/api';

class ApiGateway {
  final http.Client _client = http.Client();

  Future<List<Product>> listProducts({String currencyCode = 'USD'}) async {
    final json = await _request(
      'products.list',
      method: 'GET',
      path: '/products',
      queryParams: {'currencyCode': currencyCode},
    );
    return (json as List<dynamic>)
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Cart> getCart({String currencyCode = 'USD'}) async {
    final userId = await sessionGateway.getUserId();
    final json = await _request(
      'cart.get',
      method: 'GET',
      path: '/cart',
      queryParams: {'sessionId': userId, 'currencyCode': currencyCode},
    );
    return Cart.fromJson(json as Map<String, dynamic>);
  }

  Future<void> addCartItem(
    CartItem item, {
    String currencyCode = 'USD',
  }) async {
    final userId = await sessionGateway.getUserId();
    await _request(
      'cart.add',
      method: 'POST',
      path: '/cart',
      queryParams: {'currencyCode': currencyCode},
      body: {'item': item.toJson(), 'userId': userId},
    );
  }

  Future<void> emptyCart() async {
    final userId = await sessionGateway.getUserId();
    await _request(
      'cart.empty',
      method: 'DELETE',
      path: '/cart',
      body: {'userId': userId},
    );
  }

  Future<OrderResult> placeOrder(PlaceOrderRequest request) async {
    final json = await _request(
      'checkout.placeOrder',
      method: 'POST',
      path: '/checkout',
      queryParams: {'currencyCode': request.userCurrency},
      body: request.toJson(),
    );
    return OrderResult.fromJson(json as Map<String, dynamic>);
  }

  Future<dynamic> _request(
    String workflowName, {
    required String method,
    required String path,
    Map<String, String> queryParams = const {},
    Map<String, dynamic>? body,
  }) async {
    final workflow = await SplunkRum.instance.customTracking.startWorkflow(
      name: 'api.$workflowName',
    );
    try {
      final proxyUrl = await getFrontendProxyUrl();
      final uri = Uri.parse(
        '$proxyUrl$_basePath$path',
      ).replace(queryParameters: queryParams.isEmpty ? null : queryParams);

      final response = await _send(uri, method, body);
      final responseText = response.body;
      final data = responseText.isNotEmpty ? jsonDecode(responseText) : null;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = data is Map<String, dynamic> ? data['error'] : null;
        throw Exception(
          error ?? 'Request failed with status ${response.statusCode}',
        );
      }

      return data;
    } finally {
      await workflow.end();
    }
  }

  Future<http.Response> _send(
    Uri uri,
    String method,
    Map<String, dynamic>? body,
  ) {
    final headers = {'content-type': 'application/json'};
    final encodedBody = body != null ? jsonEncode(body) : null;

    final request = switch (method) {
      'POST' => _client.post(uri, headers: headers, body: encodedBody),
      'DELETE' => _client.delete(uri, headers: headers, body: encodedBody),
      _ => _client.get(uri, headers: headers),
    };

    // package:http's underlying dart:io HttpClient has no connect timeout by
    // default, so a dead/unreachable proxy (e.g. nothing listening on the
    // configured Frontend Proxy URL) would otherwise hang indefinitely.
    return request.timeout(const Duration(seconds: 10));
  }
}

final apiGateway = ApiGateway();
