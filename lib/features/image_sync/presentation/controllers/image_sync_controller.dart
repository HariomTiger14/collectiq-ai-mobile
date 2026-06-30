import 'dart:async';

import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/image_storage/image_storage_providers.dart';
import 'package:collectiq_ai/features/image_sync/data/repositories/shared_preferences_sync_queue_repository.dart';
import 'package:collectiq_ai/features/image_sync/domain/entities/sync_queue_snapshot.dart';
import 'package:collectiq_ai/features/image_sync/domain/repositories/sync_queue_repository.dart';
import 'package:collectiq_ai/features/image_sync/domain/services/upload_worker.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncQueueRepositoryProvider = Provider<SyncQueueRepository>((ref) {
  return const SharedPreferencesSyncQueueRepository();
});

final uploadWorkerProvider = Provider<UploadWorker>((ref) {
  return UploadWorker(
    queueRepository: ref.watch(syncQueueRepositoryProvider),
    imageStorageRepository: ref.watch(imageStorageRepositoryProvider),
    portfolioRepository: ref.watch(portfolioRepositoryProvider),
    cloudPortfolioRepository: ref.watch(cloudPortfolioRepositoryProvider),
  );
});

class ImageSyncState {
  const ImageSyncState({
    this.snapshot = const SyncQueueSnapshot(tasks: []),
    this.isUploading = false,
    this.errorMessage,
  });

  final SyncQueueSnapshot snapshot;
  final bool isUploading;
  final String? errorMessage;

  String get cloudStatus {
    if (isUploading || snapshot.uploadingCount > 0) {
      return 'Uploading';
    }
    if (snapshot.failedCount > 0) {
      return 'Needs attention';
    }
    if (snapshot.retryableCount > 0) {
      return 'Retryable';
    }
    if (snapshot.pendingCount > 0) {
      return 'Pending';
    }
    if (snapshot.uploadedCount > 0) {
      return 'Synced';
    }
    return 'Local only';
  }

  ImageSyncState copyWith({
    SyncQueueSnapshot? snapshot,
    bool? isUploading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return ImageSyncState(
      snapshot: snapshot ?? this.snapshot,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

class ImageSyncController extends Notifier<ImageSyncState> {
  late final SyncQueueRepository _queueRepository;
  late final UploadWorker _uploadWorker;

  @override
  ImageSyncState build() {
    _queueRepository = ref.watch(syncQueueRepositoryProvider);
    _uploadWorker = ref.watch(uploadWorkerProvider);
    Future.microtask(loadSnapshot);
    return const ImageSyncState();
  }

  Future<void> loadSnapshot() async {
    state = state.copyWith(
      snapshot: await _queueRepository.snapshot(),
      clearErrorMessage: true,
    );
  }

  Future<void> enqueueImage({
    required String collectibleId,
    required String localPath,
  }) async {
    if (!_isUploadCandidate(localPath)) {
      debugPrint(
        '[ImageSync] upload not queued for non-local image: $localPath',
      );
      return;
    }

    debugPrint(
      '[ImageSync] upload queued after save for collectible $collectibleId',
    );
    await _queueRepository.enqueueImageUpload(
      collectibleId: collectibleId,
      localPath: localPath,
    );
    await loadSnapshot();
    unawaited(processQueue());
  }

  Future<void> processQueue() async {
    if (state.isUploading) {
      return;
    }

    final startingSnapshot = await _queueRepository.snapshot();
    debugPrint('[ImageSync] processing upload queue');
    debugPrint('[ImageSync] queue count: ${startingSnapshot.tasks.length}');
    state = state.copyWith(isUploading: true, clearErrorMessage: true);
    try {
      await _uploadWorker.processQueue();
      state = state.copyWith(
        snapshot: await _queueRepository.snapshot(),
        isUploading: false,
      );
    } on Object catch (error, stackTrace) {
      debugPrint('[ImageSync] process queue failed: $error');
      debugPrint('$stackTrace');
      state = state.copyWith(
        snapshot: await _queueRepository.snapshot(),
        isUploading: false,
        errorMessage: 'Image sync will retry later.',
      );
    }
  }
}

final imageSyncControllerProvider =
    NotifierProvider<ImageSyncController, ImageSyncState>(
      ImageSyncController.new,
    );

bool _isUploadCandidate(String imagePath) {
  final normalizedPath = imagePath.trim();
  if (normalizedPath.isEmpty ||
      normalizedPath.startsWith('sample://') ||
      normalizedPath.startsWith('http://') ||
      normalizedPath.startsWith('https://') ||
      normalizedPath.startsWith('assets/')) {
    return false;
  }

  return true;
}
