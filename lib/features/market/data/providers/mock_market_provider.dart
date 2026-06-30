import 'dart:math';

import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_comp.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_provider.dart';

class MockMarketProvider implements MarketProvider {
  const MockMarketProvider();

  @override
  Future<MarketSummary> summarizeMarket(RecognitionResult recognition) async {
    final sources = _sourcesFor(recognition.category);
    final baseValue = recognition.pricing.estimatedMarketValue > 0
        ? recognition.pricing.estimatedMarketValue
        : recognition.estimatedValue;
    final seed = recognition.title.codeUnits.fold<int>(
      recognition.category.length,
      (sum, codeUnit) => sum + codeUnit,
    );
    final random = Random(seed);
    final comps = List<MarketComp>.generate(5, (index) {
      final source = sources[index % sources.length];
      final variance = 0.72 + (random.nextDouble() * 0.58);
      final soldPrice = (baseValue * variance).clamp(1, double.infinity);
      return MarketComp(
        source: source,
        title: _compTitle(recognition, source, index),
        soldPrice: double.parse(soldPrice.toStringAsFixed(2)),
        currency: recognition.pricing.currency,
        soldDate: DateTime.now().subtract(Duration(days: 8 + (index * 11))),
        condition: _conditionFor(recognition.condition, index),
        url: null,
      );
    });

    final sortedPrices = comps.map((comp) => comp.soldPrice).toList()..sort();
    final average =
        sortedPrices.fold<double>(0, (sum, price) => sum + price) /
        sortedPrices.length;
    final median = sortedPrices[sortedPrices.length ~/ 2];

    return MarketSummary(
      averagePrice: double.parse(average.toStringAsFixed(2)),
      medianPrice: median,
      lowPrice: sortedPrices.first,
      highPrice: sortedPrices.last,
      salesCount: comps.length,
      trendLabel: _trendLabel(average, baseValue),
      confidence: _confidenceFor(recognition.confidence, comps.length),
      lastUpdated: DateTime.now(),
      sources: sources,
      comps: comps,
    );
  }

  List<String> _sourcesFor(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('trading') || normalized.contains('card')) {
      return const ['eBay Sold', 'TCGplayer', 'COMC'];
    }
    if (normalized.contains('sport')) {
      return const ['eBay Sold', 'PSA Auction', 'COMC'];
    }
    if (normalized.contains('coin')) {
      return const ['eBay Sold', 'PriceCharting', 'Heritage Snapshot'];
    }
    if (normalized.contains('comic')) {
      return const ['eBay Sold', 'PriceCharting', 'CGC Market'];
    }
    if (normalized.contains('toy') || normalized.contains('figure')) {
      return const ['eBay Sold', 'PriceCharting', 'Collector Archive'];
    }
    return const ['eBay Sold', 'PriceCharting', 'Collector Archive'];
  }

  String _compTitle(RecognitionResult recognition, String source, int index) {
    final suffixes = [
      'sold listing',
      'verified comp',
      'recent sale',
      'auction',
    ];
    return '${recognition.title} ${suffixes[index % suffixes.length]} ($source)';
  }

  String _conditionFor(String condition, int index) {
    if (index == 0) {
      return condition;
    }
    const alternates = ['Near Mint', 'Excellent', 'Very Good', 'Graded'];
    return alternates[index % alternates.length];
  }

  String _trendLabel(double average, double baseValue) {
    if (average >= baseValue * 1.08) {
      return 'Rising';
    }
    if (average <= baseValue * 0.92) {
      return 'Cooling';
    }
    return 'Stable';
  }

  double _confidenceFor(double recognitionConfidence, int salesCount) {
    final confidence =
        (recognitionConfidence * 0.7) + min(salesCount / 10, 1) * 0.3;
    return double.parse(confidence.clamp(0, 1).toStringAsFixed(2));
  }
}
