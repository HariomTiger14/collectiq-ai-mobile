import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_bootstrap.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:dio/dio.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/foundation.dart';

class SupabaseCloudPortfolioSyncService implements CloudPortfolioSyncService {
  SupabaseCloudPortfolioSyncService({
    required this.bootstrap,
    required this.authService,
    this.supabaseDataGateway,
    this.tableName = 'portfolio_items',
  });

  final SupabaseBootstrap bootstrap;
  final AuthService authService;
  final SupabaseDataGateway? supabaseDataGateway;
  final String tableName;

  @override
  String get providerName => 'Supabase Portfolio Sync';

  @override
  Future<void> syncItem(CollectibleItem item) async {
    if (await _syncItemWithRestSession(item)) {
      return;
    }

    final userId = await _signedInUserId();
    if (userId == null) {
      return;
    }
    await bootstrap.client!
        .from(tableName)
        .upsert(supabaseRowForItem(item, userId));
  }

  @override
  Future<void> deleteItem(String itemId) async {
    if (await _deleteItemWithRestSession(itemId)) {
      return;
    }

    final userId = await _signedInUserId();
    if (userId == null) {
      return;
    }
    await bootstrap.client!
        .from(tableName)
        .update({'sync_status': 'deleted', 'updated_at': _nowIso()})
        .eq('id', itemId)
        .eq('user_id', userId);
  }

  @override
  Future<List<CollectibleItem>> fetchItems() async {
    final restItems = await _fetchItemsWithRestSession();
    if (restItems != null) {
      return restItems;
    }

    final userId = await _signedInUserId();
    if (userId == null) {
      return const [];
    }
    final rows = await bootstrap.client!
        .from(tableName)
        .select()
        .eq('user_id', userId)
        .neq('sync_status', 'deleted')
        .order('created_at', ascending: false);

    final items = <CollectibleItem>[];
    for (final row in rows.whereType<Map<String, dynamic>>()) {
      final item = itemFromSupabaseRow(row);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  @override
  Future<CollectibleItem> markSynced(CollectibleItem item) async {
    return item.copyWithCloudSync(
      syncStatus: CloudItemSyncStatus.synced,
      lastSyncedAt: DateTime.now(),
      clearSyncError: true,
    );
  }

  @override
  Future<CloudPortfolioSyncStatus> getSyncStatus() async {
    final gateway = supabaseDataGateway;
    if (gateway != null && gateway.isConfigured) {
      final session = await gateway.currentSession();
      if (session == null || session.isAnonymous) {
        return const CloudPortfolioSyncStatus(
          enabled: false,
          message:
              'Sign in to enable Supabase cloud sync. Local portfolio is active.',
        );
      }
      return CloudPortfolioSyncStatus(
        enabled: true,
        message: 'Supabase portfolio sync ready.',
        userId: session.userId,
      );
    }

    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return CloudPortfolioSyncStatus(enabled: false, message: ready.message);
    }
    final userId = await authService.currentUserId();
    if (userId == null || userId.trim().isEmpty) {
      return const CloudPortfolioSyncStatus(
        enabled: false,
        message: 'Cloud sync skipped: no signed-in Supabase user.',
      );
    }
    return CloudPortfolioSyncStatus(
      enabled: true,
      message: 'Supabase portfolio sync ready.',
      userId: userId,
    );
  }

  Future<String?> _signedInUserId() async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized || !await authService.isSignedIn()) {
      return null;
    }
    final userId = await authService.currentUserId();
    if (userId == null || userId.trim().isEmpty) {
      return null;
    }
    return userId;
  }

  Future<SupabaseAuthSession?> _signedInRestSession() async {
    final gateway = supabaseDataGateway;
    if (gateway == null || !gateway.isConfigured) {
      return null;
    }
    final session = await gateway.currentSession();
    if (session == null || session.isAnonymous) {
      return null;
    }
    return session;
  }

  Future<bool> _syncItemWithRestSession(CollectibleItem item) async {
    final gateway = supabaseDataGateway;
    final session = await _signedInRestSession();
    if (gateway == null || session == null) {
      return false;
    }
    await gateway.authenticatedPostWithSession<List<dynamic>>(
      '/rest/v1/$tableName',
      session: session,
      queryParameters: const {'on_conflict': 'id,user_id'},
      data: [supabaseRowForItem(item, session.userId)],
      options: Options(
        headers: const {'Prefer': 'resolution=merge-duplicates,return=minimal'},
      ),
    );
    return true;
  }

  Future<bool> _deleteItemWithRestSession(String itemId) async {
    final gateway = supabaseDataGateway;
    final session = await _signedInRestSession();
    if (gateway == null || session == null) {
      return false;
    }
    await gateway.authenticatedPostWithSession<List<dynamic>>(
      '/rest/v1/$tableName',
      session: session,
      queryParameters: const {'on_conflict': 'id,user_id'},
      data: [
        {
          'id': itemId,
          'user_id': session.userId,
          'sync_status': 'deleted',
          'updated_at': _nowIso(),
        },
      ],
      options: Options(
        headers: const {'Prefer': 'resolution=merge-duplicates,return=minimal'},
      ),
    );
    return true;
  }

  Future<List<CollectibleItem>?> _fetchItemsWithRestSession() async {
    final gateway = supabaseDataGateway;
    final session = await _signedInRestSession();
    if (gateway == null || session == null) {
      return null;
    }
    final response = await gateway.authenticatedGetWithSession<List<dynamic>>(
      '/rest/v1/$tableName',
      session: session,
      queryParameters: const {
        'select': '*',
        'sync_status': 'neq.deleted',
        'order': 'created_at.desc',
      },
    );

    final rows = response.data ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(itemFromSupabaseRow)
        .nonNulls
        .toList(growable: false);
  }
}

