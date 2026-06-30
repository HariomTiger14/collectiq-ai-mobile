import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_notification_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_service.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:flutter/foundation.dart';

class PriceAlertNotificationDispatcher {
  const PriceAlertNotificationDispatcher(
    this._repository,
    this._service,
    this._telemetry,
  );

  final PriceAlertNotificationRepository _repository;
  final PriceAlertNotificationService _service;
  final AppTelemetryService _telemetry;

  Future<PriceAlertNotificationResult> dispatchTriggeredAlerts(
    List<PriceAlertEvaluation> evaluations,
  ) async {
    final triggered = evaluations
        .where((evaluation) => evaluation.triggered)
        .toList(growable: false);
    if (triggered.isEmpty) {
      return const PriceAlertNotificationResult(
        status: PriceAlertNotificationDeliveryStatus.idle,
        message: 'No triggered price alerts.',
      );
    }
    _trackTelemetry(
      TelemetryEventNames.priceAlertTriggered,
      properties: {'triggered_count': triggered.length},
    );

    final preferences = await _repository.getPreferences();
    if (!preferences.enabled) {
      const result = PriceAlertNotificationResult(
        status: PriceAlertNotificationDeliveryStatus.disabled,
        message: 'Price alert notifications are disabled.',
      );
      await _repository.updateLastStatus(
        status: result.status,
        message: result.message,
      );
      return result;
    }

    await _service.initialize();
    final permissionStatus = await _service.getPermissionStatus();
    if (!permissionStatus.canNotify) {
      final result = PriceAlertNotificationResult(
        status: PriceAlertNotificationDeliveryStatus.permissionDenied,
        message:
            permissionStatus ==
                PriceAlertNotificationPermissionStatus.notSupported
            ? 'Local notifications are not supported on this platform.'
            : 'Notification permission is required for local price alerts.',
      );
      await _repository.updateLastStatus(
        status: result.status,
        message: result.message,
      );
      return result;
    }

    var delivered = 0;
    var lastMessage = 'No new triggered price alerts.';
    for (final evaluation in triggered) {
      final token = notificationTokenForAlert(evaluation.alert);
      if (preferences.notifiedAlertTokens.contains(token)) {
        continue;
      }

      final message = evaluation.message;
      final result = await _service.showPriceAlertNotification(
        id: _notificationIdForToken(token),
        title: 'Price alert triggered',
        body: message,
      );
      if (result.status != PriceAlertNotificationDeliveryStatus.delivered) {
        await _repository.updateLastStatus(
          status: result.status,
          message: result.message,
        );
        return result;
      }

      delivered += 1;
      lastMessage = message;
      await _repository.markNotified(
        token: token,
        message: message,
        notifiedAt: DateTime.now(),
        status: PriceAlertNotificationDeliveryStatus.delivered,
      );
    }

    final result = PriceAlertNotificationResult(
      status: delivered > 0
          ? PriceAlertNotificationDeliveryStatus.delivered
          : PriceAlertNotificationDeliveryStatus.idle,
      message: delivered > 0
          ? lastMessage
          : 'Triggered price alerts were already notified.',
      deliveredCount: delivered,
    );
    if (delivered == 0) {
      await _repository.updateLastStatus(
        status: result.status,
        message: result.message,
      );
    }
    debugPrint(
      '[PriceAlerts] notification dispatch status=${result.status.name} '
      'delivered=${result.deliveredCount}',
    );
    return result;
  }

  void _trackTelemetry(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) {
    _telemetry.trackEvent(eventName, properties: properties);
  }
}

String notificationTokenForAlert(PriceAlert alert) {
  final triggeredAt = alert.triggeredAt?.toIso8601String() ?? 'pending';
  return '${alert.id}:$triggeredAt';
}

int _notificationIdForToken(String token) {
  return token.hashCode & 0x7fffffff;
}
