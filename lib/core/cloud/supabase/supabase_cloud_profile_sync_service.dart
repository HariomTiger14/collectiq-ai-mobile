import 'dart:io';

import 'package:collectiq_ai/core/cloud/cloud_storage_paths.dart';
import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_profile_sync_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_bootstrap.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class SupabaseCloudProfileSyncService implements CloudProfileSyncService {
  SupabaseCloudProfileSyncService({
    required this.bootstrap,
    required this.authService,
    required this.cloudStorageService,
    this.supabaseDataGateway,
    this.tableName = 'collector_profiles',
    this.bucketName = 'collectiq-portfolio-images',
  });

  final SupabaseBootstrap bootstrap;
  final AuthService authService;
  final CloudStorageService cloudStorageService;
  final SupabaseDataGateway? supabaseDataGateway;
  final String tableName;
  final String bucketName;

  @override
  String get providerName => 'Supabase Profile Sync';

  // The app's normal sign-in path lives in its OWN auth gateway (real
  // OAuth refresh tokens -- see the stale-JWT session work), which means
  // bootstrap.client's built-in auth usually holds NO session. Every
  // request made through bootstrap.client.from() then goes out anon-only,
  // auth.uid() is NULL, and collector_profiles' RLS correctly refuses the
  // write with 42501 -- which is exactly why this table sat empty in
  // production while the UI looked synced. The portfolio and storage
  // services already learned this lesson and carry a gateway-session
  // path; this service now does the same, with bootstrap.client kept
  // only as the fallback for a session-full supabase client.
  Future<SupabaseAuthSession?> _signedInRestSession() async {
    final gateway = supabaseDataGateway;
    if (gateway == null || !gateway.isConfigured) {
      return null;
    }
    final session = await gateway.currentSession();
    if (session == null || session.isAnonymous) {
      return null;
    }
    return session;
  }

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
    final gateway = supabaseDataGateway;
    final session = await _signedInRestSession();
    if (gateway != null && session != null) {
      await gateway.authenticatedPostWithSession<List<dynamic>>(
        '/rest/v1/$tableName',
        session: session,
        queryParameters: const {'on_conflict': 'user_id'},
        data: [row],
        options: Options(
          headers: const {'Prefer': 'resolution=merge-duplicates,return=minimal'},
        ),
      );
      return;
    }
    await bootstrap.client!.from(tableName).upsert(row);
  }

  @override
  Future<CloudProfileSnapshot?> fetchProfile() async {
    final userId = await _signedInUserId();
    if (userId == null) {
      return null;
    }
    List<dynamic> rows;
    final gateway = supabaseDataGateway;
    final session = await _signedInRestSession();
    if (gateway != null && session != null) {
      final response = await gateway.authenticatedGetWithSession<List<dynamic>>(
        '/rest/v1/$tableName',
        session: session,
        queryParameters: {
          'select': '*',
          'user_id': 'eq.$userId',
          'limit': '1',
        },
      );
      rows = response.data ?? const [];
    } else {
      rows = await bootstrap.client!
          .from(tableName)
          .select()
          .eq('user_id', userId)
          .limit(1);
    }
    if (rows.isEmpty) {
      return null;
    }
    final row = (rows.first as Map).cast<String, dynamic>();
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
      // getImageUrl is gateway-aware (signed URL under the user's own
      // session); the signed URL itself needs no further auth. The old
      // bootstrap.client.storage.download() had the same anon-session
      // problem as the table writes -- storage RLS only lets the OWNER
      // read these files.
      final signedUrl = await cloudStorageService.getImageUrl(storagePath);
      final List<int> bytes;
      if (signedUrl != null && signedUrl.isNotEmpty) {
        final response = await Dio().get<List<int>>(
          signedUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        bytes = response.data ?? const [];
        if (bytes.isEmpty) {
          return null;
        }
      } else {
        bytes = await bootstrap.client!.storage
            .from(bucketName)
            .download(storagePath);
      }
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
