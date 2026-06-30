import 'package:collectiq_ai/features/image_sync/domain/entities/image_upload_task.dart';

class SyncQueueSnapshot {
  const SyncQueueSnapshot({required this.tasks, this.lastSyncAt});

  final List<ImageUploadTask> tasks;
  final DateTime? lastSyncAt;

  int get pendingCount {
    return tasks
        .where((task) => task.status == ImageUploadTaskStatus.pending)
        .length;
  }

  int get retryableCount {
    return tasks
        .where((task) => task.status == ImageUploadTaskStatus.retryable)
        .length;
  }

  int get readyToSyncCount => pendingCount + retryableCount;

  int get uploadingCount {
    return syncingCount;
  }

  int get syncingCount {
    return tasks
        .where((task) => task.status == ImageUploadTaskStatus.syncing)
        .length;
  }

  int get failedCount {
    return tasks
        .where((task) => task.status == ImageUploadTaskStatus.failed)
        .length;
  }

  int get uploadedCount {
    return syncedCount;
  }

  int get syncedCount {
    return tasks
        .where((task) => task.status == ImageUploadTaskStatus.synced)
        .length;
  }

  String get stateLabel {
    if (syncingCount > 0) {
      return 'Syncing';
    }
    if (failedCount > 0) {
      return 'Failed';
    }
    if (retryableCount > 0) {
      return 'Retryable';
    }
    if (pendingCount > 0) {
      return 'Pending';
    }
    if (syncedCount > 0) {
      return 'Synced';
    }
    return 'Local only';
  }
}
