import 'package:collectiq_ai/features/subscription/data/repositories/sit_dummy_billing_repository.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/purchase_result.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SitDummyBillingRepository', () {
    test('returns the single Pro product when enabled', () async {
      const repository = SitDummyBillingRepository(
        config: SitDummyBillingConfig(enabled: true),
      );

      final products = await repository.loadProducts();

      expect(products.map((product) => product.plan), [SubscriptionPlan.pro]);
      expect(products.every((product) => product.currencyCode == 'AUD'), true);
    });

    test('grants entitlement for a paid SIT purchase', () async {
      const repository = SitDummyBillingRepository(
        config: SitDummyBillingConfig(enabled: true),
      );

      final result = await repository.purchase(SubscriptionPlan.pro);

      expect(result.status, PurchaseResultStatus.success);
      expect(result.plan, SubscriptionPlan.pro);
      expect(result.grantsEntitlement, true);
    });

    test('restores configured SIT plan', () async {
      const repository = SitDummyBillingRepository(
        config: SitDummyBillingConfig(
          enabled: true,
          restorePlan: SubscriptionPlan.premium,
        ),
      );

      final result = await repository.restorePurchases();

      expect(result.status, PurchaseResultStatus.restored);
      expect(result.plan, SubscriptionPlan.premium);
      expect(result.grantsEntitlement, true);
    });

    test('does not expose products when disabled', () async {
      const repository = SitDummyBillingRepository(
        config: SitDummyBillingConfig(enabled: false),
      );

      final products = await repository.loadProducts();
      final result = await repository.purchase(SubscriptionPlan.pro);

      expect(products, isEmpty);
      expect(result.status, PurchaseResultStatus.failed);
      expect(result.grantsEntitlement, false);
    });
  });
}
