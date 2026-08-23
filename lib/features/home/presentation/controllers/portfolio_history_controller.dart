import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:collectiq_ai/core/currency/fx_rates_provider.dart';
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
      final displayCurrency = ref.watch(displayCurrencyProvider);
      FxRateSnapshot rates;
      try {
        rates = await ref.watch(fxRatesProvider.future);
      } catch (_) {
        rates = FxRateSnapshot.empty;
      }
      final orderedItems = collectiblesNewestFirst(items);
      final currentSnapshots = service.createCurrentSnapshots(
        orderedItems,
        displayCurrency: displayCurrency,
        currentRates: rates.currentRates,
      );
      for (final snapshot in currentSnapshots) {
        await repository.upsertSnapshot(snapshot);
      }

      // Real, backend-tracked daily history (written by the scheduled
      // repricing job) is the source of truth when available. It only
      // falls back to the device-local mechanism for brand-new accounts,
      // offline sessions, or before any cloud snapshot exists yet — so the
      // chart still shows something rather than going blank.
      var history = const <PortfolioSnapshot>[];
      // Also feeds the MAX badge's baseline (see _trueOverallChange) so it
      // can prefer real market-tracked price history over a stale/
      // provisional valueAtScan.
      var cloudSnapshots = const <PortfolioValuationSnapshot>[];
      try {
        cloudSnapshots = await ref
            .watch(cloudServiceRegistryProvider)
            .cloudPortfolioSyncService
            .fetchAllValuationSnapshots();
        history = service.historyFromCloudSnapshots(
          cloudSnapshots,
          orderedItems,
          displayCurrency: displayCurrency,
          rates: rates,
        );
      } catch (_) {
        // Cloud unavailable (offline, signed out, etc.) — fall through to
        // the local fallback below.
      }
      if (history.isEmpty) {
        history = await repository.getAllSnapshots();
      }

      return service.buildPerformance(
        currentItems: orderedItems,
        history: history,
        cloudSnapshots: cloudSnapshots,
        displayCurrency: displayCurrency,
        currentRates: rates.currentRates,
      );
    });
