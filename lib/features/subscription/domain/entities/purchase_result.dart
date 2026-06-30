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
  });

  /// Purchase status.
  final PurchaseResultStatus status;

  /// Plan affected by this purchase.
  final SubscriptionPlan? plan;

  /// User-safe message.
  final String message;

  /// Whether the result should unlock a plan.
  bool get grantsEntitlement {
    return plan != null &&
        (status == PurchaseResultStatus.success ||
            status == PurchaseResultStatus.restored);
  }
}
