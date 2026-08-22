import 'dart:async';

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
    final local = await _repository.loadProfile();
    // Local is the offline cache; when signed in with cloud sync configured the
    // cloud record is the source of truth so the profile follows the account.
    // Any cloud error (offline, table missing, cloud off) falls back to local.
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
        return _repository.saveProfile(merged);
      }
      // No cloud record yet — seed it from the local profile.
      unawaited(_pushProfile(local, uploadAvatar: true));
    } catch (_) {
      // Fall back to the local cache.
    }
    return local;
  }

  Future<void> _pushProfile(
    CollectorProfile profile, {
    bool uploadAvatar = false,
  }) async {
    try {
      await _cloudSync.pushProfile(profile, uploadAvatar: uploadAvatar);
    } catch (_) {
      // Cloud push is best-effort; the local save already succeeded.
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
