import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

enum CollectionScoreFactor {
  rarity(label: 'Rarity'),
  completeness(label: 'Completeness'),
  confidence(label: 'Confidence'),
  portfolioValue(label: 'Portfolio Value'),
  diversity(label: 'Diversity'),
  duplicates(label: 'Duplicates'),
  imageQuality(label: 'Image Quality'),
  pricingFreshness(label: 'Pricing Freshness');

  const CollectionScoreFactor({required this.label});

  final String label;
}

enum SmartCollectorInsightType { opportunity, warning, highlight, trend }

enum AiCollectorRecommendationType {
  scanBetterPhotos,
  upgradeGrading,
  sellNow,
  hold,
  watchPrice,
  addMissingCards,
}

enum WishlistStatus { wanted, owned, missing }

enum CollectionGoalType { completeBaseSet, collectPokemon, ownGradedCards }

enum AchievementType {
  firstScan,
  hundredScans,
  rareCollector,
  coinExpert,
  completionist,
}

class SmartCollectorIntelligence {
  const SmartCollectorIntelligence({
    required this.collectionScore,
    required this.insights,
    required this.recommendations,
    required this.wishlistStatusCounts,
    required this.goals,
    required this.achievements,
  });

  final CollectionScore collectionScore;
  final List<SmartCollectorInsight> insights;
  final List<AiCollectorRecommendation> recommendations;
  final Map<WishlistStatus, int> wishlistStatusCounts;
  final List<CollectionGoal> goals;
  final List<CollectorAchievement> achievements;

  List<CollectorAchievement> get unlockedAchievements {
    return achievements
        .where((achievement) => achievement.isUnlocked)
        .toList(growable: false);
  }
}

class CollectionScore {
  const CollectionScore({required this.score, required this.factorScores});

  final int score;
  final Map<CollectionScoreFactor, int> factorScores;

  String get label {
    if (score >= 850) {
      return 'Elite';
    }
    if (score >= 700) {
      return 'Strong';
    }
    if (score >= 500) {
      return 'Growing';
    }
    return 'Starting out';
  }
}

class SmartCollectorInsight {
  const SmartCollectorInsight({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String message;
  final SmartCollectorInsightType type;
}

class AiCollectorRecommendation {
  const AiCollectorRecommendation({
    required this.title,
    required this.message,
    required this.type,
  });

  final String title;
  final String message;
  final AiCollectorRecommendationType type;
}

class WishlistEntry {
  const WishlistEntry({
    required this.title,
    required this.category,
    required this.status,
    this.linkedItem,
  });

  final String title;
  final String category;
  final WishlistStatus status;
  final CollectibleItem? linkedItem;
}

class CollectionGoal {
  const CollectionGoal({
    required this.title,
    required this.description,
    required this.type,
    required this.current,
    required this.target,
  });

  final String title;
  final String description;
  final CollectionGoalType type;
  final int current;
  final int target;

  double get progress {
    if (target <= 0) {
      return 0;
    }
    return (current / target).clamp(0, 1);
  }

  String get progressLabel => '$current / $target';
}

class CollectorAchievement {
  const CollectorAchievement({
    required this.title,
    required this.description,
    required this.type,
    required this.isUnlocked,
    required this.progress,
  });

  final String title;
  final String description;
  final AchievementType type;
  final bool isUnlocked;
  final double progress;
}
