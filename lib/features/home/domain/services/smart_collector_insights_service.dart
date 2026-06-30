import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

class SmartCollectorInsightsService {
  const SmartCollectorInsightsService();

  SmartCollectorIntelligence build(CollectorDashboardAnalytics analytics) {
    final factorScores = _factorScores(analytics);
    final score = _weightedScore(factorScores);

    return SmartCollectorIntelligence(
      collectionScore: CollectionScore(
        score: score,
        factorScores: factorScores,
      ),
      insights: _insights(analytics),
      recommendations: _recommendations(analytics),
      wishlistStatusCounts: _wishlistStatusCounts(analytics),
      goals: _goals(analytics),
      achievements: _achievements(analytics),
    );
  }

  Map<CollectionScoreFactor, int> _factorScores(
    CollectorDashboardAnalytics analytics,
  ) {
    return {
      CollectionScoreFactor.rarity: _rarityScore(analytics.items),
      CollectionScoreFactor.completeness: _completenessScore(analytics),
      CollectionScoreFactor.confidence: (analytics.averageConfidence * 100)
          .round()
          .clamp(0, 100),
      CollectionScoreFactor.portfolioValue: _portfolioValueScore(
        analytics.totalValue,
      ),
      CollectionScoreFactor.diversity: _diversityScore(analytics),
      CollectionScoreFactor.duplicates:
          analytics.collectionHealth.duplicateScore,
      CollectionScoreFactor.imageQuality:
          analytics.collectionHealth.qualityScore,
      CollectionScoreFactor.pricingFreshness:
          analytics.collectionHealth.pricingFreshnessScore,
    };
  }

  int _weightedScore(Map<CollectionScoreFactor, int> factors) {
    final weighted =
        (factors[CollectionScoreFactor.rarity]! * 0.12) +
        (factors[CollectionScoreFactor.completeness]! * 0.12) +
        (factors[CollectionScoreFactor.confidence]! * 0.18) +
        (factors[CollectionScoreFactor.portfolioValue]! * 0.15) +
        (factors[CollectionScoreFactor.diversity]! * 0.12) +
        (factors[CollectionScoreFactor.duplicates]! * 0.10) +
        (factors[CollectionScoreFactor.imageQuality]! * 0.10) +
        (factors[CollectionScoreFactor.pricingFreshness]! * 0.11);
    return (weighted * 10).round().clamp(0, 1000);
  }

  int _rarityScore(List<CollectibleItem> items) {
    if (items.isEmpty) {
      return 0;
    }

    final total = items.fold<double>(
      0,
      (sum, item) => sum + _raritySignal(item),
    );
    return ((total / items.length) * 100).round().clamp(0, 100);
  }

  double _raritySignal(CollectibleItem item) {
    final text = [
      item.rarity,
      item.edition,
      item.estimatedGrade,
      item.notes,
      item.title,
    ].whereType<String>().join(' ').toLowerCase();

    if (text.contains('secret') ||
        text.contains('first edition') ||
        text.contains('1st edition') ||
        text.contains('psa 10') ||
        text.contains('rare holo')) {
      return 1;
    }
    if (text.contains('rare') ||
        text.contains('holo') ||
        text.contains('graded') ||
        text.contains('limited')) {
      return 0.78;
    }
    if (text.contains('uncommon') || text.contains('variant')) {
      return 0.55;
    }
    return 0.35;
  }

  int _completenessScore(CollectorDashboardAnalytics analytics) {
    if (analytics.itemCount == 0) {
      return 0;
    }
    final missingDataPenalty =
        analytics.collectionHealth.missingDataCount / analytics.itemCount;
    final itemProgress = (analytics.itemCount / 100).clamp(0, 1);
    final score = ((1 - missingDataPenalty) * 70) + (itemProgress * 30);
    return score.round().clamp(0, 100);
  }

  int _portfolioValueScore(double value) {
    if (value <= 0) {
      return 0;
    }
    return ((value / 10000).clamp(0, 1) * 100).round();
  }

