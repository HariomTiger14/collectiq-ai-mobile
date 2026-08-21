import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/currency/currency_conversion.dart';
import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:collectiq_ai/core/ui/currency_format.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/home/domain/services/smart_collector_insights_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

class PortfolioHistoryService {
  const PortfolioHistoryService({
    this.analyticsService = const CollectorDashboardAnalyticsService(),
    this.smartInsightsService = const SmartCollectorInsightsService(),
  });

  final CollectorDashboardAnalyticsService analyticsService;
  final SmartCollectorInsightsService smartInsightsService;

  List<PortfolioSnapshot> createCurrentSnapshots(
    List<CollectibleItem> items, {
    DateTime? capturedAt,
    String displayCurrency = 'AUD',
    Map<String, double> currentRates = const {'USD': 1.0},
  }) {
    if (items.isEmpty) {
      return const [];
    }

    final now = capturedAt ?? DateTime.now();
    return [
      for (final period in TrendSnapshotPeriod.values)
        createSnapshot(
          items,
          period: period,
          capturedAt: now,
          displayCurrency: displayCurrency,
          currentRates: currentRates,
        ),
    ];
  }

  PortfolioSnapshot createSnapshot(
    List<CollectibleItem> items, {
    required TrendSnapshotPeriod period,
    DateTime? capturedAt,
    String displayCurrency = 'AUD',
    Map<String, double> currentRates = const {'USD': 1.0},
  }) {
    final now = capturedAt ?? DateTime.now();
    final periodStart = bucketDate(now, period);
    // Every downstream total here must be in one common currency before
    // summing -- a mixed-currency portfolio summed as raw numbers produces
    // a meaningless total. Converts each item from its own currency
    // (currencyForItem) to displayCurrency using today's live rate; a
    // same-currency item is a currency==currency no-op (convertCurrent
    // returns the value unchanged).
    double convertedValue(CollectibleItem item) => convertCurrent(
      item.estimatedValue,
      from: currencyForItem(item),
      to: displayCurrency,
      currentRates: currentRates,
    );
    final convertedItems = {
      for (final item in items) item.id: convertedValue(item),
    };
    final totalValue = convertedItems.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final analytics = analyticsService.build(items);
    final intelligence = smartInsightsService.build(analytics);
    final categoryTotals = {
      for (final category in CollectorCategory.values) category: 0.0,
    };
    for (final item in items) {
      final category =
          CollectorDashboardAnalyticsService.categoryForCollectible(
            item.category,
          );
      categoryTotals[category] =
          (categoryTotals[category] ?? 0) + convertedValue(item);
    }

    return PortfolioSnapshot(
      id: PortfolioSnapshot.idFor(period, periodStart),
      period: period,
      periodStart: periodStart,
      capturedAt: now,
      totalPortfolioValue: totalValue,
      totalItems: analytics.itemCount,
      averageValue: analytics.itemCount == 0
          ? 0
          : totalValue / analytics.itemCount,
      categoryTotals: categoryTotals,
      collectionScore: intelligence.collectionScore.score,
      itemValues: convertedItems,
      itemTitles: {for (final item in items) item.id: item.title},
      itemCategories: {for (final item in items) item.id: item.category},
    );
  }

