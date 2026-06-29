import 'dart:io';

import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_schema.dart';
import 'package:collectiq_ai/features/image_storage/data/repositories/local_image_storage_repository.dart';
import 'package:collectiq_ai/features/image_storage/domain/repositories/image_storage_repository.dart';
import 'package:dio/dio.dart';

class SupabaseImageStorageRepository implements ImageStorageRepository {
  const SupabaseImageStorageRepository({
    required this.config,
    this.fallbackRepository = const LocalImageStorageRepository(),
  });

  final SupabaseConfig config;
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

    final storagePath =
        '${SupabaseStorageBuckets.collectibleImages}/'
        '$collectibleId/${Uri.file(localPath).pathSegments.last}';
    final baseUri = config.baseUri;
    if (baseUri == null) {
      return fallbackRepository.uploadImage(
        localPath: localPath,
        collectibleId: collectibleId,
      );
    }

    final file = File(localPath);
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'apikey': config.anonKey,
          'Authorization': 'Bearer ${config.anonKey}',
          'Content-Type': _contentTypeFor(localPath),
          'x-upsert': 'true',
        },
      ),
    );
    await dio.post<List<int>>(
      baseUri.resolve('/storage/v1/object/$storagePath').toString(),
      data: file.openRead(),
      options: Options(responseType: ResponseType.bytes),
    );

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
