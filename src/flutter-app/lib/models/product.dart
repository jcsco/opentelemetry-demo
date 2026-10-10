import 'money.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final String picture;
  final Money priceUsd;
  final List<String> categories;

  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.picture,
    required this.priceUsd,
    required this.categories,
  });

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        picture: json['picture'] as String? ?? '',
        priceUsd: Money.fromJson(
          json['priceUsd'] as Map<String, dynamic>? ?? const {},
        ),
        categories: (json['categories'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
      );
}
