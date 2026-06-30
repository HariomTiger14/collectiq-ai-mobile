import 'package:collectiq_ai/core/utils/json_parse.dart';

class MarketComp {
  const MarketComp({
    required this.source,
    required this.title,
    required this.soldPrice,
    required this.currency,
    required this.soldDate,
    required this.condition,
    this.url,
  });

  final String source;
  final String title;
  final double soldPrice;
  final String currency;
  final DateTime soldDate;
  final String condition;
  final String? url;

  factory MarketComp.fromJson(Map<String, dynamic> json) {
    return MarketComp(
      source: parseString(json['source'], fallback: 'Mock Market'),
      title: parseString(json['title'], fallback: 'Comparable sale'),
      soldPrice: parseNullableDouble(json['soldPrice']) ?? 0,
      currency: parseString(json['currency'], fallback: 'AUD'),
      soldDate: parseNullableDateTime(json['soldDate']) ?? DateTime.now(),
      condition: parseString(json['condition'], fallback: 'Unknown'),
      url: _optionalString(json['url']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'title': title,
      'soldPrice': soldPrice,
      'currency': currency,
      'soldDate': soldDate.toIso8601String(),
      'condition': condition,
      'url': url,
    };
  }
}

String? _optionalString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  return null;
}
