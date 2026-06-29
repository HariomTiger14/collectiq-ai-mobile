class ImageStorageReference {
  const ImageStorageReference({
    required this.path,
    required this.isRemote,
    this.publicUrl,
  });

  final String path;
  final bool isRemote;
  final String? publicUrl;
}

abstract interface class ImageStorageRepository {
  Future<ImageStorageReference> saveLocalImage(String localPath);

  Future<ImageStorageReference> uploadImage({
    required String localPath,
    required String collectibleId,
  });

  Future<String?> publicUrlFor(String storagePath);
}
