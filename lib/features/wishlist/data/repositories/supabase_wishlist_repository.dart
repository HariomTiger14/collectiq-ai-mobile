import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/wishlist/data/repositories/shared_preferences_wishlist_repository.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Cloud-backed wishlist repository. When the user is signed in, the
/// `collector_wishlist_entries` table is the source of truth and the local
/// SharedPreferences store is kept as an offline mirror. When signed out (or
/// Supabase is unconfigured) it transparently degrades to the local store.
///
/// Deletion is a soft flag (`deleted = true`) so a locally-removed entry is
/// never resurrected on another device — the same approach the price-alert
/// sync uses with `enabled`.
class SupabaseWishlistRepository implements WishlistRepository {
  const SupabaseWishlistRepository({
    required this.authService,
    required this.supabaseDataGateway,
    this.localRepository = const SharedPreferencesWishlistRepository(),
    this.tableName = 'collector_wishlist_entries',
  });

  final AuthService authService;
  final SupabaseDataGateway supabaseDataGateway;
  final WishlistRepository localRepository;
  final String tableName;

  @override
  Future<List<WishlistStatusEntry>> getEntries() async {
    final cloudEntries = await _fetchCloudEntries();
    if (cloudEntries != null) {
      await _replaceLocalEntries(cloudEntries);
      return cloudEntries;
    }
    return localRepository.getEntries();
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
    await localRepository.saveStatus(item: item, status: status);
    final session = await _signedInSession();
    if (session == null) {
      return;
    }

    final entry = WishlistStatusEntry(
      itemId: item.id,
      title: item.title,
      category: item.category,
      status: status,
      updatedAt: DateTime.now(),
    );
    try {
      await supabaseDataGateway.authenticatedPostWithSession<List<dynamic>>(
        '/rest/v1/$tableName',
        session: session,
        queryParameters: const {'on_conflict': 'user_id,portfolio_item_id'},
        data: [supabaseRowForWishlistEntry(entry, session.userId)],
        options: Options(
          headers: const {
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
        ),
      );
    } on Object catch (error) {
      debugPrint('[Wishlist] cloud save failed: $error');
    }
  }

  @override
  Future<void> deleteStatus(String itemId) async {
    await localRepository.deleteStatus(itemId);
    final session = await _signedInSession();
    if (session == null) {
      return;
    }

    try {
      await supabaseDataGateway.authenticatedPostWithSession<List<dynamic>>(
        '/rest/v1/$tableName',
        session: session,
        queryParameters: const {'on_conflict': 'user_id,portfolio_item_id'},
        data: [
          {
            'user_id': session.userId,
            'portfolio_item_id': itemId,
            'deleted': true,
            'updated_at': DateTime.now().toIso8601String(),
          },
        ],
        options: Options(
          headers: const {
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
        ),
      );
    } on Object catch (error) {
      debugPrint('[Wishlist] cloud delete failed: $error');
    }
  }

  @override
  Future<void> clear() async {
    await localRepository.clear();
    final entries = await _fetchCloudEntries();
    if (entries == null) {
      return;
    }
    for (final entry in entries) {
      await deleteStatus(entry.itemId);
    }
  }

  Future<List<WishlistStatusEntry>?> _fetchCloudEntries() async {
    final session = await _signedInSession();
    if (session == null) {
      return null;
    }

    try {
      final response = await supabaseDataGateway
          .authenticatedGetWithSession<List<dynamic>>(
            '/rest/v1/$tableName',
            session: session,
            queryParameters: const {
              'select': '*',
              'deleted': 'eq.false',
              'order': 'updated_at.desc',
            },
          );
      return (response.data ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(wishlistEntryFromSupabaseRow)
          .nonNulls
          .where((entry) => entry.itemId.trim().isNotEmpty)
          .toList(growable: false);
    } on Object catch (error) {
      debugPrint('[Wishlist] cloud fetch failed: $error');
      return null;
    }
  }

  Future<SupabaseAuthSession?> _signedInSession() async {
    if (!supabaseDataGateway.isConfigured) {
      return null;
    }
    final session = await supabaseDataGateway.currentSession();
    if (session == null || session.isAnonymous) {
      return null;
    }
    if (!await authService.isSignedIn()) {
      return null;
    }
    return session;
  }

  Future<void> _replaceLocalEntries(List<WishlistStatusEntry> entries) async {
    await localRepository.clear();
    for (final entry in entries) {
      await localRepository.saveStatus(
        item: _itemFromEntry(entry),
        status: entry.status,
      );
    }
  }
}

CollectibleItem _itemFromEntry(WishlistStatusEntry entry) {
  return CollectibleItem(
    id: entry.itemId,
    title: entry.title,
    category: entry.category,
    estimatedValue: 0,
    confidence: 0,
    condition: 'Unknown',
    recommendation: '',
    imagePath: '',
    createdAt: entry.updatedAt,
  );
}

@visibleForTesting
Map<String, dynamic> supabaseRowForWishlistEntry(
  WishlistStatusEntry entry,
  String userId,
) {
  return {
    'user_id': userId,
    'portfolio_item_id': entry.itemId,
    'title': entry.title,
    'category': entry.category,
    'status': entry.status.name,
    'deleted': false,
    'raw_json': entry.toJson(),
    'updated_at': entry.updatedAt.toIso8601String(),
  };
}

@visibleForTesting
WishlistStatusEntry? wishlistEntryFromSupabaseRow(Map<String, dynamic> row) {
  try {
    final rawJson = row['raw_json'];
    if (rawJson is Map) {
      return WishlistStatusEntry.fromJson({
        ...rawJson.map((key, value) => MapEntry(key.toString(), value)),
        'itemId': row['portfolio_item_id'] ?? rawJson['itemId'],
        'title': row['title'] ?? rawJson['title'],
        'category': row['category'] ?? rawJson['category'],
        'status': row['status'] ?? rawJson['status'],
        'updatedAt': row['updated_at'] ?? rawJson['updatedAt'],
      });
    }

    return WishlistStatusEntry(
      itemId: row['portfolio_item_id'] as String? ?? '',
      title: row['title'] as String? ?? 'Collectible',
      category: row['category'] as String? ?? 'Other',
      status: wishlistStatusFromName(row['status'] as String?),
      updatedAt:
          DateTime.tryParse(row['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  } on Object {
    return null;
  }
}
