import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

class PriceAlertEvaluator {
  const PriceAlertEvaluator();

  List<PriceAlertEvaluation> evaluateAlerts({
    required List<PriceAlert> alerts,
    required List<CollectibleItem> items,
    DateTime? now,
  }) {
    final itemsById = {for (final item in items) item.id: item};
    return [
      for (final alert in alerts)
        if (itemsById[alert.itemId] != null)
          evaluateAlert(alert: alert, item: itemsById[alert.itemId]!, now: now),
    ];
  }

  PriceAlertEvaluation evaluateAlert({
    required PriceAlert alert,
    required CollectibleItem item,
    DateTime? now,
  }) {
    if (alert.status == PriceAlertStatus.paused) {
      return PriceAlertEvaluation(
        alert: alert,
        triggered: false,
        message: 'Alert paused for ${alert.itemTitle}.',
      );
    }

    final currentValue = item.estimatedValue;
    final message = _message(alert, item, currentValue, now ?? DateTime.now());
    final triggered = message != null;
    if (!triggered) {
      return PriceAlertEvaluation(
        alert: alert.copyWith(itemTitle: item.title),
        triggered: false,
        message: _waitingMessage(alert, item),
      );
    }

    final updatedAlert = alert.copyWith(
      itemTitle: item.title,
      status: PriceAlertStatus.triggered,
      updatedAt: now ?? DateTime.now(),
      triggeredAt: alert.triggeredAt ?? now ?? DateTime.now(),
      message: message,
    );
    return PriceAlertEvaluation(
      alert: updatedAlert,
      triggered: true,
      message: message,
    );
  }

  PriceAlertSummary summaryFromEvaluations(
    List<PriceAlertEvaluation> evaluations,
  ) {
    final alerts = evaluations.map((evaluation) => evaluation.alert).toList();
    final triggered = alerts
        .where((alert) => alert.status == PriceAlertStatus.triggered)
        .toList(growable: false);
    final active = alerts
        .where((alert) => alert.status == PriceAlertStatus.active)
        .toList(growable: false);
    return PriceAlertSummary(
      alerts: alerts,
      triggeredAlerts: triggered,
      activeAlerts: active,
      messages: evaluations
          .where((evaluation) => evaluation.triggered)
          .map((evaluation) => evaluation.message)
          .toList(growable: false),
    );
  }

  String? _message(
    PriceAlert alert,
    CollectibleItem item,
    double currentValue,
    DateTime now,
  ) {
    final rule = alert.rule;
    switch (rule.type) {
      case PriceAlertRuleType.priceRisesAboveAmount:
        final amount = rule.amount ?? double.infinity;
        return currentValue >= amount
            ? '${item.title} rose above ${_aud(amount)}.'
            : null;
      case PriceAlertRuleType.priceDropsBelowAmount:
        final amount = rule.amount ?? double.negativeInfinity;
        return currentValue <= amount
            ? '${item.title} dropped below ${_aud(amount)}.'
            : null;
      case PriceAlertRuleType.percentageIncrease:
        final baseline = rule.baselineValue ?? currentValue;
        final percentage = rule.percentage ?? 0;
        if (baseline <= 0) {
          return null;
        }
        final change = (currentValue - baseline) / baseline;
        return change >= percentage
            ? '${item.title} gained ${_percent(change)} since tracking started.'
            : null;
      case PriceAlertRuleType.percentageDecrease:
        final baseline = rule.baselineValue ?? currentValue;
        final percentage = rule.percentage ?? 0;
        if (baseline <= 0) {
          return null;
        }
        final change = (baseline - currentValue) / baseline;
        return change >= percentage
            ? '${item.title} lost ${_percent(change)} since tracking started.'
            : null;
      case PriceAlertRuleType.stalePricingReminder:
        final lastUpdated =
            item.marketSummary?.lastUpdated ?? item.pricing?.lastUpdated;
        if (lastUpdated == null) {
          return '${item.title} needs fresh pricing data.';
        }
        final staleAfterDays = rule.staleAfterDays ?? 30;
        return now.difference(lastUpdated).inDays >= staleAfterDays
            ? '${item.title} pricing is stale. Refresh market data.'
            : null;
    }
  }

  String _waitingMessage(PriceAlert alert, CollectibleItem item) {
    switch (alert.rule.type) {
      case PriceAlertRuleType.priceRisesAboveAmount:
        return 'Watching ${item.title} for a rise above ${_aud(alert.rule.amount ?? 0)}.';
      case PriceAlertRuleType.priceDropsBelowAmount:
        return 'Watching ${item.title} for a drop below ${_aud(alert.rule.amount ?? 0)}.';
      case PriceAlertRuleType.percentageIncrease:
        return 'Watching ${item.title} for a ${_percent(alert.rule.percentage ?? 0)} gain.';
      case PriceAlertRuleType.percentageDecrease:
        return 'Watching ${item.title} for a ${_percent(alert.rule.percentage ?? 0)} drop.';
      case PriceAlertRuleType.stalePricingReminder:
        return 'Watching ${item.title} for stale pricing.';
    }
  }

  String _aud(double value) {
    final whole = value.toStringAsFixed(0);
    final withCommas = whole.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return 'AUD $withCommas';
  }

  String _percent(double value) {
    return '${(value * 100).toStringAsFixed(0)}%';
  }
}
