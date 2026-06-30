import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

class CollectorDashboardAnalyticsService {
  const CollectorDashboardAnalyticsService();

  CollectorDashboardAnalytics build(List<CollectibleItem> orderedItems) {
    final items = List<CollectibleItem>.unmodifiable(orderedItems);
    final itemCount = items.length;
    final totalValue = items.fold<double>(
      0,
      (sum, item) => sum + item.estimatedValue,
    );
    final totalConfidence = items.fold<double>(
      0,
      (sum, item) => sum + item.confidence,
    );
    final categoryDistribution = {
      for (final category in CollectorCategory.values) category: 0,
    };
    for (final item in items) {
      final category = categoryForCollectible(item.category);
      categoryDistribution[category] =
          (categoryDistribution[category] ?? 0) + 1;
    }

    final highestValueItem = _maxBy(items, (item) => item.estimatedValue);
    final lowestValueItem = _minBy(items, (item) => item.estimatedValue);
    final mostRecentItem = items.isEmpty ? null : items.first;
    final strongestConfidenceItem = _maxBy(items, (item) => item.confidence);
    final largestCategory = _largestCategory(categoryDistribution);
    final lowConfidenceItems = items
        .where((item) => item.confidence < 0.75)
        .toList(growable: false);
    final newestTimestamp = _newestTimestamp(items);
    final recentCutoff = newestTimestamp?.subtract(const Duration(days: 7));
    final recentlyAddedCount = recentCutoff == null
        ? 0
        : items
              .where(
                (item) =>
                    !collectibleDisplayTimestamp(item).isBefore(recentCutoff),
              )
              .length;
    final topHighestValue = _sortedByValue(items, descending: true).take(5);
    final topLowestConfidence = _sortedByConfidence(
      items,
      descending: false,
    ).take(5);
    final newestAdditions = items.take(5);
    final health = _healthScore(items);

    final analytics = CollectorDashboardAnalytics(
      items: items,
      totalValue: totalValue,
      itemCount: itemCount,
      averageItemValue: itemCount == 0 ? 0 : totalValue / itemCount,
      averageConfidence: itemCount == 0 ? 0 : totalConfidence / itemCount,
      recentlyAddedCount: recentlyAddedCount,
      categoryDistribution: categoryDistribution,
      lowConfidenceItems: lowConfidenceItems,
      topHighestValue: topHighestValue.toList(growable: false),
      topLowestConfidence: topLowestConfidence.toList(growable: false),
      newestAdditions: newestAdditions.toList(growable: false),
      collectionHealth: health,
      insights: const [],
      recommendations: const [],
      dailySnapshots: _snapshots(items, TrendSnapshotPeriod.daily),
      weeklySnapshots: _snapshots(items, TrendSnapshotPeriod.weekly),
      monthlySnapshots: _snapshots(items, TrendSnapshotPeriod.monthly),
      highestValueItem: highestValueItem,
      lowestValueItem: lowestValueItem,
      mostRecentItem: mostRecentItem,
      strongestConfidenceItem: strongestConfidenceItem,
      largestCategory: largestCategory,
    );

    return CollectorDashboardAnalytics(
      items: analytics.items,
      totalValue: analytics.totalValue,
      itemCount: analytics.itemCount,
      averageItemValue: analytics.averageItemValue,
      averageConfidence: analytics.averageConfidence,
      recentlyAddedCount: analytics.recentlyAddedCount,
      categoryDistribution: analytics.categoryDistribution,
      lowConfidenceItems: analytics.lowConfidenceItems,
      topHighestValue: analytics.topHighestValue,
      topLowestConfidence: analytics.topLowestConfidence,
      newestAdditions: analytics.newestAdditions,
      collectionHealth: analytics.collectionHealth,
      insights: _insights(analytics),
      recommendations: _recommendations(analytics),
      dailySnapshots: analytics.dailySnapshots,
      weeklySnapshots: analytics.weeklySnapshots,
      monthlySnapshots: analytics.monthlySnapshots,
      highestValueItem: analytics.highestValueItem,
      lowestValueItem: analytics.lowestValueItem,
      mostRecentItem: analytics.mostRecentItem,
      strongestConfidenceItem: analytics.strongestConfidenceItem,
      largestCategory: analytics.largestCategory,
    );
  }

