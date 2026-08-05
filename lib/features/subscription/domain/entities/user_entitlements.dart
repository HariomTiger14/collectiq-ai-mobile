import 'package:collectiq_ai/features/subscription/domain/entities/plan_limits.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';

/// Current local entitlement snapshot.
class UserEntitlements {
  /// Creates immutable entitlements.
  const UserEntitlements({
    required this.plan,
    required this.usageLimit,
    required this.planLimits,
    this.paymentsConfigured = false,
  });

  /// Default local-first development entitlements. Caps mirror the real Free
  /// tier so the paywall/limits can be exercised in dev/SIT; scans stay
  /// unlimited locally so scanner testing isn't blocked by the monthly ceiling.
  static const developmentFree = UserEntitlements(
    plan: SubscriptionPlan.free,
    usageLimit: UsageLimit.unlimited,
    planLimits: PlanLimits(
      plan: SubscriptionPlan.free,
      scanLimit: UsageLimit.unlimited,
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
  );

  /// Current plan.
  final SubscriptionPlan plan;

  /// Usage limits for the current plan.
  final UsageLimit usageLimit;

  /// Feature limits and paid access for the current plan.
  final PlanLimits planLimits;

  /// Whether payments are configured in this build.
  final bool paymentsConfigured;

  /// Whether payments are configured in this build.
  bool get isPaid => plan != SubscriptionPlan.free;

  /// Creates entitlements for a plan.
  factory UserEntitlements.forPlan({
    required SubscriptionPlan plan,
    required UsageLimit freeLimit,
    bool paymentsConfigured = false,
  }) {
    final planLimits = PlanLimits.forPlan(plan: plan, freeScanLimit: freeLimit);

    return UserEntitlements(
      plan: plan,
      usageLimit: planLimits.scanLimit,
      planLimits: planLimits,
      paymentsConfigured: paymentsConfigured,
    );
  }
}
