import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';

/// Persists the locally known entitlement snapshot.
abstract interface class EntitlementRepository {
  /// Loads the currently granted plan.
  Future<SubscriptionPlan> loadPlan();

  /// Saves the currently granted plan.
  ///
  /// [source] and [purchaseToken] carry a real store receipt through to the
  /// backend for verification (e.g. 'google_play' + the Play Billing
  /// purchase token) -- omitted for anything that isn't a real purchase
  /// (a downgrade to free, a dev-only toggle), in which case the backend
  /// treats it as an unverified 'mock' report, same as before this existed.
  Future<void> savePlan(
    SubscriptionPlan plan, {
    String? source,
    String? purchaseToken,
  });
}
