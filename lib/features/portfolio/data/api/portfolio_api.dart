import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/core/network/api_result.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the portfolio API data source.
final portfolioApiProvider = Provider<PortfolioApi>((ref) {
  return PortfolioApi(ref.watch(apiClientProvider));
});

/// API data source for portfolio-related Azure backend operations.
class PortfolioApi {
  /// Creates a portfolio API with an injected API client.
  const PortfolioApi(this._apiClient);

  final ApiClient _apiClient;

  /// Returns a mocked remote portfolio item list.
  Future<ApiResult<List<CollectibleItem>>> getPortfolio() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final endpoint = '${_apiClient.baseUrl}${ApiConstants.portfolioPath}';

    if (endpoint.isEmpty) {
      return const ApiFailure(
        message: 'Portfolio request could not be prepared.',
        code: 'portfolio.invalid_endpoint',
      );
    }

    return const ApiSuccess(<CollectibleItem>[]);
  }

  /// Saves a portfolio item and returns the mocked saved item.
  Future<ApiResult<CollectibleItem>> savePortfolio(CollectibleItem item) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final endpoint = '${_apiClient.baseUrl}${ApiConstants.portfolioPath}';

    if (endpoint.isEmpty) {
      return const ApiFailure(
        message: 'Portfolio save request could not be prepared.',
        code: 'portfolio.save.invalid_endpoint',
      );
    }

    return ApiSuccess(item);
  }

  /// Deletes a portfolio item and returns a mocked success flag.
  Future<ApiResult<bool>> deleteItem(String itemId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final endpoint =
        '${_apiClient.baseUrl}${ApiConstants.portfolioItemPath}/$itemId';

    if (itemId.isEmpty || endpoint.isEmpty) {
      return const ApiFailure(
        message: 'Portfolio delete request could not be prepared.',
        code: 'portfolio.delete.invalid_item',
      );
    }

    return const ApiSuccess(true);
  }

  /// Reprices a portfolio item using trusted backend pricing providers.
  Future<ApiResult<PortfolioRepriceResult>> repriceItem(
    CollectibleItem item, {
    String correctionSource = 'manual',
  }) async {
    try {
      final response = await _apiClient.post(
        '/api/pricing/reprice',
        data: {
          'itemId': item.id,
          'previousValue': item.estimatedValue,
          'previousCurrency': item.pricing?.currency ?? 'AUD',
          'displayCurrency': item.pricing?.currency ?? 'AUD',
          'correctionSource': correctionSource,
          'identity': {
            'title': item.title,
            'category': item.category,
            'brand': item.brand,
            'setName': item.setName,
            'series': item.series,
            'cardNumber': item.cardNumber,
            'condition': item.condition,
            'year': item.year,
            'edition': item.edition,
            'language': item.language,
            'rarity': item.rarity,
            'playerOrCharacter': item.playerOrCharacter,
            'estimatedGrade': item.estimatedGrade,
            'notes': item.notes,
          },
        },
      );
      final data = response.data;
      if (data is! Map) {
        return const ApiFailure(
          message: 'Pricing response could not be read.',
          code: 'pricing.invalid_response',
        );
      }
      return ApiSuccess(
        PortfolioRepriceResult.fromJson(Map<String, dynamic>.from(data)),
      );
    } catch (_) {
      return const ApiFailure(
        message: 'Trusted pricing is unavailable. Please try again later.',
        code: 'pricing.reprice_failed',
      );
    }
  }
}

/// Parsed trusted reprice response for portfolio updates.
class PortfolioRepriceResult {
  /// Creates a parsed reprice result.
  const PortfolioRepriceResult({
    required this.status,
    required this.pricing,
    required this.marketSummary,
    this.displayMessage,
    this.reasonCode,
  });

  final String status;
  final PricingInfo pricing;
  final MarketSummary marketSummary;
  final String? displayMessage;
  final String? reasonCode;

  bool get isAvailable => status == 'available';

  factory PortfolioRepriceResult.fromJson(Map<String, dynamic> json) {
    final pricingJson = Map<String, dynamic>.from(
      json['pricing'] as Map? ?? const {},
    );
    final status = pricingJson['status'] as String? ?? 'unavailable';
    final estimatedValue = _nullableDouble(pricingJson['estimatedMarketValue']);
    final lowEstimate = _nullableDouble(pricingJson['lowEstimate']);
    final highEstimate = _nullableDouble(pricingJson['highEstimate']);
    final currency = pricingJson['currency'] as String? ?? 'AUD';
    final pricingSource = Map<String, dynamic>.from(
      pricingJson['pricingSource'] as Map? ?? const {},
    );
    final confidence =
        _nullableDouble(pricingJson['confidenceScore']) ??
        ((_nullableDouble(pricingJson['pricingConfidence']) ?? 0) / 100);
    final lastChecked = pricingSource['lastChecked'];
    final sales = (pricingJson['comparableSales'] as List? ?? const [])
        .whereType<Map>()
        .map((sale) => Map<String, dynamic>.from(sale))
        .toList(growable: false);

    final pricing = PricingInfo(
      estimatedMarketValue: estimatedValue ?? 0,
      lowEstimate: lowEstimate ?? 0,
      highEstimate: highEstimate ?? 0,
      currency: currency,
      pricingSource: pricingSource['name'] as String? ?? 'Trusted pricing',
      pricingConfidence: confidence.clamp(0, 1).toDouble(),
      lastUpdated: _dateTimeOrNull(lastChecked),
      valuationStatus: status == 'available'
          ? ValuationStatus.marketEstimated
          : ValuationStatus.unavailable,
      valuationSource: pricingSource['name'] as String? ?? 'trusted_pricing',
    );

    return PortfolioRepriceResult(
      status: status,
      displayMessage: pricingJson['displayMessage'] as String?,
      reasonCode: pricingJson['reasonCode'] as String?,
      pricing: pricing,
      marketSummary: MarketSummary.fromJson({
        'averagePrice': estimatedValue ?? 0,
        'medianPrice': estimatedValue ?? 0,
        'lowPrice': lowEstimate ?? 0,
        'highPrice': highEstimate ?? 0,
        'salesCount': sales.length,
        'trendLabel': 'Stable',
        'confidence': confidence,
        'lastUpdated': _dateTimeOrNull(lastChecked)?.toIso8601String(),
        'sources': [pricing.pricingSource],
        'comps': sales,
      }),
    );
  }
}

double? _nullableDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

DateTime? _dateTimeOrNull(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}
