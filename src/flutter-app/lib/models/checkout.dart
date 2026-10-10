import 'cart.dart';
import 'money.dart';

class Address {
  final String streetAddress;
  final String city;
  final String state;
  final String country;
  final String zipCode;

  const Address({
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.country,
    required this.zipCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        streetAddress: json['streetAddress'] as String? ?? '',
        city: json['city'] as String? ?? '',
        state: json['state'] as String? ?? '',
        country: json['country'] as String? ?? '',
        zipCode: json['zipCode'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'streetAddress': streetAddress,
        'city': city,
        'state': state,
        'country': country,
        'zipCode': zipCode,
      };
}

class CreditCardInfo {
  final String creditCardNumber;
  final int creditCardCvv;
  final int creditCardExpirationYear;
  final int creditCardExpirationMonth;

  const CreditCardInfo({
    required this.creditCardNumber,
    required this.creditCardCvv,
    required this.creditCardExpirationYear,
    required this.creditCardExpirationMonth,
  });

  Map<String, dynamic> toJson() => {
        'creditCardNumber': creditCardNumber,
        'creditCardCvv': creditCardCvv,
        'creditCardExpirationYear': creditCardExpirationYear,
        'creditCardExpirationMonth': creditCardExpirationMonth,
      };
}

class PlaceOrderRequest {
  final String userId;
  final String userCurrency;
  final Address address;
  final String email;
  final CreditCardInfo creditCard;

  const PlaceOrderRequest({
    required this.userId,
    required this.userCurrency,
    required this.address,
    required this.email,
    required this.creditCard,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userCurrency': userCurrency,
        'address': address.toJson(),
        'email': email,
        'creditCard': creditCard.toJson(),
      };
}

class OrderItem {
  final CartItem item;
  final Money? cost;

  const OrderItem({required this.item, required this.cost});

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        item: CartItem.fromJson(json['item'] as Map<String, dynamic>),
        cost: json['cost'] != null
            ? Money.fromJson(json['cost'] as Map<String, dynamic>)
            : null,
      );
}

class OrderResult {
  final String orderId;
  final String shippingTrackingId;
  final Money? shippingCost;
  final Address shippingAddress;
  final List<OrderItem> items;

  const OrderResult({
    required this.orderId,
    required this.shippingTrackingId,
    required this.shippingCost,
    required this.shippingAddress,
    required this.items,
  });

  factory OrderResult.fromJson(Map<String, dynamic> json) => OrderResult(
        orderId: json['orderId'] as String? ?? '',
        shippingTrackingId: json['shippingTrackingId'] as String? ?? '',
        shippingCost: json['shippingCost'] != null
            ? Money.fromJson(json['shippingCost'] as Map<String, dynamic>)
            : null,
        shippingAddress: Address.fromJson(
          json['shippingAddress'] as Map<String, dynamic>? ?? const {},
        ),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
