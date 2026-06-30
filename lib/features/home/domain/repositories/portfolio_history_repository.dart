import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';

abstract class PortfolioHistoryRepository {
  Future<List<PortfolioSnapshot>> getSnapshots(TrendSnapshotPeriod period);

  Future<List<PortfolioSnapshot>> getAllSnapshots();

  Future<void> upsertSnapshot(PortfolioSnapshot snapshot);

  Future<void> clearHistory();
}
