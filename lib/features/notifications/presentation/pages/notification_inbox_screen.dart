import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/notifications/domain/entities/app_notification.dart';
import 'package:collectiq_ai/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Inbox of event-shaped notifications (triggered price alerts). Each row
/// deep-links to the relevant item's detail page.
class NotificationInboxScreen extends ConsumerStatefulWidget {
  const NotificationInboxScreen({super.key});

  @override
  ConsumerState<NotificationInboxScreen> createState() =>
      _NotificationInboxScreenState();
}

class _NotificationInboxScreenState
    extends ConsumerState<NotificationInboxScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the inbox clears the unread badge.
    WidgetsBinding.instance.addPostFrameCallback((_) => _markSeen());
  }

  Future<void> _markSeen() async {
    await ref.read(notificationSeenStoreProvider).markSeen(DateTime.now());
    if (!mounted) {
      return;
    }
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
        ),
        body: inbox.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => _InboxMessage(
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
              itemBuilder: (_, index) => _NotificationRow(
                notification: notifications[index],
                onTap: () => _openItem(notifications[index]),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final (icon, color) = _visualFor(notification.kind);
    return Material(
      color: HomeTokens.surface,
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
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              color: HomeTokens.textPrimary,
                              fontWeight: FontWeight.w800,
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
              const Icon(
                Icons.chevron_right,
                color: HomeTokens.textSecondary,
              ),
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
