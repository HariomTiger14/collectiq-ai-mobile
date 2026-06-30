import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';

/// Current local entitlement snapshot.
class UserEntitlements {
  /// Creates immutable entitlements.
  const UserEntitlements({required this.plan, required this.usageLimit});

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
  bool get paymentsConfigured => false;
}
