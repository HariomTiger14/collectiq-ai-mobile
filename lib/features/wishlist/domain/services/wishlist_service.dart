import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

class WishlistService {
  const WishlistService();

  WishlistSummary buildSummary({
    required List<CollectibleItem> items,
    required List<WishlistStatusEntry> entries,
  }) {
    final entryByItemId = {for (final entry in entries) entry.itemId: entry};
    final counts = {for (final status in WishlistStatus.values) status: 0};

    for (final item in items) {
      final status = entryByItemId[item.id]?.status ?? WishlistStatus.owned;
      counts[status] = (counts[status] ?? 0) + 1;
    }

    for (final entry in entries) {
      if (!items.any((item) => item.id == entry.itemId)) {
        counts[entry.status] = (counts[entry.status] ?? 0) + 1;
      }
    }

    return WishlistSummary(
      counts: counts,
      entries: entries,
      recommendations: _recommendations(counts),
    );
  }

  List<String> _recommendations(Map<WishlistStatus, int> counts) {
    final wanted = counts[WishlistStatus.wanted] ?? 0;
    final missing = counts[WishlistStatus.missing] ?? 0;
    final owned = counts[WishlistStatus.owned] ?? 0;

    return [
      if (missing > 0) 'Review missing collectibles',
      if (wanted > 0) 'Add missing items to wishlist',
      if (owned < 100) 'Scan more Pokemon cards',
      if (missing <= 3 && missing > 0) "You're close to completing this goal",
    ];
  }
}
