import 'package:collectiq_ai/features/notifications/data/notification_event_store.dart';
import 'package:collectiq_ai/features/notifications/domain/entities/notification_event.dart';
import 'package:collectiq_ai/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

NotificationEvent _event({
  required String id,
  required DateTime createdAt,
  DateTime? readAt,
}) {
  return NotificationEvent(
    id: id,
    itemId: 'item-$id',
    title: 'Item $id',
    body: 'Body $id',
    createdAt: createdAt,
    kind: NotificationKind.priceUp,
    readAt: readAt,
  );
}

ProviderContainer _container() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  final now = DateTime.now();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('append dedupes by id and delete removes', () async {
    const store = NotificationEventStore();
    await store.append(_event(id: 'a', createdAt: now));
    await store.append(_event(id: 'a', createdAt: now)); // duplicate
    await store.append(
      _event(id: 'b', createdAt: now.subtract(const Duration(hours: 1))),
    );

    expect((await store.all()).map((e) => e.id).toSet(), {'a', 'b'});

    await store.delete(['a']);
    expect((await store.all()).map((e) => e.id), ['b']);
  });

  test('inbox is newest-first and trims the retention window', () async {
    const store = NotificationEventStore();
    await store.append(
      _event(id: 'recent', createdAt: now.subtract(const Duration(days: 2))),
    );
    await store.append(
      _event(id: 'older', createdAt: now.subtract(const Duration(hours: 3))),
    );
    await store.append(
      _event(id: 'expired', createdAt: now.subtract(const Duration(days: 40))),
    );

    final inbox = await _container().read(notificationInboxProvider.future);

    expect(inbox.map((n) => n.id), ['older', 'recent']);
  });

  test('unread count reflects events without a readAt', () async {
    const store = NotificationEventStore();
    await store.append(_event(id: 'unread', createdAt: now));
    await store.append(
      _event(
        id: 'read',
        createdAt: now.subtract(const Duration(hours: 2)),
        readAt: now,
      ),
    );

    final unread = await _container().read(
      unreadNotificationCountProvider.future,
    );

    expect(unread, 1);
  });

  test('markRead clears unread', () async {
    const store = NotificationEventStore();
    await store.append(_event(id: 'x', createdAt: now));
    await store.append(
      _event(id: 'y', createdAt: now.subtract(const Duration(minutes: 5))),
    );

    await store.markRead(['x', 'y'], now);

    final unread = await _container().read(
      unreadNotificationCountProvider.future,
    );
    expect(unread, 0);
  });
}
