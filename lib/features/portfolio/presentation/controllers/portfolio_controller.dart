import 'package:collectiq_ai/core/cloud/cloud_portfolio_sync_coordinator.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
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
  bool _hasLoaded = false;

  @override
  PortfolioState build() {
    _repository = ref.watch(portfolioRepositoryProvider);
    ensureLoaded();
    return const PortfolioState();
  }

  void ensureLoaded() {
    if (_hasLoaded) {
      return;
    }
    _hasLoaded = true;
    Future.microtask(loadItems);
  }

  /// Loads all portfolio items from the repository.
  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final items = await _repository.getItems();
      state = state.copyWith(
        items: collectiblesNewestFirst(items),
        isLoading: false,
      );
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
      final immediateItems = collectiblesNewestFirst([
        savedItem,
        ...state.items.where((existingItem) => existingItem.id != savedItem.id),
      ]);
      state = state.copyWith(items: immediateItems, isLoading: false);

      final persistedItems = await _repository.getItems();
      state = state.copyWith(
        items: collectiblesNewestFirst(persistedItems),
        isLoading: false,
      );
      await _syncPendingCloudItems();
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
      state = state.copyWith(
        items: collectiblesNewestFirst(items),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to merge cloud portfolio item.',
      );
    }
  }

  /// Updates [item] locally and refreshes portfolio state.
  Future<void> updateItem(CollectibleItem item) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _repository.updateItem(item);
      final immediateItems = collectiblesNewestFirst([
        item,
        ...state.items.where((existingItem) => existingItem.id != item.id),
      ]);
      state = state.copyWith(items: immediateItems, isLoading: false);

      final persistedItems = await _repository.getItems();
      state = state.copyWith(
        items: collectiblesNewestFirst(persistedItems),
        isLoading: false,
      );
      await _syncUpdatedCloudItem(item);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to update portfolio item.',
      );
    }
  }

  /// Removes the item with [id] and refreshes portfolio state.
  Future<void> removeItem(String id) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      await _repository.removeItem(id);
      final items = await _repository.getItems();
      state = state.copyWith(
        items: collectiblesNewestFirst(items),
        isLoading: false,
      );
      await _deleteCloudItem(id);
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

  Future<void> _syncPendingCloudItems() async {
    try {
      await CloudPortfolioSyncCoordinator(
        registry: ref.read(cloudServiceRegistryProvider),
        portfolioRepository: _repository,
      ).syncPendingItems();
      final items = collectiblesNewestFirst(await _repository.getItems());
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {}
  }

  Future<void> _syncUpdatedCloudItem(CollectibleItem item) async {
    try {
      await CloudPortfolioSyncCoordinator(
        registry: ref.read(cloudServiceRegistryProvider),
        portfolioRepository: _repository,
      ).syncUpdatedItem(item);
      final items = collectiblesNewestFirst(await _repository.getItems());
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {}
  }

  Future<void> _deleteCloudItem(String id) async {
    try {
      await CloudPortfolioSyncCoordinator(
        registry: ref.read(cloudServiceRegistryProvider),
        portfolioRepository: _repository,
      ).deleteCloudItem(id);
    } catch (_) {}
  }
}

/// Provides portfolio state and actions.
final portfolioControllerProvider =
    NotifierProvider<PortfolioController, PortfolioState>(
      PortfolioController.new,
    );
