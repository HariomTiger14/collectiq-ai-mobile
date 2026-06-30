import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/purchase_result.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/billing_repository.dart';

/// Safe billing fallback used when Google Play Billing is not configured.
class UnavailableBillingRepository implements BillingRepository {
  /// Creates an unavailable billing repository.
  const UnavailableBillingRepository();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<List<BillingProduct>> loadProducts() async => const [];

  @override
  Future<PurchaseResult> purchase(SubscriptionPlan plan) async {
    return const PurchaseResult(
      status: PurchaseResultStatus.failed,
      message: 'Payments are not configured for this build.',
    );
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    return const PurchaseResult(
      status: PurchaseResultStatus.failed,
      message: 'Payments are not configured for this build.',
    );
  }
}
