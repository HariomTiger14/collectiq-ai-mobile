import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';

/// Visual grouping for a notification, driving its icon and tone.
enum NotificationKind {
  priceUp,
  priceDown,
  stale,
  generic;

  static NotificationKind fromName(String? value) {
    for (final kind in NotificationKind.values) {
      if (kind.name == value) {
        return kind;
      }
    }
    return NotificationKind.generic;
  }
}

/// A persisted, append-once notification *event* — one row per trigger. Unlike
/// deriving the inbox from currently-triggered alerts, the log keeps history
/// even after an alert re-arms, and carries per-event read state.
class NotificationEvent {
  const NotificationEvent({
    required this.id,
    required this.itemId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.kind,
    this.readAt,
  });

  /// Stable per-trigger id (`alertId@timestamp`) — the dedupe + delete key.
  final String id;

  /// Portfolio item this event points to (deep-link target).
  final String itemId;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationKind kind;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  NotificationEvent copyWith({DateTime? readAt}) {
    return NotificationEvent(
      id: id,
      itemId: itemId,
      title: title,
      body: body,
      createdAt: createdAt,
      kind: kind,
      readAt: readAt ?? this.readAt,
    );
  }

  /// Builds an inbox entry from an incoming push.
  ///
  /// Every push is something PackLox told the user, so it should be findable
  /// afterwards. Before this, only price alerts reached the inbox -- a
  /// broadcast or an admin message existed as a banner and nowhere else, so
  /// dismissing it destroyed the only copy.
  ///
  /// Dedupes on the FCM message id, so a push that arrives in the foreground
  /// and is then tapped logs once, not twice.
  factory NotificationEvent.fromPushMessage({
    required String messageId,
    required String? title,
    required String? body,
    required Map<String, dynamic> data,
    DateTime? sentAt,
  }) {
    final itemId = (data['itemId'] ?? data['item_id'] ?? '').toString();
    return NotificationEvent(
      id: 'push@$messageId',
      itemId: itemId,
      title: (title ?? '').trim().isEmpty ? 'PackLox' : title!.trim(),
      body: (body ?? '').trim(),
      createdAt: sentAt ?? DateTime.now(),
      // A push carrying no explicit kind is generic rather than guessed at --
      // a wrong price-direction icon is worse than a neutral one.
      kind: NotificationKind.fromName(
        (data['kind'] ?? data['type'] ?? '').toString(),
      ),
    );
  }

  factory NotificationEvent.fromPriceAlert(PriceAlert alert) {
    final createdAt = alert.triggeredAt ?? alert.updatedAt;
    final kind = switch (alert.rule.type) {
      PriceAlertRuleType.priceRisesAboveAmount ||
      PriceAlertRuleType.percentageIncrease => NotificationKind.priceUp,
      PriceAlertRuleType.priceDropsBelowAmount ||
      PriceAlertRuleType.percentageDecrease => NotificationKind.priceDown,
      PriceAlertRuleType.stalePricingReminder => NotificationKind.stale,
    };
    return NotificationEvent(
      id: '${alert.id}@${createdAt.toIso8601String()}',
      itemId: alert.itemId,
      title: alert.itemTitle,
      body: (alert.message != null && alert.message!.trim().isNotEmpty)
          ? alert.message!
          : _defaultBody(alert.rule.type),
      createdAt: createdAt,
      kind: kind,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'title': title,
      'body': body,
      'createdAt': createdAt.toIso8601String(),
      'kind': kind.name,
      'readAt': readAt?.toIso8601String(),
    };
  }

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      id: json['id'] as String? ?? '',
      itemId: json['itemId'] as String? ?? '',
      title: json['title'] as String? ?? 'Collectible',
      body: json['body'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      kind: NotificationKind.fromName(json['kind'] as String?),
      readAt: json['readAt'] is String
          ? DateTime.tryParse(json['readAt'] as String)
          : null,
    );
  }

  static String _defaultBody(PriceAlertRuleType type) {
    return switch (type) {
      PriceAlertRuleType.priceRisesAboveAmount =>
        'Price rose above your target.',
      PriceAlertRuleType.priceDropsBelowAmount =>
        'Price dropped below your target.',
      PriceAlertRuleType.percentageIncrease =>
        'Value climbed past your alert threshold.',
      PriceAlertRuleType.percentageDecrease =>
        'Value fell past your alert threshold.',
      PriceAlertRuleType.stalePricingReminder =>
        'Pricing looks stale — refresh to keep the value accurate.',
    };
  }
}
