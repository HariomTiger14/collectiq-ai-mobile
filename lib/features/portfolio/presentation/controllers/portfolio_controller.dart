import 'dart:io';

import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the local portfolio repository.
final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return const SharedPreferencesPortfolioRepository();
});

/// Immutable state for the portfolio feature.
class PortfolioState {
  /// Creates portfolio state.
  const PortfolioState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  /// Saved portfolio items.
  final List<CollectibleItem> items;

  /// Whether a portfolio operation is in progress.
  final bool isLoading;

  /// User-safe portfolio error message.
  final String? errorMessage;

  /// Total estimated portfolio value.
  double get totalValue {
    return items.fold<double>(0, (total, item) => total + item.estimatedValue);
  }

  /// Total saved item count.
  int get itemCount => items.length;

  /// Creates a copy with updated fields.
  PortfolioState copyWith({
    List<CollectibleItem>? items,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return PortfolioState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

/// Coordinates portfolio presentation state.
class PortfolioController extends Notifier<PortfolioState> {
  /// Portfolio repository dependency.
  late final PortfolioRepository _repository;

  @override
  PortfolioState build() {
    _repository = ref.watch(portfolioRepositoryProvider);
    Future.microtask(loadItems);
    return const PortfolioState();
  }

  /// Loads all portfolio items from the repository.
  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final items = await _repository.getItems();
      await _logLoadedImagePaths(items);
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load portfolio.',
      );
    }
  }

  /// Saves [item] and refreshes portfolio state.
  Future<void> saveItem(CollectibleItem item) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _repository.addItem(item);
      final items = await _repository.getItems();
      await _logLoadedImagePaths(items);
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to save portfolio item.',
      );
    }
  }

  /// Removes the item with [id] and refreshes portfolio state.
  Future<void> removeItem(String id) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _repository.removeItem(id);
      final items = await _repository.getItems();
      await _logLoadedImagePaths(items);
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to remove portfolio item.',
      );
    }
  }

  /// Clears all saved portfolio items.
  Future<void> clearPortfolio() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _repository.clearPortfolio();
      state = state.copyWith(items: const [], isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to clear portfolio.',
      );
    }
  }

  Future<void> _logLoadedImagePaths(List<CollectibleItem> items) async {
    for (final item in items) {
      debugPrint('[Portfolio] loaded item.imagePath: ${item.imagePath}');
      debugPrint(
        '[Portfolio] loaded image file exists: '
        '${await _localFileExists(item.imagePath)}',
      );
    }
  }

  Future<bool> _localFileExists(String imagePath) async {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty ||
        normalizedPath.startsWith('sample://') ||
        normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://') ||
        normalizedPath.startsWith('assets/')) {
      return false;
    }

    return File(normalizedPath).exists();
  }
}

/// Provides portfolio state and actions.
final portfolioControllerProvider =
    NotifierProvider<PortfolioController, PortfolioState>(
      PortfolioController.new,
    );
