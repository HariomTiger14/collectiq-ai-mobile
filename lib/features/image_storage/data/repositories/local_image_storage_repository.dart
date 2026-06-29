import 'package:collectiq_ai/features/image_storage/domain/repositories/image_storage_repository.dart';

class LocalImageStorageRepository implements ImageStorageRepository {
  const LocalImageStorageRepository();

  @override
  Future<ImageStorageReference> saveLocalImage(String localPath) async {
    return ImageStorageReference(path: localPath, isRemote: false);
  }

  @override
  Future<ImageStorageReference> uploadImage({
    required String localPath,
    required String collectibleId,
  }) {
    return saveLocalImage(localPath);
  }

  @override
  Future<String?> publicUrlFor(String storagePath) async {
    return null;
  }
}
