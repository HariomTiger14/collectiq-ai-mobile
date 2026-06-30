import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';

class PortfolioSnapshot {
  const PortfolioSnapshot({
    required this.id,
    required this.period,
    required this.periodStart,
    required this.capturedAt,
    required this.totalPortfolioValue,
    required this.totalItems,
    required this.averageValue,
    required this.categoryTotals,
    required this.collectionScore,
    required this.itemValues,
    required this.itemTitles,
    required this.itemCategories,
  });

  final String id;
  final TrendSnapshotPeriod period;
  final DateTime periodStart;
  final DateTime capturedAt;
  final double totalPortfolioValue;
  final int totalItems;
  final double averageValue;
  final Map<CollectorCategory, double> categoryTotals;
  final int collectionScore;
  final Map<String, double> itemValues;
  final Map<String, String> itemTitles;
  final Map<String, String> itemCategories;

  factory PortfolioSnapshot.fromJson(Map<String, dynamic> json) {
    final period = _periodFromName(json['period'] as String?);
    final periodStart =
        DateTime.tryParse(json['periodStart'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return PortfolioSnapshot(
      id: json['id'] as String? ?? _snapshotId(period, periodStart),
      period: period,
      periodStart: periodStart,
      capturedAt:
          DateTime.tryParse(json['capturedAt'] as String? ?? '') ?? periodStart,
      totalPortfolioValue:
          (json['totalPortfolioValue'] as num?)?.toDouble() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      averageValue: (json['averageValue'] as num?)?.toDouble() ?? 0,
      categoryTotals: _categoryTotalsFromJson(json['categoryTotals']),
      collectionScore: (json['collectionScore'] as num?)?.toInt() ?? 0,
      itemValues: _doubleMapFromJson(json['itemValues']),
      itemTitles: _stringMapFromJson(json['itemTitles']),
      itemCategories: _stringMapFromJson(json['itemCategories']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'period': period.name,
      'periodStart': periodStart.toIso8601String(),
      'capturedAt': capturedAt.toIso8601String(),
      'totalPortfolioValue': totalPortfolioValue,
      'totalItems': totalItems,
      'averageValue': averageValue,
      'categoryTotals': {
        for (final entry in categoryTotals.entries) entry.key.name: entry.value,
      },
      'collectionScore': collectionScore,
      'itemValues': itemValues,
      'itemTitles': itemTitles,
      'itemCategories': itemCategories,
    };
  }

  static String idFor(TrendSnapshotPeriod period, DateTime periodStart) {
    return _snapshotId(period, periodStart);
  }
}

class PortfolioValueChange {
  const PortfolioValueChange({
    required this.label,
    required this.currentValue,
    required this.previousValue,
  });

  final String label;
  final double currentValue;
  final double previousValue;

  double get absoluteChange => currentValue - previousValue;

  double get percentageChange {
    if (previousValue == 0) {
      return currentValue == 0 ? 0 : 1;
    }
    return absoluteChange / previousValue;
  }

  bool get isPositive => absoluteChange >= 0;
}

class PortfolioValueMover {
  const PortfolioValueMover({
    required this.itemId,
    required this.title,
    required this.category,
    required this.previousValue,
    required this.currentValue,
  });

  final String itemId;
  final String title;
  final String category;
  final double previousValue;
  final double currentValue;

  double get absoluteChange => currentValue - previousValue;

  double get percentageChange {
    if (previousValue == 0) {
      return currentValue == 0 ? 0 : 1;
    }
    return absoluteChange / previousValue;
  }
}

class PortfolioPerformance {
  const PortfolioPerformance({
    required this.todayChange,
    required this.weeklyChange,
    required this.monthlyChange,
    required this.overallChange,
    required this.topGainers,
    required this.topLosers,
    required this.recentlyAppreciated,
    required this.recentlyDropped,
    required this.recommendations,
    required this.dailySnapshots,
    required this.weeklySnapshots,
    required this.monthlySnapshots,
  });

  final PortfolioValueChange todayChange;
  final PortfolioValueChange weeklyChange;
  final PortfolioValueChange monthlyChange;
  final PortfolioValueChange overallChange;
  final List<PortfolioValueMover> topGainers;
  final List<PortfolioValueMover> topLosers;
  final List<PortfolioValueMover> recentlyAppreciated;
  final List<PortfolioValueMover> recentlyDropped;
  final List<String> recommendations;
  final List<PortfolioSnapshot> dailySnapshots;
  final List<PortfolioSnapshot> weeklySnapshots;
  final List<PortfolioSnapshot> monthlySnapshots;

  PortfolioValueMover? get topGainer =>
      topGainers.isEmpty ? null : topGainers.first;

  PortfolioValueMover? get topLoser =>
      topLosers.isEmpty ? null : topLosers.first;

  bool get hasHistory =>
      dailySnapshots.length > 1 ||
      weeklySnapshots.length > 1 ||
      monthlySnapshots.length > 1;
}

TrendSnapshotPeriod _periodFromName(String? value) {
  for (final period in TrendSnapshotPeriod.values) {
    if (period.name == value) {
      return period;
    }
  }
  return TrendSnapshotPeriod.daily;
}

Map<CollectorCategory, double> _categoryTotalsFromJson(Object? value) {
  final result = {
    for (final category in CollectorCategory.values) category: 0.0,
  };
  if (value is! Map) {
    return result;
  }

  for (final entry in value.entries) {
    final category = CollectorCategory.values
        .where((candidate) => candidate.name == entry.key)
        .firstOrNull;
    if (category != null) {
      result[category] = (entry.value as num?)?.toDouble() ?? 0;
    }
  }
  return result;
}

Map<String, double> _doubleMapFromJson(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: _toDouble(entry.value),
  };
}

Map<String, String> _stringMapFromJson(Object? value) {
  if (value is! Map) {
    return const {};
  }
  return {
    for (final entry in value.entries)
      if (entry.key is String) entry.key as String: entry.value.toString(),
  };
}

double _toDouble(Object? value) {
  return (value as num?)?.toDouble() ?? 0;
}

String _snapshotId(TrendSnapshotPeriod period, DateTime periodStart) {
  final date = DateTime(periodStart.year, periodStart.month, periodStart.day);
  return '${period.name}:${date.toIso8601String()}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
