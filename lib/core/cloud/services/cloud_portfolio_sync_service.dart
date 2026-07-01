import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

class CloudPortfolioSyncStatus {
  const CloudPortfolioSyncStatus({
    required this.enabled,
    required this.message,
    this.userId,
    this.lastSyncedAt,
  });

  final bool enabled;
  final String message;
  final String? userId;
  final DateTime? lastSyncedAt;
}

abstract interface class CloudPortfolioSyncService {
  String get providerName;

  Future<void> syncItem(CollectibleItem item);

  Future<void> deleteItem(String itemId);

  Future<List<CollectibleItem>> fetchItems();

  Future<CollectibleItem> markSynced(CollectibleItem item);

  Future<CloudPortfolioSyncStatus> getSyncStatus();
}
