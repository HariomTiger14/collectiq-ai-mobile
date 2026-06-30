import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/wishlist/data/repositories/shared_preferences_wishlist_repository.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:collectiq_ai/features/wishlist/domain/services/wishlist_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return const SharedPreferencesWishlistRepository();
});

final wishlistServiceProvider = Provider<WishlistService>((ref) {
  return const WishlistService();
});

final wishlistEntriesProvider = FutureProvider<List<WishlistStatusEntry>>((
  ref,
) async {
  final repository = ref.watch(wishlistRepositoryProvider);
  return repository.getEntries();
});

final wishlistStatusForItemProvider =
    FutureProvider.family<WishlistStatus, String>((ref, itemId) async {
      final repository = ref.watch(wishlistRepositoryProvider);
      return repository.getStatusForItem(itemId);
    });

final wishlistSummaryProvider =
    FutureProvider.family<WishlistSummary, List<CollectibleItem>>((
      ref,
      items,
    ) async {
      final entries = await ref.watch(wishlistEntriesProvider.future);
      final service = ref.watch(wishlistServiceProvider);
      return service.buildSummary(items: items, entries: entries);
    });
