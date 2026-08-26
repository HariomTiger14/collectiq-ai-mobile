import 'dart:io';

import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/cloud_storage_paths.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/foundation.dart';

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
    final cloudIds = {for (final item in cloudItems) item.id};
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
    // A previously-synced local item that no longer appears in the cloud
    // response has been removed server-side (soft-deleted, an admin
    // action, a direct data fix, or a delete synced from another device) --
    // without this, a device that already cached the item would keep
    // showing it forever, since the loop above only ever adds/updates,
    // never removes. Only ever touches items already confirmed `synced` --
    // a `pendingUpload`/`failed`/`localOnly` item is a real local change
    // that hasn't reached the cloud yet and must never be discarded just
    // because it isn't in this response.
    for (final localItem in localItems) {
      if (localItem.syncStatus == CloudItemSyncStatus.synced &&
          !cloudIds.contains(localItem.id)) {
        await portfolioRepository.removeItem(localItem.id);
      }
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
    final stopwatch = Stopwatch()..start();
    final canSync = await _canSync();
    debugPrint(
      '[CloudSync] deleteCloudItem($itemId) canSync=$canSync '
      '(_canSync took ${stopwatch.elapsedMilliseconds}ms)',
    );
    if (!canSync) {
      return;
    }
    stopwatch.reset();
    // A single flaky request (a slow token refresh, a dropped connection)
    // shouldn't cost the whole delete -- the local item is already gone by
    // the time this runs, so on failure the item would otherwise silently
    // reappear on the next sync. One retry rides out a transient blip
    // without masking a real, persistent failure.
    try {
      await registry.cloudPortfolioSyncService.deleteItem(itemId);
    } on Object catch (error) {
      debugPrint(
        '[CloudSync] deleteCloudItem($itemId) first attempt failed, '
        'retrying once: $error',
      );
      await Future<void>.delayed(const Duration(seconds: 2));
      await registry.cloudPortfolioSyncService.deleteItem(itemId);
    }
    debugPrint(
      '[CloudSync] deleteCloudItem($itemId) remote call took '
      '${stopwatch.elapsedMilliseconds}ms',
    );
  }

  Future<void> syncValuationSnapshot(CollectibleItem item) async {
    if (!await _canSync()) {
      return;
    }
    await registry.cloudPortfolioSyncService.syncValuationSnapshot(item);
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

    // An item saved from catalog search with no photo of its own carries a
    // BUNDLED ASSET path for its image, not a file on disk. File.exists()
    // is always false for those (assets are compiled into the binary), so
    // treating that as "the photo went missing" aborted the sync before it
    // pushed any metadata -- leaving the item local-only, invisible to the
    // cloud, and unrecoverable if the app was reinstalled or signed out.
    // It also has no cloud row to soft-delete, so it silently sidesteps the
    // safety net every other item gets. There is simply nothing to upload
    // here, which is expected rather than an error.
    final hasBundledAssetImage = _isBundledAssetPath(item.imagePath);
    if (!hasBundledAssetImage && !await File(item.imagePath).exists()) {
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
      // Skip the image upload entirely when the "image" is the bundled
      // placeholder -- there is no file to send. The metadata still syncs,
      // so the item exists in the cloud and is recoverable; the artwork
      // fills in later if the user adds a real photo.
      CloudStorageUploadResult? uploadResult;
      if (!hasBundledAssetImage) {
        final cloudPath = CloudStoragePaths.portfolioImage(
          userId: userId,
          itemId: item.id,
          extension: _extensionFor(item.imagePath),
        );
        uploadResult = await registry.cloudStorageService.uploadImage(
          localPath: item.imagePath,
          destinationPath: cloudPath,
        );
        if (uploadResult == null || uploadResult.publicUrl == null) {
          throw StateError('Cloud image upload was skipped.');
        }
      }
      final uploadedGalleryImages = await _uploadGalleryImages(
        userId: userId,
        item: item,
      );

      final uploadedItem = pendingItem.copyWithCloudSync(
        imageStoragePath: uploadResult?.path,
        cloudImageUrl: uploadResult?.publicUrl,
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

/// Whether [path] points at an asset compiled into the app bundle rather
/// than a file on disk. Catalog-saved items with no user photo use one of
/// these as their image, and dart:io cannot see them -- File.exists() is
/// always false -- so they must not be mistaken for a missing file.
bool _isBundledAssetPath(String path) {
  return path.trim().startsWith('assets/');
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