  /// Builds real day-by-day (plus derived weekly/monthly) history from the
  /// backend-tracked value snapshots, instead of the device-local-only
  /// mechanism this used to rely on. For each calendar day from the earliest
  /// snapshot through today, every item's most-recently-known value *as of*
  /// that day is carried forward and summed — so a day with no repricing
  /// activity correctly repeats the prior day's total (a real flat line)
  /// rather than being skipped or estimated.
  List<PortfolioSnapshot> historyFromCloudSnapshots(
    List<PortfolioValuationSnapshot> cloudSnapshots,
    List<CollectibleItem> currentItems, {
    DateTime? now,
    String displayCurrency = 'AUD',
    FxRateSnapshot rates = FxRateSnapshot.empty,
  }) {
    if (cloudSnapshots.isEmpty || currentItems.isEmpty) {
      return const [];
    }

    final today = bucketDate(now ?? DateTime.now(), TrendSnapshotPeriod.daily);
    final byItem = <String, List<PortfolioValuationSnapshot>>{};
    for (final snapshot in cloudSnapshots) {
      if (snapshot.valueAud == null) {
        continue;
      }
      (byItem[snapshot.portfolioItemId] ??= []).add(snapshot);
    }
    if (byItem.isEmpty) {
      return const [];
    }
    for (final history in byItem.values) {
      history.sort((a, b) => a.pricedAt.compareTo(b.pricedAt));
    }

    final earliest = byItem.values
        .map((history) => bucketDate(history.first.pricedAt, TrendSnapshotPeriod.daily))
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final dayCount = today.difference(earliest).inDays;
    if (dayCount < 0) {
      return const [];
    }
    final itemById = {for (final item in currentItems) item.id: item};

    final dailySnapshots = <PortfolioSnapshot>[];
    for (var offset = 0; offset <= dayCount; offset++) {
      final day = earliest.add(Duration(days: offset));
      final snapshot = _snapshotAsOf(
        day,
        byItem,
        itemById,
        displayCurrency: displayCurrency,
        rates: rates,
      );
      if (snapshot != null) {
        dailySnapshots.add(snapshot);
      }
    }
    if (dailySnapshots.isEmpty) {
      return const [];
    }

    final weeklyByBucket = <String, PortfolioSnapshot>{};
    final monthlyByBucket = <String, PortfolioSnapshot>{};
    for (final daily in dailySnapshots) {
      final weekStart = bucketDate(daily.periodStart, TrendSnapshotPeriod.weekly);
      weeklyByBucket[PortfolioSnapshot.idFor(TrendSnapshotPeriod.weekly, weekStart)] =
          _asPeriod(daily, TrendSnapshotPeriod.weekly, weekStart);

      final monthStart = bucketDate(
        daily.periodStart,
        TrendSnapshotPeriod.monthly,
      );
      monthlyByBucket[PortfolioSnapshot.idFor(
            TrendSnapshotPeriod.monthly,
            monthStart,
          )] =
          _asPeriod(daily, TrendSnapshotPeriod.monthly, monthStart);
    }

    return [
      ...dailySnapshots,
      ...weeklyByBucket.values,
      ...monthlyByBucket.values,
    ];
  }

  PortfolioSnapshot? _snapshotAsOf(
    DateTime day,
    Map<String, List<PortfolioValuationSnapshot>> byItem,
    Map<String, CollectibleItem> itemById, {
    required String displayCurrency,
    required FxRateSnapshot rates,
  }) {
    final itemValues = <String, double>{};
    final itemTitles = <String, String>{};
    final itemCategories = <String, String>{};
    final categoryTotals = {
      for (final category in CollectorCategory.values) category: 0.0,
    };
    var total = 0.0;

    for (final entry in byItem.entries) {
      final item = itemById[entry.key];
      // Anchor each item's contribution to when it actually entered the
      // portfolio, not to its earliest available valuation snapshot --
      // catalog-matched items can have snapshots backfilled from real
      // pre-ownership market history, which must never count toward "my
      // portfolio's" total/gain before I actually owned the item.
      if (item != null &&
          day.isBefore(bucketDate(item.createdAt, TrendSnapshotPeriod.daily))) {
        continue;
      }

      PortfolioValuationSnapshot? asOf;
      for (final candidate in entry.value) {
        if (!bucketDate(
          candidate.pricedAt,
          TrendSnapshotPeriod.daily,
        ).isAfter(day)) {
          asOf = candidate;
        } else {
          break;
        }
      }
      final rawValue = asOf?.valueAud;
      if (asOf == null || rawValue == null) {
        continue;
      }
      // Converted using the rate that was actually in effect ON `day`, not
      // today's rate applied backward -- see currency_conversion.dart's
      // convertHistorical doc comment for why that distinction matters for
      // a chart's shape, not just its scale.
      final value = convertHistorical(
        rawValue,
        from: asOf.currency,
        to: displayCurrency,
        date: day,
        rates: rates,
      );
      final title = item?.title ?? entry.key;
      final category = item?.category ?? 'Collectible';
      itemValues[entry.key] = value;
      itemTitles[entry.key] = title;
      itemCategories[entry.key] = category;
      total += value;
      final bucket = CollectorDashboardAnalyticsService.categoryForCollectible(
        category,
      );
      categoryTotals[bucket] = (categoryTotals[bucket] ?? 0) + value;
    }

    if (itemValues.isEmpty) {
      return null;
    }
    return PortfolioSnapshot(
      id: PortfolioSnapshot.idFor(TrendSnapshotPeriod.daily, day),
      period: TrendSnapshotPeriod.daily,
      periodStart: day,
      capturedAt: day,
      totalPortfolioValue: total,
      totalItems: itemValues.length,
      averageValue: total / itemValues.length,
      categoryTotals: categoryTotals,
      collectionScore: 0,
      itemValues: itemValues,
      itemTitles: itemTitles,
      itemCategories: itemCategories,
    );
  }