@visibleForTesting
Map<String, dynamic> supabaseRowForItem(CollectibleItem item, String userId) {
  final rawJson = item.toJson();
  return {
    'id': item.id,
    'user_id': userId,
    'category': item.category,
    'title': item.title,
    'manufacturer': item.brand,
    'series': item.series ?? item.setName,
    'year': _parseYear(item.year),
    'country': item.country,
    'estimated_value_low':
        item.pricing?.lowEstimate ?? item.marketSummary?.lowPrice,
    'estimated_value_high':
        item.pricing?.highEstimate ?? item.marketSummary?.highPrice,
    'image_local_path': item.imagePath,
    'image_storage_path': item.imageStoragePath,
    'cloud_image_url': item.cloudImageUrl,
    'sync_status': item.syncStatus.name,
    'last_synced_at': item.lastSyncedAt?.toIso8601String(),
    'raw_json': rawJson,
    'created_at': item.createdAt.toIso8601String(),
    'updated_at': _nowIso(),
  };
}

@visibleForTesting
CollectibleItem? itemFromSupabaseRow(Map<String, dynamic> row) {
  final rawJson = row['raw_json'];
  try {
    if (rawJson is Map) {
      final typedRawJson = rawJson.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return CollectibleItem.fromJson({
        ...typedRawJson,
        'id': row['id'] ?? typedRawJson['id'],
        'imageStoragePath':
            row['image_storage_path'] ?? typedRawJson['imageStoragePath'],
        'cloudImageUrl':
            row['cloud_image_url'] ?? typedRawJson['cloudImageUrl'],
        'syncStatus': row['sync_status'] ?? typedRawJson['syncStatus'],
        'lastSyncedAt': row['last_synced_at'] ?? typedRawJson['lastSyncedAt'],
        'createdAt': row['created_at'] ?? typedRawJson['createdAt'],
      });
    }

    return CollectibleItem.fromJson({
      'id': row['id'] as String? ?? '',
      'title': row['title'] as String? ?? 'Unknown collectible',
      'category': row['category'] as String? ?? 'Other',
      'estimatedValue': _number(row['estimated_value_high']) ?? 0,
      'confidence': 0,
      'condition': 'Unknown',
      'recommendation': 'Review this synced collectible.',
      'imagePath': row['image_local_path'] as String? ?? '',
      'imageStoragePath': row['image_storage_path'],
      'cloudImageUrl': row['cloud_image_url'],
      'syncStatus': row['sync_status'],
      'lastSyncedAt': row['last_synced_at'],
      'createdAt': row['created_at'],
      'brand': row['manufacturer'],
      'series': row['series'],
      'year': row['year']?.toString(),
      'country': row['country'],
    });
  } on Object {
    return null;
  }
}

int? _parseYear(String? value) {
  if (value == null) {
    return null;
  }
  return int.tryParse(value.trim());
}

num? _number(Object? value) {
  if (value is num) {
    return value;
  }
  if (value is String) {
    return num.tryParse(value);
  }
  return null;
}

String _nowIso() => DateTime.now().toIso8601String();
