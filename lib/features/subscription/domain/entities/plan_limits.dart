import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';

/// Free-tier caps. Dart-defines let us dial these without a code change while
/// we learn what actually converts. "10 collectibles" is the primary wall and
/// is enforced on every saved item (scan or catalog-add).
const kFreeMaxCollectibles = int.fromEnvironment(
  'PACKLOX_FREE_COLLECTIBLES',
  defaultValue: 10,
);
const kFreeMaxPhotosPerItem = int.fromEnvironment(
  'PACKLOX_FREE_PHOTOS_PER_ITEM',
  defaultValue: 2,
);
const kFreeMaxActiveAlerts = int.fromEnvironment(
  'PACKLOX_FREE_ACTIVE_ALERTS',
  defaultValue: 1,
);
const kFreeMonthlyRefreshes = int.fromEnvironment(
  'PACKLOX_FREE_MONTHLY_REFRESHES',
  defaultValue: 10,
);

/// Pro is "Unlimited" in the UI, implemented as a high safety cap so no code
/// path has to reason about true infinity. Photos stay a real, finite perk.
const kUnlimitedTierCap = 999999;
const kProMaxPhotosPerItem = 12;

/// Any cap at or above this reads as "Unlimited" in user-facing labels.
const kUnlimitedLabelThreshold = 100000;

/// Feature access and quota limits for a subscription plan.
class PlanLimits {
  /// Creates immutable plan limits.
  const PlanLimits({
    required this.plan,
    required this.scanLimit,
    required this.maxPortfolioItems,
    required this.maxPhotosPerItem,
    required this.maxActivePriceAlerts,
    required this.monthlyPriceRefreshes,
    required this.canUseFullValueHistory,
    required this.canExportPortfolio,
    required this.canUseAdvancedFilters,
    required this.canBulkRefreshValues,
    required this.canUsePortfolioIntelligence,
  });

  /// Plan these limits apply to.
  final SubscriptionPlan plan;

  /// Scan quota for this plan.
  final UsageLimit scanLimit;

  /// Maximum saved portfolio items.
  final int maxPortfolioItems;

  /// Maximum user-added photos per collectible.
  final int maxPhotosPerItem;

  /// Maximum active price alerts.
  final int maxActivePriceAlerts;

  /// Manual pricing refreshes available per month.
  final int monthlyPriceRefreshes;

  /// Whether full item and portfolio value history is unlocked.
  final bool canUseFullValueHistory;

  /// Whether CSV/PDF exports are unlocked.
  final bool canExportPortfolio;

  /// Whether advanced portfolio filters are unlocked.
  final bool canUseAdvancedFilters;

  /// Whether bulk value refresh is unlocked.
  final bool canBulkRefreshValues;

  /// Whether deeper portfolio intelligence is unlocked.
  final bool canUsePortfolioIntelligence;

  /// Limits for the active plan.
  factory PlanLimits.forPlan({
    required SubscriptionPlan plan,
    required UsageLimit freeScanLimit,
  }) {
    return switch (plan) {
      SubscriptionPlan.free => PlanLimits(
        plan: plan,
        // The daily scan limit is only a quiet anti-abuse ceiling; the real
        // free wall is the saved-collectibles cap below.
        scanLimit: freeScanLimit,
        maxPortfolioItems: kFreeMaxCollectibles,
        maxPhotosPerItem: kFreeMaxPhotosPerItem,
        maxActivePriceAlerts: kFreeMaxActiveAlerts,
        monthlyPriceRefreshes: kFreeMonthlyRefreshes,
        canUseFullValueHistory: false,
        canExportPortfolio: false,
        canUseAdvancedFilters: false,
        canBulkRefreshValues: false,
        canUsePortfolioIntelligence: false,
      ),
      // Pro is the single paid tier (old Pro + Premium merged): everything
      // unlimited. `premium` maps to the same limits for data safety in case
      // any account still carries that value.
      SubscriptionPlan.pro || SubscriptionPlan.premium => PlanLimits(
        plan: plan,
        scanLimit: UsageLimit.unlimited,
        maxPortfolioItems: kUnlimitedTierCap,
        maxPhotosPerItem: kProMaxPhotosPerItem,
        maxActivePriceAlerts: kUnlimitedTierCap,
        monthlyPriceRefreshes: kUnlimitedTierCap,
        canUseFullValueHistory: true,
        canExportPortfolio: true,
        canUseAdvancedFilters: true,
        canBulkRefreshValues: true,
        canUsePortfolioIntelligence: true,
      ),
    };
  }

  /// Whether a new portfolio item can be added.
  bool canAddPortfolioItem(
    int currentItemCount, {
    bool replacingExisting = false,
  }) {
    return replacingExisting || currentItemCount < maxPortfolioItems;
  }

  /// Whether another photo can be added to an item.
  bool canAddPhoto(int currentPhotoCount) {
    return currentPhotoCount < maxPhotosPerItem;
  }

  /// Whether another active price alert can be created.
  bool canCreatePriceAlert(int currentActiveAlertCount) {
    return currentActiveAlertCount < maxActivePriceAlerts;
  }

  /// Human-readable scan limit.
  String get scanLimitLabel {
    return scanLimit.isUnlimited
        ? 'Unlimited scans'
        : '${scanLimit.dailyFreeScanLimit} scans/day';
  }

  /// Human-readable portfolio item limit.
  String get portfolioItemsLabel {
    if (maxPortfolioItems >= kUnlimitedLabelThreshold) {
      return 'Unlimited';
    }
    return _limitLabel(maxPortfolioItems, singular: 'item', plural: 'items');
  }

  /// Human-readable photo limit.
  String get photosPerItemLabel {
    return '$maxPhotosPerItem photos/item';
  }

  /// Human-readable price alert limit.
  String get priceAlertsLabel {
    if (maxActivePriceAlerts >= kUnlimitedLabelThreshold) {
      return 'Unlimited';
    }
    return _limitLabel(
      maxActivePriceAlerts,
      singular: 'active alert',
      plural: 'active alerts',
    );
  }

  /// Message shown when the portfolio item cap is reached.
  String get portfolioLimitMessage {
    return 'Your ${plan.displayName} plan supports $portfolioItemsLabel. Upgrade to save more collectibles.';
  }

  static String _limitLabel(
    int count, {
    required String singular,
    required String plural,
  }) {
    return '$count ${count == 1 ? singular : plural}';
  }
}
