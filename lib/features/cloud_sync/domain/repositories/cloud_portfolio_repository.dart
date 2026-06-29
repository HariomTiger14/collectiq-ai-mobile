import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

/// Contract for future cloud portfolio sync providers.
abstract interface class CloudPortfolioRepository {
  /// Returns current cloud sync status.
  Future<SyncStatus> getSyncStatus();

  /// Uploads local portfolio items when cloud sync is available.
  Future<SyncStatus> uploadLocalItems(List<CollectibleItem> items);

  /// Downloads cloud portfolio items.
  Future<List<CollectibleItem>> downloadCloudItems();
}
