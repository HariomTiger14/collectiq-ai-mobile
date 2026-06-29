import 'package:collectiq_ai/features/image_sync/domain/entities/image_upload_task.dart';
import 'package:collectiq_ai/features/image_sync/domain/entities/sync_queue_snapshot.dart';

abstract interface class SyncQueueRepository {
  Future<ImageUploadTask> enqueueImageUpload({
    required String collectibleId,
    required String localPath,
  });

  Future<List<ImageUploadTask>> getTasks();

  Future<List<ImageUploadTask>> getUploadableTasks();

  Future<void> saveTask(ImageUploadTask task);

  Future<void> markLastSync(DateTime syncedAt);

  Future<SyncQueueSnapshot> snapshot();
}
