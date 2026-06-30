import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_service.dart';
import 'package:flutter/services.dart';

class MethodChannelPriceAlertNotificationService
    implements PriceAlertNotificationService {
  const MethodChannelPriceAlertNotificationService([
    this._channel = const MethodChannel('collectiq_ai/notifications'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod<void>('initialize');
    } on MissingPluginException {
      return;
    }
  }

  @override
  Future<PriceAlertNotificationPermissionStatus> getPermissionStatus() async {
    try {
      final status = await _channel.invokeMethod<String>('getPermissionStatus');
      return PriceAlertNotificationPermissionStatus.fromName(status);
    } on MissingPluginException {
      return PriceAlertNotificationPermissionStatus.notSupported;
    } on PlatformException {
      return PriceAlertNotificationPermissionStatus.unknown;
    }
  }

  @override
  Future<PriceAlertNotificationPermissionStatus> requestPermission() async {
    try {
      final status = await _channel.invokeMethod<String>('requestPermission');
      return PriceAlertNotificationPermissionStatus.fromName(status);
    } on MissingPluginException {
      return PriceAlertNotificationPermissionStatus.notSupported;
    } on PlatformException {
      return PriceAlertNotificationPermissionStatus.denied;
    }
  }

  @override
  Future<PriceAlertNotificationResult> showPriceAlertNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'showPriceAlertNotification',
        {'id': id, 'title': title, 'body': body},
      );
      final status = PriceAlertNotificationDeliveryStatus.fromName(
        result?['status'] as String?,
      );
      return PriceAlertNotificationResult(
        status: status,
        message: result?['message'] as String? ?? status.label,
        deliveredCount: status == PriceAlertNotificationDeliveryStatus.delivered
            ? 1
            : 0,
      );
    } on MissingPluginException {
      return const PriceAlertNotificationResult(
        status: PriceAlertNotificationDeliveryStatus.failed,
        message: 'Local notifications are not supported on this platform.',
      );
    } on PlatformException catch (error) {
      return PriceAlertNotificationResult(
        status: PriceAlertNotificationDeliveryStatus.failed,
        message: error.message ?? 'Unable to show price alert notification.',
      );
    }
  }
}
