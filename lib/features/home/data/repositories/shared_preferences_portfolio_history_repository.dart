import 'dart:convert';

import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';
import 'package:collectiq_ai/features/home/domain/repositories/portfolio_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPortfolioHistoryRepository
    implements PortfolioHistoryRepository {
  const SharedPreferencesPortfolioHistoryRepository();

  static const _storageKey = 'portfolio_value_history_snapshots';

  @override
  Future<List<PortfolioSnapshot>> getSnapshots(
    TrendSnapshotPeriod period,
  ) async {
    final snapshots = await getAllSnapshots();
    return snapshots
        .where((snapshot) => snapshot.period == period)
        .toList(growable: false);
  }

  @override
  Future<List<PortfolioSnapshot>> getAllSnapshots() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final snapshots =
        decoded
            .whereType<Map<String, dynamic>>()
            .map(PortfolioSnapshot.fromJson)
            .toList()
          ..sort(_snapshotSort);
    return snapshots;
  }

  @override
  Future<void> upsertSnapshot(PortfolioSnapshot snapshot) async {
    final snapshots = await getAllSnapshots();
    final next = [
      snapshot,
      ...snapshots.where((existing) => existing.id != snapshot.id),
    ]..sort(_snapshotSort);
    await _persist(next);
  }

  @override
  Future<void> clearHistory() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  Future<void> _persist(List<PortfolioSnapshot> snapshots) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode([for (final snapshot in snapshots) snapshot.toJson()]),
    );
  }
}

int _snapshotSort(PortfolioSnapshot a, PortfolioSnapshot b) {
  final periodComparison = a.period.index.compareTo(b.period.index);
  if (periodComparison != 0) {
    return periodComparison;
  }
  return a.periodStart.compareTo(b.periodStart);
}
