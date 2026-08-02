import 'dart:io';

import 'package:collectiq_ai/core/cloud/cloud_storage_paths.dart';
import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_profile_sync_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_bootstrap.dart';
import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';
import 'package:path_provider/path_provider.dart';

class SupabaseCloudProfileSyncService implements CloudProfileSyncService {
  SupabaseCloudProfileSyncService({
    required this.bootstrap,
    required this.authService,
    required this.cloudStorageService,
    this.tableName = 'profiles',
    this.bucketName = 'collectiq-portfolio-images',
  });

  final SupabaseBootstrap bootstrap;
  final AuthService authService;
  final CloudStorageService cloudStorageService;
  final String tableName;
  final String bucketName;

  @override
  String get providerName => 'Supabase Profile Sync';

  Future<String?> _signedInUserId() async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized || !await authService.isSignedIn()) {
      return null;
    }
    final userId = await authService.currentUserId();
    if (userId == null || userId.trim().isEmpty) {
      return null;
    }
    return userId;
  }

  @override
  Future<void> pushProfile(
    CollectorProfile profile, {
    bool uploadAvatar = false,
  }) async {
    final userId = await _signedInUserId();
    if (userId == null) {
      return;
    }

    String? avatarStoragePath;
    if (uploadAvatar) {
      final destination = CloudStoragePaths.profileAvatar(userId: userId);
      final localAvatar = profile.avatarPath?.trim();
      if (localAvatar != null &&
          localAvatar.isNotEmpty &&
          await File(localAvatar).exists()) {
        final result = await cloudStorageService.uploadImage(
          localPath: localAvatar,
          destinationPath: destination,
        );
        avatarStoragePath = result?.path ?? destination;
      } else {
        // Profile has no avatar: clear the stored one.
        try {
          await cloudStorageService.deleteImage(destination);
        } catch (_) {}
        avatarStoragePath = null;
      }
    }

    final row = <String, dynamic>{
      'user_id': userId,
      'display_name': profile.displayName,
      'country_code': profile.countryCode,
      'preferred_currency': profile.preferredCurrency,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    if (uploadAvatar) {
      row['avatar_path'] = avatarStoragePath;
    }
    await bootstrap.client!.from(tableName).upsert(row);
  }

  @override
  Future<CloudProfileSnapshot?> fetchProfile() async {
    final userId = await _signedInUserId();
    if (userId == null) {
      return null;
    }
    final rows = await bootstrap.client!
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }
    final row = rows.first;
    final avatarPath = (row['avatar_path'] as String?)?.trim();
    String? avatarLocalPath;
    if (avatarPath != null && avatarPath.isNotEmpty) {
      avatarLocalPath = await _downloadAvatar(avatarPath);
    }
    return CloudProfileSnapshot(
      displayName: row['display_name'] as String?,
      avatarLocalPath: avatarLocalPath,
      countryCode: row['country_code'] as String?,
      preferredCurrency: row['preferred_currency'] as String?,
    );
  }

  Future<String?> _downloadAvatar(String storagePath) async {
    try {
      final bytes = await bootstrap.client!.storage
          .from(bucketName)
          .download(storagePath);
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final profileDirectory = Directory(
        '${documentsDirectory.path}${Platform.pathSeparator}packlox_profile',
      );
      await profileDirectory.create(recursive: true);
      final outputPath =
          '${profileDirectory.path}${Platform.pathSeparator}'
          'profile_avatar_cloud.jpg';
      final file = File(outputPath);
      await file.writeAsBytes(bytes, flush: true);
      return outputPath;
    } catch (_) {
      return null;
    }
  }
}
