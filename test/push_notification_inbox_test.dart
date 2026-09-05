/// Every push should be findable in the app afterwards.
///
/// Only price alerts used to reach the inbox, because the app logs those
/// itself when it evaluates them. Anything else -- a broadcast, an admin
/// message, a support reply -- existed as a banner and nowhere else, so
/// dismissing it destroyed the only copy the user had.
import 'package:collectiq_ai/features/notifications/domain/entities/notification_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  NotificationEvent build({
    String messageId = 'm-1',
    String? title = 'PackLox update',
    String? body = 'Pricing sources refreshed.',
    Map<String, dynamic> data = const {},
    DateTime? sentAt,
  }) => NotificationEvent.fromPushMessage(
    messageId: messageId,
    title: title,
    body: body,
    data: data,
    sentAt: sentAt,
  );

  test('carries the notification the user actually saw', () {
    final event = build();
    expect(event.title, 'PackLox update');
    expect(event.body, 'Pricing sources refreshed.');
  });

  test('dedupes on the FCM message id', () {
    // The same push can be observed twice -- once arriving in the foreground,
    // again when tapped. It must occupy one inbox row, not two.
    expect(build(messageId: 'abc').id, build(messageId: 'abc').id);
    expect(build(messageId: 'abc').id, isNot(build(messageId: 'xyz').id));
  });

  test('keeps the deep-link target when the push carries one', () {
    expect(build(data: const {'itemId': 'item-42'}).itemId, 'item-42');
    expect(build(data: const {'item_id': 'item-7'}).itemId, 'item-7');
  });

  test('a push with no target is still recorded, just not linkable', () {
    // A broadcast has nothing to navigate to. That is exactly the case the
    // old behaviour dropped on the floor.
    expect(build().itemId, isEmpty);
  });

  test('an unknown or absent kind is generic, never guessed', () {
    // Showing a price-up arrow on an announcement would be worse than a
    // neutral icon.
    expect(build().kind, NotificationKind.generic);
    expect(build(data: const {'kind': 'nonsense'}).kind, NotificationKind.generic);
  });

  test('an explicit kind is honoured', () {
    expect(build(data: const {'kind': 'priceUp'}).kind, NotificationKind.priceUp);
    expect(build(data: const {'type': 'priceDown'}).kind, NotificationKind.priceDown);
  });

  test('a missing title falls back rather than rendering blank', () {
    expect(build(title: null).title, 'PackLox');
    expect(build(title: '   ').title, 'PackLox');
  });

  test('uses the send time when known, so ordering reflects reality', () {
    final sent = DateTime.utc(2026, 9, 5, 11, 30);
    expect(build(sentAt: sent).createdAt, sent);
  });
}
