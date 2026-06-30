import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';

abstract class PriceAlertNotificationRepository {
  Future<PriceAlertNotificationPreferences> getPreferences();

  Future<void> savePreferences(PriceAlertNotificationPreferences preferences);

  Future<void> setEnabled(bool enabled);

  Future<void> markNotified({
    required String token,
    required String message,
    required DateTime notifiedAt,
    required PriceAlertNotificationDeliveryStatus status,
  });

  Future<void> updateLastStatus({
    required PriceAlertNotificationDeliveryStatus status,
    required String message,
  });

  Future<void> clearNotificationHistory();
}
