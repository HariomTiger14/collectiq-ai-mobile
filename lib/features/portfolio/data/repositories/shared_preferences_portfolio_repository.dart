import 'dart:convert';

import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local portfolio repository backed by shared preferences.
class SharedPreferencesPortfolioRepository implements PortfolioRepository {
  /// Creates a shared preferences portfolio repository.
  const SharedPreferencesPortfolioRepository();

  static const _itemsKey = 'portfolio_items';

  @override
  Future<CollectibleItem> addItem(CollectibleItem item) async {
    final items = await getItems();
    final savedAt = _nextSavedAt(items);
    final savedItem = item.copyWithSavedAt(savedAt);
    _logItemTimestamp('saving', savedItem);
    final updatedItems = [
      savedItem,
      ...items.where((existingItem) => existingItem.id != savedItem.id),
    ]..sort(compareCollectiblesNewestFirst);
    _logFinalOrder('addItem-before-persist', updatedItems);
    await _saveItems(updatedItems);
    return savedItem;
  }

  @override
  Future<void> upsertSyncedItem(CollectibleItem item) async {
    final items = await getItems();
    final updatedItems = [
      item,
      ...items.where((existingItem) => existingItem.id != item.id),
    ]..sort(compareCollectiblesNewestFirst);
    _logFinalOrder('upsertSyncedItem-before-persist', updatedItems);
    await _saveItems(updatedItems);
  }

  @override
  Future<List<CollectibleItem>> getItems() async {
    final preferences = await SharedPreferences.getInstance();
    final encodedItems = preferences.getString(_itemsKey);
    if (encodedItems == null || encodedItems.isEmpty) {
      return const [];
    }

    final decodedItems = jsonDecode(encodedItems) as List<dynamic>;
    final items = decodedItems
        .map((item) => CollectibleItem.fromJson(item as Map<String, dynamic>))
        .toList();
    final sortedItems = collectiblesNewestFirst(items);
    _logFinalOrder('loaded', sortedItems);
    for (final item in sortedItems) {
      _logItemTimestamp('loaded', item);
    }
    return sortedItems;
  }

  @override
  Future<void> removeItem(String id) async {
    final items = await getItems();
    final updatedItems = items.where((item) => item.id != id).toList();
    await _saveItems(updatedItems);
  }

  @override
  Future<void> updateItemImageSync({
    required String itemId,
    required String imageStoragePath,
    required String cloudImageUrl,
  }) async {
    final items = await getItems();
    final updatedItems = [
      for (final item in items)
        if (item.id == itemId)
          item.copyWithImageSync(
            imageStoragePath: imageStoragePath,
            cloudImageUrl: cloudImageUrl,
          )
        else
          item,
    ]..sort(compareCollectiblesNewestFirst);
    await _saveItems(updatedItems);
  }

  @override
  Future<void> clearPortfolio() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_itemsKey);
  }

  Future<void> _saveItems(List<CollectibleItem> items) async {
    final preferences = await SharedPreferences.getInstance();
    final sortedItems = collectiblesNewestFirst(items);
    _logFinalOrder('persisting', sortedItems);
    for (final item in sortedItems) {
      _logItemTimestamp('persisting', item);
    }
    final encodedItems = jsonEncode(
      sortedItems.map((item) => item.toJson()).toList(growable: false),
    );
    await preferences.setString(_itemsKey, encodedItems);
  }

  DateTime _nextSavedAt(List<CollectibleItem> existingItems) {
    final now = DateTime.now();
    if (existingItems.isEmpty) {
      return now;
    }

    final newestExisting = collectibleDisplayTimestamp(existingItems.first);
    if (now.isAfter(newestExisting)) {
      return now;
    }

    final adjusted = newestExisting.add(const Duration(microseconds: 1));
    debugPrint(
      '[PortfolioRepository] adjusted savedAt above existing max '
      'now=${now.toIso8601String()} '
      'newestExisting=${newestExisting.toIso8601String()} '
      'adjusted=${adjusted.toIso8601String()}',
    );
    return adjusted;
  }

  void _logItemTimestamp(String action, CollectibleItem item) {
    debugPrint(
      '[PortfolioRepository] $action item '
      'id=${item.id} '
      'title="${item.title}" '
      'imageSource=${_imageSourceFor(item.imagePath)} '
      'createdAt=${item.createdAt.toIso8601String()} '
      'savedAt=${item.createdAt.toIso8601String()} '
      'updatedAt=not-tracked '
      'displayTimestamp='
      '${collectibleDisplayTimestamp(item).toIso8601String()}',
    );
  }

  void _logFinalOrder(String action, List<CollectibleItem> items) {
    debugPrint(
      '[PortfolioRepository] $action final order: '
      '${items.map((item) => '${item.id}@${collectibleDisplayTimestamp(item).toIso8601String()}').join(' > ')}',
    );
  }

  String _imageSourceFor(String imagePath) {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.startsWith('sample://')) {
      return 'sample';
    }
    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return 'network';
    }
    if (normalizedPath.startsWith('assets/')) {
      return 'asset';
    }
    if (normalizedPath.isEmpty) {
      return 'missing';
    }

    return 'local';
  }
}