  PortfolioSnapshot _asPeriod(
    PortfolioSnapshot source,
    TrendSnapshotPeriod period,
    DateTime periodStart,
  ) {
    return PortfolioSnapshot(
      id: PortfolioSnapshot.idFor(period, periodStart),
      period: period,
      periodStart: periodStart,
      capturedAt: source.capturedAt,
      totalPortfolioValue: source.totalPortfolioValue,
      totalItems: source.totalItems,
      averageValue: source.averageValue,
      categoryTotals: source.categoryTotals,
      collectionScore: source.collectionScore,
      itemValues: source.itemValues,
      itemTitles: source.itemTitles,
      itemCategories: source.itemCategories,
    );
  }

  PortfolioPerformance buildPerformance({
    required List<CollectibleItem> currentItems,
    required List<PortfolioSnapshot> history,
    DateTime? capturedAt,
  }) {
    final currentSnapshots = createCurrentSnapshots(
      currentItems,
      capturedAt: capturedAt,
    );
    final allSnapshots = _mergeCurrentSnapshots(history, currentSnapshots);
    final now = capturedAt ?? DateTime.now();
    final currentDaily = _currentSnapshot(
      allSnapshots,
      TrendSnapshotPeriod.daily,
      now,
    );
    final currentWeekly = _currentSnapshot(
      allSnapshots,
      TrendSnapshotPeriod.weekly,
      now,
    );
    final currentMonthly = _currentSnapshot(
      allSnapshots,
      TrendSnapshotPeriod.monthly,
      now,
    );

    final todayPrevious = _previousSnapshot(currentDaily, allSnapshots);
    final weekPrevious = _previousSnapshot(currentWeekly, allSnapshots);
    final monthPrevious = _previousSnapshot(currentMonthly, allSnapshots);
    final firstSnapshot = _firstSnapshot(
      allSnapshots,
      TrendSnapshotPeriod.daily,
    );
    final movers = _movers(currentDaily, todayPrevious);
    final topGainers =
        movers.where((mover) => mover.absoluteChange > 0).toList()
          ..sort((a, b) => b.absoluteChange.compareTo(a.absoluteChange));
    final topLosers = movers.where((mover) => mover.absoluteChange < 0).toList()
      ..sort((a, b) => a.absoluteChange.compareTo(b.absoluteChange));

    final dailySnapshots = _snapshotsFor(
      allSnapshots,
      TrendSnapshotPeriod.daily,
    );
    final weeklySnapshots = _snapshotsFor(
      allSnapshots,
      TrendSnapshotPeriod.weekly,
    );
    final monthlySnapshots = _snapshotsFor(
      allSnapshots,
      TrendSnapshotPeriod.monthly,
    );

    final performance = PortfolioPerformance(
      todayChange: _change('Today', currentDaily, todayPrevious),
      weeklyChange: _change('This Week', currentWeekly, weekPrevious),
      monthlyChange: _change('This Month', currentMonthly, monthPrevious),
      overallChange: _change('Overall', currentDaily, firstSnapshot),
      topGainers: topGainers.take(5).toList(growable: false),
      topLosers: topLosers.take(5).toList(growable: false),
      recentlyAppreciated: topGainers.take(3).toList(growable: false),
      recentlyDropped: topLosers.take(3).toList(growable: false),
      recommendations: const [],
      dailySnapshots: dailySnapshots,
      weeklySnapshots: weeklySnapshots,
      monthlySnapshots: monthlySnapshots,
    );

    return PortfolioPerformance(
      todayChange: performance.todayChange,
      weeklyChange: performance.weeklyChange,
      monthlyChange: performance.monthlyChange,
      overallChange: performance.overallChange,
      topGainers: performance.topGainers,
      topLosers: performance.topLosers,
      recentlyAppreciated: performance.recentlyAppreciated,
      recentlyDropped: performance.recentlyDropped,
      recommendations: _recommendations(performance, currentDaily),
      dailySnapshots: performance.dailySnapshots,
      weeklySnapshots: performance.weeklySnapshots,
      monthlySnapshots: performance.monthlySnapshots,
    );
  }

  DateTime bucketDate(DateTime date, TrendSnapshotPeriod period) {
    final normalized = DateTime(date.year, date.month, date.day);
    switch (period) {
      case TrendSnapshotPeriod.daily:
        return normalized;
      case TrendSnapshotPeriod.weekly:
        return normalized.subtract(Duration(days: normalized.weekday - 1));
      case TrendSnapshotPeriod.monthly:
        return DateTime(date.year, date.month);
    }
  }

  List<PortfolioSnapshot> _mergeCurrentSnapshots(
    List<PortfolioSnapshot> history,
    List<PortfolioSnapshot> currentSnapshots,
  ) {
    final byId = <String, PortfolioSnapshot>{
      for (final snapshot in history) snapshot.id: snapshot,
      for (final snapshot in currentSnapshots) snapshot.id: snapshot,
    };
    return byId.values.toList()..sort(_snapshotSort);
  }

