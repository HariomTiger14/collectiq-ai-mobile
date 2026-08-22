import 'package:collectiq_ai/features/notifications/data/notification_event_store.dart';
import 'package:collectiq_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:collectiq_ai/features/notifications/domain/entities/notification_event.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rolling-window bounds so the inbox stays tidy on its own.
const notificationRetention = Duration(days: 30);
const notificationMaxVisible = 50;

final notificationEventStoreProvider = Provider<NotificationEventStore>((ref) {
  return const NotificationEventStore();
});

List<NotificationEvent> _visibleEvents(List<NotificationEvent> events) {
  final cutoff = DateTime.now().subtract(notificationRetention);
  final visible =
      events.where((e) => e.createdAt.isAfter(cutoff)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return visible.length > notificationMaxVisible
      ? visible.sublist(0, notificationMaxVisible)
      : visible;
}

/// Visible notifications, newest first, trimmed to the rolling window.
final notificationInboxProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
      final events = await ref.watch(notificationEventStoreProvider).all();
      return _visibleEvents(events).map(AppNotification.fromEvent).toList();
    });

/// Unread count (per-event, within the rolling window) — drives the bell badge.
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final events = await ref.watch(notificationEventStoreProvider).all();
  return _visibleEvents(events).where((e) => !e.isRead).length;
});
