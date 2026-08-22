import 'package:collectiq_ai/features/notifications/domain/entities/notification_event.dart';

/// UI view-model for a single inbox notification, built from a persisted
/// [NotificationEvent].
class AppNotification {
  const AppNotification({
    required this.id,
    required this.itemId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.kind,
    required this.isRead,
  });

  final String id;

  /// Portfolio item this notification points to (deep-link target).
  final String itemId;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationKind kind;
  final bool isRead;

  factory AppNotification.fromEvent(NotificationEvent event) {
    return AppNotification(
      id: event.id,
      itemId: event.itemId,
      title: event.title,
      body: event.body,
      createdAt: event.createdAt,
      kind: event.kind,
      isRead: event.isRead,
    );
  }
}
