import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/purchase_result.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/billing_repository.dart';

/// SIT-only billing configuration.
class SitDummyBillingConfig {
  /// Creates SIT dummy billing config.
  const SitDummyBillingConfig({
    required this.enabled,
    this.restorePlan = SubscriptionPlan.pro,
  });

  /// Whether dummy billing should be enabled for this build.
  final bool enabled;

  /// Plan granted by restore purchases in SIT.
  final SubscriptionPlan restorePlan;

  /// Reads config from build-time environment.
  factory SitDummyBillingConfig.fromEnvironment() {
    const appEnv = String.fromEnvironment('APP_ENV');
    const explicitlyEnabled = bool.fromEnvironment(
      'SIT_DUMMY_BILLING',
      defaultValue: false,
    );
    const restorePlanName = String.fromEnvironment(
      'SIT_DUMMY_BILLING_RESTORE_PLAN',
      defaultValue: 'pro',
    );

    return SitDummyBillingConfig(
      enabled: explicitlyEnabled || appEnv == 'sit',
      restorePlan: SubscriptionPlan.fromName(restorePlanName),
    );
  }
}

/// Fake billing provider used by SIT builds for end-to-end app testing.
class SitDummyBillingRepository implements BillingRepository {
  /// Creates SIT dummy billing repository.
  const SitDummyBillingRepository({required this.config});

  /// SIT dummy billing config.
  final SitDummyBillingConfig config;

  static const _products = [
    BillingProduct(
      id: 'sit_pro_monthly',
      plan: SubscriptionPlan.pro,
      title: 'PackLox Pro',
      // Kept short: the plan metrics above this card already break out what
      // Pro adds per-feature, so this only needs to be a one-line summary,
      // not a repeat of the same list (which was also getting cut off).
      description: 'Unlimited scans and collection, plus every advanced tool.',
      price: 'AUD 9.99 / month',
      currencyCode: 'AUD',
    ),
  ];

  @override
  Future<bool> isAvailable() async => config.enabled;

  @override
  Future<List<BillingProduct>> loadProducts() async {
    if (!config.enabled) {
      return const [];
    }
    return _products;
  }

  @override
  Future<PurchaseResult> purchase(SubscriptionPlan plan) async {
    if (!config.enabled) {
      return const PurchaseResult(
        status: PurchaseResultStatus.failed,
        message: 'SIT billing is not enabled for this build.',
      );
    }
    if (plan == SubscriptionPlan.free) {
      return const PurchaseResult(
        status: PurchaseResultStatus.success,
        plan: SubscriptionPlan.free,
        message: 'Free plan is active.',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    return PurchaseResult(
      status: PurchaseResultStatus.success,
      plan: plan,
      message: 'SIT purchase complete: ${plan.displayName} is active.',
    );
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    if (!config.enabled) {
      return const PurchaseResult(
        status: PurchaseResultStatus.failed,
        message: 'SIT billing is not enabled for this build.',
      );
    }

    await Future<void>.delayed(const Duration(milliseconds: 250));
    return PurchaseResult(
      status: PurchaseResultStatus.restored,
      plan: config.restorePlan,
      message:
          'SIT restore complete: ${config.restorePlan.displayName} is active.',
    );
  }
}