  int _diversityScore(CollectorDashboardAnalytics analytics) {
    if (analytics.itemCount == 0) {
      return 0;
    }
    final activeCategories = analytics.categoryDistribution.values
        .where((count) => count > 0)
        .length;
    return ((activeCategories / CollectorCategory.values.length) * 100)
        .round()
        .clamp(0, 100);
  }

  List<SmartCollectorInsight> _insights(CollectorDashboardAnalytics analytics) {
    if (analytics.isEmpty) {
      return const [
        SmartCollectorInsight(
          title: 'Start your collector profile',
          message: 'Scan your first collectible to unlock smart guidance.',
          type: SmartCollectorInsightType.highlight,
        ),
      ];
    }

    final insights = <SmartCollectorInsight>[];
    final duplicates = _duplicateGroups(analytics.items);
    for (final entry in duplicates.entries.take(2)) {
      insights.add(
        SmartCollectorInsight(
          title: 'Duplicate collectibles',
          message: 'You have ${entry.value} duplicate ${entry.key}.',
          type: SmartCollectorInsightType.warning,
        ),
      );
    }

    final rescansNeeded =
        analytics.lowConfidenceItems.length +
        analytics.collectionHealth.lowQualityCount;
    if (rescansNeeded > 0) {
      insights.add(
        SmartCollectorInsight(
          title: 'Three collectibles need rescanning',
          message:
              '$rescansNeeded collectibles could use a cleaner photo or confidence review.',
          type: SmartCollectorInsightType.warning,
        ),
      );
    }

    final highestValueCategory = _highestValueCategory(analytics);
    if (highestValueCategory != null) {
      insights.add(
        SmartCollectorInsight(
          title: 'Highest value category',
          message:
              'Your highest value category is ${highestValueCategory.label}.',
          type: SmartCollectorInsightType.highlight,
        ),
      );
    }

    final smallestCategory = _smallestActiveCategory(analytics);
    if (smallestCategory != null) {
      final count = analytics.categoryDistribution[smallestCategory] ?? 0;
      final percent = ((count / analytics.itemCount) * 100).round();
      insights.add(
        SmartCollectorInsight(
          title: '${smallestCategory.label} are underrepresented',
          message:
              '${smallestCategory.label} make up only $percent% of your collection.',
          type: SmartCollectorInsightType.opportunity,
        ),
      );
    }

    final appreciatingComic = analytics.items
        .where(_comicMayAppreciate)
        .firstOrNull;
    if (appreciatingComic != null) {
      insights.add(
        SmartCollectorInsight(
          title: 'Comic watchlist signal',
          message: '${appreciatingComic.title} may appreciate. Watch pricing.',
          type: SmartCollectorInsightType.trend,
        ),
      );
    }

    return insights.take(6).toList(growable: false);
  }

