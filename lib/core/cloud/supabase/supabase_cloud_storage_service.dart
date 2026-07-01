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
    final gateway = supabaseDataGateway;
    final restPublicUrl = _restPublicUrl(gateway, path);
    if (restPublicUrl != null) {
      return restPublicUrl;
    }

    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized || path.trim().isEmpty) {
      return null;
    }

    final normalizedPath = _normalizePath(path);
    try {
      return await bootstrap.client!.storage
          .from(bucketName)
          .createSignedUrl(normalizedPath, 60 * 60);
    } on Object {
      return bootstrap.client!.storage
          .from(bucketName)
          .getPublicUrl(normalizedPath);
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
    if (gateway == null || !gateway.isConfigured) {
      return null;
    }
    final session = await gateway.currentSession();
    if (session == null || session.isAnonymous) {
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
      publicUrl: _restPublicUrl(gateway, normalizedPath),
    );
  }

  String? _restPublicUrl(SupabaseDataGateway? gateway, String path) {
    final baseUri = gateway?.config.baseUri;
    if (baseUri == null || path.trim().isEmpty) {
      return null;
    }
    final normalizedPath = _normalizePath(path);
    return baseUri
        .resolve('/storage/v1/object/public/$bucketName/$normalizedPath')
        .toString();
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
