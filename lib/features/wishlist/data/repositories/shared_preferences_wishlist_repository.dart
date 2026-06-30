import 'dart:convert';

import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesWishlistRepository implements WishlistRepository {
  const SharedPreferencesWishlistRepository();

  static const _storageKey = 'wishlist_status_entries';

  @override
  Future<List<WishlistStatusEntry>> getEntries() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return const [];
    }

    final entries =
        decoded
            .whereType<Map>()
            .map((json) => WishlistStatusEntry.fromJson(Map.from(json)))
            .where((entry) => entry.itemId.trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries;
  }

  @override
  Future<WishlistStatus> getStatusForItem(String itemId) async {
    final entries = await getEntries();
    for (final entry in entries) {
      if (entry.itemId == itemId) {
        return entry.status;
      }
    }
    return WishlistStatus.owned;
  }

  @override
  Future<void> saveStatus({
    required CollectibleItem item,
    required WishlistStatus status,
  }) async {
    final entries = await getEntries();
    final next = [
      WishlistStatusEntry(
        itemId: item.id,
        title: item.title,
        category: item.category,
        status: status,
        updatedAt: DateTime.now(),
      ),
      ...entries.where((entry) => entry.itemId != item.id),
    ];
    await _persist(next);
  }

  @override
  Future<void> deleteStatus(String itemId) async {
    final entries = await getEntries();
    await _persist(
      entries.where((entry) => entry.itemId != itemId).toList(growable: false),
    );
  }

  @override
  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_storageKey);
  }

  Future<void> _persist(List<WishlistStatusEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _storageKey,
      jsonEncode([for (final entry in entries) entry.toJson()]),
    );
  }
}
