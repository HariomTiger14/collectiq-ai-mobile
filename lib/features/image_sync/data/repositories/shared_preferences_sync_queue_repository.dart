import 'dart:convert';

import 'package:collectiq_ai/features/image_sync/domain/entities/image_upload_task.dart';
import 'package:collectiq_ai/features/image_sync/domain/entities/sync_queue_snapshot.dart';
import 'package:collectiq_ai/features/image_sync/domain/repositories/sync_queue_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesSyncQueueRepository implements SyncQueueRepository {
  const SharedPreferencesSyncQueueRepository();

  static const _tasksKey = 'image_upload_tasks';
  static const _lastSyncKey = 'image_upload_last_sync_at';
  static const _staleSyncingTimeout = Duration(minutes: 15);

  @override
  Future<ImageUploadTask> enqueueImageUpload({
    required String collectibleId,
    required String localPath,
  }) async {
    final tasks = await getTasks();
    final existingTask = tasks.where((task) {
      return task.collectibleId == collectibleId && task.localPath == localPath;
    }).firstOrNull;

    if (existingTask != null &&
        existingTask.status != ImageUploadTaskStatus.synced) {
      return existingTask;
    }

    final now = DateTime.now();
    final task = ImageUploadTask(
      id: 'image-upload-${now.microsecondsSinceEpoch}',
      collectibleId: collectibleId,
      localPath: localPath,
      status: ImageUploadTaskStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await _saveTasks([task, ...tasks]);
    return task;
  }

  @override
  Future<List<ImageUploadTask>> getTasks() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedTasks = preferences.getString(_tasksKey);
    if (encodedTasks == null || encodedTasks.isEmpty) {
      return const [];
    }

    final decodedTasks = jsonDecode(encodedTasks) as List<dynamic>;
    return decodedTasks
        .whereType<Map<String, dynamic>>()
        .map(ImageUploadTask.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<ImageUploadTask>> getUploadableTasks() async {
    final tasks = await getTasks();
    final now = DateTime.now();
    var changed = false;
    final normalizedTasks = tasks
        .map((task) {
          if (_isStaleSyncingTask(task, now)) {
            changed = true;
            return task.copyWith(
              status: ImageUploadTaskStatus.retryable,
              lastError: 'Upload was interrupted and will retry.',
              nextRetryAt: now,
              updatedAt: now,
            );
          }

          return task;
        })
        .toList(growable: false);

    if (changed) {
      await _saveTasks(normalizedTasks);
    }

    return normalizedTasks
        .where((task) => task.canUpload)
        .toList(growable: false);
  }

  @override
  Future<void> saveTask(ImageUploadTask task) async {
    final tasks = await getTasks();
    final updatedTasks = [
      task,
      ...tasks.where((existingTask) => existingTask.id != task.id),
    ];
    await _saveTasks(updatedTasks);
  }

  @override
  Future<void> markLastSync(DateTime syncedAt) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastSyncKey, syncedAt.toIso8601String());
  }

  @override
  Future<SyncQueueSnapshot> snapshot() async {
    final preferences = await SharedPreferences.getInstance();
    final lastSyncValue = preferences.getString(_lastSyncKey);
    return SyncQueueSnapshot(
      tasks: await getTasks(),
      lastSyncAt: lastSyncValue == null
          ? null
          : DateTime.tryParse(lastSyncValue),
    );
  }

  Future<void> _saveTasks(List<ImageUploadTask> tasks) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedTasks = jsonEncode(
      tasks.map((task) => task.toJson()).toList(growable: false),
    );
    await preferences.setString(_tasksKey, encodedTasks);
  }

  bool _isStaleSyncingTask(ImageUploadTask task, DateTime now) {
    if (task.status != ImageUploadTaskStatus.syncing) {
      return false;
    }

    return now.difference(task.updatedAt) >= _staleSyncingTimeout;
  }
}