  List<AiCollectorRecommendation> _recommendations(
    CollectorDashboardAnalytics analytics,
  ) {
    if (analytics.isEmpty) {
      return const [
        AiCollectorRecommendation(
          title: 'Add missing cards',
          message: 'Start with a first scan, then build a wishlist.',
          type: AiCollectorRecommendationType.addMissingCards,
        ),
      ];
    }

    final recommendations = <AiCollectorRecommendation>[];
    if (analytics.lowConfidenceItems.isNotEmpty ||
        analytics.collectionHealth.lowQualityCount > 0) {
      recommendations.add(
        const AiCollectorRecommendation(
          title: 'Scan better photos',
          message: 'Retake low-confidence items with bright, even lighting.',
          type: AiCollectorRecommendationType.scanBetterPhotos,
        ),
      );
    }

    final gradingCandidates = analytics.topHighestValue
        .where(
          (item) => item.estimatedValue >= 500 && item.estimatedGrade == null,
        )
        .take(1);
    for (final item in gradingCandidates) {
      recommendations.add(
        AiCollectorRecommendation(
          title: 'Upgrade grading',
          message: '${item.title} may benefit from professional grading.',
          type: AiCollectorRecommendationType.upgradeGrading,
        ),
      );
    }

    final sellCandidate = analytics.items
        .where((item) => _trendFor(item).contains('rising'))
        .firstOrNull;
    if (sellCandidate != null) {
      recommendations.add(
        AiCollectorRecommendation(
          title: 'Sell now',
          message:
              '${sellCandidate.title} has a rising market trend. Review comps before selling.',
          type: AiCollectorRecommendationType.sellNow,
        ),
      );
    }

    final holdCandidate = analytics.items
        .where((item) => _raritySignal(item) >= 0.78)
        .firstOrNull;
    if (holdCandidate != null) {
      recommendations.add(
        AiCollectorRecommendation(
          title: 'Hold',
          message: '${holdCandidate.title} has rare-collector signals.',
          type: AiCollectorRecommendationType.hold,
        ),
      );
    }

    if (analytics.collectionHealth.stalePricingCount > 0) {
      recommendations.add(
        AiCollectorRecommendation(
          title: 'Watch price',
          message:
              '${analytics.collectionHealth.stalePricingCount} items have stale or missing pricing.',
          type: AiCollectorRecommendationType.watchPrice,
        ),
      );
    }

    if (_pokemonCardCount(analytics.items) < 100) {
      recommendations.add(
        const AiCollectorRecommendation(
          title: 'Add missing cards',
          message:
              'Track missing cards to work toward a 100-card Pokémon goal.',
          type: AiCollectorRecommendationType.addMissingCards,
        ),
      );
    }

    return recommendations.take(6).toList(growable: false);
  }

  Map<WishlistStatus, int> _wishlistStatusCounts(
    CollectorDashboardAnalytics analytics,
  ) {
    return {
      WishlistStatus.owned: analytics.itemCount,
      WishlistStatus.wanted: _wantedFoundationCount(analytics),
      WishlistStatus.missing: _missingFoundationCount(analytics),
    };
  }

  int _wantedFoundationCount(CollectorDashboardAnalytics analytics) {
    if (analytics.itemCount == 0) {
      return 1;
    }
    return analytics.lowConfidenceItems.isNotEmpty ? 2 : 1;
  }

  int _missingFoundationCount(CollectorDashboardAnalytics analytics) {
    final pokemonCount = _pokemonCardCount(analytics.items);
    if (pokemonCount == 0) {
      return 1;
    }
    return (100 - pokemonCount).clamp(0, 100);
  }

  List<CollectionGoal> _goals(CollectorDashboardAnalytics analytics) {
    final baseSetCount = analytics.items.where(_isBaseSetItem).length;
    final pokemonCount = _pokemonCardCount(analytics.items);
    final gradedCount = analytics.items.where(_isGradedItem).length;

    return [
      CollectionGoal(
        title: 'Complete Base Set',
        description: 'Track progress toward a complete 102-card Base Set.',
        type: CollectionGoalType.completeBaseSet,
        current: baseSetCount,
        target: 102,
      ),
      CollectionGoal(
        title: 'Collect 100 Pokemon',
        description: 'Build a deep Pokémon collection profile.',
        type: CollectionGoalType.collectPokemon,
        current: pokemonCount,
        target: 100,
      ),
      CollectionGoal(
        title: 'Own 50 graded cards',
        description: 'Grow a verified graded-card collection.',
        type: CollectionGoalType.ownGradedCards,
        current: gradedCount,
        target: 50,
      ),
    ];
  }

