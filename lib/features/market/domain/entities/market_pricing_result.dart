import 'package:collectiq_ai/core/utils/json_parse.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_comp.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';

/// Market-pricing output prepared for future live pricing providers.
class MarketPricingResult {
  /// Creates an immutable market-pricing result.
  const MarketPricingResult({
    required this.estimatedValue,
    required this.lowEstimate,
    required this.highEstimate,
    required this.currency,
    required this.marketTrend,
    required this.comparableSales,
    required this.confidence,
    required this.sourceLabel,
    required this.lastUpdated,
  });

  /// Estimated market value.
  final double estimatedValue;

  /// Low value estimate.
  final double lowEstimate;

  /// High value estimate.
  final double highEstimate;

  /// Currency code.
  final String currency;

  /// Trend label such as Stable, Rising, or Cooling.
  final String marketTrend;

  /// Recent comparable sales.
  final List<MarketComp> comparableSales;

  /// Pricing confidence, normalized to 0-1.
  final double confidence;

  /// Provider/source label safe for UI display.
  final String sourceLabel;

  /// Last time pricing was refreshed.
  final DateTime lastUpdated;

  /// Parses a pricing result with safe defaults for partial provider data.
  factory MarketPricingResult.fromJson(Map<String, dynamic> json) {
    final comps = (json['comparableSales'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MarketComp.fromJson)
        .toList(growable: false);
    final estimatedValue =
        parseNullableDouble(
          json['estimatedValue'] ?? json['estimatedMarketValue'],
        ) ??
        0;

    return MarketPricingResult(
      estimatedValue: estimatedValue,
      lowEstimate:
          parseNullableDouble(json['lowEstimate'] ?? json['lowValue']) ??
          estimatedValue,
      highEstimate:
          parseNullableDouble(json['highEstimate'] ?? json['highValue']) ??
          estimatedValue,
      currency: parseString(json['currency'], fallback: 'AUD'),
      marketTrend: parseString(json['marketTrend'], fallback: 'Stable'),
      comparableSales: comps,
      confidence: _normalizeConfidence(json['confidence']),
      sourceLabel: parseString(json['sourceLabel'], fallback: 'Unknown'),
      lastUpdated: parseNullableDateTime(json['lastUpdated']) ?? DateTime.now(),
    );
  }

  /// Converts this result to existing scan/portfolio pricing information.
  PricingInfo toPricingInfo() {
    return PricingInfo(
      estimatedMarketValue: estimatedValue,
      lowEstimate: lowEstimate,
      highEstimate: highEstimate,
      currency: currency,
      pricingSource: sourceLabel,
      pricingConfidence: confidence,
      lastUpdated: lastUpdated,
      valuationStatus: estimatedValue > 0
          ? ValuationStatus.marketEstimated
          : ValuationStatus.noMarketMatch,
      valuationSource: sourceLabel,
      pricingExplanation: estimatedValue > 0
          ? 'Matched using trusted market data from $sourceLabel.'
          : 'No trusted market match found from $sourceLabel.',
      reasonCode: estimatedValue > 0 ? null : 'NO_MARKET_MATCH',
      valuationStrategy: estimatedValue > 0 ? 'sold_completed' : 'unavailable',
      attributionText: estimatedValue > 0
          ? 'Pricing data powered by $sourceLabel'
          : null,
      displayString: estimatedValue > 0
          ? '\$${estimatedValue.toStringAsFixed(2)} $currency'
          : null,
      originalPrice: estimatedValue > 0 ? estimatedValue : null,
      originalCurrency: estimatedValue > 0 ? currency : null,
      exchangeRateUsed: currency == 'AUD' && estimatedValue > 0 ? 1 : null,
      exchangeRateDate: currency == 'AUD' && estimatedValue > 0
          ? lastUpdated
          : null,
      lowEstimateAud: currency == 'AUD' ? lowEstimate : null,
      highEstimateAud: currency == 'AUD' ? highEstimate : null,
    );
  }

  /// Converts this result to the existing market summary UI model.
  MarketSummary toMarketSummary() {
    return MarketSummary(
      averagePrice: estimatedValue,
      medianPrice: estimatedValue,
      lowPrice: lowEstimate,
      highPrice: highEstimate,
      salesCount: comparableSales.length,
      trendLabel: marketTrend,
      confidence: confidence,
      lastUpdated: lastUpdated,
      sources: [sourceLabel],
      comps: comparableSales,
    );
  }
}

double _normalizeConfidence(Object? value) {
  final confidence = parseNullableDouble(value) ?? 0;
  return confidence > 1 ? confidence / 100 : confidence;
}
