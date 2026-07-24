import 'dart:io';

import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/cloud_storage_paths.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

class CloudPortfolioSyncCoordinator {
  const CloudPortfolioSyncCoordinator({
    required this.registry,
    required this.portfolioRepository,
  });

  final CloudServiceRegistry registry;
  final PortfolioRepository portfolioRepository;

  Future<void> syncPendingItems() async {
    if (!await _canSync()) {
      return;
    }

    final items = await portfolioRepository.getItems();
    for (final item in items.where(_isSyncCandidate)) {
      await _syncItem(item);
    }
  }

  Future<int> syncNow() async {
    if (!await _canSync()) {
      return 0;
    }

    await syncPendingItems();
    final localItems = await portfolioRepository.getItems();
    final localById = {for (final item in localItems) item.id: item};
    final cloudItems = await registry.cloudPortfolioSyncService.fetchItems();
    var mergedCount = 0;
    for (final cloudItem in cloudItems) {
      final localItem = localById[cloudItem.id];
      if (localItem != null &&
          localItem.syncStatus != CloudItemSyncStatus.synced) {
        continue;
      }
      await portfolioRepository.upsertSyncedItem(
        cloudItem.copyWithCloudSync(
          syncStatus: CloudItemSyncStatus.synced,
          lastSyncedAt: cloudItem.lastSyncedAt ?? DateTime.now(),
          clearSyncError: true,
        ),
      );
      mergedCount += 1;
    }
    return mergedCount;
  }

  Future<void> syncUpdatedItem(CollectibleItem item) async {
    if (!await _canSync()) {
      return;
    }

    try {
      final pendingItem = item.copyWithCloudSync(
        syncStatus: CloudItemSyncStatus.pendingUpload,
        clearSyncError: true,
      );
      await portfolioRepository.upsertSyncedItem(pendingItem);
      await registry.cloudPortfolioSyncService.syncItem(pendingItem);
      final syncedItem = await registry.cloudPortfolioSyncService.markSynced(
        pendingItem,
      );
      await portfolioRepository.upsertSyncedItem(syncedItem);
    } on Object catch (error) {
      await portfolioRepository.upsertSyncedItem(
        item.copyWithCloudSync(
          syncStatus: CloudItemSyncStatus.failed,
          syncError: error.toString(),
        ),
      );
    }
  }

  Future<void> deleteCloudItem(String itemId) async {
    if (!await _canSync()) {
      return;
    }
    await registry.cloudPortfolioSyncService.deleteItem(itemId);
  }

  Future<bool> _canSync() async {
    final flags = registry.config.featureFlags;
    if (!registry.config.allowsCloudServices) {
      return false;
    }
    if (!flags.useCloudPortfolioSync || !flags.useCloudImageStorage) {
      return false;
    }
    return registry.authService.isSignedIn();
  }

  bool _isSyncCandidate(CollectibleItem item) {
    return item.syncStatus == CloudItemSyncStatus.localOnly ||
        item.syncStatus == CloudItemSyncStatus.pendingUpload ||
        item.syncStatus == CloudItemSyncStatus.failed;
  }

  Future<void> _syncItem(CollectibleItem item) async {
    final userId = await registry.authService.currentUserId();
    if (userId == null || userId.trim().isEmpty) {
      return;
    }

    final localImage = File(item.imagePath);
    if (!await localImage.exists()) {
      await portfolioRepository.upsertSyncedItem(
        item.copyWithCloudSync(
          syncStatus: CloudItemSyncStatus.failed,
          syncError: 'Local image file is missing.',
        ),
      );
      return;
    }

    final pendingItem = item.copyWithCloudSync(
      syncStatus: CloudItemSyncStatus.pendingUpload,
      clearSyncError: true,
    );
    await portfolioRepository.upsertSyncedItem(pendingItem);

    try {
      final cloudPath = CloudStoragePaths.portfolioImage(
        userId: userId,
        itemId: item.id,
        extension: _extensionFor(item.imagePath),
      );
      final uploadResult = await registry.cloudStorageService.uploadImage(
        localPath: item.imagePath,
        destinationPath: cloudPath,
      );
      if (uploadResult == null || uploadResult.publicUrl == null) {
        throw StateError('Cloud image upload was skipped.');
      }
      final uploadedGalleryImages = await _uploadGalleryImages(
        userId: userId,
        item: item,
      );

      final uploadedItem = pendingItem.copyWithCloudSync(
        imageStoragePath: uploadResult.path,
        cloudImageUrl: uploadResult.publicUrl,
        galleryImages: uploadedGalleryImages,
        syncStatus: CloudItemSyncStatus.pendingUpload,
        clearSyncError: true,
      );
      await registry.cloudPortfolioSyncService.syncItem(uploadedItem);
      final syncedItem = await registry.cloudPortfolioSyncService.markSynced(
        uploadedItem,
      );
      await portfolioRepository.upsertSyncedItem(syncedItem);
    } on Object catch (error) {
      await portfolioRepository.upsertSyncedItem(
        pendingItem.copyWithCloudSync(
          syncStatus: CloudItemSyncStatus.failed,
          syncError: error.toString(),
        ),
      );
    }
  }

  Future<List<CollectibleImage>> _uploadGalleryImages({
    required String userId,
    required CollectibleItem item,
  }) async {
    final images = item.effectiveGalleryImages;
    if (images.isEmpty) {
      return const [];
    }

    final uploadedImages = <CollectibleImage>[];
    for (var index = 0; index < images.length; index += 1) {
      final image = images[index];
      final path = image.path.trim();
      if (path.isEmpty ||
          path == item.imagePath ||
          path.startsWith('sample://') ||
          _isRemotePath(path)) {
        uploadedImages.add(image);
        continue;
      }

      final localImage = File(path);
      if (!await localImage.exists()) {
        uploadedImages.add(image);
        continue;
      }

      final role = _safePathSegment(image.role ?? 'image-$index');
      final destinationPath = CloudStoragePaths.portfolioImageVariant(
        userId: userId,
        itemId: item.id,
        role: role,
        index: index,
        extension: _extensionFor(path),
      );
      final uploadResult = await registry.cloudStorageService.uploadImage(
        localPath: path,
        destinationPath: destinationPath,
      );
      uploadedImages.add(
        uploadResult == null || uploadResult.publicUrl == null
            ? image
            : image.copyWithCloudImage(
                imageStoragePath: uploadResult.path,
                cloudImageUrl: uploadResult.publicUrl,
              ),
      );
    }

    return uploadedImages;
  }
}

String _extensionFor(String path) {
  final normalized = path.toLowerCase();
  if (normalized.endsWith('.png')) {
    return '.png';
  }
  if (normalized.endsWith('.webp')) {
    return '.webp';
  }
  if (normalized.endsWith('.jpeg')) {
    return '.jpeg';
  }
  return '.jpg';
}

bool _isRemotePath(String path) {
  final normalized = path.toLowerCase();
  return normalized.startsWith('http://') || normalized.startsWith('https://');
}

String _safePathSegment(String value) {
  final normalized = value.trim().toLowerCase().replaceAll(
    RegExp(r'[^a-z0-9_-]+'),
    '-',
  );
  return normalized.isEmpty ? 'image' : normalized;
}
