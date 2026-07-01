import 'dart:io';

import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/cloud_storage_paths.dart';
import 'package:collectiq_ai/features/image_sync/domain/entities/image_upload_task.dart';
import 'package:collectiq_ai/features/image_sync/domain/repositories/sync_queue_repository.dart';
import 'package:collectiq_ai/features/image_sync/domain/services/retry_policy.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:flutter/foundation.dart';

class UploadWorker {
  const UploadWorker({
    required this.queueRepository,
    required this.portfolioRepository,
    required this.registry,
    this.retryPolicy = const RetryPolicy(),
  });

  final SyncQueueRepository queueRepository;
  final PortfolioRepository portfolioRepository;
  final CloudServiceRegistry registry;
  final RetryPolicy retryPolicy;

  Future<void> processQueue() async {
    final tasks = await queueRepository.getUploadableTasks();
    debugPrint('[ImageSync] queue count: ${tasks.length}');
    for (final task in tasks) {
      await _uploadTask(task);
    }
  }

  Future<void> _uploadTask(ImageUploadTask task) async {
    debugPrint('[ImageSync] current task id: ${task.id}');
    if (!_isLocalImagePath(task.localPath) ||
        !await File(task.localPath).exists()) {
      debugPrint('[ImageSync] upload skipped; file missing: ${task.localPath}');
      await _markFailed(task, 'Local image file is not available.');
      return;
    }

    final imageFile = File(task.localPath);
    final fileSize = await imageFile.length();
    debugPrint('[ImageSync] current file size: $fileSize');
    final now = DateTime.now();
    await queueRepository.saveTask(
      task.copyWith(
        status: ImageUploadTaskStatus.syncing,
        progress: 0.1,
        updatedAt: now,
        clearLastError: true,
        clearNextRetryAt: true,
      ),
    );

    try {
      debugPrint('[ImageSync] upload start: ${task.id}');
      final userId = await registry.authService.currentUserId();
      if (userId == null || userId.trim().isEmpty) {
        await _markFailed(task, 'Cloud image storage requires sign in.');
        return;
      }

      final destinationPath = CloudStoragePaths.portfolioImage(
        userId: userId,
        itemId: task.collectibleId,
        extension: _extensionFor(task.localPath),
      );
      final reference = await registry.cloudStorageService.uploadImage(
        localPath: task.localPath,
        destinationPath: destinationPath,
      );

      if (reference == null || reference.publicUrl == null) {
        debugPrint('[ImageSync] upload produced local reference only');
        await _markFailed(task, 'Cloud image storage is not configured.');
        return;
      }

      final uploadedTask = task.copyWith(
        status: ImageUploadTaskStatus.synced,
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
      debugPrint('[ImageSync] upload success: ${task.id}');
      await _uploadUpdatedCollectible(task.collectibleId);
    } on Object catch (error, stackTrace) {
      debugPrint('[ImageSync] upload failure: $error');
      debugPrint('$stackTrace');
      await _markFailed(task, error.toString());
    }
  }

  Future<void> _uploadUpdatedCollectible(String collectibleId) async {
    final items = await portfolioRepository.getItems();
    final updatedItems = items
        .where((item) => item.id == collectibleId)
        .toList(growable: false);
    if (updatedItems.isEmpty) {
      return;
    }

    debugPrint('[ImageSync] database upsert start: $collectibleId');
    for (final item in updatedItems) {
      await registry.cloudPortfolioSyncService.syncItem(item);
    }
    debugPrint('[ImageSync] database upsert success: $collectibleId');
  }

  Future<void> _markFailed(ImageUploadTask task, String message) async {
    final now = DateTime.now();
    final nextAttempt = task.attemptCount + 1;
    final shouldRetry = retryPolicy.shouldRetry(nextAttempt);
    await queueRepository.saveTask(
      task.copyWith(
        status: shouldRetry
            ? ImageUploadTaskStatus.retryable
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
