import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

abstract class WishlistRepository {
  Future<List<WishlistStatusEntry>> getEntries();

  Future<WishlistStatus> getStatusForItem(String itemId);

  Future<void> saveStatus({
    required CollectibleItem item,
    required WishlistStatus status,
  });

  Future<void> deleteStatus(String itemId);

  Future<void> clear();
}
