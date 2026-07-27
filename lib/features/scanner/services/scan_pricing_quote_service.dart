import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/core/utils/json_parse.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final scanPricingQuoteServiceProvider = Provider<ScanPricingQuoteService>((
  ref,
) {
  return ScanPricingQuoteService(apiClient: ref.watch(apiClientProvider));
});

class ScanPricingQuoteService {
  const ScanPricingQuoteService({required ApiClient apiClient})
    : this._(apiClient);

  const ScanPricingQuoteService._(this._apiClient);

  final ApiClient _apiClient;

  Future<ScanPricingQuote> quote(ScanResult result) async {
    final response = await _apiClient.post(
      ApiConstants.pricingQuotePath,
      data: _requestFor(result),
    );
    final payload = _unwrapResponse(response.data);
    return ScanPricingQuote.fromJson(payload);
  }

  Future<ScanPricingQuote> quoteItem(CollectibleItem item) async {
    final response = await _apiClient.post(
      ApiConstants.pricingQuotePath,
      data: _requestForItem(item),
    );
    final payload = _unwrapResponse(response.data);
    return ScanPricingQuote.fromJson(payload);
  }

  Future<ScanPricingQuote> reprice(ScanResult result) async {
    final response = await _apiClient.post(
      ApiConstants.pricingRepricePath,
      data: _repriceRequestFor(result),
    );
    final payload = _unwrapResponse(response.data);
    return ScanPricingQuote.fromRepriceJson(payload);
  }

  Map<String, dynamic> _requestFor(ScanResult result) {
    return {
      'itemName': result.title,
      'category': result.category,
      'condition': result.condition,
      'estimatedValue': result.aiEstimatedValue ?? result.estimatedValue,
      'displayCurrency': result.pricing.currency,
      'year': result.year,
      'brand': result.brand,
      'setName': result.setName,
      'series': result.series,
      'cardNumber': result.cardNumber,
      'playerOrCharacter': result.playerOrCharacter,
      'rarity': result.rarity,
      'edition': result.edition,
      'language': result.language,
      'notes': result.notes,
    };
  }

  Map<String, dynamic> _requestForItem(CollectibleItem item) {
    return {
      'itemName': item.title,
      'category': item.category,
      'condition': item.condition,
      'estimatedValue': item.aiEstimatedValue ?? item.estimatedValue,
      'displayCurrency': item.pricing?.currency ?? 'AUD',
      'year': item.year,
      'brand': item.brand,
      'setName': item.setName,
      'series': item.series,
      'cardNumber': item.cardNumber,
      'playerOrCharacter': item.playerOrCharacter,
      'rarity': item.rarity,
      'edition': item.edition,
      'language': item.language,
      'notes': item.notes,
    };
  }

  Map<String, dynamic> _repriceRequestFor(ScanResult result) {
    return {
      'itemId': result.id,
      'previousValue': result.estimatedMarketValue ?? result.estimatedValue,
      'previousCurrency': result.pricing.currency,
      'displayCurrency': 'AUD',
      'correctionSource': 'scan_review',
      'identity': {
        'title': result.title,
        'category': result.category,
        'brand': result.brand,
        'setName': result.setName,
        'series': result.series,
        'cardNumber': result.cardNumber,
        'condition': result.condition,
        'year': result.year,
        'edition': result.edition,
        'language': result.language,
        'rarity': result.rarity,
        'playerOrCharacter': result.playerOrCharacter,
        'estimatedGrade': result.estimatedGrade,
        'notes': result.notes,
      },
    };
  }

  Map<String, dynamic> _unwrapResponse(Object? data) {
    final decoded = parseJsonMap(data);
    for (final key in const ['result', 'data']) {
      final nested = parseJsonMap(decoded[key]);
      if (nested.isNotEmpty) {
        return nested;
      }
    }
    return decoded;
  }
}

class ScanPricingQuote {
  const ScanPricingQuote({
    required this.estimatedValue,
    required this.pricing,
    required this.marketSummary,
    required this.estimatedMarketValue,
    required this.aiEstimatedValue,
    required this.valuationStatus,
    required this.valuationSource,
    required this.valuationConfidence,
  });

  final double estimatedValue;
  final PricingInfo pricing;
  final MarketSummary? marketSummary;
  final double? estimatedMarketValue;
  final double? aiEstimatedValue;
  final ValuationStatus valuationStatus;
  final String valuationSource;
  final double? valuationConfidence;

