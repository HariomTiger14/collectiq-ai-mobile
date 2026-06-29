import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/repositories/cloud_portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

/// Mock cloud portfolio repository used until real cloud sync is connected.
class MockCloudPortfolioRepository implements CloudPortfolioRepository {
  /// Creates a mock cloud portfolio repository.
  const MockCloudPortfolioRepository();

  static const localOnlyStatus = SyncStatus(
    state: SyncState.localOnly,
    message: 'Cloud sync is not configured. Portfolio is saved locally.',
    isCloudBackupEnabled: false,
  );

  @override
  Future<SyncStatus> getSyncStatus() async {
    return localOnlyStatus;
  }

  @override
  Future<SyncStatus> uploadLocalItems(List<CollectibleItem> items) async {
    return SyncStatus(
      state: SyncState.localOnly,
      message: 'Cloud backup is not enabled yet.',
      isCloudBackupEnabled: false,
      pendingItemCount: items.length,
    );
  }

  @override
  Future<List<CollectibleItem>> downloadCloudItems() async {
    return const [];
  }
}
