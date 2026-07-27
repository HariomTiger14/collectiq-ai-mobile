import 'package:collectiq_ai/features/subscription/domain/entities/plan_limits.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanLimits', () {
    test('free plan keeps core collecting useful but bounded', () {
      final limits = PlanLimits.forPlan(
        plan: SubscriptionPlan.free,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 10),
      );

      expect(limits.scanLimit.dailyFreeScanLimit, 10);
      expect(limits.maxPortfolioItems, 250);
      expect(limits.maxPhotosPerItem, 2);
      expect(limits.maxActivePriceAlerts, 3);
      expect(limits.canUseFullValueHistory, isFalse);
      expect(limits.canExportPortfolio, isFalse);
      expect(limits.canUseAdvancedFilters, isFalse);
    });

    test('pro unlocks collector tools without bulk refresh', () {
      final limits = PlanLimits.forPlan(
        plan: SubscriptionPlan.pro,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 10),
      );

      expect(limits.maxPortfolioItems, 1000);
      expect(limits.maxPhotosPerItem, 6);
      expect(limits.maxActivePriceAlerts, 25);
      expect(limits.canUseFullValueHistory, isTrue);
      expect(limits.canExportPortfolio, isTrue);
      expect(limits.canUseAdvancedFilters, isTrue);
      expect(limits.canBulkRefreshValues, isFalse);
    });

    test('premium unlocks heavy collector tools', () {
      final limits = PlanLimits.forPlan(
        plan: SubscriptionPlan.premium,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 10),
      );

      expect(limits.scanLimit.isUnlimited, isTrue);
      expect(limits.maxPortfolioItems, 10000);
      expect(limits.maxPhotosPerItem, 12);
      expect(limits.maxActivePriceAlerts, 100);
      expect(limits.canBulkRefreshValues, isTrue);
      expect(limits.canUsePortfolioIntelligence, isTrue);
    });

    test('portfolio and alert helper checks enforce caps', () {
      final limits = PlanLimits.forPlan(
        plan: SubscriptionPlan.free,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 10),
      );

      expect(limits.canAddPortfolioItem(249), isTrue);
      expect(limits.canAddPortfolioItem(250), isFalse);
      expect(limits.canAddPortfolioItem(250, replacingExisting: true), isTrue);
      expect(limits.canCreatePriceAlert(2), isTrue);
      expect(limits.canCreatePriceAlert(3), isFalse);
    });
  });
}
