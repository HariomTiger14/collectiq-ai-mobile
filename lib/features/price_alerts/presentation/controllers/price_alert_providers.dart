import 'dart:async';

import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/price_alerts/data/repositories/shared_preferences_price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/data/repositories/supabase_price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_evaluator.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_notification_controller.dart';
import 'package:collectiq_ai/features/notifications/domain/entities/notification_event.dart';
import 'package:collectiq_ai/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final priceAlertRepositoryProvider = Provider<PriceAlertRepository>((ref) {
  final supabaseDataGateway = ref.watch(supabaseServiceProvider);
  final registry = ref.watch(cloudServiceRegistryProvider);
  if (supabaseDataGateway.isConfigured) {
    return SupabasePriceAlertRepository(
      authService: registry.authService,
      supabaseDataGateway: supabaseDataGateway,
    );
  }
  return const SharedPreferencesPriceAlertRepository();
});

final priceAlertEvaluatorProvider = Provider<PriceAlertEvaluator>((ref) {
  return const PriceAlertEvaluator();
});

final itemPriceAlertsProvider = FutureProvider.family<List<PriceAlert>, String>(
  (ref, itemId) async {
    final repository = ref.watch(priceAlertRepositoryProvider);
    return repository.getAlertsForItem(itemId);
  },
);

final priceAlertSummaryProvider =
    FutureProvider.family<PriceAlertSummary, List<CollectibleItem>>((
      ref,
      items,
    ) async {
      return evaluateAndDispatchPriceAlerts(ref, items);
    });

/// Evaluates saved price alerts against the current portfolio values, flips any
/// that meet their condition to `triggered`, logs a notification event, and
/// dispatches the local notification. Extracted from [priceAlertSummaryProvider]
/// so it can also be invoked imperatively when the portfolio loads/syncs —
/// previously the summary provider had no watchers, so alerts never fired.
Future<PriceAlertSummary> evaluateAndDispatchPriceAlerts(
  Ref ref,
  List<CollectibleItem> items,
) async {
  final repository = ref.read(priceAlertRepositoryProvider);
  final evaluator = ref.read(priceAlertEvaluatorProvider);
  final alerts = await repository.getAlerts();
  final evaluations = evaluator.evaluateAlerts(alerts: alerts, items: items);
  for (final evaluation in evaluations) {
    final previous = alerts.where((alert) => alert.id == evaluation.alert.id);
    final previousAlert = previous.isEmpty ? null : previous.first;
    if (previousAlert == null ||
        previousAlert.status != evaluation.alert.status ||
        previousAlert.message != evaluation.alert.message ||
        previousAlert.triggeredAt != evaluation.alert.triggeredAt) {
      await repository.saveAlert(evaluation.alert);
    }
    // Log a notification event on a fresh trigger. The event store dedupes by
    // alertId@triggeredAt, so re-evaluations never double-log.
    if (evaluation.triggered && evaluation.alert.isTriggered) {
      await ref
          .read(notificationEventStoreProvider)
          .append(NotificationEvent.fromPriceAlert(evaluation.alert));
    }
  }
  // Surface alerts that were triggered elsewhere (e.g. the server-side
  // scheduler, synced in via SupabasePriceAlertRepository) in the in-app inbox.
  // Dedup by alertId@triggeredAt means already-logged events never repeat.
  final eventStore = ref.read(notificationEventStoreProvider);
  for (final alert in alerts) {
    if (alert.isTriggered) {
      await eventStore.append(NotificationEvent.fromPriceAlert(alert));
    }
  }
  unawaited(
    ref
        .read(priceAlertNotificationDispatcherProvider)
        .dispatchTriggeredAlerts(evaluations),
  );
  return evaluator.summaryFromEvaluations(evaluations);
}

PriceAlert buildPriceAlert({
  required CollectibleItem item,
  required PriceAlertRuleType type,
}) {
  final now = DateTime.now();
  return PriceAlert(
    id: 'alert-${item.id}-${type.name}-${now.microsecondsSinceEpoch}',
    itemId: item.id,
    itemTitle: item.title,
    rule: _ruleForType(item: item, type: type),
    status: PriceAlertStatus.active,
    createdAt: now,
    updatedAt: now,
  );
}

PriceAlertRule _ruleForType({
  required CollectibleItem item,
  required PriceAlertRuleType type,
}) {
  final value = item.estimatedValue;
  switch (type) {
    case PriceAlertRuleType.priceRisesAboveAmount:
      return PriceAlertRule(type: type, amount: value * 1.1);
    case PriceAlertRuleType.priceDropsBelowAmount:
      return PriceAlertRule(type: type, amount: value * 0.9);
    case PriceAlertRuleType.percentageIncrease:
      return PriceAlertRule(type: type, percentage: 0.1, baselineValue: value);
    case PriceAlertRuleType.percentageDecrease:
      return PriceAlertRule(type: type, percentage: 0.1, baselineValue: value);
    case PriceAlertRuleType.stalePricingReminder:
      return PriceAlertRule(type: type, staleAfterDays: 30);
  }
}
