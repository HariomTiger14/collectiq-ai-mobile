import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';

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
        scanLimit: freeScanLimit,
        maxPortfolioItems: 250,
        maxPhotosPerItem: 2,
        maxActivePriceAlerts: 3,
        monthlyPriceRefreshes: 10,
        canUseFullValueHistory: false,
        canExportPortfolio: false,
        canUseAdvancedFilters: false,
        canBulkRefreshValues: false,
        canUsePortfolioIntelligence: false,
      ),
      SubscriptionPlan.pro => const PlanLimits(
        plan: SubscriptionPlan.pro,
        scanLimit: UsageLimit(dailyFreeScanLimit: 250),
        maxPortfolioItems: 1000,
        maxPhotosPerItem: 6,
        maxActivePriceAlerts: 25,
        monthlyPriceRefreshes: 100,
        canUseFullValueHistory: true,
        canExportPortfolio: true,
        canUseAdvancedFilters: true,
        canBulkRefreshValues: false,
        canUsePortfolioIntelligence: true,
      ),
      SubscriptionPlan.premium => const PlanLimits(
        plan: SubscriptionPlan.premium,
        scanLimit: UsageLimit.unlimited,
        maxPortfolioItems: 10000,
        maxPhotosPerItem: 12,
        maxActivePriceAlerts: 100,
        monthlyPriceRefreshes: 1000,
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
    return _limitLabel(maxPortfolioItems, singular: 'item', plural: 'items');
  }

  /// Human-readable photo limit.
  String get photosPerItemLabel {
    return '$maxPhotosPerItem photos/item';
  }

  /// Human-readable price alert limit.
  String get priceAlertsLabel {
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
