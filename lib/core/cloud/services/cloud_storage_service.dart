class CloudStorageUploadResult {
  const CloudStorageUploadResult({required this.path, this.publicUrl});

  final String path;
  final String? publicUrl;
}

abstract interface class CloudStorageService {
  String get providerName;

  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  });

  Future<void> deleteImage(String path);

  Future<String?> getImageUrl(String path);
}
