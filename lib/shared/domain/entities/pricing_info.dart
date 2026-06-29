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
  });

  final double estimatedMarketValue;
  final double lowEstimate;
  final double highEstimate;
  final String currency;
  final String pricingSource;
  final double pricingConfidence;
  final DateTime? lastUpdated;

  /// Creates pricing information from backend or local JSON.
  factory PricingInfo.fromJson(Map<String, dynamic> json) {
    final pricingConfidence = (json['pricingConfidence'] as num? ?? 0)
        .toDouble();

    return PricingInfo(
      estimatedMarketValue: (json['estimatedMarketValue'] as num).toDouble(),
      lowEstimate: (json['lowEstimate'] as num).toDouble(),
      highEstimate: (json['highEstimate'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'AUD',
      pricingSource: json['pricingSource'] as String? ?? 'Unknown',
      pricingConfidence: pricingConfidence > 1
          ? pricingConfidence / 100
          : pricingConfidence,
      lastUpdated: _dateTimeOrNull(json['lastUpdated']),
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
    };
  }
}

DateTime? _dateTimeOrNull(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return DateTime.tryParse(value);
}
