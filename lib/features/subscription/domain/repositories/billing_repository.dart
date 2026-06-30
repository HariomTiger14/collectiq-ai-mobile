import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/purchase_result.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';

/// Billing abstraction used by subscription controllers.
abstract interface class BillingRepository {
  /// Whether the billing provider is available and configured.
  Future<bool> isAvailable();

  /// Loads available subscription products.
  Future<List<BillingProduct>> loadProducts();

  /// Starts a purchase flow for [plan].
  Future<PurchaseResult> purchase(SubscriptionPlan plan);

  /// Restores previous purchases.
  Future<PurchaseResult> restorePurchases();
}