  List<CollectorAchievement> _achievements(
    CollectorDashboardAnalytics analytics,
  ) {
    final rareCount = analytics.items
        .where((item) => _raritySignal(item) >= 0.78)
        .length;
    final coinCount =
        analytics.categoryDistribution[CollectorCategory.coins] ?? 0;
    final goals = _goals(analytics);
    final completionistProgress = goals.isEmpty
        ? 0.0
        : goals
              .map((goal) => goal.progress)
              .reduce((best, progress) => progress > best ? progress : best);

    return [
      CollectorAchievement(
        title: 'First Scan',
        description: 'Save your first collectible.',
        type: AchievementType.firstScan,
        isUnlocked: analytics.itemCount >= 1,
        progress: (analytics.itemCount / 1).clamp(0, 1),
      ),
      CollectorAchievement(
        title: '100 Scans',
        description: 'Save 100 collectibles.',
        type: AchievementType.hundredScans,
        isUnlocked: analytics.itemCount >= 100,
        progress: (analytics.itemCount / 100).clamp(0, 1),
      ),
      CollectorAchievement(
        title: 'Rare Collector',
        description: 'Own a collectible with rare signals.',
        type: AchievementType.rareCollector,
        isUnlocked: rareCount >= 1,
        progress: (rareCount / 1).clamp(0, 1),
      ),
      CollectorAchievement(
        title: 'Coin Expert',
        description: 'Save 10 coins.',
        type: AchievementType.coinExpert,
        isUnlocked: coinCount >= 10,
        progress: (coinCount / 10).clamp(0, 1),
      ),
      CollectorAchievement(
        title: 'Completionist',
        description: 'Complete one collection goal.',
        type: AchievementType.completionist,
        isUnlocked: completionistProgress >= 1,
        progress: completionistProgress,
      ),
    ];
  }

  Map<String, int> _duplicateGroups(List<CollectibleItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      final key = '${item.title}|${item.category}'.toLowerCase();
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final duplicates = <String, int>{};
    for (final entry in counts.entries) {
      if (entry.value > 1) {
        final title = items
            .firstWhere(
              (item) =>
                  '${item.title}|${item.category}'.toLowerCase() == entry.key,
            )
            .title;
        duplicates[title] = entry.value - 1;
      }
    }
    return duplicates;
  }

  CollectorCategory? _highestValueCategory(
    CollectorDashboardAnalytics analytics,
  ) {
    if (analytics.isEmpty) {
      return null;
    }

    final values = {
      for (final category in CollectorCategory.values) category: 0.0,
    };
    for (final item in analytics.items) {
      final category =
          CollectorDashboardAnalyticsService.categoryForCollectible(
            item.category,
          );
      values[category] = (values[category] ?? 0) + item.estimatedValue;
    }

    CollectorCategory? best;
    var bestValue = 0.0;
    for (final entry in values.entries) {
      if (entry.value > bestValue) {
        best = entry.key;
        bestValue = entry.value;
      }
    }
    return best;
  }

  CollectorCategory? _smallestActiveCategory(
    CollectorDashboardAnalytics analytics,
  ) {
    CollectorCategory? smallest;
    var smallestCount = analytics.itemCount + 1;
    for (final entry in analytics.categoryDistribution.entries) {
      if (entry.value > 0 && entry.value < smallestCount) {
        smallest = entry.key;
        smallestCount = entry.value;
      }
    }
    return smallest;
  }

  bool _comicMayAppreciate(CollectibleItem item) {
    final category = item.category.toLowerCase();
    if (!category.contains('comic')) {
      return false;
    }
    final trend = _trendFor(item);
    return trend.contains('rising') ||
        trend.contains('up') ||
        trend.contains('appreciat');
  }

  String _trendFor(CollectibleItem item) {
    return (item.marketSummary?.trendLabel ?? '').toLowerCase();
  }

  bool _isBaseSetItem(CollectibleItem item) {
    final text = [
      item.setName,
      item.series,
      item.title,
    ].whereType<String>().join(' ').toLowerCase();
    return text.contains('base set');
  }

  int _pokemonCardCount(List<CollectibleItem> items) {
    return items.where((item) {
      final text = [
        item.title,
        item.category,
        item.brand,
        item.setName,
        item.series,
      ].whereType<String>().join(' ').toLowerCase();
      return text.contains('pokemon') || text.contains('pokémon');
    }).length;
  }

  bool _isGradedItem(CollectibleItem item) {
    final text = [
      item.estimatedGrade,
      item.condition,
      item.notes,
    ].whereType<String>().join(' ').toLowerCase();
    return text.contains('psa') ||
        text.contains('bgs') ||
        text.contains('cgc') ||
        text.contains('graded');
  }
}