  static CollectorCategory categoryForCollectible(String category) {
    final value = category.toLowerCase();
    if (value.contains('card') || value.contains('tcg')) {
      return CollectorCategory.cards;
    }
    if (value.contains('coin')) {
      return CollectorCategory.coins;
    }
    if (value.contains('comic')) {
      return CollectorCategory.comics;
    }
    if (value.contains('memorabilia') ||
        value.contains('sports') ||
        value.contains('autograph') ||
        value.contains('jersey')) {
      return CollectorCategory.memorabilia;
    }

    return CollectorCategory.other;
  }

  CollectionHealthScore _healthScore(List<CollectibleItem> items) {
    if (items.isEmpty) {
      return const CollectionHealthScore(
        score: 0,
        confidenceScore: 0,
        metadataScore: 0,
        pricingFreshnessScore: 0,
        duplicateScore: 100,
        qualityScore: 0,
        duplicateCount: 0,
        missingDataCount: 0,
        stalePricingCount: 0,
        lowQualityCount: 0,
      );
    }

    final confidenceScore = _scoreAverage(
      items.fold<double>(0, (sum, item) => sum + item.confidence) /
          items.length,
    );
    final missingDataCount = items.where(_hasMissingImportantData).length;
    final metadataScore = _scoreRatio(
      good: items.length - missingDataCount,
      total: items.length,
    );
    final stalePricingCount = items.where(_hasStalePricing).length;
    final pricingFreshnessScore = _scoreRatio(
      good: items.length - stalePricingCount,
      total: items.length,
    );
    final duplicateCount = _duplicateCount(items);
    final duplicateScore = _scoreRatio(
      good: items.length - duplicateCount,
      total: items.length,
    );
    final lowQualityCount = items.where(_hasLowQualitySignal).length;
    final qualityScore = _scoreRatio(
      good: items.length - lowQualityCount,
      total: items.length,
    );
    final score =
        (confidenceScore * 0.35 +
                metadataScore * 0.2 +
                pricingFreshnessScore * 0.2 +
                duplicateScore * 0.15 +
                qualityScore * 0.1)
            .round()
            .clamp(0, 100);

    return CollectionHealthScore(
      score: score,
      confidenceScore: confidenceScore,
      metadataScore: metadataScore,
      pricingFreshnessScore: pricingFreshnessScore,
      duplicateScore: duplicateScore,
      qualityScore: qualityScore,
      duplicateCount: duplicateCount,
      missingDataCount: missingDataCount,
      stalePricingCount: stalePricingCount,
      lowQualityCount: lowQualityCount,
    );
  }

  List<CollectionInsight> _insights(CollectorDashboardAnalytics analytics) {
    if (analytics.isEmpty) {
      return const [
        CollectionInsight(
          title: 'Add your first collectible',
          message: 'Scan an item to unlock collection intelligence.',
          type: CollectionInsightType.highlight,
        ),
      ];
    }

    return [
      CollectionInsight(
        title: 'Collection value increased',
        message:
            'Your tracked value is ${_aud(analytics.totalValue)} across ${analytics.itemCount} items.',
        type: CollectionInsightType.positive,
      ),
      if (analytics.lowConfidenceItems.isNotEmpty)
        CollectionInsight(
          title: 'Low confidence scans',
          message:
              '${analytics.lowConfidenceItems.length} items should be reviewed or rescanned.',
          type: CollectionInsightType.warning,
        ),
      if (analytics.topLowestConfidence.isNotEmpty)
        CollectionInsight(
          title: 'Cards needing review',
          message:
              '${analytics.topLowestConfidence.first.title} has the lowest confidence signal.',
          type: CollectionInsightType.review,
        ),
      if (analytics.highestValueItem != null)
        CollectionInsight(
          title: 'Highest value item',
          message:
              '${analytics.highestValueItem!.title} leads at ${_aud(analytics.highestValueItem!.estimatedValue)}.',
          type: CollectionInsightType.highlight,
        ),
      if (analytics.largestCategory != null)
        CollectionInsight(
          title: 'Most scanned category',
          message:
              '${analytics.largestCategory!.label} is your largest category.',
          type: CollectionInsightType.positive,
        ),
    ];
  }

