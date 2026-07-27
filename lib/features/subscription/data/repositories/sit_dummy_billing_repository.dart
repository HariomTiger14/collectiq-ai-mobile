import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/purchase_result.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/billing_repository.dart';

/// SIT-only billing configuration.
class SitDummyBillingConfig {
  /// Creates SIT dummy billing config.
  const SitDummyBillingConfig({
    required this.enabled,
    this.restorePlan = SubscriptionPlan.premium,
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
      defaultValue: 'premium',
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
      description: 'Higher scan limits, cloud portfolio tools, and alerts.',
      price: 'AUD 9.99 / month',
      currencyCode: 'AUD',
    ),
    BillingProduct(
      id: 'sit_premium_monthly',
      plan: SubscriptionPlan.premium,
      title: 'PackLox Premium',
      description: 'Unlimited scans and advanced collector testing access.',
      price: 'AUD 19.99 / month',
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
