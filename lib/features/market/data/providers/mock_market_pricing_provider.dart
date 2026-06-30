import 'dart:math';

import 'package:collectiq_ai/features/market/domain/entities/market_comp.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_pricing_request.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_pricing_result.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_pricing_provider.dart';

/// Deterministic mock pricing provider used until live pricing APIs are ready.
class MockMarketPricingProvider implements MarketPricingProvider {
  /// Creates a mock market-pricing provider.
  const MockMarketPricingProvider();

  @override
  Future<MarketPricingResult> price(MarketPricingRequest request) async {
    final baseValue = _baseValueFor(request);
    final sources = _sourcesFor(request.category);
    final seed = _seedFor(request);
    final random = Random(seed);
    final lastUpdated = request.asOfDate ?? DateTime.utc(2026, 6, 30);
    final comps = List<MarketComp>.generate(5, (index) {
      final source = sources[index % sources.length];
      final variance = 0.76 + (random.nextDouble() * 0.52);
      final soldPrice = (baseValue * variance).clamp(1, double.infinity);
      return MarketComp(
        source: source,
        title: _compTitle(request, source, index),
        soldPrice: double.parse(soldPrice.toStringAsFixed(2)),
        currency: request.currency,
        soldDate: lastUpdated.subtract(Duration(days: 7 + (index * 10))),
        condition: _conditionFor(request.condition, index),
      );
    });
    final sortedPrices = comps.map((comp) => comp.soldPrice).toList()..sort();
    final average =
        sortedPrices.fold<double>(0, (sum, price) => sum + price) /
        sortedPrices.length;

    return MarketPricingResult(
      estimatedValue: double.parse(average.toStringAsFixed(2)),
      lowEstimate: sortedPrices.first,
      highEstimate: sortedPrices.last,
      currency: request.currency,
      marketTrend: _trendLabel(average, baseValue),
      comparableSales: comps,
      confidence: _confidenceFor(request, comps.length),
      sourceLabel: 'Mock pricing blend: ${sources.join(' + ')}',
      lastUpdated: lastUpdated,
    );
  }

  double _baseValueFor(MarketPricingRequest request) {
    final normalizedCategory = request.category.toLowerCase();
    final normalizedTitle = request.title.toLowerCase();
    if (normalizedTitle.contains('charizard')) {
      return 1850;
    }
    if (normalizedTitle.contains('mantle')) {
      return 125000;
    }
    if (normalizedCategory.contains('coin')) {
      return 240;
    }
    if (normalizedCategory.contains('comic')) {
      return 420;
    }
    if (normalizedCategory.contains('toy') ||
        normalizedCategory.contains('figure')) {
      return 160;
    }
    if (normalizedCategory.contains('card')) {
      return 95;
    }
    return 120;
  }

  int _seedFor(MarketPricingRequest request) {
    final text = [
      request.title,
      request.category,
      request.condition,
      request.year,
      request.brand,
      request.setName,
      request.cardNumber,
      request.playerOrCharacter,
    ].whereType<String>().join('|');
    return text.codeUnits.fold<int>(17, (sum, codeUnit) => sum + codeUnit);
  }

  List<String> _sourcesFor(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('trading') || normalized.contains('card')) {
      return const ['eBay Completed', 'TCGplayer', 'COMC'];
    }
    if (normalized.contains('coin')) {
      return const ['eBay Completed', 'PriceCharting', 'Heritage Snapshot'];
    }
    if (normalized.contains('comic')) {
      return const ['eBay Completed', 'PriceCharting', 'CGC Market'];
    }
    return const ['eBay Completed', 'PriceCharting', 'Collector Archive'];
  }

  String _compTitle(MarketPricingRequest request, String source, int index) {
    const suffixes = ['completed sale', 'verified comp', 'auction result'];
    return '${request.title} ${suffixes[index % suffixes.length]} ($source)';
  }

  String _conditionFor(String? condition, int index) {
    if (index == 0 && condition != null && condition.trim().isNotEmpty) {
      return condition;
    }
    const alternates = ['Near Mint', 'Excellent', 'Very Good', 'Graded'];
    return alternates[index % alternates.length];
  }

  String _trendLabel(double average, double baseValue) {
    if (average >= baseValue * 1.06) {
      return 'Rising';
    }
    if (average <= baseValue * 0.94) {
      return 'Cooling';
    }
    return 'Stable';
  }

  double _confidenceFor(MarketPricingRequest request, int salesCount) {
    final hasSpecificIdentifiers =
        request.year != null ||
        request.setName != null ||
        request.cardNumber != null ||
        request.playerOrCharacter != null;
    final confidence =
        (salesCount / 8).clamp(0, 1) * 0.55 +
        (hasSpecificIdentifiers ? 0.35 : 0.2);
    return double.parse(confidence.clamp(0, 0.95).toStringAsFixed(2));
  }
}
