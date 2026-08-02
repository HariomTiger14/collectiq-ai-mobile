import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';

/// Cloud copy of a collector profile, with the avatar already downloaded to a
/// local file path so the UI can render it with `Image.file` like the
/// device-local avatar.
class CloudProfileSnapshot {
  const CloudProfileSnapshot({
    this.displayName,
    this.avatarLocalPath,
    this.countryCode,
    this.preferredCurrency,
  });

  final String? displayName;
  final String? avatarLocalPath;
  final String? countryCode;
  final String? preferredCurrency;

  bool get isEmpty =>
      (displayName == null || displayName!.trim().isEmpty) &&
      (avatarLocalPath == null || avatarLocalPath!.trim().isEmpty) &&
      (countryCode == null || countryCode!.trim().isEmpty) &&
      (preferredCurrency == null || preferredCurrency!.trim().isEmpty);
}

/// Syncs the collector profile (display name + avatar + country/currency) to the
/// authenticated user's cloud record so it follows the account across devices.
/// Device-local storage remains the offline cache.
abstract interface class CloudProfileSyncService {
  String get providerName;

  /// Upserts the user's profile row. When [uploadAvatar] is true, also
  /// (re)uploads the profile's local avatar file, or clears the stored avatar
  /// when the profile has none.
  Future<void> pushProfile(
    CollectorProfile profile, {
    bool uploadAvatar = false,
  });

  /// Fetches the user's cloud profile (downloading the avatar to a local file),
  /// or null when there is no cloud record / not signed in.
  Future<CloudProfileSnapshot?> fetchProfile();
}
