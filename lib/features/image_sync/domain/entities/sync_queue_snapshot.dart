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

  int get uploadingCount {
    return tasks
        .where((task) => task.status == ImageUploadTaskStatus.uploading)
        .length;
  }

  int get failedCount {
    return tasks
        .where((task) => task.status == ImageUploadTaskStatus.failed)
        .length;
  }

  int get uploadedCount {
    return tasks
        .where((task) => task.status == ImageUploadTaskStatus.uploaded)
        .length;
  }
}
