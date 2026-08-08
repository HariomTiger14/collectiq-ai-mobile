import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_notification_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_service.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_notification_controller.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/screens/price_alerts_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows an empty state when there are no alerts', (
    tester,
  ) async {
    await tester.pumpPriceAlerts(alerts: []);

    expect(find.text('No price alerts yet'), findsOneWidget);
  });

  testWidgets('lists an alert with its item, rule, and status', (
    tester,
  ) async {
    await tester.pumpPriceAlerts(
      alerts: [
        PriceAlert(
          id: 'alert-1',
          itemId: 'item-1',
          itemTitle: 'Charizard #4',
          rule: const PriceAlertRule(
            type: PriceAlertRuleType.percentageIncrease,
            percentage: 0.1,
            baselineValue: 100,
          ),
          status: PriceAlertStatus.active,
          createdAt: DateTime(2026, 8, 1),
          updatedAt: DateTime(2026, 8, 1),
        ),
      ],
    );

    expect(find.text('Charizard #4'), findsOneWidget);
    expect(find.text('Increases by 10%'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
    expect(find.text('No price alerts yet'), findsNothing);
  });

  testWidgets(
    'groups triggered alerts under Needs Attention, active under Watching',
    (tester) async {
      await tester.pumpPriceAlerts(
        alerts: [
          PriceAlert(
            id: 'alert-active',
            itemId: 'item-1',
            itemTitle: 'Charizard #4',
            rule: const PriceAlertRule(
              type: PriceAlertRuleType.percentageIncrease,
              percentage: 0.1,
              baselineValue: 100,
            ),
            status: PriceAlertStatus.active,
            createdAt: DateTime(2026, 8, 1),
            updatedAt: DateTime(2026, 8, 1),
          ),
          PriceAlert(
            id: 'alert-triggered',
            itemId: 'item-2',
            itemTitle: 'Air Force 1',
            rule: const PriceAlertRule(
              type: PriceAlertRuleType.stalePricingReminder,
              staleAfterDays: 30,
            ),
            status: PriceAlertStatus.triggered,
            createdAt: DateTime(2026, 8, 2),
            updatedAt: DateTime(2026, 8, 2),
            triggeredAt: DateTime(2026, 8, 2),
          ),
        ],
      );

      expect(find.text('Needs Attention'), findsOneWidget);
      expect(find.text('Watching'), findsOneWidget);
      expect(find.text('Charizard #4'), findsOneWidget);
      expect(find.text('Air Force 1'), findsOneWidget);
    },
  );

  testWidgets('deleting an alert removes it from the list', (tester) async {
    final repository = _FakePriceAlertRepository([
      PriceAlert(
        id: 'alert-1',
        itemId: 'item-1',
        itemTitle: 'Charizard #4',
        rule: const PriceAlertRule(
          type: PriceAlertRuleType.stalePricingReminder,
          staleAfterDays: 30,
        ),
        status: PriceAlertStatus.active,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    ]);
    await tester.pumpPriceAlerts(repository: repository);
    expect(find.text('Charizard #4'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.alerts, isEmpty);
    expect(find.text('Charizard #4'), findsNothing);
    expect(find.text('No price alerts yet'), findsOneWidget);
  });

  testWidgets('resetting a triggered alert clears its triggered state', (
    tester,
  ) async {
    final repository = _FakePriceAlertRepository([
      PriceAlert(
        id: 'alert-1',
        itemId: 'item-1',
        itemTitle: 'Charizard #4',
        rule: const PriceAlertRule(
          type: PriceAlertRuleType.percentageDecrease,
          percentage: 0.1,
          baselineValue: 100,
        ),
        status: PriceAlertStatus.triggered,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
        triggeredAt: DateTime(2026, 8, 2),
        message: 'Value dropped 12%',
      ),
    ]);
    await tester.pumpPriceAlerts(repository: repository);
    expect(find.text('Triggered'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(repository.alerts.single.status, PriceAlertStatus.active);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('a notified alert can also be reset, not just a triggered one', (
    tester,
  ) async {
    // isTriggered covers both `triggered` and the post-push `notified`
    // terminal state -- a Reset offered only for `triggered` would strand
    // notified alerts with no way back to active.
    final repository = _FakePriceAlertRepository([
      PriceAlert(
        id: 'alert-1',
        itemId: 'item-1',
        itemTitle: 'Air Force 1',
        rule: const PriceAlertRule(
          type: PriceAlertRuleType.priceRisesAboveAmount,
          amount: 200,
        ),
        status: PriceAlertStatus.notified,
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
        triggeredAt: DateTime(2026, 8, 2),
        message: 'Air Force 1 gained 101% since tracking started.',
      ),
    ]);
    await tester.pumpPriceAlerts(repository: repository);
    expect(find.text('Notified'), findsOneWidget);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(repository.alerts.single.status, PriceAlertStatus.active);
    expect(find.text('Active'), findsOneWidget);
  });
}

extension on WidgetTester {
  Future<void> pumpPriceAlerts({
    List<PriceAlert>? alerts,
    PriceAlertRepository? repository,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: [
          priceAlertRepositoryProvider.overrideWithValue(
            repository ?? _FakePriceAlertRepository(alerts ?? const []),
          ),
          priceAlertNotificationRepositoryProvider.overrideWithValue(
            _FakeNotificationRepository(),
          ),
          priceAlertNotificationServiceProvider.overrideWithValue(
            _FakeNotificationService(),
          ),
        ],
        child: const MaterialApp(home: PriceAlertsScreen()),
      ),
    );
    await pump();
    await pump(const Duration(milliseconds: 240));
  }
}

class _FakePriceAlertRepository implements PriceAlertRepository {
  _FakePriceAlertRepository(List<PriceAlert> initial)
    : alerts = List.of(initial);

  List<PriceAlert> alerts;

  @override
  Future<List<PriceAlert>> getAlerts() async => List.of(alerts);

  @override
  Future<List<PriceAlert>> getAlertsForItem(String itemId) async {
    return alerts.where((alert) => alert.itemId == itemId).toList();
  }

  @override
  Future<void> saveAlert(PriceAlert alert) async {
    alerts = [
      for (final existing in alerts)
        if (existing.id != alert.id) existing,
      alert,
    ];
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    alerts = alerts.where((alert) => alert.id != alertId).toList();
  }

  @override
  Future<void> clearAlerts() async {
    alerts = [];
  }
}

class _FakeNotificationRepository implements PriceAlertNotificationRepository {
  PriceAlertNotificationPreferences preferences =
      PriceAlertNotificationPreferences.defaults;

  @override
  Future<void> clearNotificationHistory() async {}

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
  }) async {}

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
  }) async {}
}

class _FakeNotificationService implements PriceAlertNotificationService {
  @override
  Future<PriceAlertNotificationPermissionStatus> getPermissionStatus() async {
    return PriceAlertNotificationPermissionStatus.granted;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<PushNotificationToken?> getPushToken() async => null;

  @override
  Future<PriceAlertNotificationPermissionStatus> requestPermission() async {
    return PriceAlertNotificationPermissionStatus.granted;
  }

  @override
  Future<PriceAlertNotificationResult> showPriceAlertNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    return const PriceAlertNotificationResult(
      status: PriceAlertNotificationDeliveryStatus.delivered,
      message: 'ok',
      deliveredCount: 1,
    );
  }
}
