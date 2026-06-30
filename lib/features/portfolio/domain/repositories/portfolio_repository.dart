import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

/// Contract for portfolio persistence.
abstract interface class PortfolioRepository {
  /// Adds [item] to the portfolio and returns the final saved item.
  Future<CollectibleItem> addItem(CollectibleItem item);

  /// Upserts a cloud-synced item without changing its original saved timestamp.
  Future<void> upsertSyncedItem(CollectibleItem item);

  /// Returns all saved portfolio items.
  Future<List<CollectibleItem>> getItems();

  /// Removes an item from the portfolio by [id].
  Future<void> removeItem(String id);

  /// Updates cloud image metadata after background image sync completes.
  Future<void> updateItemImageSync({
    required String itemId,
    required String imageStoragePath,
    required String cloudImageUrl,
  });

  /// Clears all saved portfolio items.
  Future<void> clearPortfolio();
}
