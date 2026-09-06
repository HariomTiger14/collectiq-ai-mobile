import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_profile_sync_service.dart';
import 'package:collectiq_ai/features/profile/data/repositories/shared_preferences_profile_repository.dart';
import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';
import 'package:collectiq_ai/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return const SharedPreferencesProfileRepository();
});

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, CollectorProfile>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<CollectorProfile> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  CloudProfileSyncService get _cloudSync =>
      ref.read(cloudServiceRegistryProvider).cloudProfileSyncService;

  @override
  Future<CollectorProfile> build() async {
    // Resolve on the local cache alone and let the cloud land after.
    //
    // Awaiting the cloud fetch here left the whole app without a profile for
    // as long as that network call took, and every reader of
    // displayCurrencyProvider fell back to its 'AUD' default meanwhile — so a
    // collector who reads in USD watched Home render in AUD and then switch.
    // The local cache already holds the currency they picked, so serve that
    // immediately; the cloud record still wins, just a moment later instead
    // of holding up the first frame.
    final local = await _repository.loadProfile();
    unawaited(_mergeCloudProfile(local));
    return local;
  }

  /// Merges the cloud record over the local cache in the background.
  ///
  /// The cloud stays the source of truth when signed in with cloud sync
  /// configured, so the profile follows the account; any cloud error
  /// (offline, table missing, cloud off) leaves the local cache in place.
  Future<void> _mergeCloudProfile(CollectorProfile local) async {
    try {
      final cloud = await _cloudSync.fetchProfile();
      if (cloud != null && !cloud.isEmpty) {
        final merged = CollectorProfile(
          displayName: (cloud.displayName?.trim().isNotEmpty ?? false)
              ? cloud.displayName!.trim()
              : local.displayName,
          avatarPath: cloud.avatarLocalPath ?? local.avatarPath,
          countryCode: (cloud.countryCode?.trim().isNotEmpty ?? false)
              ? cloud.countryCode!
              : local.countryCode,
          preferredCurrency:
              (cloud.preferredCurrency?.trim().isNotEmpty ?? false)
              ? cloud.preferredCurrency!
              : local.preferredCurrency,
        );
        state = AsyncValue.data(await _repository.saveProfile(merged));
        return;
      }
      // No cloud record yet — seed it from the local profile.
      unawaited(_pushProfile(local, uploadAvatar: true));
    } catch (error) {
      // Fall back to the local cache — but say why in the log. This path
      // swallowed a schema mismatch for weeks (collector_profiles empty in
      // production while the UI looked synced); silent catches hide
      // exactly the failures this sync exists to prevent.
      debugPrint('[ProfileSync] cloud fetch failed, using local cache: $error');
    }
  }

  Future<void> _pushProfile(
    CollectorProfile profile, {
    bool uploadAvatar = false,
  }) async {
    try {
      await _cloudSync.pushProfile(profile, uploadAvatar: uploadAvatar);
      debugPrint('[ProfileSync] profile pushed (uploadAvatar: $uploadAvatar)');
    } catch (error) {
      // Cloud push is best-effort; the local save already succeeded. But
      // best-effort must not mean invisible -- see build()'s catch.
      debugPrint('[ProfileSync] profile push FAILED: $error');
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    final current = state.hasValue
        ? state.requireValue
        : await _repository.loadProfile();
    final saved = await _repository.saveProfile(
      current.copyWith(displayName: displayName),
    );
    state = AsyncValue.data(saved);
    unawaited(_pushProfile(saved));
  }

  Future<void> updateAvatar(String sourcePath) async {
    final saved = await _repository.saveAvatarFromPath(sourcePath);
    state = AsyncValue.data(saved);
    unawaited(_pushProfile(saved, uploadAvatar: true));
  }

  Future<void> removeAvatar() async {
    final current = state.hasValue
        ? state.requireValue
        : await _repository.loadProfile();
    // Empty avatarPath is treated as "no avatar" and cleared by the repository.
    final saved = await _repository.saveProfile(current.copyWith(avatarPath: ''));
    state = AsyncValue.data(saved);
    unawaited(_pushProfile(saved, uploadAvatar: true));
  }

  /// Sets the currency the collector reads prices in, without touching their
  /// country.
  ///
  /// Settings' "Country & Currency" picker sets both together, which is right
  /// for that screen. The Home selector is only about how prices are read --
  /// living in Australia and reading in USD is a legitimate combination, and
  /// silently relocating someone because they glanced at USD is not.
  Future<void> updatePreferredCurrency(String currencyCode) async {
    final current = state.hasValue
        ? state.requireValue
        : await _repository.loadProfile();
    final normalized = CollectorProfile.normalizeCurrency(currencyCode);
    if (normalized == current.preferredCurrency) {
      return;
    }
    final saved = await _repository.saveProfile(
      current.copyWith(preferredCurrency: normalized),
    );
    state = AsyncValue.data(saved);
    unawaited(_pushProfile(saved));
  }

  Future<void> updateCountry(String countryCode) async {
    final current = state.hasValue
        ? state.requireValue
        : await _repository.loadProfile();
    final normalizedCountry = CollectorProfile.normalizeCountryCode(
      countryCode,
    );
    final saved = await _repository.saveProfile(
      current.copyWith(
        countryCode: normalizedCountry,
        preferredCurrency: CollectorProfile.currencyForCountry(
          normalizedCountry,
        ),
      ),
    );
    state = AsyncValue.data(saved);
    unawaited(_pushProfile(saved));
  }
}
