import 'package:collectiq_ai/features/notifications/data/notification_seen_store.dart';
import 'package:collectiq_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rolling-window bounds so the inbox stays tidy on its own.
const notificationRetention = Duration(days: 30);
const notificationMaxVisible = 50;

final notificationSeenStoreProvider = Provider<NotificationSeenStore>((ref) {
  return const NotificationSeenStore();
});

/// Visible notifications (triggered price alerts), newest first, with dismissed
/// events removed and trimmed to the rolling window.
final notificationInboxProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
      final repository = ref.watch(priceAlertRepositoryProvider);
      final dismissed = await ref
          .watch(notificationSeenStoreProvider)
          .dismissedKeys();
      final cutoff = DateTime.now().subtract(notificationRetention);

      final alerts = await repository.getAlerts();
      final notifications =
          alerts
              .where((alert) => alert.isTriggered)
              .map(AppNotification.fromPriceAlert)
              .where((n) => !dismissed.contains(n.dismissKey))
              .where((n) => n.createdAt.isAfter(cutoff))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications.length > notificationMaxVisible
          ? notifications.sublist(0, notificationMaxVisible)
          : notifications;
    });

/// Number of visible notifications newer than the last inbox visit — drives the
/// bell badge. Returns the full count when the inbox has never been opened.
final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final notifications = await ref.watch(notificationInboxProvider.future);
  if (notifications.isEmpty) {
    return 0;
  }
  final lastSeen = await ref.watch(notificationSeenStoreProvider).lastSeenAt();
  if (lastSeen == null) {
    return notifications.length;
  }
  return notifications.where((n) => n.createdAt.isAfter(lastSeen)).length;
});
