import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Number of price alerts currently in a triggered state, aggregated across the
/// whole portfolio.
///
/// This is intentionally read-only: it reports the last persisted alert state
/// rather than re-evaluating rules, so surfacing it on the Home screen stays
/// side-effect free. Alerts are (re)evaluated wherever they are managed
/// (collectible detail / [priceAlertSummaryProvider]).
final homeTriggeredAlertCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final repository = ref.watch(priceAlertRepositoryProvider);
  final alerts = await repository.getAlerts();
  return alerts.where((alert) => alert.isTriggered).length;
});
