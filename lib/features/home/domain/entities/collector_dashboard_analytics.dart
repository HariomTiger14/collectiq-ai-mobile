import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

enum CollectorCategory {
  cards(label: 'Cards'),
  coins(label: 'Coins'),
  comics(label: 'Comics'),
  memorabilia(label: 'Memorabilia'),
  other(label: 'Other');

  const CollectorCategory({required this.label});

  final String label;
}

enum TrendSnapshotPeriod {
  daily(label: 'Daily'),
  weekly(label: 'Weekly'),
  monthly(label: 'Monthly');

  const TrendSnapshotPeriod({required this.label});

  final String label;
}

enum CollectionInsightType { positive, warning, review, highlight }

enum CollectionRecommendationType {
  scanAgain,
  improvePhoto,
  upgradePlan,
  reviewLowConfidence,
  addMoreCollectibles,
}

class CollectorDashboardAnalytics {
  const CollectorDashboardAnalytics({
    required this.items,
    required this.totalValue,
    required this.itemCount,
    required this.averageItemValue,
    required this.averageConfidence,
    required this.recentlyAddedCount,
    required this.categoryDistribution,
    required this.lowConfidenceItems,
    required this.topHighestValue,
    required this.topLowestConfidence,
    required this.newestAdditions,
    required this.collectionHealth,
    required this.insights,
    required this.recommendations,
    required this.dailySnapshots,
    required this.weeklySnapshots,
    required this.monthlySnapshots,
    this.highestValueItem,
    this.lowestValueItem,
    this.mostRecentItem,
    this.strongestConfidenceItem,
    this.largestCategory,
  });

  final List<CollectibleItem> items;
  final double totalValue;
  final int itemCount;
  final double averageItemValue;
  final double averageConfidence;
  final int recentlyAddedCount;
  final Map<CollectorCategory, int> categoryDistribution;
  final List<CollectibleItem> lowConfidenceItems;
  final List<CollectibleItem> topHighestValue;
  final List<CollectibleItem> topLowestConfidence;
  final List<CollectibleItem> newestAdditions;
  final CollectionHealthScore collectionHealth;
  final List<CollectionInsight> insights;
  final List<CollectionRecommendation> recommendations;
  final List<TrendSnapshot> dailySnapshots;
  final List<TrendSnapshot> weeklySnapshots;
  final List<TrendSnapshot> monthlySnapshots;
  final CollectibleItem? highestValueItem;
  final CollectibleItem? lowestValueItem;
  final CollectibleItem? mostRecentItem;
  final CollectibleItem? strongestConfidenceItem;
  final CollectorCategory? largestCategory;

  bool get isEmpty => itemCount == 0;
}

class CollectionHealthScore {
  const CollectionHealthScore({
    required this.score,
    required this.confidenceScore,
    required this.metadataScore,
    required this.pricingFreshnessScore,
    required this.duplicateScore,
    required this.qualityScore,
    required this.duplicateCount,
    required this.missingDataCount,
    required this.stalePricingCount,
    required this.lowQualityCount,
  });

  final int score;
  final int confidenceScore;
  final int metadataScore;
  final int pricingFreshnessScore;
  final int duplicateScore;
  final int qualityScore;
  final int duplicateCount;
  final int missingDataCount;
  final int stalePricingCount;
  final int lowQualityCount;

  String get label {
    if (score >= 85) {
      return 'Excellent';
    }
    if (score >= 70) {
      return 'Healthy';
    }
    if (score >= 50) {
      return 'Needs review';
    }
    return 'Needs attention';
  }
}

class CollectionInsight {
  const CollectionInsight({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String message;
  final CollectionInsightType type;
}

class CollectionRecommendation {
  const CollectionRecommendation({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String message;
  final CollectionRecommendationType type;
}

class TrendSnapshot {
  const TrendSnapshot({
    required this.period,
    required this.date,
    required this.totalValue,
    required this.itemCount,
    required this.averageConfidence,
  });

  final TrendSnapshotPeriod period;
  final DateTime date;
  final double totalValue;
  final int itemCount;
  final double averageConfidence;
}
