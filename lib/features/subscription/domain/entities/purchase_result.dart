import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';

/// Purchase lifecycle states normalized from Google Play Billing.
enum PurchaseResultStatus {
  /// Purchase completed and the entitlement can be granted.
  success,

  /// Existing purchase was restored.
  restored,

  /// Purchase is pending in Google Play.
  pending,

  /// User cancelled the purchase flow.
  cancelled,

  /// Purchase failed.
  failed,
}

/// Result returned by billing repositories.
class PurchaseResult {
  /// Creates a purchase result.
  const PurchaseResult({
    required this.status,
    required this.message,
    this.plan,
    this.source,
    this.purchaseToken,
  });

  /// Purchase status.
  final PurchaseResultStatus status;

  /// Plan affected by this purchase.
  final SubscriptionPlan? plan;

  /// User-safe message.
  final String message;

  /// Store this purchase came from (e.g. 'google_play', 'app_store') --
  /// null for a synthetic/free result that isn't a real store purchase.
  final String? source;

  /// The store's own verification token for this purchase -- Google
  /// Play's opaque purchase token, or Apple's signed transaction JWS.
  /// Sent to the backend so it can verify the purchase actually happened
  /// rather than trusting the plan name alone.
  final String? purchaseToken;

  /// Whether the result should unlock a plan.
  bool get grantsEntitlement {
    return plan != null &&
        (status == PurchaseResultStatus.success ||
            status == PurchaseResultStatus.restored);
  }
}
