import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';

abstract class PriceAlertRepository {
  Future<List<PriceAlert>> getAlerts();

  Future<List<PriceAlert>> getAlertsForItem(String itemId);

  Future<void> saveAlert(PriceAlert alert);

  Future<void> deleteAlert(String alertId);

  Future<void> clearAlerts();
}

/// Raised when an alert was removed locally but the change never reached the
/// cloud, so it will reappear on the next sync.
///
/// Exists because the failure used to be logged and discarded, letting the UI
/// report a deletion that had not happened.
class PriceAlertDeleteFailedException implements Exception {
  const PriceAlertDeleteFailedException(this.alertId, this.cause);

  final String alertId;
  final Object cause;

  @override
  String toString() =>
      'PriceAlertDeleteFailedException($alertId): $cause';
}
