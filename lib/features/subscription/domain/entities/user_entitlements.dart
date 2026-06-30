import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';

/// Current local entitlement snapshot.
class UserEntitlements {
  /// Creates immutable entitlements.
  const UserEntitlements({
    required this.plan,
    required this.usageLimit,
    this.paymentsConfigured = false,
  });

  /// Default local-first development entitlements.
  static const developmentFree = UserEntitlements(
    plan: SubscriptionPlan.free,
    usageLimit: UsageLimit.unlimited,
  );

  /// Current plan.
  final SubscriptionPlan plan;

  /// Usage limits for the current plan.
  final UsageLimit usageLimit;

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
    final usageLimit = switch (plan) {
      SubscriptionPlan.free => freeLimit,
      SubscriptionPlan.pro => const UsageLimit(
        dailyFreeScanLimit: 250,
        isUnlimited: false,
      ),
      SubscriptionPlan.premium => UsageLimit.unlimited,
    };

    return UserEntitlements(
      plan: plan,
      usageLimit: usageLimit,
      paymentsConfigured: paymentsConfigured,
    );
  }
}
