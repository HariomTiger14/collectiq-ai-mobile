import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';

/// Persists the locally known entitlement snapshot.
abstract interface class EntitlementRepository {
  /// Loads the currently granted plan.
  Future<SubscriptionPlan> loadPlan();

  /// Saves the currently granted plan.
  Future<void> savePlan(SubscriptionPlan plan);
}
