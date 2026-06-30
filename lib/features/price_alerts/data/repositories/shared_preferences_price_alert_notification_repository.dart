import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/domain/repositories/price_alert_notification_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesPriceAlertNotificationRepository
    implements PriceAlertNotificationRepository {
  const SharedPreferencesPriceAlertNotificationRepository();

  static const _enabledKey = 'price_alert_notifications_enabled';
  static const _notifiedTokensKey = 'price_alert_notification_tokens';
  static const _lastStatusKey = 'price_alert_notification_last_status';
  static const _lastMessageKey = 'price_alert_notification_last_message';
  static const _lastNotificationAtKey =
      'price_alert_notification_last_notification_at';

  @override
  Future<PriceAlertNotificationPreferences> getPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(_enabledKey) ??
        PriceAlertNotificationPreferences.defaults.enabled;
    final tokens = prefs.getStringList(_notifiedTokensKey) ?? const <String>[];
    final lastStatus = PriceAlertNotificationDeliveryStatus.fromName(
      prefs.getString(_lastStatusKey),
    );
    final lastMessage = _optionalString(prefs.getString(_lastMessageKey));
    final lastNotificationAt = _optionalDate(
      prefs.getString(_lastNotificationAtKey),
    );

    return PriceAlertNotificationPreferences(
      enabled: enabled,
      notifiedAlertTokens: tokens.toSet(),
      lastDeliveryStatus: lastStatus,
      lastMessage: lastMessage,
      lastNotificationAt: lastNotificationAt,
    );
  }

  @override
  Future<void> savePreferences(
    PriceAlertNotificationPreferences preferences,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, preferences.enabled);
    await prefs.setStringList(
      _notifiedTokensKey,
      preferences.notifiedAlertTokens.toList()..sort(),
    );
    await prefs.setString(_lastStatusKey, preferences.lastDeliveryStatus.name);
    final lastMessage = preferences.lastMessage;
    if (lastMessage == null) {
      await prefs.remove(_lastMessageKey);
    } else {
      await prefs.setString(_lastMessageKey, lastMessage);
    }

    final lastNotificationAt = preferences.lastNotificationAt;
    if (lastNotificationAt == null) {
      await prefs.remove(_lastNotificationAtKey);
    } else {
      await prefs.setString(
        _lastNotificationAtKey,
        lastNotificationAt.toIso8601String(),
      );
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    final preferences = await getPreferences();
    await savePreferences(preferences.copyWith(enabled: enabled));
  }

  @override
  Future<void> markNotified({
    required String token,
    required String message,
    required DateTime notifiedAt,
    required PriceAlertNotificationDeliveryStatus status,
  }) async {
    final preferences = await getPreferences();
    await savePreferences(
      preferences.copyWith(
        notifiedAlertTokens: {...preferences.notifiedAlertTokens, token},
        lastDeliveryStatus: status,
        lastMessage: message,
        lastNotificationAt: notifiedAt,
      ),
    );
  }

  @override
  Future<void> updateLastStatus({
    required PriceAlertNotificationDeliveryStatus status,
    required String message,
  }) async {
    final preferences = await getPreferences();
    await savePreferences(
      preferences.copyWith(
        lastDeliveryStatus: status,
        lastMessage: message,
        clearLastNotificationAt:
            status != PriceAlertNotificationDeliveryStatus.delivered,
      ),
    );
  }

  @override
  Future<void> clearNotificationHistory() async {
    final preferences = await getPreferences();
    await savePreferences(
      preferences.copyWith(
        notifiedAlertTokens: const {},
        lastDeliveryStatus: PriceAlertNotificationDeliveryStatus.idle,
        clearLastMessage: true,
        clearLastNotificationAt: true,
      ),
    );
  }
}

String? _optionalString(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) {
    return null;
  }
  return normalized;
}

DateTime? _optionalDate(String? value) {
  if (value == null) {
    return null;
  }
  return DateTime.tryParse(value);
}
