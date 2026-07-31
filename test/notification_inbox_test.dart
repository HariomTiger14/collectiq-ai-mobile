import 'package:collectiq_ai/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePriceAlertRepository implements PriceAlertRepository {
  _FakePriceAlertRepository(this._alerts);

  final List<PriceAlert> _alerts;

  @override
  Future<List<PriceAlert>> getAlerts() async => _alerts;

  @override
  Future<List<PriceAlert>> getAlertsForItem(String itemId) async =>
      _alerts.where((a) => a.itemId == itemId).toList();

  @override
  Future<void> saveAlert(PriceAlert alert) async {}

  @override
  Future<void> deleteAlert(String alertId) async {}

  @override
  Future<void> clearAlerts() async {}
}

PriceAlert _alert({
  required String id,
  required PriceAlertStatus status,
  required DateTime triggeredAt,
}) {
  return PriceAlert(
    id: id,
    itemId: 'item-$id',
    itemTitle: 'Item $id',
    rule: const PriceAlertRule(type: PriceAlertRuleType.priceRisesAboveAmount),
    status: status,
    createdAt: triggeredAt.subtract(const Duration(days: 1)),
    updatedAt: triggeredAt,
    triggeredAt: triggeredAt,
    message: 'Alert $id',
  );
}

ProviderContainer _containerFor(List<PriceAlert> alerts) {
  final container = ProviderContainer(
    overrides: [
      priceAlertRepositoryProvider.overrideWithValue(
        _FakePriceAlertRepository(alerts),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  final now = DateTime.now();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('only triggered alerts become notifications', () async {
    final container = _containerFor([
      _alert(id: 'a', status: PriceAlertStatus.triggered, triggeredAt: now),
      _alert(
        id: 'b',
        status: PriceAlertStatus.active,
        triggeredAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);

    final inbox = await container.read(notificationInboxProvider.future);

    expect(inbox.map((n) => n.id), ['a']);
  });

  test('notifications older than the retention window are trimmed', () async {
    final container = _containerFor([
      _alert(
        id: 'recent',
        status: PriceAlertStatus.triggered,
        triggeredAt: now.subtract(const Duration(days: 2)),
      ),
      _alert(
        id: 'old',
        status: PriceAlertStatus.triggered,
        triggeredAt: now.subtract(const Duration(days: 40)),
      ),
    ]);

    final inbox = await container.read(notificationInboxProvider.future);

    expect(inbox.map((n) => n.id), ['recent']);
  });

  test('dismissed notifications are excluded', () async {
    final triggeredAt = now.subtract(const Duration(hours: 3));
    final dismissKey = 'gone@${triggeredAt.toIso8601String()}';
    SharedPreferences.setMockInitialValues({
      'notifications_dismissed_keys': [dismissKey],
    });

    final container = _containerFor([
      _alert(
        id: 'gone',
        status: PriceAlertStatus.triggered,
        triggeredAt: triggeredAt,
      ),
      _alert(
        id: 'kept',
        status: PriceAlertStatus.triggered,
        triggeredAt: now.subtract(const Duration(hours: 1)),
      ),
    ]);

    final inbox = await container.read(notificationInboxProvider.future);

    expect(inbox.map((n) => n.id), ['kept']);
  });

  test('unread count reflects notifications newer than last seen', () async {
    final container = _containerFor([
      _alert(
        id: 'new',
        status: PriceAlertStatus.triggered,
        triggeredAt: now.subtract(const Duration(minutes: 5)),
      ),
      _alert(
        id: 'seen',
        status: PriceAlertStatus.triggered,
        triggeredAt: now.subtract(const Duration(hours: 10)),
      ),
    ]);
    await container
        .read(notificationSeenStoreProvider)
        .markSeen(now.subtract(const Duration(hours: 1)));

    final unread = await container.read(unreadNotificationCountProvider.future);

    expect(unread, 1);
  });
}
