import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_notification_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_dispatcher.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_service.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_notification_controller.dart';
import 'package:collectiq_ai/features/settings/presentation/settings_screen.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PriceAlertNotificationDispatcher', () {
    test('notification service disabled does not send notification', () async {
      final repository = _FakeNotificationRepository(
        preferences: const PriceAlertNotificationPreferences(
          enabled: false,
          notifiedAlertTokens: {},
        ),
      );
      final service = _FakeNotificationService(
        permissionStatus: PriceAlertNotificationPermissionStatus.granted,
      );
      final dispatcher = PriceAlertNotificationDispatcher(
        repository,
        service,
        const NoopTelemetryService(),
      );

      final result = await dispatcher.dispatchTriggeredAlerts([
        _triggeredEvaluation(),
      ]);

      expect(result.status, PriceAlertNotificationDeliveryStatus.disabled);
      expect(service.showCount, 0);
      expect(
        repository.preferences.lastDeliveryStatus,
        PriceAlertNotificationDeliveryStatus.disabled,
      );
    });

    test('permission denied handling does not send notification', () async {
      final repository = _FakeNotificationRepository();
      final service = _FakeNotificationService(
        permissionStatus: PriceAlertNotificationPermissionStatus.denied,
      );
      final dispatcher = PriceAlertNotificationDispatcher(
        repository,
        service,
        const NoopTelemetryService(),
      );

      final result = await dispatcher.dispatchTriggeredAlerts([
        _triggeredEvaluation(),
      ]);

      expect(
        result.status,
        PriceAlertNotificationDeliveryStatus.permissionDenied,
      );
      expect(service.showCount, 0);
      expect(repository.preferences.lastMessage, contains('permission'));
    });

    test('triggered alert sends notification once', () async {
      final repository = _FakeNotificationRepository();
      final service = _FakeNotificationService(
        permissionStatus: PriceAlertNotificationPermissionStatus.granted,
      );
      final dispatcher = PriceAlertNotificationDispatcher(
        repository,
        service,
        const NoopTelemetryService(),
      );
      final evaluation = _triggeredEvaluation();

      final first = await dispatcher.dispatchTriggeredAlerts([evaluation]);
      final second = await dispatcher.dispatchTriggeredAlerts([evaluation]);

      expect(first.status, PriceAlertNotificationDeliveryStatus.delivered);
      expect(first.deliveredCount, 1);
      expect(second.deliveredCount, 0);
      expect(service.showCount, 1);
      expect(
        repository.preferences.notifiedAlertTokens,
        contains(notificationTokenForAlert(evaluation.alert)),
      );
    });
  });

  testWidgets('Settings status renders notification state', (tester) async {
    final repository = _FakeNotificationRepository();
    final service = _FakeNotificationService(
      permissionStatus: PriceAlertNotificationPermissionStatus.denied,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          priceAlertNotificationRepositoryProvider.overrideWithValue(
            repository,
          ),
          priceAlertNotificationServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Price alert notifications'), findsOneWidget);
    expect(find.text('Notification permission'), findsOneWidget);
    expect(find.text('Denied'), findsWidgets);
    expect(
      find.byKey(const ValueKey('settings-price-alert-notifications-switch')),
      findsOneWidget,
    );
  });
}

PriceAlertEvaluation _triggeredEvaluation() {
  final now = DateTime(2026, 6, 30, 12);
  final alert = PriceAlert(
    id: 'alert-1',
    itemId: 'item-1',
    itemTitle: 'Charizard',
    rule: const PriceAlertRule(
      type: PriceAlertRuleType.priceRisesAboveAmount,
      amount: 1000,
    ),
    status: PriceAlertStatus.triggered,
    createdAt: now.subtract(const Duration(days: 1)),
    updatedAt: now,
    triggeredAt: now,
    message: 'Charizard rose above AUD 1,000.',
  );
  return PriceAlertEvaluation(
    alert: alert,
    triggered: true,
    message: alert.message!,
  );
}

class _FakeNotificationRepository implements PriceAlertNotificationRepository {
  _FakeNotificationRepository({PriceAlertNotificationPreferences? preferences})
    : preferences = preferences ?? PriceAlertNotificationPreferences.defaults;

  PriceAlertNotificationPreferences preferences;

  @override
  Future<void> clearNotificationHistory() async {
    preferences = preferences.copyWith(
      notifiedAlertTokens: const {},
      lastDeliveryStatus: PriceAlertNotificationDeliveryStatus.idle,
      clearLastMessage: true,
      clearLastNotificationAt: true,
    );
  }

  @override
  Future<PriceAlertNotificationPreferences> getPreferences() async {
    return preferences;
  }

  @override
  Future<void> markNotified({
    required String token,
    required String message,
    required DateTime notifiedAt,
    required PriceAlertNotificationDeliveryStatus status,
  }) async {
    preferences = preferences.copyWith(
      notifiedAlertTokens: {...preferences.notifiedAlertTokens, token},
      lastDeliveryStatus: status,
      lastMessage: message,
      lastNotificationAt: notifiedAt,
    );
  }

  @override
  Future<void> savePreferences(
    PriceAlertNotificationPreferences preferences,
  ) async {
    this.preferences = preferences;
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    preferences = preferences.copyWith(enabled: enabled);
  }

  @override
  Future<void> updateLastStatus({
    required PriceAlertNotificationDeliveryStatus status,
    required String message,
  }) async {
    preferences = preferences.copyWith(
      lastDeliveryStatus: status,
      lastMessage: message,
    );
  }
}

class _FakeNotificationService implements PriceAlertNotificationService {
  _FakeNotificationService({required this.permissionStatus});

  PriceAlertNotificationPermissionStatus permissionStatus;
  int showCount = 0;

  @override
  Future<PriceAlertNotificationPermissionStatus> getPermissionStatus() async {
    return permissionStatus;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<PriceAlertNotificationPermissionStatus> requestPermission() async {
    return permissionStatus;
  }

  @override
  Future<PriceAlertNotificationResult> showPriceAlertNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    showCount += 1;
    return PriceAlertNotificationResult(
      status: PriceAlertNotificationDeliveryStatus.delivered,
      message: body,
      deliveredCount: 1,
    );
  }
}
