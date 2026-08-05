import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/plan_limits.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Portfolio plan limits', () {
    test('blocks adding a new item when portfolio cap is reached', () async {
      final repository = _MemoryPortfolioRepository([
        _item(id: 'existing-item'),
      ]);
      final container = ProviderContainer(
        overrides: [
          portfolioRepositoryProvider.overrideWithValue(repository),
          activePlanLimitsProvider.overrideWithValue(
            PlanLimits(
              plan: SubscriptionPlan.free,
              scanLimit: const UsageLimit(monthlyFreeScanLimit: 10),
              maxPortfolioItems: 1,
              maxPhotosPerItem: 2,
              maxActivePriceAlerts: 3,
              monthlyPriceRefreshes: 10,
              canUseFullValueHistory: false,
              canExportPortfolio: false,
              canUseAdvancedFilters: false,
              canBulkRefreshValues: false,
              canUsePortfolioIntelligence: false,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);
      await container
          .read(portfolioControllerProvider.notifier)
          .saveItem(_item(id: 'new-item'));

      final state = container.read(portfolioControllerProvider);
      expect(repository.items, hasLength(1));
      expect(repository.items.single.id, 'existing-item');
      expect(state.errorMessage, contains('supports 1 item'));
    });

    test(
      'allows updating an existing item when portfolio cap is reached',
      () async {
        final repository = _MemoryPortfolioRepository([
          _item(id: 'existing-item', title: 'Before'),
        ]);
        final container = ProviderContainer(
          overrides: [
            portfolioRepositoryProvider.overrideWithValue(repository),
            activePlanLimitsProvider.overrideWithValue(
              PlanLimits(
                plan: SubscriptionPlan.free,
                scanLimit: const UsageLimit(monthlyFreeScanLimit: 10),
                maxPortfolioItems: 1,
                maxPhotosPerItem: 2,
                maxActivePriceAlerts: 3,
                monthlyPriceRefreshes: 10,
                canUseFullValueHistory: false,
                canExportPortfolio: false,
                canUseAdvancedFilters: false,
                canBulkRefreshValues: false,
                canUsePortfolioIntelligence: false,
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await Future<void>.delayed(Duration.zero);
        await container
            .read(portfolioControllerProvider.notifier)
            .saveItem(_item(id: 'existing-item', title: 'After'));

        expect(repository.items, hasLength(1));
        expect(repository.items.single.title, 'After');
        expect(
          container.read(portfolioControllerProvider).errorMessage,
          isNull,
        );
      },
    );
  });
}

class _MemoryPortfolioRepository implements PortfolioRepository {
  _MemoryPortfolioRepository(List<CollectibleItem> initialItems)
    : items = [...initialItems];

  final List<CollectibleItem> items;

  @override
  Future<CollectibleItem> addItem(CollectibleItem item) async {
    items
      ..removeWhere((existingItem) => existingItem.id == item.id)
      ..insert(0, item);
    return item;
  }

  @override
  Future<void> clearPortfolio() async {
    items.clear();
  }

  @override
  Future<List<CollectibleItem>> getItems() async {
    return [...items];
  }

  @override
  Future<void> removeItem(String id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> updateItem(CollectibleItem item) async {
    await addItem(item);
  }

  @override
  Future<void> updateItemImageSync({
    required String itemId,
    required String imageStoragePath,
    required String cloudImageUrl,
  }) async {}

  @override
  Future<void> upsertSyncedItem(CollectibleItem item) async {
    await addItem(item);
  }
}

CollectibleItem _item({required String id, String title = 'Collectible'}) {
  return CollectibleItem(
    id: id,
    title: title,
    category: 'Card',
    estimatedValue: 10,
    confidence: 0.8,
    condition: 'Good',
    recommendation: 'Hold',
    imagePath: 'sample://card',
    createdAt: DateTime.parse('2026-07-27T00:00:00.000'),
  );
}
