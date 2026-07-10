import 'package:collectiq_ai/core/utils/json_parse.dart';

enum ValuationStatus {
  marketEstimated('market_estimated'),
  aiEstimated('ai_estimated'),
  providerNotConfigured('provider_not_configured'),
  noMarketMatch('no_market_match'),
  lookupFailed('lookup_failed'),
  unavailable('unavailable');

  const ValuationStatus(this.wireValue);

  final String wireValue;

  static ValuationStatus fromJson(Object? value) {
    final normalized = parseString(value).trim().toLowerCase();
    return switch (normalized) {
      'market_estimated' => ValuationStatus.marketEstimated,
      'ai_estimated' => ValuationStatus.aiEstimated,
      'provider_not_configured' => ValuationStatus.providerNotConfigured,
      'no_market_match' => ValuationStatus.noMarketMatch,
      'lookup_failed' => ValuationStatus.lookupFailed,
      _ => ValuationStatus.unavailable,
    };
  }
}

/// Market pricing information supplied by a pricing provider.
class PricingInfo {
  /// Creates immutable pricing information.
  const PricingInfo({
    required this.estimatedMarketValue,
    required this.lowEstimate,
    required this.highEstimate,
    required this.currency,
    required this.pricingSource,
    required this.pricingConfidence,
    required this.lastUpdated,
    this.valuationStatus = ValuationStatus.unavailable,
    this.valuationSource = 'unknown',
    this.aiEstimatedValue,
  });

  final double estimatedMarketValue;
  final double lowEstimate;
  final double highEstimate;
  final String currency;
  final String pricingSource;
  final double pricingConfidence;
  final DateTime? lastUpdated;
  final ValuationStatus valuationStatus;
  final String valuationSource;
  final double? aiEstimatedValue;

  /// Creates pricing information from backend or local JSON.
  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    final pricingConfidence =
        parseNullableDouble(json['pricingConfidence']) ?? 0;

    return PricingInfo(
      estimatedMarketValue:
          parseNullableDouble(json['estimatedMarketValue']) ?? 0,
      lowEstimate: parseNullableDouble(json['lowEstimate']) ?? 0,
      highEstimate: parseNullableDouble(json['highEstimate']) ?? 0,
      currency: parseString(json['currency'], fallback: 'AUD'),
      pricingSource: parseString(json['pricingSource'], fallback: 'Unknown'),
      pricingConfidence: pricingConfidence > 1
          ? pricingConfidence / 100
          : pricingConfidence,
      lastUpdated: _dateTimeOrNull(json['lastUpdated']),
      valuationStatus: ValuationStatus.fromJson(json['valuationStatus']),
      valuationSource: parseString(
        json['valuationSource'],
        fallback: parseString(json['pricingSource'], fallback: 'unknown'),
      ),
      aiEstimatedValue: parseNullableDouble(json['aiEstimatedValue']),
    );
  }

  /// Creates fallback pricing from a legacy estimate.
  factory PricingInfo.fromLegacyEstimate(double estimatedValue) {
    return PricingInfo(
      estimatedMarketValue: estimatedValue,
      lowEstimate: estimatedValue,
      highEstimate: estimatedValue,
      currency: 'AUD',
      pricingSource: 'Legacy AI estimate',
      pricingConfidence: 0,
      lastUpdated: null,
      valuationStatus: estimatedValue > 0
          ? ValuationStatus.aiEstimated
          : ValuationStatus.unavailable,
      valuationSource: 'legacy_ai_estimate',
      aiEstimatedValue: estimatedValue > 0 ? estimatedValue : null,
    );
  }

  /// Converts pricing information to a local JSON map.
  Map<String, dynamic> toJson() {
    return {
      'estimatedMarketValue': estimatedMarketValue,
      'lowEstimate': lowEstimate,
      'highEstimate': highEstimate,
      'currency': currency,
      'pricingSource': pricingSource,
      'pricingConfidence': pricingConfidence,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'valuationStatus': valuationStatus.wireValue,
      'valuationSource': valuationSource,
      'aiEstimatedValue': aiEstimatedValue,
    };
  }
}

DateTime? _dateTimeOrNull(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
