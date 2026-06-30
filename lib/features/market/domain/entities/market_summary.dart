import 'package:collectiq_ai/core/utils/json_parse.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_comp.dart';

class MarketSummary {
  const MarketSummary({
    required this.averagePrice,
    required this.medianPrice,
    required this.lowPrice,
    required this.highPrice,
    required this.salesCount,
    required this.trendLabel,
    required this.confidence,
    required this.lastUpdated,
    required this.sources,
    required this.comps,
  });

  final double averagePrice;
  final double medianPrice;
  final double lowPrice;
  final double highPrice;
  final int salesCount;
  final String trendLabel;
  final double confidence;
  final DateTime lastUpdated;
  final List<String> sources;
  final List<MarketComp> comps;

  factory MarketSummary.fromJson(Map<String, dynamic> json) {
    return MarketSummary(
      averagePrice: parseNullableDouble(json['averagePrice']) ?? 0,
      medianPrice: parseNullableDouble(json['medianPrice']) ?? 0,
      lowPrice: parseNullableDouble(json['lowPrice']) ?? 0,
      highPrice: parseNullableDouble(json['highPrice']) ?? 0,
      salesCount: parseNullableInt(json['salesCount']) ?? 0,
      trendLabel: parseString(json['trendLabel'], fallback: 'Stable'),
      confidence: _normalizeConfidence(json['confidence']),
      lastUpdated: parseNullableDateTime(json['lastUpdated']) ?? DateTime.now(),
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .map((source) => parseString(source))
          .where((source) => source.isNotEmpty)
          .toList(growable: false),
      comps: (json['comps'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MarketComp.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'averagePrice': averagePrice,
      'medianPrice': medianPrice,
      'lowPrice': lowPrice,
      'highPrice': highPrice,
      'salesCount': salesCount,
      'trendLabel': trendLabel,
      'confidence': confidence,
      'lastUpdated': lastUpdated.toIso8601String(),
      'sources': sources,
      'comps': [for (final comp in comps) comp.toJson()],
    };
  }
}

double _normalizeConfidence(Object? value) {
  final confidence = parseNullableDouble(value) ?? 0;
  return confidence > 1 ? confidence / 100 : confidence;
}
