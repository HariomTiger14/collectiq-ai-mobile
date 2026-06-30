import 'dart:convert';

import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPriceAlertRepository implements PriceAlertRepository {
  const SharedPreferencesPriceAlertRepository();

  static const _storageKey = 'price_alerts';

  @override
  Future<List<PriceAlert>> getAlerts() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final alerts =
        decoded
            .whereType<Map<String, dynamic>>()
            .map(PriceAlert.fromJson)
            .where((alert) => alert.id.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return alerts;
  }

  @override
  Future<List<PriceAlert>> getAlertsForItem(String itemId) async {
    final alerts = await getAlerts();
    return alerts
        .where((alert) => alert.itemId == itemId)
        .toList(growable: false);
  }

  @override
  Future<void> saveAlert(PriceAlert alert) async {
    final alerts = await getAlerts();
    final next = [alert, ...alerts.where((existing) => existing.id != alert.id)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persist(next);
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    final alerts = await getAlerts();
    await _persist(
      alerts.where((alert) => alert.id != alertId).toList(growable: false),
    );
  }

  @override
  Future<void> clearAlerts() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  Future<void> _persist(List<PriceAlert> alerts) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode([for (final alert in alerts) alert.toJson()]),
    );
  }
}
