import 'dart:async';

import 'package:collectiq_ai/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PushNotificationNavigationCoordinator {
  PushNotificationNavigationCoordinator({this.messaging});

  final FirebaseMessaging? messaging;
  StreamSubscription<RemoteMessage>? _openedSubscription;
  String? _lastHandledMessageKey;

  Future<void> start({
    required Future<void> Function(PushNotificationNavigationIntent intent)
    onIntent,
  }) async {
    await _ensureFirebaseInitialized();
    final firebaseMessaging = messaging ?? FirebaseMessaging.instance;
    final initialMessage = await firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      unawaited(_handleMessage(initialMessage, onIntent: onIntent));
    }
    _openedSubscription?.cancel();
    _openedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
      (message) => unawaited(_handleMessage(message, onIntent: onIntent)),
    );
  }

  Future<void> dispose() async {
    await _openedSubscription?.cancel();
    _openedSubscription = null;
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

enum PushNotificationNavigationTarget { portfolioItem, settings, home }

class PushNotificationNavigationIntent {
  const PushNotificationNavigationIntent._({
    required this.target,
    this.portfolioItemId,
    this.priceAlertId,
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

  const PushNotificationNavigationIntent.settings()
    : this._(target: PushNotificationNavigationTarget.settings);

  const PushNotificationNavigationIntent.home()
    : this._(target: PushNotificationNavigationTarget.home);

  final PushNotificationNavigationTarget target;
  final String? portfolioItemId;
  final String? priceAlertId;

  String get dedupeKey {
    return [target.name, portfolioItemId ?? '', priceAlertId ?? ''].join(':');
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
