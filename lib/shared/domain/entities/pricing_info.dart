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
    this.pricingExplanation,
    this.reasonCode,
    this.valuationStrategy,
    this.attributionText,
    this.displayString,
    this.originalPrice,
    this.originalCurrency,
    this.exchangeRateUsed,
    this.exchangeRateDate,
    this.lowEstimateAud,
    this.highEstimateAud,
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
  final String? pricingExplanation;
  final String? reasonCode;
  final String? valuationStrategy;
  final String? attributionText;
  final String? displayString;
  final double? originalPrice;
  final String? originalCurrency;
  final double? exchangeRateUsed;
  final DateTime? exchangeRateDate;
  final double? lowEstimateAud;
  final double? highEstimateAud;

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
      pricingExplanation: parseString(json['pricingExplanation']).trim().isEmpty
          ? null
          : parseString(json['pricingExplanation']),
      reasonCode: _emptyStringAsNull(json['reasonCode']),
      valuationStrategy: _emptyStringAsNull(json['valuationStrategy']),
      attributionText: _emptyStringAsNull(json['attributionText']),
      displayString: _emptyStringAsNull(json['displayString']),
      originalPrice: parseNullableDouble(json['originalPrice']),
      originalCurrency: _emptyStringAsNull(json['originalCurrency']),
      exchangeRateUsed: parseNullableDouble(json['exchangeRateUsed']),
      exchangeRateDate: _dateTimeOrNull(json['exchangeRateDate']),
      lowEstimateAud: parseNullableDouble(json['lowEstimateAud']),
      highEstimateAud: parseNullableDouble(json['highEstimateAud']),
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
      pricingExplanation: estimatedValue > 0
          ? 'Legacy AI estimate; no market source was used.'
          : null,
      reasonCode: estimatedValue > 0 ? 'LEGACY_AI_ESTIMATE' : null,
      valuationStrategy: estimatedValue > 0 ? 'ai_estimate' : null,
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
      'pricingExplanation': pricingExplanation,
      'reasonCode': reasonCode,
      'valuationStrategy': valuationStrategy,
      'attributionText': attributionText,
      'displayString': displayString,
      'originalPrice': originalPrice,
      'originalCurrency': originalCurrency,
      'exchangeRateUsed': exchangeRateUsed,
      'exchangeRateDate': exchangeRateDate?.toIso8601String(),
      'lowEstimateAud': lowEstimateAud,
      'highEstimateAud': highEstimateAud,
    };
  }
}

String? _emptyStringAsNull(Object? value) {
  final parsed = parseString(value).trim();
  return parsed.isEmpty ? null : parsed;
}

DateTime? _dateTimeOrNull(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
