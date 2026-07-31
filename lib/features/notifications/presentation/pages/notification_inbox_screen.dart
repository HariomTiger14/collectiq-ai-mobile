import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:collectiq_ai/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inbox of event-shaped notifications (triggered price alerts). Each row
/// deep-links to the relevant item's detail page. The list is a rolling window
/// (see [notificationInboxProvider]) with swipe-to-dismiss and Clear all.
class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen> {
  // Captured before we mark the inbox seen, so this visit still shows which
  // notifications are new (unread) since the previous visit.
  DateTime? _lastSeen;
  bool _seenCaptured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureThenMarkSeen());
  }

  Future<void> _captureThenMarkSeen() async {
    final store = ref.read(notificationSeenStoreProvider);
    final last = await store.lastSeenAt();
    if (!mounted) {
      return;
    }
    setState(() {
      _lastSeen = last;
      _seenCaptured = true;
    });
    // Opening the inbox clears the unread badge for next time.
    await store.markSeen(DateTime.now());
    if (!mounted) {
      return;
    }
    ref.invalidate(unreadNotificationCountProvider);
  }

  bool _isUnread(AppNotification n) {
    if (!_seenCaptured) {
      return false;
    }
    return _lastSeen == null || n.createdAt.isAfter(_lastSeen!);
  }

  Future<void> _dismiss(Iterable<String> keys) async {
    await ref.read(notificationSeenStoreProvider).dismiss(keys);
    if (!mounted) {
      return;
    }
    ref.invalidate(notificationInboxProvider);
    ref.invalidate(unreadNotificationCountProvider);
  }

  void _openItem(AppNotification notification) {
    final item = ref
        .read(portfolioControllerProvider)
        .items
        .where((candidate) => candidate.id == notification.itemId)
        .firstOrNull;
    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That item is no longer in your collection.'),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectibleDetailPage(item: item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inbox = ref.watch(notificationInboxProvider);
    final items = inbox.asData?.value ?? const <AppNotification>[];
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        key: const ValueKey('notification-inbox-screen'),
        backgroundColor: HomeTokens.background,
        appBar: AppBar(
          backgroundColor: HomeTokens.background,
          foregroundColor: HomeTokens.textPrimary,
          elevation: 0,
          title: const Text(
            'Notifications',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          actions: [
            if (items.isNotEmpty)
              TextButton(
                key: const ValueKey('notification-clear-all'),
                onPressed: () => _dismiss(items.map((n) => n.dismissKey)),
                child: const Text(
                  'Clear all',
                  style: TextStyle(
                    color: HomeTokens.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        body: inbox.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const _InboxMessage(
            icon: Icons.cloud_off_rounded,
            title: 'Couldn\'t load notifications',
            body: 'Check your connection and try again.',
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return const _InboxMessage(
                icon: Icons.notifications_none_rounded,
                title: 'You\'re all caught up',
                body:
                    'Price-alert notifications for your items will show up here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, index) {
                final notification = notifications[index];
                return Dismissible(
                  key: ValueKey('notification-${notification.dismissKey}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _dismiss([notification.dismissKey]),
                  background: const _DismissBackground(),
                  child: _NotificationRow(
                    notification: notification,
                    unread: _isUnread(notification),
                    onTap: () => _openItem(notification),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _DismissBackground extends StatelessWidget {
  const _DismissBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: HomeTokens.negative.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
      ),
      child: const Icon(Icons.close_rounded, color: HomeTokens.negative),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.notification,
    required this.unread,
    required this.onTap,
  });

  final AppNotification notification;
  final bool unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, color) = _visualFor(notification.kind);
    return Material(
      color: unread ? HomeTokens.surfaceRaised : HomeTokens.surface,
      borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(HomeTokens.controlRadius),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (unread)
                          Container(
                            key: const ValueKey('notification-unread-dot'),
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: HomeTokens.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              color: unread
                                  ? HomeTokens.textPrimary
                                  : HomeTokens.textSecondary,
                              fontWeight: unread
                                  ? FontWeight.w800
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(notification.createdAt),
                          style: textTheme.labelSmall?.copyWith(
                            color: HomeTokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: textTheme.bodySmall?.copyWith(
                        color: HomeTokens.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right, color: HomeTokens.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  (IconData, Color) _visualFor(NotificationKind kind) {
    return switch (kind) {
      NotificationKind.priceUp => (
        Icons.trending_up_rounded,
        HomeTokens.positive,
      ),
      NotificationKind.priceDown => (
        Icons.trending_down_rounded,
        HomeTokens.negative,
      ),
      NotificationKind.stale => (Icons.schedule_rounded, HomeTokens.warning),
      NotificationKind.generic => (
        Icons.notifications_none_rounded,
        HomeTokens.accent,
      ),
    };
  }
}

String _relativeTime(DateTime at) {
  final delta = DateTime.now().difference(at);
  if (delta.inMinutes < 1) {
    return 'now';
  }
  if (delta.inMinutes < 60) {
    return '${delta.inMinutes}m';
  }
  if (delta.inHours < 24) {
    return '${delta.inHours}h';
  }
  if (delta.inDays < 7) {
    return '${delta.inDays}d';
  }
  return '${delta.inDays ~/ 7}w';
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: HomeTokens.textMuted, size: 44),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: HomeTokens.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: HomeTokens.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
