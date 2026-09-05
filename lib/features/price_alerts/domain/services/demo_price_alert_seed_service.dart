import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/foundation.dart';

/// Dev/QA helper that seeds a handful of *triggered* price alerts on the
/// highest-value demo items so the notification inbox renders real content
/// instead of an empty state.
class DemoPriceAlertSeedService {
  const DemoPriceAlertSeedService();

  static const _demoPrefix = 'packlox-demo-alert-';

  /// Seeds triggered alerts and returns them so callers can mirror them into
  /// the notification event log.
  Future<List<PriceAlert>> seed({
    required PriceAlertRepository repository,
    required List<CollectibleItem> items,
    DateTime? now,
  }) async {
    final valued = items
        .where((item) => item.estimatedValue > 0)
        .toList(growable: false);
    if (valued.isEmpty) {
      return const [];
    }
    final today = now ?? DateTime.now();
    final ranked = [...valued]
      ..sort((a, b) => b.estimatedValue.compareTo(a.estimatedValue));
    final picks = ranked.take(3).toList(growable: false);

    final specs = <_AlertSpec>[
      _AlertSpec(
        rule: PriceAlertRuleType.priceRisesAboveAmount,
        hoursAgo: 3,
        message: (item) =>
            '${item.title} rose above your target of '
            '${_money(item.estimatedValue * 0.9)}.',
      ),
      _AlertSpec(
        rule: PriceAlertRuleType.percentageIncrease,
        hoursAgo: 27,
        message: (item) => '${item.title} is up 12% since you set the alert.',
      ),
      _AlertSpec(
        rule: PriceAlertRuleType.stalePricingReminder,
        hoursAgo: 74,
        message: (item) =>
            'We haven\'t refreshed pricing for ${item.title} in 30 days.',
      ),
    ];

    final created = <PriceAlert>[];
    for (var index = 0; index < picks.length; index++) {
      final item = picks[index];
      final spec = specs[index % specs.length];
      final triggeredAt = today.subtract(Duration(hours: spec.hoursAgo));
      final alert = PriceAlert(
        id: '$_demoPrefix${item.id}',
        itemId: item.id,
        itemTitle: item.title,
        rule: PriceAlertRule(
          type: spec.rule,
          amount: spec.rule == PriceAlertRuleType.priceRisesAboveAmount
              ? item.estimatedValue * 0.9
              : null,
          percentage: spec.rule == PriceAlertRuleType.percentageIncrease
              ? 10
              : null,
          staleAfterDays:
              spec.rule == PriceAlertRuleType.stalePricingReminder ? 30 : null,
        ),
        status: PriceAlertStatus.triggered,
        createdAt: triggeredAt.subtract(const Duration(days: 4)),
        updatedAt: triggeredAt,
        triggeredAt: triggeredAt,
        message: spec.message(item),
      );
      await repository.saveAlert(alert);
      created.add(alert);
    }
    return created;
  }

  Future<void> clear(PriceAlertRepository repository) async {
    final alerts = await repository.getAlerts();
    for (final alert in alerts.where((a) => a.id.startsWith(_demoPrefix))) {
      try {
        await repository.deleteAlert(alert.id);
      } on Object catch (error) {
        // Seeding cleanup is best-effort: one alert the cloud refuses to
        // release must not stop the rest being cleared.
        debugPrint('[PriceAlerts] demo clear skipped ${alert.id}: $error');
      }
    }
  }

  String _money(double value) => '\$${value.round()}';
}

class _AlertSpec {
  const _AlertSpec({
    required this.rule,
    required this.hoursAgo,
    required this.message,
  });

  final PriceAlertRuleType rule;
  final int hoursAgo;
  final String Function(CollectibleItem item) message;
}
