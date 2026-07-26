import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_notification_service.dart';
import 'package:collectiq_ai/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

bool _firebaseReady = false;

class MethodChannelPriceAlertNotificationService
    implements PriceAlertNotificationService {
  const MethodChannelPriceAlertNotificationService([
    this._channel = const MethodChannel('collectiq_ai/notifications'),
  ]);

  final MethodChannel _channel;

  @override
  Future<void> initialize() async {
    try {
      await _channel.invokeMethod<void>('initialize');
    } on MissingPluginException {
      // Local notification bridge is unavailable on this platform.
    }
    await _ensureFirebaseInitialized();
  }

  @override
  Future<PushNotificationToken?> getPushToken() async {
    await _ensureFirebaseInitialized();
    if (!_firebaseReady) {
      return null;
    }
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      final token = await messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        return null;
      }
      return PushNotificationToken(
        token: token,
        provider: 'fcm',
        platform: _platformLabel,
        createdAt: DateTime.now(),
      );
    } on Object {
      return null;
    }
  }

  @override
  Future<PriceAlertNotificationPermissionStatus> getPermissionStatus() async {
    try {
      final status = await _channel.invokeMethod<String>('getPermissionStatus');
      return PriceAlertNotificationPermissionStatus.fromName(status);
    } on MissingPluginException {
      return PriceAlertNotificationPermissionStatus.notSupported;
    } on PlatformException {
      return PriceAlertNotificationPermissionStatus.unknown;
    }
  }

  @override
  Future<PriceAlertNotificationPermissionStatus> requestPermission() async {
    final remotePermission = await _requestFirebasePermission();
    try {
      final status = await _channel.invokeMethod<String>('requestPermission');
      return PriceAlertNotificationPermissionStatus.fromName(status);
    } on MissingPluginException {
      return remotePermission;
    } on PlatformException {
      return PriceAlertNotificationPermissionStatus.denied;
    }
  }

  @override
  Future<PriceAlertNotificationResult> showPriceAlertNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'showPriceAlertNotification',
        {'id': id, 'title': title, 'body': body},
      );
      final status = PriceAlertNotificationDeliveryStatus.fromName(
        result?['status'] as String?,
      );
      return PriceAlertNotificationResult(
        status: status,
        message: result?['message'] as String? ?? status.label,
        deliveredCount: status == PriceAlertNotificationDeliveryStatus.delivered
            ? 1
            : 0,
      );
    } on MissingPluginException {
      return const PriceAlertNotificationResult(
        status: PriceAlertNotificationDeliveryStatus.failed,
        message: 'Local notifications are not supported on this platform.',
      );
    } on PlatformException catch (error) {
      return PriceAlertNotificationResult(
        status: PriceAlertNotificationDeliveryStatus.failed,
        message: error.message ?? 'Unable to show price alert notification.',
      );
    }
  }
}

Future<void> _ensureFirebaseInitialized() async {
  if (_firebaseReady) {
    return;
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    _firebaseReady = true;
  } on Object {
    _firebaseReady = false;
  }
}

Future<PriceAlertNotificationPermissionStatus>
_requestFirebasePermission() async {
  await _ensureFirebaseInitialized();
  if (!_firebaseReady) {
    return PriceAlertNotificationPermissionStatus.notSupported;
  }
  try {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized || AuthorizationStatus.provisional =>
        PriceAlertNotificationPermissionStatus.granted,
      AuthorizationStatus.denied =>
        PriceAlertNotificationPermissionStatus.denied,
      AuthorizationStatus.notDetermined =>
        PriceAlertNotificationPermissionStatus.unknown,
    };
  } on Object {
    return PriceAlertNotificationPermissionStatus.notSupported;
  }
}

String get _platformLabel {
  if (kIsWeb) {
    return 'web';
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.macOS => 'macos',
    TargetPlatform.windows => 'windows',
    TargetPlatform.linux => 'linux',
    TargetPlatform.fuchsia => 'fuchsia',
  };
}
