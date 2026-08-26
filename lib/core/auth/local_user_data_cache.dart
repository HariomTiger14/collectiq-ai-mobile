import 'package:shared_preferences/shared_preferences.dart';

/// Keys holding a signed-in user's own data in on-device SharedPreferences.
///
/// None of these keys are namespaced by user id, so on a shared device a
/// second account signing in after a sign-out would otherwise still see the
/// previous account's cached portfolio, wishlist, alerts, and profile.
/// [clearLocalUserData] wipes exactly these keys -- never anything on the
/// server -- so it's safe to call unconditionally on sign-out.
const localUserDataCacheKeys = <String>[
  'portfolio_items',
  'portfolio_value_history_snapshots',
  'wishlist_status_entries',
  'price_alerts',
  'price_alert_notifications_enabled',
  'price_alert_notification_tokens',
  'price_alert_notification_last_status',
  'price_alert_notification_last_message',
  'packlox.profile.display_name',
  'packlox.profile.avatar_path',
  'packlox.profile.country_code',
  'packlox.profile.preferred_currency',
  'image_upload_tasks',
  'image_upload_last_sync_at',
  'subscription_active_plan',
  'subscription_scan_month',
  'subscription_scans_used_month',
  'subscription_price_refresh_month',
];

Future<void> clearLocalUserData() async {
  final preferences = await SharedPreferences.getInstance();
  for (final key in localUserDataCacheKeys) {
    await preferences.remove(key);
  }
}
