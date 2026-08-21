import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';

class PortfolioValuationSnapshot {
  const PortfolioValuationSnapshot({
    required this.id,
    required this.portfolioItemId,
    required this.valuationStatus,
    required this.pricedAt,
    this.valueAud,
    this.lowEstimateAud,
    this.highEstimateAud,
    this.displayString,
    this.pricingProvider,
    this.confidenceScore,
    this.currency = 'AUD',
  });

  final String id;
  final String portfolioItemId;
  final double? valueAud;
  final double? lowEstimateAud;
  final double? highEstimateAud;
  final String? displayString;
  final ValuationStatus valuationStatus;
  final String? pricingProvider;
  final double? confidenceScore;
  final DateTime pricedAt;

  /// The currency `valueAud`/`lowEstimateAud`/`highEstimateAud` are actually
  /// denominated in -- those columns are historically misnamed (they hold
  /// whatever display currency was active when the row was written, not
  /// necessarily AUD). Defaults to AUD for rows written before this column
  /// existed, matching the backfill migration
  /// (202608220001_valuation_snapshot_currency.sql).
  final String currency;

  factory PortfolioValuationSnapshot.fromJson(Map<String, dynamic> json) {
    return PortfolioValuationSnapshot(
      id: _string(json['id']) ?? '',
      portfolioItemId: _string(json['portfolio_item_id']) ?? '',
      valueAud: _double(json['value_aud']),
      lowEstimateAud: _double(json['low_estimate_aud']),
      highEstimateAud: _double(json['high_estimate_aud']),
      displayString: _string(json['display_string']),
      valuationStatus: ValuationStatus.fromJson(json['valuation_status']),
      pricingProvider: _string(json['pricing_provider']),
      confidenceScore: _double(json['confidence_score']),
      pricedAt:
          _date(json['priced_at']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      currency: _string(json['currency'])?.toUpperCase() ?? 'AUD',
    );
  }
}

String? _string(Object? value) {
  if (value is! String) {
    return null;
  }
  final clean = value.trim();
  return clean.isEmpty ? null : clean;
}

double? _double(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

DateTime? _date(Object? value) {
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

class CloudPortfolioSyncStatus {
  const CloudPortfolioSyncStatus({
    required this.enabled,
    required this.message,
    this.userId,
    this.lastSyncedAt,
  });

  final bool enabled;
  final String message;
  final String? userId;
  final DateTime? lastSyncedAt;
}

abstract interface class CloudPortfolioSyncService {
  String get providerName;

  Future<void> syncItem(CollectibleItem item);

  Future<void> deleteItem(String itemId);

  Future<void> syncValuationSnapshot(CollectibleItem item);

  Future<List<PortfolioValuationSnapshot>> fetchValuationSnapshots(
    String itemId,
  );

  /// All valuation snapshots across every item the user owns — used to draw
  /// the portfolio-total value history chart (Home screen), as opposed to
  /// [fetchValuationSnapshots] which is scoped to one item's own chart.
  Future<List<PortfolioValuationSnapshot>> fetchAllValuationSnapshots();

  Future<List<CollectibleItem>> fetchItems();

  Future<CollectibleItem> markSynced(CollectibleItem item);

  Future<CloudPortfolioSyncStatus> getSyncStatus();
}
