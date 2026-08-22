import 'dart:io';

import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_bootstrap.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCloudStorageService implements CloudStorageService {
  SupabaseCloudStorageService({
    required this.bootstrap,
    required this.authService,
    this.supabaseDataGateway,
    this.bucketName = 'collectiq-portfolio-images',
  });

  final SupabaseBootstrap bootstrap;
  final AuthService authService;
  final SupabaseDataGateway? supabaseDataGateway;
  final String bucketName;

  // Comfortably under the server-side signed-URL lifetime so a URL handed
  // to a widget doesn't expire mid-display; ResilientCollectibleImage's
  // cache also refreshes before this window closes.
  static const _signedUrlExpirySeconds = 60 * 60;

  @override
  String get providerName => 'Supabase Storage';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    final restUpload = await _uploadImageWithRestSession(
      localPath: localPath,
      destinationPath: destinationPath,
    );
    if (restUpload != null) {
      return restUpload;
    }

    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized || !await authService.isSignedIn()) {
      return null;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      throw StateError('Local image file is missing.');
    }

    final normalizedPath = _normalizePath(destinationPath);
    await bootstrap.client!.storage
        .from(bucketName)
        .upload(
          normalizedPath,
          file,
          fileOptions: FileOptions(
            upsert: true,
            contentType: _contentTypeFor(localPath),
          ),
        );

    return CloudStorageUploadResult(
      path: normalizedPath,
      publicUrl: await getImageUrl(normalizedPath),
    );
  }

  @override
  Future<void> deleteImage(String path) async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized || !await authService.isSignedIn()) {
      return;
    }
    await bootstrap.client!.storage.from(bucketName).remove([
      _normalizePath(path),
    ]);
  }

  @override
  Future<String?> getImageUrl(String path) async {
    if (path.trim().isEmpty) {
      return null;
    }

    final gateway = supabaseDataGateway;
    final session = await _signedInRestSession(gateway);
    if (gateway != null && session != null) {
      final restSignedUrl = await _fetchSignedUrlRest(gateway, session, path);
      if (restSignedUrl != null) {
        return restSignedUrl;
      }
    }

    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return null;
    }

    final normalizedPath = _normalizePath(path);
    try {
      return await bootstrap.client!.storage
          .from(bucketName)
          .createSignedUrl(normalizedPath, _signedUrlExpirySeconds);
    } on Object {
      return null;
    }
  }

  String _normalizePath(String path) {
    final trimmed = path.trim().replaceAll('\\', '/');
    final withoutBucket = trimmed.startsWith('$bucketName/')
        ? trimmed.substring(bucketName.length + 1)
        : trimmed;
    return withoutBucket.replaceAll(RegExp('/+'), '/');
  }

  Future<CloudStorageUploadResult?> _uploadImageWithRestSession({
    required String localPath,
    required String destinationPath,
  }) async {
    final gateway = supabaseDataGateway;
    final session = await _signedInRestSession(gateway);
    if (gateway == null || session == null) {
      return null;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      throw StateError('Local image file is missing.');
    }

    final normalizedPath = _normalizePath(destinationPath);
    final bytes = await file.readAsBytes();
    await gateway.authenticatedPostWithSession<void>(
      '/storage/v1/object/$bucketName/$normalizedPath',
      session: session,
      data: bytes,
      options: Options(
        headers: {
          'Content-Type': _contentTypeFor(localPath),
          'x-upsert': 'true',
        },
        responseType: ResponseType.json,
      ),
    );

    return CloudStorageUploadResult(
      path: normalizedPath,
      publicUrl: await _fetchSignedUrlRest(gateway, session, normalizedPath),
    );
  }

  Future<SupabaseAuthSession?> _signedInRestSession(
    SupabaseDataGateway? gateway,
  ) async {
    if (gateway == null || !gateway.isConfigured) {
      return null;
    }
    final session = await gateway.currentSession();
    if (session == null || session.isAnonymous) {
      return null;
    }
    return session;
  }

  // The bucket is private, so the only URL that will ever actually resolve
  // is a signed one -- there is no stable "public" URL to construct by
  // string formatting (that was the bug: a blindly-built /object/public/...
  // URL 404s with "Bucket not found" against a private bucket, even though
  // the upload itself succeeded). Callers must treat the result as
  // short-lived and re-resolve it via [getImageUrl] at display time rather
  // than caching it indefinitely.
  Future<String?> _fetchSignedUrlRest(
    SupabaseDataGateway gateway,
    SupabaseAuthSession session,
    String path,
  ) async {
    final normalizedPath = _normalizePath(path);
    try {
      final response = await gateway.authenticatedPostWithSession<
        Map<String, dynamic>
      >(
        '/storage/v1/object/sign/$bucketName/$normalizedPath',
        session: session,
        data: {'expiresIn': _signedUrlExpirySeconds},
      );
      final signedPath = response.data?['signedURL'] as String?;
      if (signedPath == null || signedPath.isEmpty) {
        return null;
      }
      final baseUri = gateway.config.baseUri;
      if (baseUri == null) {
        return null;
      }
      return baseUri.resolve('/storage/v1$signedPath').toString();
    } on Object {
      return null;
    }
  }
}

String _contentTypeFor(String path) {
  final normalizedPath = path.toLowerCase();
  if (normalizedPath.endsWith('.png')) {
    return 'image/png';
  }
  if (normalizedPath.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}
