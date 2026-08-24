import 'package:collectiq_ai/core/navigation/push_notification_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pushNotificationNavigationIntentFromData', () {
    test('routes price alert payloads to portfolio item detail', () {
      final intent = pushNotificationNavigationIntentFromData({
        'type': 'price_alert',
        'portfolioItemId': 'item-123',
        'priceAlertId': 'alert-456',
      });

      expect(intent, isNotNull);
      expect(intent!.target, PushNotificationNavigationTarget.portfolioItem);
      expect(intent.portfolioItemId, 'item-123');
      expect(intent.priceAlertId, 'alert-456');
    });

    test('routes test pushes to settings', () {
      final intent = pushNotificationNavigationIntentFromData({
        'type': 'test_push',
      });

      expect(intent, isNotNull);
      expect(intent!.target, PushNotificationNavigationTarget.settings);
    });

    test('ignores unknown push payloads', () {
      final intent = pushNotificationNavigationIntentFromData({
        'type': 'marketing_push',
      });

      expect(intent, isNull);
    });

    test('falls back home for price alert without item id', () {
      final intent = pushNotificationNavigationIntentFromData({
        'type': 'price_alert',
      });

      expect(intent, isNotNull);
      expect(intent!.target, PushNotificationNavigationTarget.home);
    });

    test('routes a support ticket reply push to the ticket thread', () {
      final intent = pushNotificationNavigationIntentFromData({
        'type': 'support_ticket_reply',
        'ticketId': 'ticket-123',
      });

      expect(intent, isNotNull);
      expect(intent!.target, PushNotificationNavigationTarget.supportTicket);
      expect(intent.ticketId, 'ticket-123');
    });

    test(
      'routes a support ticket resolved push to the ticket thread too '
      '(real gap found live: the backend added a new "resolved" push kind '
      'alongside the existing "reply" one, but this switch only handled '
      '"reply" -- tapping a resolved-ticket notification would have '
      'silently gone nowhere)',
      () {
        final intent = pushNotificationNavigationIntentFromData({
          'type': 'support_ticket_resolved',
          'ticketId': 'ticket-123',
        });

        expect(intent, isNotNull);
        expect(intent!.target, PushNotificationNavigationTarget.supportTicket);
        expect(intent.ticketId, 'ticket-123');
      },
    );

    test('falls back to settings for a resolved push without a ticket id', () {
      final intent = pushNotificationNavigationIntentFromData({
        'type': 'support_ticket_resolved',
      });

      expect(intent, isNotNull);
      expect(intent!.target, PushNotificationNavigationTarget.settings);
    });
  });
}
