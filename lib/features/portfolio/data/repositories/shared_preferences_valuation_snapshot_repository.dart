import 'dart:convert';

import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesValuationSnapshotRepository {
  const SharedPreferencesValuationSnapshotRepository();

  static const _key = 'packlox.portfolio.valuation_snapshots.v1';

  Future<List<PortfolioValuationSnapshot>> getSnapshots(String itemId) async {
    final snapshots = await getAllSnapshots();
    final filtered = snapshots
        .where((snapshot) => snapshot.portfolioItemId == itemId)
        .toList();
    filtered.sort((left, right) => left.pricedAt.compareTo(right.pricedAt));
    return filtered;
  }

  Future<List<PortfolioValuationSnapshot>> getAllSnapshots() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getStringList(_key) ?? const [];
    final snapshots = <PortfolioValuationSnapshot>[];
    for (final entry in raw) {
      try {
        final decoded = jsonDecode(entry);
        if (decoded is Map<String, dynamic>) {
          snapshots.add(PortfolioValuationSnapshot.fromJson(decoded));
        } else if (decoded is Map) {
          snapshots.add(
            PortfolioValuationSnapshot.fromJson(
              decoded.map((key, value) => MapEntry(key.toString(), value)),
            ),
          );
        }
      } catch (_) {
        // Ignore corrupt local history rows; pricing should never fail because
        // one old snapshot could not be decoded.
      }
    }
    snapshots.sort((left, right) => left.pricedAt.compareTo(right.pricedAt));
    return snapshots;
  }

  Future<void> recordSnapshot(CollectibleItem item) async {
    final snapshot = _snapshotForItem(item);
    final snapshots = await getAllSnapshots();
    final retained = snapshots.where((existing) {
      return existing.id != snapshot.id;
    }).toList();
    retained.add(snapshot);
    retained.sort((left, right) => left.pricedAt.compareTo(right.pricedAt));
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _key,
      [
        for (final row in retained) jsonEncode(_jsonForSnapshot(row)),
      ],
    );
  }
}

PortfolioValuationSnapshot _snapshotForItem(CollectibleItem item) {
  final pricing = item.pricing;
  final value = _snapshotValue(item);
  final currency = pricing?.currency.trim().toUpperCase() ?? 'AUD';
  final pricedAt =
      item.lastValueRefreshedAt ??
      pricing?.lastUpdated ??
      DateTime.now();
  final provider = pricing?.pricingSource.trim().isNotEmpty == true
      ? pricing!.pricingSource
      : item.valuationSource;
  return PortfolioValuationSnapshot(
    id: '${item.id}-${pricedAt.toIso8601String()}',
    portfolioItemId: item.id,
    valueAud: value,
    lowEstimateAud: pricing?.lowEstimate ?? item.marketSummary?.lowPrice,
    highEstimateAud: pricing?.highEstimate ?? item.marketSummary?.highPrice,
    displayString: value == null ? null : _snapshotDisplay(value, currency),
    valuationStatus: item.valuationStatus,
    pricingProvider: provider,
    confidenceScore: pricing?.pricingConfidence ?? item.marketSummary?.confidence,
    pricedAt: pricedAt,
  );
}

Map<String, dynamic> _jsonForSnapshot(PortfolioValuationSnapshot snapshot) {
  return {
    'id': snapshot.id,
    'portfolio_item_id': snapshot.portfolioItemId,
    'value_aud': snapshot.valueAud,
    'low_estimate_aud': snapshot.lowEstimateAud,
    'high_estimate_aud': snapshot.highEstimateAud,
    'display_string': snapshot.displayString,
    'valuation_status': snapshot.valuationStatus.wireValue,
    'pricing_provider': snapshot.pricingProvider,
    'confidence_score': snapshot.confidenceScore,
    'priced_at': snapshot.pricedAt.toIso8601String(),
  };
}

double? _snapshotValue(CollectibleItem item) {
  final marketValue = item.pricing?.estimatedMarketValue;
  if (marketValue != null && marketValue > 0) {
    return marketValue;
  }
  if (item.valuationStatus == ValuationStatus.marketEstimated &&
      item.estimatedValue > 0) {
    return item.estimatedValue;
  }
  return null;
}

String _snapshotDisplay(double value, String currency) {
  final rounded = value.toStringAsFixed(2);
  return '$currency $rounded';
}
