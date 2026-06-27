import 'dart:convert';

import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local portfolio repository backed by shared preferences.
class SharedPreferencesPortfolioRepository implements PortfolioRepository {
  /// Creates a shared preferences portfolio repository.
  const SharedPreferencesPortfolioRepository();

  static const _itemsKey = 'portfolio_items';

  @override
  Future<void> addItem(CollectibleItem item) async {
    debugPrint(
      '[PortfolioRepository] saving item.imagePath: '
      '${item.imagePath}',
    );
    final items = await getItems();
    final updatedItems = [
      item,
      ...items.where((existingItem) => existingItem.id != item.id),
    ];
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
        .toList(growable: false);
    for (final item in items) {
      debugPrint(
        '[PortfolioRepository] loaded item.imagePath: '
        '${item.imagePath}',
      );
    }
    return items;
  }

  @override
  Future<void> removeItem(String id) async {
    final items = await getItems();
    final updatedItems = items.where((item) => item.id != id).toList();
    await _saveItems(updatedItems);
  }

  @override
  Future<void> clearPortfolio() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_itemsKey);
  }

  Future<void> _saveItems(List<CollectibleItem> items) async {
    final preferences = await SharedPreferences.getInstance();
    final encodedItems = jsonEncode(
      items.map((item) => item.toJson()).toList(growable: false),
    );
    await preferences.setString(_itemsKey, encodedItems);
  }
}