  PortfolioSnapshot? _currentSnapshot(
    List<PortfolioSnapshot> snapshots,
    TrendSnapshotPeriod period,
    DateTime capturedAt,
  ) {
    final currentId = PortfolioSnapshot.idFor(
      period,
      bucketDate(capturedAt, period),
    );
    final exact = snapshots.where((snapshot) => snapshot.id == currentId);
    if (exact.isNotEmpty) {
      return exact.first;
    }
    return _lastSnapshot(snapshots, period);
  }

  PortfolioSnapshot? _previousSnapshot(
    PortfolioSnapshot? current,
    List<PortfolioSnapshot> snapshots,
  ) {
    if (current == null) {
      return null;
    }
    final previous =
        snapshots
            .where(
              (snapshot) =>
                  snapshot.period == current.period &&
                  snapshot.periodStart.isBefore(current.periodStart),
            )
            .toList()
          ..sort(_snapshotSort);
    return previous.isEmpty ? null : previous.last;
  }

  PortfolioSnapshot? _firstSnapshot(
    List<PortfolioSnapshot> snapshots,
    TrendSnapshotPeriod period,
  ) {
    final filtered = _snapshotsFor(snapshots, period);
    return filtered.isEmpty ? null : filtered.first;
  }

  PortfolioSnapshot? _lastSnapshot(
    List<PortfolioSnapshot> snapshots,
    TrendSnapshotPeriod period,
  ) {
    final filtered = _snapshotsFor(snapshots, period);
    return filtered.isEmpty ? null : filtered.last;
  }

  List<PortfolioSnapshot> _snapshotsFor(
    List<PortfolioSnapshot> snapshots,
    TrendSnapshotPeriod period,
  ) {
    return snapshots
        .where((snapshot) => snapshot.period == period)
        .toList(growable: false)
      ..sort(_snapshotSort);
  }

  PortfolioValueChange _change(
    String label,
    PortfolioSnapshot? current,
    PortfolioSnapshot? previous,
  ) {
    final currentValue = current?.totalPortfolioValue ?? 0;
    final previousValue = previous?.totalPortfolioValue ?? currentValue;
    return PortfolioValueChange(
      label: label,
      currentValue: currentValue,
      previousValue: previousValue,
    );
  }

  List<PortfolioValueMover> _movers(
    PortfolioSnapshot? current,
    PortfolioSnapshot? previous,
  ) {
    if (current == null || previous == null) {
      return const [];
    }

    final ids = {...current.itemValues.keys, ...previous.itemValues.keys};
    return [
      for (final id in ids)
        PortfolioValueMover(
          itemId: id,
          title: current.itemTitles[id] ?? previous.itemTitles[id] ?? id,
          category:
              current.itemCategories[id] ??
              previous.itemCategories[id] ??
              'Collectible',
          previousValue: previous.itemValues[id] ?? 0,
          currentValue: current.itemValues[id] ?? 0,
        ),
    ];
  }

  List<String> _recommendations(
    PortfolioPerformance performance,
    PortfolioSnapshot? current,
  ) {
    final recommendations = <String>[];
    if (performance.weeklyChange.absoluteChange > 0) {
      recommendations.add(
        'Collection gained ${_formatPercent(performance.weeklyChange.percentageChange)} this week.',
      );
    } else if (performance.weeklyChange.absoluteChange < 0) {
      recommendations.add(
        'Collection dipped ${_formatPercent(performance.weeklyChange.percentageChange.abs())} this week.',
      );
    }

    final strongestCategory = _strongestCategory(current);
    if (strongestCategory != null) {
      recommendations.add(
        '${strongestCategory.label} outperform the rest of your collection.',
      );
    }

    if (performance.topLosers.isNotEmpty) {
      recommendations.add('${performance.topLosers.length} items lost value.');
      recommendations.add('Watch ${performance.topLosers.first.title}.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Keep scanning to build a stronger value history.');
    }

    return recommendations.take(4).toList(growable: false);
  }

  CollectorCategory? _strongestCategory(PortfolioSnapshot? snapshot) {
    if (snapshot == null || snapshot.categoryTotals.isEmpty) {
      return null;
    }
    CollectorCategory? best;
    var bestValue = double.negativeInfinity;
    for (final entry in snapshot.categoryTotals.entries) {
      if (entry.value > bestValue && entry.value > 0) {
        best = entry.key;
        bestValue = entry.value;
      }
    }
    return best;
  }

  String _formatPercent(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }
}

int _snapshotSort(PortfolioSnapshot a, PortfolioSnapshot b) {
  final periodComparison = a.period.index.compareTo(b.period.index);
  if (periodComparison != 0) {
    return periodComparison;
  }
  return a.periodStart.compareTo(b.periodStart);
}