  List<CollectionRecommendation> _recommendations(
    CollectorDashboardAnalytics analytics,
  ) {
    if (analytics.isEmpty) {
      return const [
        CollectionRecommendation(
          title: 'Add more collectibles',
          message: 'Scan your first item to start building portfolio history.',
          type: CollectionRecommendationType.addMoreCollectibles,
        ),
      ];
    }

    final recommendations = <CollectionRecommendation>[];
    if (analytics.lowConfidenceItems.isNotEmpty) {
      recommendations.add(
        CollectionRecommendation(
          title: 'Review low confidence',
          message:
              'Review ${analytics.lowConfidenceItems.length} items with confidence below 75%.',
          type: CollectionRecommendationType.reviewLowConfidence,
        ),
      );
      recommendations.add(
        const CollectionRecommendation(
          title: 'Scan again',
          message: 'Retake low-confidence items with better light and framing.',
          type: CollectionRecommendationType.scanAgain,
        ),
      );
    }
    if (analytics.collectionHealth.lowQualityCount > 0) {
      recommendations.add(
        CollectionRecommendation(
          title: 'Improve photo',
          message:
              '${analytics.collectionHealth.lowQualityCount} items mention image quality issues.',
          type: CollectionRecommendationType.improvePhoto,
        ),
      );
    }
    if (analytics.itemCount < 5) {
      recommendations.add(
        const CollectionRecommendation(
          title: 'Add more collectibles',
          message:
              'Scan at least five items for more useful collection trends.',
          type: CollectionRecommendationType.addMoreCollectibles,
        ),
      );
    }
    if (analytics.itemCount >= 5 || analytics.totalValue >= 1000) {
      recommendations.add(
        const CollectionRecommendation(
          title: 'Upgrade plan',
          message: 'Unlock deeper valuation history and collection monitoring.',
          type: CollectionRecommendationType.upgradePlan,
        ),
      );
    }

    return recommendations.take(5).toList(growable: false);
  }

  List<TrendSnapshot> _snapshots(
    List<CollectibleItem> items,
    TrendSnapshotPeriod period,
  ) {
    final buckets = <DateTime, List<CollectibleItem>>{};
    for (final item in items) {
      final bucket = _bucketDate(collectibleDisplayTimestamp(item), period);
      buckets.putIfAbsent(bucket, () => []).add(item);
    }

    final dates = buckets.keys.toList()..sort();
    return [
      for (final date in dates)
        TrendSnapshot(
          period: period,
          date: date,
          totalValue: buckets[date]!.fold<double>(
            0,
            (sum, item) => sum + item.estimatedValue,
          ),
          itemCount: buckets[date]!.length,
          averageConfidence:
              buckets[date]!.fold<double>(
                0,
                (sum, item) => sum + item.confidence,
              ) /
              buckets[date]!.length,
        ),
    ];
  }

  DateTime _bucketDate(DateTime date, TrendSnapshotPeriod period) {
    final normalized = DateTime(date.year, date.month, date.day);
    switch (period) {
      case TrendSnapshotPeriod.daily:
        return normalized;
      case TrendSnapshotPeriod.weekly:
        return normalized.subtract(Duration(days: normalized.weekday - 1));
      case TrendSnapshotPeriod.monthly:
        return DateTime(date.year, date.month);
    }
  }

