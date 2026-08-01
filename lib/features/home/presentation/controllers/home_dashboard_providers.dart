import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Number of price alerts currently in a triggered state across the portfolio.
///
/// Read-only: reports the last persisted alert state rather than re-evaluating
/// rules, so surfacing it on the Home dashboard stays side-effect free.
final homeTriggeredAlertCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final repository = ref.watch(priceAlertRepositoryProvider);
  final alerts = await repository.getAlerts();
  return alerts.where((alert) => alert.isTriggered).length;
});

/// Timestamp of the last silent Home auto-sync. App-scoped (survives HomePage
/// rebuilds/navigation) so the on-appear background refresh can be throttled.
final homeLastAutoSyncProvider =
    NotifierProvider<HomeLastAutoSyncController, DateTime?>(
      HomeLastAutoSyncController.new,
    );

class HomeLastAutoSyncController extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  void mark(DateTime at) => state = at;
}
