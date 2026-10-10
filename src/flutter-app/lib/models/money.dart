class Money {
  final String currencyCode;
  final int units;
  final int nanos;

  const Money({
    required this.currencyCode,
    required this.units,
    required this.nanos,
  });

  factory Money.fromJson(Map<String, dynamic> json) => Money(
        currencyCode: json['currencyCode'] as String? ?? 'USD',
        units: (json['units'] as num?)?.toInt() ?? 0,
        nanos: (json['nanos'] as num?)?.toInt() ?? 0,
      );

  double get amount => units + nanos / 1e9;

  String get formatted => '\$ ${amount.toStringAsFixed(2)}';
}
