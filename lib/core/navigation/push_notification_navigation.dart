import 'dart:async';

import 'package:collectiq_ai/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationNavigationCoordinator {
  PushNotificationNavigationCoordinator({this.messaging});

  final FirebaseMessaging? messaging;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  String? _lastHandledMessageKey;

  /// [onReceived] is called for every push this app observes, so the inbox can
  /// keep a copy. Separate from [onIntent], which only fires for messages that
  /// carry a navigation target -- a broadcast has nothing to navigate to but
  /// still belongs in the inbox.
  Future<void> start({
    required Future<void> Function(PushNotificationNavigationIntent intent)
    onIntent,
    Future<void> Function(RemoteMessage message)? onReceived,
  }) async {
    await _ensureFirebaseInitialized();
    final firebaseMessaging = messaging ?? FirebaseMessaging.instance;
    final initialMessage = await firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(onReceived?.call(initialMessage));
      unawaited(_handleMessage(initialMessage, onIntent: onIntent));
    }
    _openedSubscription?.cancel();
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(onReceived?.call(message));
      unawaited(_handleMessage(message, onIntent: onIntent));
    });
    // Foreground arrivals. iOS shows no banner while the app is open and this
    // stream is the only signal that a push landed at all -- without it, a
    // user actively using PackLox sees nothing whatsoever.
    _foregroundSubscription?.cancel();
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      unawaited(onReceived?.call(message));
    });
  }

  Future<void> dispose() async {
    await _openedSubscription?.cancel();
    _openedSubscription = null;
    await _foregroundSubscription?.cancel();
    _foregroundSubscription = null;
  }

  Future<void> _handleMessage(
    RemoteMessage message, {
    required Future<void> Function(PushNotificationNavigationIntent intent)
    onIntent,
  }) async {
    final intent = pushNotificationNavigationIntentFromData(message.data);
    if (intent == null) {
      return;
    }
    final messageKey = message.messageId ?? intent.dedupeKey;
    if (messageKey == _lastHandledMessageKey) {
      return;
    }
    _lastHandledMessageKey = messageKey;
    await onIntent(intent);
  }
}

Future<void> _ensureFirebaseInitialized() async {
  if (Firebase.apps.isNotEmpty) {
    return;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

enum PushNotificationNavigationTarget {
  portfolioItem,
  settings,
  home,
  supportTicket,
}

class PushNotificationNavigationIntent {
  const PushNotificationNavigationIntent._({
    required this.target,
    this.portfolioItemId,
    this.priceAlertId,
    this.ticketId,
  });

  factory PushNotificationNavigationIntent.portfolioItem({
    required String portfolioItemId,
    String? priceAlertId,
  }) {
    return PushNotificationNavigationIntent._(
      target: PushNotificationNavigationTarget.portfolioItem,
      portfolioItemId: portfolioItemId,
      priceAlertId: priceAlertId,
    );
  }

  factory PushNotificationNavigationIntent.supportTicket({
    required String ticketId,
  }) {
    return PushNotificationNavigationIntent._(
      target: PushNotificationNavigationTarget.supportTicket,
      ticketId: ticketId,
    );
  }

  const PushNotificationNavigationIntent.settings()
    : this._(target: PushNotificationNavigationTarget.settings);

  const PushNotificationNavigationIntent.home()
    : this._(target: PushNotificationNavigationTarget.home);

  final PushNotificationNavigationTarget target;
  final String? portfolioItemId;
  final String? priceAlertId;
  final String? ticketId;

  String get dedupeKey {
    return [
      target.name,
      portfolioItemId ?? '',
      priceAlertId ?? '',
      ticketId ?? '',
    ].join(':');
  }
}

PushNotificationNavigationIntent? pushNotificationNavigationIntentFromData(
  Map<String, dynamic> data,
) {
  final type = _string(data['type']);
  switch (type) {
    case 'price_alert':
      final portfolioItemId = _string(data['portfolioItemId']);
      if (portfolioItemId == null || portfolioItemId.isEmpty) {
        return const PushNotificationNavigationIntent.home();
      }
      return PushNotificationNavigationIntent.portfolioItem(
        portfolioItemId: portfolioItemId,
        priceAlertId: _string(data['priceAlertId']),
      );
    case 'support_ticket_reply':
    case 'support_ticket_resolved':
      final ticketId = _string(data['ticketId']);
      if (ticketId == null || ticketId.isEmpty) {
        return const PushNotificationNavigationIntent.settings();
      }
      return PushNotificationNavigationIntent.supportTicket(
        ticketId: ticketId,
      );
    case 'test_push':
      return const PushNotificationNavigationIntent.settings();
    default:
      return null;
  }
}

String? _string(Object? value) {
  if (value is String) {
    return value.trim();
  }
  return null;
}
