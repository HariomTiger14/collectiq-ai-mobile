import 'dart:io';

import 'package:collectiq_ai/features/cloud_sync/domain/repositories/cloud_portfolio_repository.dart';
import 'package:collectiq_ai/features/image_storage/domain/repositories/image_storage_repository.dart';
import 'package:collectiq_ai/features/image_sync/domain/entities/image_upload_task.dart';
import 'package:collectiq_ai/features/image_sync/domain/repositories/sync_queue_repository.dart';
import 'package:collectiq_ai/features/image_sync/domain/services/retry_policy.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';

class UploadWorker {
  const UploadWorker({
    required this.queueRepository,
    required this.imageStorageRepository,
    required this.portfolioRepository,
    this.cloudPortfolioRepository,
    this.retryPolicy = const RetryPolicy(),
  });

  final SyncQueueRepository queueRepository;
  final ImageStorageRepository imageStorageRepository;
  final PortfolioRepository portfolioRepository;
  final CloudPortfolioRepository? cloudPortfolioRepository;
  final RetryPolicy retryPolicy;

  Future<void> processQueue() async {
    final tasks = await queueRepository.getUploadableTasks();
    for (final task in tasks) {
      await _uploadTask(task);
    }
  }

  Future<void> _uploadTask(ImageUploadTask task) async {
    if (!_isLocalImagePath(task.localPath) ||
        !await File(task.localPath).exists()) {
      await _markFailed(task, 'Local image file is not available.');
      return;
    }

    final now = DateTime.now();
    await queueRepository.saveTask(
      task.copyWith(
        status: ImageUploadTaskStatus.uploading,
        progress: 0.1,
        updatedAt: now,
        clearLastError: true,
        clearNextRetryAt: true,
      ),
    );

    try {
      final reference = await imageStorageRepository.uploadImage(
        localPath: task.localPath,
        collectibleId: task.collectibleId,
      );

      if (!reference.isRemote || reference.publicUrl == null) {
        await _markFailed(task, 'Cloud image storage is not configured.');
        return;
      }

      final uploadedTask = task.copyWith(
        status: ImageUploadTaskStatus.uploaded,
        storagePath: reference.path,
        publicUrl: reference.publicUrl,
        progress: 1,
        updatedAt: DateTime.now(),
        clearLastError: true,
        clearNextRetryAt: true,
      );
      await queueRepository.saveTask(uploadedTask);
      await queueRepository.markLastSync(uploadedTask.updatedAt);
      await portfolioRepository.updateItemImageSync(
        itemId: task.collectibleId,
        imageStoragePath: reference.path,
        cloudImageUrl: reference.publicUrl!,
      );
      await _uploadUpdatedCollectible(task.collectibleId);
    } on Exception catch (error) {
      await _markFailed(task, error.toString());
    }
  }

  Future<void> _uploadUpdatedCollectible(String collectibleId) async {
    final cloudRepository = cloudPortfolioRepository;
    if (cloudRepository == null) {
      return;
    }

    final items = await portfolioRepository.getItems();
    final updatedItems = items
        .where((item) => item.id == collectibleId)
        .toList(growable: false);
    if (updatedItems.isEmpty) {
      return;
    }

    await cloudRepository.uploadLocalItems(updatedItems);
  }

  Future<void> _markFailed(ImageUploadTask task, String message) async {
    final now = DateTime.now();
    final nextAttempt = task.attemptCount + 1;
    final shouldRetry = retryPolicy.shouldRetry(nextAttempt);
    await queueRepository.saveTask(
      task.copyWith(
        status: shouldRetry
            ? ImageUploadTaskStatus.pending
            : ImageUploadTaskStatus.failed,
        attemptCount: nextAttempt,
        lastError: message,
        nextRetryAt: shouldRetry
            ? retryPolicy.nextRetryAt(nextAttempt, now)
            : null,
        progress: 0,
        updatedAt: now,
        clearNextRetryAt: !shouldRetry,
      ),
    );
  }
}

bool _isLocalImagePath(String imagePath) {
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
