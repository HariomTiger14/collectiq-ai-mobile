import 'dart:math' as math;

import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';
import 'package:collectiq_ai/features/home/domain/repositories/portfolio_history_repository.dart';

/// Dev/QA helper that backfills daily portfolio-value snapshots so the Home
/// "Portfolio value" trend, gain/loss chart, and delta render immediately
/// instead of waiting for real day-over-day accrual.
///
/// Generates a realistic, non-monotonic curve (rises and dips) that lands
/// exactly on the current portfolio value, so the seeded history stays
/// consistent with the live "today" snapshot the app records from real items —
/// and so the gain/loss shading shows both green and red stretches.
class DemoValueHistorySeedService {
  const DemoValueHistorySeedService();

  Future<void> seed({
    required PortfolioHistoryRepository repository,
    required double currentTotalValue,
    required int itemCount,
    DateTime? now,
    int days = 32,
  }) async {
    if (currentTotalValue <= 0 || days < 2) {
      return;
    }
    final today = now ?? DateTime.now();
    final anchor = DateTime(today.year, today.month, today.day);

    // A gentle overall uptrend with layered oscillation so the line zig-zags
    // and dips below period baselines (showing red) instead of a straight ramp.
    final raw = <double>[
      for (var i = 0; i < days; i++)
        () {
          final t = i / (days - 1);
          final growth = 0.75 + 0.25 * t;
          final wave =
              0.07 * math.sin(i * 0.62) +
              0.035 * math.sin(i * 1.9 + 1.1) -
              0.02 * math.cos(i * 0.33);
          return math.max(0.05, growth + wave);
        }(),
    ];
    // Normalise so the final (today) point equals the current portfolio value.
    final lastRaw = raw.last;

    for (var i = 0; i < days; i++) {
      final date = anchor.subtract(Duration(days: days - 1 - i));
      final value = currentTotalValue * (raw[i] / lastRaw);
      await repository.upsertSnapshot(
        PortfolioSnapshot(
          id: PortfolioSnapshot.idFor(TrendSnapshotPeriod.daily, date),
          period: TrendSnapshotPeriod.daily,
          periodStart: date,
          capturedAt: date,
          totalPortfolioValue: value,
          totalItems: itemCount,
          averageValue: itemCount == 0 ? 0 : value / itemCount,
          categoryTotals: {
            for (final category in CollectorCategory.values) category: 0.0,
          },
          collectionScore: 0,
          itemValues: const {},
          itemTitles: const {},
          itemCategories: const {},
        ),
      );
    }
  }

  Future<void> clear(PortfolioHistoryRepository repository) {
    return repository.clearHistory();
  }
}
