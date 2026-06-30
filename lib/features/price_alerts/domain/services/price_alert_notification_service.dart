import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';

abstract class PriceAlertNotificationService {
  Future<void> initialize();

  Future<PriceAlertNotificationPermissionStatus> getPermissionStatus();

  Future<PriceAlertNotificationPermissionStatus> requestPermission();

  Future<PriceAlertNotificationResult> showPriceAlertNotification({
    required int id,
    required String title,
    required String body,
  });
}
