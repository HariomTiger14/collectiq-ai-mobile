import 'package:collectiq_ai/features/home/data/repositories/shared_preferences_portfolio_history_repository.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';
import 'package:collectiq_ai/features/home/domain/repositories/portfolio_history_repository.dart';
import 'package:collectiq_ai/features/home/domain/services/portfolio_history_service.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final portfolioHistoryRepositoryProvider = Provider<PortfolioHistoryRepository>(
  (ref) {
    return const SharedPreferencesPortfolioHistoryRepository();
  },
);

final portfolioHistoryServiceProvider = Provider<PortfolioHistoryService>((
  ref,
) {
  return const PortfolioHistoryService();
});

final portfolioPerformanceProvider =
    FutureProvider.family<PortfolioPerformance, List<CollectibleItem>>((
      ref,
      items,
    ) async {
      final repository = ref.watch(portfolioHistoryRepositoryProvider);
      final service = ref.watch(portfolioHistoryServiceProvider);
      final orderedItems = collectiblesNewestFirst(items);
      final currentSnapshots = service.createCurrentSnapshots(orderedItems);
      for (final snapshot in currentSnapshots) {
        await repository.upsertSnapshot(snapshot);
      }
      final history = await repository.getAllSnapshots();
      return service.buildPerformance(
        currentItems: orderedItems,
        history: history,
      );
    });
