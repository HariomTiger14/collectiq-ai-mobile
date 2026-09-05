import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/price_alerts/data/repositories/shared_preferences_price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SupabasePriceAlertRepository implements PriceAlertRepository {
  const SupabasePriceAlertRepository({
    required this.authService,
    required this.supabaseDataGateway,
    this.localRepository = const SharedPreferencesPriceAlertRepository(),
    this.tableName = 'price_alerts',
  });

  final AuthService authService;
  final SupabaseDataGateway supabaseDataGateway;
  final PriceAlertRepository localRepository;
  final String tableName;

  @override
  Future<List<PriceAlert>> getAlerts() async {
    final cloudAlerts = await _fetchCloudAlerts();
    if (cloudAlerts != null) {
      await _replaceLocalAlerts(cloudAlerts);
      return cloudAlerts;
    }
    return localRepository.getAlerts();
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
    await localRepository.saveAlert(alert);
    final session = await _signedInSession();
    if (session == null) {
      return;
    }

    try {
      await supabaseDataGateway.authenticatedPostWithSession<List<dynamic>>(
        '/rest/v1/$tableName',
        session: session,
        queryParameters: const {'on_conflict': 'id,user_id'},
        data: [supabaseRowForPriceAlert(alert, session.userId)],
        options: Options(
          headers: const {
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
        ),
      );
    } on Object catch (error) {
      debugPrint('[PriceAlerts] cloud save failed: $error');
    }
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    await localRepository.deleteAlert(alertId);
    final session = await _signedInSession();
    if (session == null) {
      return;
    }

    try {
      await supabaseDataGateway.authenticatedPostWithSession<List<dynamic>>(
        '/rest/v1/$tableName',
        session: session,
        queryParameters: const {'on_conflict': 'id,user_id'},
        data: [
          {
            'id': alertId,
            'user_id': session.userId,
            'status': PriceAlertStatus.paused.name,
            'enabled': false,
            'updated_at': DateTime.now().toIso8601String(),
          },
        ],
        options: Options(
          headers: const {
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
        ),
      );
    } on Object catch (error) {
      // Rethrow. Swallowing this is why "Price alert deleted" appeared while
      // the alert stayed on screen: the local row went, the cloud row kept
      // enabled=true, and the next fetch restored it. Measured 2026-09-05:
      // zero rows had ever reached enabled=false, so this had never once
      // succeeded and nothing ever said so.
      debugPrint('[PriceAlerts] cloud delete failed: $error');
      throw PriceAlertDeleteFailedException(alertId, error);
    }
  }

  @override
  Future<void> clearAlerts() async {
    await localRepository.clearAlerts();
    final session = await _signedInSession();
    if (session == null) {
      return;
    }

    final alerts = await _fetchCloudAlerts();
    if (alerts == null) {
      return;
    }
    for (final alert in alerts) {
      await deleteAlert(alert.id);
    }
  }

  Future<List<PriceAlert>?> _fetchCloudAlerts() async {
    final session = await _signedInSession();
    if (session == null) {
      return null;
    }

    try {
      final response = await supabaseDataGateway
          .authenticatedGetWithSession<List<dynamic>>(
            '/rest/v1/$tableName',
            session: session,
            queryParameters: const {
              'select': '*',
              'enabled': 'eq.true',
              'order': 'created_at.desc',
            },
          );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(priceAlertFromSupabaseRow)
          .nonNulls
          .toList(growable: false);
    } on Object catch (error) {
      debugPrint('[PriceAlerts] cloud fetch failed: $error');
      return null;
    }
  }

  Future<SupabaseAuthSession?> _signedInSession() async {
    if (!supabaseDataGateway.isConfigured) {
      return null;
    }
    final session = await supabaseDataGateway.currentSession();
    if (session == null || session.isAnonymous) {
      return null;
    }
    if (!await authService.isSignedIn()) {
      return null;
    }
    return session;
  }

  Future<void> _replaceLocalAlerts(List<PriceAlert> alerts) async {
    await localRepository.clearAlerts();
    for (final alert in alerts) {
      await localRepository.saveAlert(alert);
    }
  }
}

@visibleForTesting
Map<String, dynamic> supabaseRowForPriceAlert(PriceAlert alert, String userId) {
  final rule = alert.rule;
  return {
    'id': alert.id,
    'user_id': userId,
    'portfolio_item_id': alert.itemId,
    'item_title': alert.itemTitle,
    'rule_type': rule.type.name,
    'target_amount': rule.amount,
    'percentage': rule.percentage,
    'baseline_value': rule.baselineValue,
    'stale_after_days': rule.staleAfterDays,
    'status': alert.status.name,
    'enabled': alert.status != PriceAlertStatus.paused,
    'triggered_at': alert.triggeredAt?.toIso8601String(),
    'message': alert.message,
    'raw_json': alert.toJson(),
    'created_at': alert.createdAt.toIso8601String(),
    'updated_at': alert.updatedAt.toIso8601String(),
  };
}

@visibleForTesting
PriceAlert? priceAlertFromSupabaseRow(Map<String, dynamic> row) {
  try {
    final rawJson = row['raw_json'];
    if (rawJson is Map) {
      return PriceAlert.fromJson({
        ...rawJson.map((key, value) => MapEntry(key.toString(), value)),
        'id': row['id'],
        'itemId': row['portfolio_item_id'],
        'itemTitle': row['item_title'],
        'status': row['status'],
        'triggeredAt': row['triggered_at'],
        'message': row['message'],
        'createdAt': row['created_at'],
        'updatedAt': row['updated_at'],
      });
    }

    return PriceAlert(
      id: row['id'] as String? ?? '',
      itemId: row['portfolio_item_id'] as String? ?? '',
      itemTitle: row['item_title'] as String? ?? 'Collectible',
      rule: PriceAlertRule(
        type: PriceAlertRuleType.fromName(row['rule_type'] as String?),
        amount: _number(row['target_amount']),
        percentage: _number(row['percentage']),
        baselineValue: _number(row['baseline_value']),
        staleAfterDays: _int(row['stale_after_days']),
      ),
      status: PriceAlertStatus.fromName(row['status'] as String?),
      createdAt: _date(row['created_at']),
      updatedAt: _date(row['updated_at']),
      triggeredAt: _optionalDate(row['triggered_at']),
      message: _optionalString(row['message']),
    );
  } on Object {
    return null;
  }
}

double? _number(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value);
  }
  return null;
}

int? _int(Object? value) {
  if (value is num) {
    return value.toInt();
  }
  if (value is String) {
    return int.tryParse(value);
  }
  return null;
}

DateTime _date(Object? value) {
  return _optionalDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime? _optionalDate(Object? value) {
  if (value is! String) {
    return null;
  }
  return DateTime.tryParse(value);
}

String? _optionalString(Object? value) {
  if (value is! String) {
    return null;
  }
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
