import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';

/// Visual grouping for a notification, driving its icon and tone.
enum NotificationKind { priceUp, priceDown, stale, generic }

/// A single, event-shaped notification shown in the inbox.
///
/// Today these are derived from triggered [PriceAlert]s, but the shape is
/// deliberately alert-agnostic so future event sources (valuation-ready,
/// portfolio milestones, …) can map into the same inbox.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.itemId,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.kind,
  });

  final String id;

  /// Portfolio item this notification points to (deep-link target).
  final String itemId;
  final String title;
  final String body;
  final DateTime createdAt;
  final NotificationKind kind;

  factory AppNotification.fromPriceAlert(PriceAlert alert) {
    final kind = switch (alert.rule.type) {
      PriceAlertRuleType.priceRisesAboveAmount ||
      PriceAlertRuleType.percentageIncrease => NotificationKind.priceUp,
      PriceAlertRuleType.priceDropsBelowAmount ||
      PriceAlertRuleType.percentageDecrease => NotificationKind.priceDown,
      PriceAlertRuleType.stalePricingReminder => NotificationKind.stale,
    };
    return AppNotification(
      id: alert.id,
      itemId: alert.itemId,
      title: alert.itemTitle,
      body: (alert.message != null && alert.message!.trim().isNotEmpty)
          ? alert.message!
          : _defaultBody(alert.rule.type),
      createdAt: alert.triggeredAt ?? alert.updatedAt,
      kind: kind,
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
