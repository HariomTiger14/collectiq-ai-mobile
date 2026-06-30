import 'package:collectiq_ai/features/price_alerts/data/repositories/shared_preferences_price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_evaluator.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final priceAlertRepositoryProvider = Provider<PriceAlertRepository>((ref) {
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
      final repository = ref.watch(priceAlertRepositoryProvider);
      final evaluator = ref.watch(priceAlertEvaluatorProvider);
      final alerts = await repository.getAlerts();
      final evaluations = evaluator.evaluateAlerts(
        alerts: alerts,
        items: items,
      );
      for (final evaluation in evaluations) {
        final previous = alerts.where(
          (alert) => alert.id == evaluation.alert.id,
        );
        final previousAlert = previous.isEmpty ? null : previous.first;
        if (previousAlert == null ||
            previousAlert.status != evaluation.alert.status ||
            previousAlert.message != evaluation.alert.message ||
            previousAlert.triggeredAt != evaluation.alert.triggeredAt) {
          await repository.saveAlert(evaluation.alert);
        }
      }
      return evaluator.summaryFromEvaluations(evaluations);
    });

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
