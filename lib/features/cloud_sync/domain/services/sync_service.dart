import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

abstract interface class SyncService {
  Future<SyncStatus> currentStatus();

  Future<SyncStatus> markPending(List<CollectibleItem> localItems);

  Future<SyncStatus> syncLocalItems(List<CollectibleItem> localItems);

  Future<List<CollectibleItem>> downloadCloudItems();
}
