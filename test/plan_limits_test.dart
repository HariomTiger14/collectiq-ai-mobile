import 'package:collectiq_ai/features/subscription/domain/entities/plan_limits.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlanLimits', () {
    test('free plan keeps core collecting useful but bounded', () {
      final limits = PlanLimits.forPlan(
        plan: SubscriptionPlan.free,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 20),
      );

      expect(limits.scanLimit.dailyFreeScanLimit, 20);
      expect(limits.maxPortfolioItems, kFreeMaxCollectibles);
      expect(limits.maxPhotosPerItem, kFreeMaxPhotosPerItem);
      expect(limits.maxActivePriceAlerts, kFreeMaxActiveAlerts);
      expect(limits.canUseFullValueHistory, isFalse);
      expect(limits.canExportPortfolio, isFalse);
      expect(limits.canUseAdvancedFilters, isFalse);
      expect(limits.canUsePortfolioIntelligence, isFalse);
    });

    test('pro is the single paid tier: everything unlocked', () {
      final limits = PlanLimits.forPlan(
        plan: SubscriptionPlan.pro,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 20),
      );

      expect(limits.scanLimit.isUnlimited, isTrue);
      expect(limits.maxPortfolioItems, kUnlimitedTierCap);
      expect(limits.maxPhotosPerItem, kProMaxPhotosPerItem);
      expect(limits.maxActivePriceAlerts, kUnlimitedTierCap);
      expect(limits.monthlyPriceRefreshes, kUnlimitedTierCap);
      expect(limits.canUseFullValueHistory, isTrue);
      expect(limits.canExportPortfolio, isTrue);
      expect(limits.canUseAdvancedFilters, isTrue);
      expect(limits.canUsePortfolioIntelligence, isTrue);
      expect(limits.canBulkRefreshValues, isTrue);
    });

    test('premium maps to the same limits as pro (data safety)', () {
      final premium = PlanLimits.forPlan(
        plan: SubscriptionPlan.premium,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 20),
      );
      final pro = PlanLimits.forPlan(
        plan: SubscriptionPlan.pro,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 20),
      );

      expect(premium.scanLimit.isUnlimited, isTrue);
      expect(premium.maxPortfolioItems, pro.maxPortfolioItems);
      expect(premium.maxPhotosPerItem, pro.maxPhotosPerItem);
      expect(premium.maxActivePriceAlerts, pro.maxActivePriceAlerts);
      expect(premium.canUsePortfolioIntelligence, isTrue);
    });

    test('high pro caps read as "Unlimited" in labels', () {
      final pro = PlanLimits.forPlan(
        plan: SubscriptionPlan.pro,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 20),
      );

      expect(pro.portfolioItemsLabel, 'Unlimited');
      expect(pro.priceAlertsLabel, 'Unlimited');
    });

    test('portfolio and alert helper checks enforce the free caps', () {
      final limits = PlanLimits.forPlan(
        plan: SubscriptionPlan.free,
        freeScanLimit: const UsageLimit(dailyFreeScanLimit: 20),
      );

      expect(limits.canAddPortfolioItem(kFreeMaxCollectibles - 1), isTrue);
      expect(limits.canAddPortfolioItem(kFreeMaxCollectibles), isFalse);
      expect(
        limits.canAddPortfolioItem(
          kFreeMaxCollectibles,
          replacingExisting: true,
        ),
        isTrue,
      );
      expect(limits.canCreatePriceAlert(kFreeMaxActiveAlerts - 1), isTrue);
      expect(limits.canCreatePriceAlert(kFreeMaxActiveAlerts), isFalse);
    });
  });
}
