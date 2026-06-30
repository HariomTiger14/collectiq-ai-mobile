import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
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

  /// Canonical newest-first list for every display surface.
  List<CollectibleItem> get orderedItems => collectiblesNewestFirst(items);

  /// Whether a portfolio operation is in progress.
  final bool isLoading;

  /// User-safe portfolio error message.
  final String? errorMessage;

  /// Total estimated portfolio value.
  double get totalValue {
    return orderedItems.fold<double>(
      0,
      (total, item) => total + item.estimatedValue,
    );
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
      final sortedItems = collectiblesNewestFirst(items);
      _logFinalOrder('loadItems', sortedItems);
      state = state.copyWith(items: sortedItems, isLoading: false);
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
      final savedItem = await _repository.addItem(item);
      debugPrint(
        '[PortfolioController] saveItem returned saved item '
        'id=${savedItem.id} '
        'title="${savedItem.title}" '
        'createdAt=${savedItem.createdAt.toIso8601String()} '
        'savedAt=${savedItem.createdAt.toIso8601String()} '
        'updatedAt=not-tracked '
        'displayTimestamp='
        '${collectibleDisplayTimestamp(savedItem).toIso8601String()}',
      );
      final immediateItems = collectiblesNewestFirst([
        savedItem,
        ...state.items.where((existingItem) => existingItem.id != savedItem.id),
      ]);
      _logFinalOrder('saveItem-immediate', immediateItems);
      state = state.copyWith(items: immediateItems, isLoading: false);

      final persistedItems = await _repository.getItems();
      final sortedItems = collectiblesNewestFirst(persistedItems);
      _logFinalOrder('saveItem-reload', sortedItems);
      state = state.copyWith(items: sortedItems, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to save portfolio item.',
      );
    }
  }

  /// Merges a cloud item into local state without changing its saved timestamp.
  Future<void> upsertSyncedItem(CollectibleItem item) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _repository.upsertSyncedItem(item);
      final items = await _repository.getItems();
      final sortedItems = collectiblesNewestFirst(items);
      _logFinalOrder('upsertSyncedItem', sortedItems);
      state = state.copyWith(items: sortedItems, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to merge cloud portfolio item.',
      );
    }
  }

  /// Removes the item with [id] and refreshes portfolio state.
  Future<void> removeItem(String id) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _repository.removeItem(id);
      final items = await _repository.getItems();
      final sortedItems = collectiblesNewestFirst(items);
      _logFinalOrder('removeItem', sortedItems);
      state = state.copyWith(items: sortedItems, isLoading: false);
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

  void _logFinalOrder(String source, List<CollectibleItem> items) {
    debugPrint(
      '[PortfolioController] $source final order: '
      '${items.map((item) => '${item.id}@${collectibleDisplayTimestamp(item).toIso8601String()}').join(' > ')}',
    );
    for (final item in items) {
      debugPrint(
        '[PortfolioController] $source item '
        'id=${item.id} '
        'title="${item.title}" '
        'imagePath=${item.imagePath} '
        'createdAt=${item.createdAt.toIso8601String()} '
        'savedAt=${item.createdAt.toIso8601String()} '
        'updatedAt=not-tracked '
        'displayTimestamp='
        '${collectibleDisplayTimestamp(item).toIso8601String()}',
      );
    }
  }
}

/// Provides portfolio state and actions.
final portfolioControllerProvider =
    NotifierProvider<PortfolioController, PortfolioState>(
      PortfolioController.new,
    );
