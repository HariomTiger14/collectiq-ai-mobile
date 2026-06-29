import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

enum SyncConflictResolution { newestWins }

class SyncConflict {
  const SyncConflict({
    required this.localItem,
    required this.cloudItem,
    this.resolution = SyncConflictResolution.newestWins,
  });

  final CollectibleItem localItem;
  final CollectibleItem cloudItem;
  final SyncConflictResolution resolution;

  CollectibleItem resolve() {
    return cloudItem.createdAt.isAfter(localItem.createdAt)
        ? cloudItem
        : localItem;
  }
}