  factory ScanPricingQuote.fromJson(Map<String, dynamic> json) {
    final pricingJson = parseJsonMap(json['pricing']);
    final marketSummaryJson = parseJsonMap(json['marketSummary']);
    final pricing = PricingInfo.fromJson({
      ...pricingJson,
      if (!pricingJson.containsKey('estimatedMarketValue'))
        'estimatedMarketValue': json['estimatedMarketValue'],
      if (!pricingJson.containsKey('lowEstimate'))
        'lowEstimate': json['lowEstimate'],
      if (!pricingJson.containsKey('highEstimate'))
        'highEstimate': json['highEstimate'],
      if (!pricingJson.containsKey('currency')) 'currency': json['currency'],
      if (!pricingJson.containsKey('valuationStatus'))
        'valuationStatus': json['valuationStatus'],
      if (!pricingJson.containsKey('valuationSource'))
        'valuationSource': json['valuationSource'],
      if (!pricingJson.containsKey('pricingConfidence'))
        'pricingConfidence': json['valuationConfidence'],
    });
    return ScanPricingQuote(
      estimatedValue:
          parseNullableDouble(json['estimatedValue']) ??
          pricing.estimatedMarketValue,
      pricing: pricing,
      marketSummary: marketSummaryJson.isEmpty
          ? null
          : MarketSummary.fromJson(marketSummaryJson),
      estimatedMarketValue: parseNullableDouble(json['estimatedMarketValue']),
      aiEstimatedValue: parseNullableDouble(json['aiEstimatedValue']),
      valuationStatus: ValuationStatus.fromJson(json['valuationStatus']),
      valuationSource: parseString(
        json['valuationSource'],
        fallback: 'unknown',
      ),
      valuationConfidence: _normalizeConfidence(json['valuationConfidence']),
    );
  }

  factory ScanPricingQuote.fromRepriceJson(Map<String, dynamic> json) {
    final pricingJson = parseJsonMap(json['pricing']);
    final sourceJson = parseJsonMap(pricingJson['pricingSource']);
    final originalJson = parseJsonMap(pricingJson['originalMarketPayload']);
    final matchJson = parseJsonMap(pricingJson['matchMetadata']);
    final status = parseString(pricingJson['status']);
    final isAvailable = status.toLowerCase() == 'available';
    final pricingSource = parseString(
      sourceJson['name'],
      fallback: isAvailable ? 'Market provider' : 'market',
    );
    final pricing = PricingInfo.fromJson({
      'estimatedMarketValue': pricingJson['estimatedMarketValue'],
      'lowEstimate': pricingJson['lowEstimate'],
      'highEstimate': pricingJson['highEstimate'],
      'currency': pricingJson['currency'],
      'pricingSource': pricingSource,
      'pricingConfidence': pricingJson['confidenceScore'],
      'lastUpdated': sourceJson['lastChecked'],
      'valuationStatus': isAvailable ? 'market_estimated' : 'unavailable',
      'valuationSource': pricingSource,
      'pricingExplanation':
          matchJson['reason'] ?? pricingJson['displayMessage'],
      'reasonCode': pricingJson['reasonCode'],
      'valuationStrategy': pricingJson['valuationStrategy'],
      'attributionText': sourceJson['attributionText'],
      'displayString': pricingJson['displayString'],
      'originalPrice': originalJson['price'],
      'originalCurrency': originalJson['currency'],
      'exchangeRateUsed': originalJson['exchangeRateUsed'],
      'exchangeRateDate': originalJson['exchangeRateDate'],
    });
    return ScanPricingQuote(
      estimatedValue: pricing.estimatedMarketValue,
      pricing: pricing,
      marketSummary: null,
      estimatedMarketValue: pricing.estimatedMarketValue > 0
          ? pricing.estimatedMarketValue
          : null,
      aiEstimatedValue: null,
      valuationStatus: pricing.valuationStatus,
      valuationSource: pricing.valuationSource,
      valuationConfidence: pricing.pricingConfidence,
    );
  }
}

double? _normalizeConfidence(Object? value) {
  final confidence = parseNullableDouble(value);
  if (confidence == null) {
    return null;
  }
  return confidence > 1 ? confidence / 100 : confidence;
}
