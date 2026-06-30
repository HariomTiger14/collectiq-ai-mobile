import 'dart:io';

import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_ids.dart';
import 'package:collectiq_ai/core/supabase/supabase_schema.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/image_storage/data/repositories/local_image_storage_repository.dart';
import 'package:collectiq_ai/features/image_storage/domain/repositories/image_storage_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SupabaseImageStorageRepository implements ImageStorageRepository {
  const SupabaseImageStorageRepository({
    required this.config,
    this.supabaseService,
    this.fallbackRepository = const LocalImageStorageRepository(),
  });

  final SupabaseConfig config;
  final SupabaseService? supabaseService;
  final ImageStorageRepository fallbackRepository;

  @override
  Future<ImageStorageReference> saveLocalImage(String localPath) {
    return fallbackRepository.saveLocalImage(localPath);
  }

  @override
  Future<ImageStorageReference> uploadImage({
    required String localPath,
    required String collectibleId,
  }) async {
    if (!config.isConfigured) {
      return fallbackRepository.uploadImage(
        localPath: localPath,
        collectibleId: collectibleId,
      );
    }

    final baseUri = config.baseUri;
    if (baseUri == null) {
      return fallbackRepository.uploadImage(
        localPath: localPath,
        collectibleId: collectibleId,
      );
    }

    final session =
        await (supabaseService ?? SupabaseService.instance(config: config))
            .currentSession();
    if (session == null || session.isAnonymous) {
      debugPrint(
        '[Supabase Storage] upload skipped: signed-in session missing',
      );
      return fallbackRepository.uploadImage(
        localPath: localPath,
        collectibleId: collectibleId,
      );
    }

    final storagePath = storagePathFor(
      localPath: localPath,
      collectibleId: collectibleId,
      userId: session.userId,
    );
    final file = File(localPath);
    final fileExists = await file.exists();
    final fileSize = fileExists ? await file.length() : 0;
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'apikey': config.anonKey,
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': _contentTypeFor(localPath),
          'x-upsert': 'true',
        },
      ),
    );
    final uploadUrl = baseUri.resolve('/storage/v1/object/$storagePath');
    debugPrint(
      '[Supabase Storage] bucket: ${SupabaseStorageBuckets.collectibleImages}',
    );
    debugPrint('[Supabase Storage] object path: $storagePath');
    debugPrint(
      '[Supabase Storage] content type: ${_contentTypeFor(localPath)}',
    );
    debugPrint('[Supabase Storage] file exists: $fileExists');
    debugPrint('[Supabase Storage] file size: $fileSize');
    final bytes = await file.readAsBytes();
    debugPrint('[Supabase Storage] upload bytes: ${bytes.length}');
    try {
      await dio.post<void>(
        uploadUrl.toString(),
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': _contentTypeFor(localPath),
            'x-upsert': 'true',
          },
          responseType: ResponseType.json,
        ),
      );
    } on DioException catch (error) {
      SupabaseService.logDioException(error, payload: bytes);
      rethrow;
    }

    return ImageStorageReference(
      path: storagePath,
      isRemote: true,
      publicUrl: await publicUrlFor(storagePath),
    );
  }

  @override
  Future<String?> publicUrlFor(String storagePath) async {
    final baseUri = config.baseUri;
    if (!config.isConfigured || baseUri == null) {
      return null;
    }

    return baseUri.resolve('/storage/v1/object/public/$storagePath').toString();
  }

  static String storagePathFor({
    required String localPath,
    required String collectibleId,
    required String userId,
  }) {
    final cloudId = cloudUuidFor(collectibleId);
    final safeUserId = _safePathSegment(userId);
    final extension = _extensionFor(localPath);
    return '${SupabaseStorageBuckets.collectibleImages}/'
        '$safeUserId/$cloudId/image$extension';
  }
}

String _contentTypeFor(String path) {
  final normalizedPath = path.toLowerCase();
  if (normalizedPath.endsWith('.png')) {
    return 'image/png';
  }
  if (normalizedPath.endsWith('.jpg') || normalizedPath.endsWith('.jpeg')) {
    return 'image/jpeg';
  }

  return 'application/octet-stream';
}

String _extensionFor(String path) {
  final filename = Uri.file(path).pathSegments.last.toLowerCase();
  if (filename.endsWith('.png')) {
    return '.png';
  }
  if (filename.endsWith('.jpg')) {
    return '.jpg';
  }
  if (filename.endsWith('.jpeg')) {
    return '.jpeg';
  }

  return '.jpg';
}

String _safePathSegment(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]'), '-')
      .replaceAll(RegExp('-+'), '-');
}
