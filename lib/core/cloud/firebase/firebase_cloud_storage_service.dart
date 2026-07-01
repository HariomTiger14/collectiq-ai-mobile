import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import 'package:collectiq_ai/core/cloud/firebase/firebase_bootstrap.dart';
import 'package:collectiq_ai/core/cloud/cloud_storage_paths.dart';
import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';

@Deprecated(
  'SupabaseCloudStorageService is the primary DEV/STAGING image storage '
  'implementation. Firebase Storage is retained only for reference and should '
  'not be selected by CloudServiceRegistry.',
)
class FirebaseCloudStorageService implements CloudStorageService {
  FirebaseCloudStorageService({
    required this.bootstrap,
    required this.authService,
    this.storage,
  });

  final FirebaseBootstrap bootstrap;
  final AuthService authService;
  final FirebaseStorage? storage;

  FirebaseStorage get _firebaseStorage => storage ?? FirebaseStorage.instance;

  @override
  String get providerName => 'Firebase Storage';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized || !await authService.isSignedIn()) {
      return null;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      throw StateError('Local image file is missing.');
    }

    final reference = _firebaseStorage.ref(destinationPath);
    await reference.putFile(
      file,
      SettableMetadata(contentType: _contentTypeFor(localPath)),
    );
    return CloudStorageUploadResult(
      path: destinationPath,
      publicUrl: await reference.getDownloadURL(),
    );
  }

  @override
  Future<void> deleteImage(String path) async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized || !await authService.isSignedIn()) {
      return;
    }
    await _firebaseStorage.ref(path).delete();
  }

  @override
  Future<String?> getImageUrl(String path) async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized || path.trim().isEmpty) {
      return null;
    }
    return _firebaseStorage.ref(path).getDownloadURL();
  }

  static String imagePathFor({
    required String userId,
    required String itemId,
    String extension = '.jpg',
  }) {
    return CloudStoragePaths.portfolioImage(
      userId: userId,
      itemId: itemId,
      extension: extension,
    );
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
