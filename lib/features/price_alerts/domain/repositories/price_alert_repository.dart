import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';

abstract class PriceAlertRepository {
  Future<List<PriceAlert>> getAlerts();

  Future<List<PriceAlert>> getAlertsForItem(String itemId);

  Future<void> saveAlert(PriceAlert alert);

  Future<void> deleteAlert(String alertId);

  Future<void> clearAlerts();
}
