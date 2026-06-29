import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/repositories/cloud_portfolio_repository.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/services/sync_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

class LocalFirstSyncService implements SyncService {
  const LocalFirstSyncService({required this.repository});

  final CloudPortfolioRepository repository;

  @override
  Future<SyncStatus> currentStatus() {
    return repository.getSyncStatus();
  }

  @override
  Future<SyncStatus> markPending(List<CollectibleItem> localItems) async {
    return SyncStatus(
      state: SyncState.pending,
      message: 'Cloud sync is not enabled. Local changes are waiting.',
      isCloudBackupEnabled: false,
      pendingItemCount: localItems.length,
    );
  }

  @override
  Future<SyncStatus> syncLocalItems(List<CollectibleItem> localItems) {
    return repository.uploadLocalItems(localItems);
  }

  @override
  Future<List<CollectibleItem>> downloadCloudItems() {
    return repository.downloadCloudItems();
  }
}
