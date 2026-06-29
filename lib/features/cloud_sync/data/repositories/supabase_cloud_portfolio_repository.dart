import 'package:collectiq_ai/core/supabase/supabase_ids.dart';
import 'package:collectiq_ai/core/supabase/supabase_schema.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/core/utils/json_parse.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/repositories/cloud_portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class SupabaseCloudPortfolioRepository implements CloudPortfolioRepository {
  const SupabaseCloudPortfolioRepository({required this.supabaseService});

  final SupabaseService supabaseService;

  @override
  Future<SyncStatus> getSyncStatus() async {
    if (!supabaseService.isConfigured) {
      return const SyncStatus(
        state: SyncState.localOnly,
        message: 'Cloud sync is not configured. Portfolio is saved locally.',
        isCloudBackupEnabled: false,
      );
    }

    debugPrint('[Sync] ensuring anonymous Supabase session for sync status');
    final session = await supabaseService.ensureAnonymousSession();
    debugPrint('[Sync] Supabase current user id: ${session.userId}');
    return SyncStatus(
      state: SyncState.synced,
      message: 'Cloud connected as anonymous user ${_shortId(session.userId)}.',
      isCloudBackupEnabled: true,
      authenticatedUserId: session.userId,
      lastSyncedAt: DateTime.now(),
    );
  }

  @override
  Future<SyncStatus> uploadLocalItems(List<CollectibleItem> items) async {
    if (!supabaseService.isConfigured) {
      return SyncStatus(
        state: SyncState.localOnly,
        message: 'Cloud sync is not configured. Portfolio is saved locally.',
        isCloudBackupEnabled: false,
        pendingItemCount: items.length,
      );
    }

    final session = await supabaseService.ensureAnonymousSession();
    if (items.isEmpty) {
      return SyncStatus(
        state: SyncState.synced,
        message: 'Cloud connected. No local items need upload.',
        isCloudBackupEnabled: true,
        authenticatedUserId: session.userId,
        lastSyncedAt: DateTime.now(),
      );
    }

    try {
      debugPrint(
        '[Sync] uploading ${items.length} item(s) for ${session.userId}',
      );
      final rows = [
        for (final item in items) _rowForItem(item, session.userId),
      ];
      debugPrint('[Sync] collectibles upsert payload keys: ${rows.first.keys}');
      await supabaseService.authenticatedPost<List<dynamic>>(
        '/rest/v1/${SupabaseTables.collectibles}',
        queryParameters: const {'on_conflict': 'id'},
        data: rows,
        options: Options(
          headers: const {
            'Prefer': 'resolution=merge-duplicates,return=minimal',
          },
        ),
      );

      return SyncStatus(
        state: SyncState.synced,
        message: 'Cloud sync complete.',
        isCloudBackupEnabled: true,
        authenticatedUserId: session.userId,
        lastSyncedAt: DateTime.now(),
      );
    } on Exception catch (error) {
      debugPrint('[Sync] upload failed: $error');
      return SyncStatus(
        state: SyncState.failed,
        message: 'Cloud sync failed. Changes remain saved locally.',
        isCloudBackupEnabled: true,
        pendingItemCount: items.length,
      );
    }
  }

  @override
  Future<List<CollectibleItem>> downloadCloudItems() async {
    if (!supabaseService.isConfigured) {
      return const [];
    }

    await supabaseService.ensureAnonymousSession();
    final response = await supabaseService.authenticatedGet<List<dynamic>>(
      '/rest/v1/${SupabaseTables.collectibles}',
      queryParameters: const {'select': '*', 'order': 'updated_at.desc'},
    );

    final rows = response.data ?? const [];
    return rows
        .whereType<Map<String, dynamic>>()
        .map(itemFromCloudRow)
        .toList(growable: false);
  }

  Map<String, dynamic> _rowForItem(CollectibleItem item, String userId) {
    return {
      'id': cloudUuidFor(item.id),
      'user_id': userId,
      'title': item.title,
      'category': item.category,
      'condition': item.condition,
      'image_path': item.imagePath,
      'image_storage_path': item.imageStoragePath,
      'estimated_value': item.estimatedValue,
      'confidence': item.confidence,
      'metadata': {
        'localId': item.id,
        'year': item.year,
        'brand': item.brand,
        'setName': item.setName,
        'series': item.series,
        'cardNumber': item.cardNumber,
        'playerOrCharacter': item.playerOrCharacter,
        'rarity': item.rarity,
        'estimatedGrade': item.estimatedGrade,
        'language': item.language,
        'edition': item.edition,
        'country': item.country,
        'mint': item.mint,
        'material': item.material,
        'notes': item.notes,
        'recommendation': item.recommendation,
        'cloudImageUrl': item.cloudImageUrl,
      },
      'ai_review': {
        'primaryMatch': item.primaryMatch,
        'alternativeMatches': [
          for (final match in item.alternativeMatches) match.toJson(),
        ],
        'confidenceExplanation': item.confidenceExplanation,
        'detectionQuality': item.detectionQuality,
        'aiReasoning': item.aiReasoning,
      },
      'pricing': item.pricing?.toJson() ?? const <String, dynamic>{},
      'saved_at': item.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  CollectibleItem itemFromCloudRow(Map<String, dynamic> row) {
    final metadata = parseJsonMap(row['metadata']);
    final aiReview = parseJsonMap(row['ai_review']);
    final pricing = parseJsonMap(row['pricing']);
    final storagePath = _optionalString(row['image_storage_path']);
    final cloudImageUrl =
        _optionalString(metadata['cloudImageUrl']) ??
        _publicUrlFor(storagePath);
    final createdAt =
        parseNullableDateTime(row['saved_at']) ??
        parseNullableDateTime(row['created_at']) ??
        DateTime.now();

    return CollectibleItem.fromJson({
      'id':
          _optionalString(metadata['localId']) ??
          parseString(
            row['id'],
            fallback: 'cloud-${DateTime.now().microsecondsSinceEpoch}',
          ),
      'title': parseString(row['title'], fallback: 'Untitled collectible'),
      'category': parseString(row['category'], fallback: 'Collectible'),
      'estimatedValue': parseNullableDouble(row['estimated_value']) ?? 0,
      'confidence': parseNullableDouble(row['confidence']) ?? 0,
      'condition': parseString(row['condition'], fallback: 'Unknown'),
      'recommendation': parseString(metadata['recommendation']),
      'imagePath': cloudImageUrl ?? parseString(row['image_path']),
      'imageStoragePath': storagePath,
      'cloudImageUrl': cloudImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'pricing': pricing.isEmpty ? null : pricing,
      'primaryMatch': aiReview['primaryMatch'],
      'alternativeMatches': aiReview['alternativeMatches'],
      'confidenceExplanation': aiReview['confidenceExplanation'],
      'detectionQuality': aiReview['detectionQuality'],
      'aiReasoning': aiReview['aiReasoning'],
      'year': metadata['year'],
      'brand': metadata['brand'],
      'setName': metadata['setName'],
      'series': metadata['series'],
      'cardNumber': metadata['cardNumber'],
      'playerOrCharacter': metadata['playerOrCharacter'],
      'rarity': metadata['rarity'],
      'estimatedGrade': metadata['estimatedGrade'],
      'language': metadata['language'],
      'edition': metadata['edition'],
      'country': metadata['country'],
      'mint': metadata['mint'],
      'material': metadata['material'],
      'notes': metadata['notes'],
    });
  }

  String? _publicUrlFor(String? storagePath) {
    final baseUri = supabaseService.config.baseUri;
    if (storagePath == null || storagePath.isEmpty || baseUri == null) {
      return null;
    }

    return baseUri.resolve('/storage/v1/object/public/$storagePath').toString();
  }
}

String? _optionalString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value;
  }

  return null;
}

String _shortId(String value) {
  if (value.length <= 8) {
    return value;
  }

  return value.substring(0, 8);
}
