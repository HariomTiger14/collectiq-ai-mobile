import 'package:collectiq_ai/features/image_storage/data/repositories/local_image_storage_repository.dart';
import 'package:collectiq_ai/features/image_storage/domain/repositories/image_storage_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageStorageRepositoryProvider = Provider<ImageStorageRepository>((ref) {
  return const LocalImageStorageRepository();
});