  bool _hasMissingImportantData(CollectibleItem item) {
    final fields = [
      item.year,
      item.brand,
      item.setName,
      item.series,
      item.cardNumber,
      item.playerOrCharacter,
      item.rarity,
      item.condition,
      item.notes,
    ];
    return fields
            .where((value) => value != null && value.trim().isNotEmpty)
            .length <
        3;
  }

  bool _hasStalePricing(CollectibleItem item) {
    final lastUpdated =
        item.marketSummary?.lastUpdated ?? item.pricing?.lastUpdated;
    if (lastUpdated == null) {
      return true;
    }
    final newest = _newestTimestamp([item]) ?? DateTime.now();
    return newest.difference(lastUpdated).inDays > 30;
  }

  bool _hasLowQualitySignal(CollectibleItem item) {
    final quality = [
      item.detectionQuality,
      item.confidenceExplanation,
      item.aiReasoning,
      item.notes,
    ].whereType<String>().join(' ').toLowerCase();
    return quality.contains('blurry') ||
        quality.contains('glare') ||
        quality.contains('dark') ||
        quality.contains('cropped') ||
        quality.contains('low resolution') ||
        quality.contains('poor');
  }

  int _duplicateCount(List<CollectibleItem> items) {
    final seen = <String>{};
    var duplicates = 0;
    for (final item in items) {
      final key = [item.title, item.category].join('|').toLowerCase().trim();
      if (key.isEmpty) {
        continue;
      }
      if (!seen.add(key)) {
        duplicates += 1;
      }
    }
    return duplicates;
  }

  int _scoreAverage(double value) {
    return (value.clamp(0, 1) * 100).round();
  }

  int _scoreRatio({required int good, required int total}) {
    if (total <= 0) {
      return 0;
    }
    return ((good.clamp(0, total) / total) * 100).round();
  }

  DateTime? _newestTimestamp(List<CollectibleItem> items) {
    DateTime? newest;
    for (final item in items) {
      final timestamp = collectibleDisplayTimestamp(item);
      if (newest == null || timestamp.isAfter(newest)) {
        newest = timestamp;
      }
    }
    return newest;
  }

  Iterable<CollectibleItem> _sortedByValue(
    List<CollectibleItem> items, {
    required bool descending,
  }) {
    final sorted = [...items]
      ..sort((a, b) {
        final comparison = a.estimatedValue.compareTo(b.estimatedValue);
        return descending ? -comparison : comparison;
      });
    return sorted;
  }

  Iterable<CollectibleItem> _sortedByConfidence(
    List<CollectibleItem> items, {
    required bool descending,
  }) {
    final sorted = [...items]
      ..sort((a, b) {
        final comparison = a.confidence.compareTo(b.confidence);
        return descending ? -comparison : comparison;
      });
    return sorted;
  }

  CollectorCategory? _largestCategory(
    Map<CollectorCategory, int> categoryCounts,
  ) {
    CollectorCategory? largest;
    var largestCount = 0;
    for (final entry in categoryCounts.entries) {
      if (entry.value > largestCount) {
        largest = entry.key;
        largestCount = entry.value;
      }
    }
    return largest;
  }

  CollectibleItem? _maxBy(
    List<CollectibleItem> items,
    double Function(CollectibleItem item) valueFor,
  ) {
    CollectibleItem? best;
    for (final item in items) {
      if (best == null || valueFor(item) > valueFor(best)) {
        best = item;
      }
    }
    return best;
  }

  CollectibleItem? _minBy(
    List<CollectibleItem> items,
    double Function(CollectibleItem item) valueFor,
  ) {
    CollectibleItem? best;
    for (final item in items) {
      if (best == null || valueFor(item) < valueFor(best)) {
        best = item;
      }
    }
    return best;
  }

  String _aud(double value) {
    return 'AUD ${value.toStringAsFixed(0)}';
  }
}
