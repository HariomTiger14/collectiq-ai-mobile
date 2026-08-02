import 'dart:async';

import 'package:collectiq_ai/core/cloud/cloud_portfolio_sync_coordinator.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_valuation_snapshot_repository.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/domain/services/demo_collectible_seed_service.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the local portfolio repository.
final portfolioRepositoryProvider = Provider<PortfolioRepository>((ref) {
  return const SharedPreferencesPortfolioRepository();
});

final valuationSnapshotRepositoryProvider =
    Provider<SharedPreferencesValuationSnapshotRepository>((ref) {
      return const SharedPreferencesValuationSnapshotRepository();
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
  // Evaluates saved price alerts against the current portfolio values and fires
  // any that meet their condition. Best-effort; runs whenever values may have
  // changed (load / cloud sync) so alerts actually trigger.
  void _evaluatePriceAlerts() {
    final items = state.items;
    if (items.isEmpty) {
      return;
    }
    unawaited(
      evaluateAndDispatchPriceAlerts(ref, items).then((_) {}, onError: (_) {}),
    );
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final items = await _repository.getItems();
      state = state.copyWith(
        items: collectiblesNewestFirst(items),
        isLoading: false,
      );
      _evaluatePriceAlerts();
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
      final persistedItemsBeforeSave = await _repository.getItems();
      final replacingExisting = persistedItemsBeforeSave.any(
        (existingItem) => existingItem.id == item.id,
      );
      final planLimits = ref.read(activePlanLimitsProvider);
      if (!planLimits.canAddPortfolioItem(
        persistedItemsBeforeSave.length,
        replacingExisting: replacingExisting,
      )) {
        state = state.copyWith(
          items: collectiblesNewestFirst(persistedItemsBeforeSave),
          isLoading: false,
          errorMessage: planLimits.portfolioLimitMessage,
        );
        return;
      }

      final itemForSave = item.valueAtScan == null
          ? item.copyWith(valueAtScan: item.estimatedValue)
          : item;
      final savedItem = await _repository.addItem(itemForSave);
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

  /// Updates [item] and records a cloud valuation snapshot when available.
  Future<void> updateItemWithValuationSnapshot(CollectibleItem item) async {
    await updateItem(item);
    final recorded = await ref
        .read(valuationSnapshotRepositoryProvider)
        .recordSnapshotIfValueChanged(item);
    if (recorded) {
      await _syncCloudValuationSnapshot(item);
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

  Future<int> seedDemoItems() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final seededCount = await const DemoCollectibleSeedService()
          .seedPortfolio(_repository);
      final items = await _repository.getItems();
      state = state.copyWith(
        items: collectiblesNewestFirst(items),
        isLoading: false,
      );
      return seededCount;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to seed demo portfolio items.',
      );
      return 0;
    }
  }

  Future<int> clearDemoItems() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final removedCount = await const DemoCollectibleSeedService()
          .clearDemoItems(_repository);
      final items = await _repository.getItems();
      state = state.copyWith(
        items: collectiblesNewestFirst(items),
        isLoading: false,
      );
      return removedCount;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to clear demo portfolio items.',
      );
      return 0;
    }
  }

  /// Attempts to upload local/pending portfolio items to the signed-in cloud account.
  Future<void> syncPendingCloudItems() async {
    await _syncPendingCloudItems();
  }

  /// Pulls signed-in cloud portfolio items into the local portfolio cache.
  Future<int> syncCloudPortfolioNow() async {
    try {
      final mergedCount = await CloudPortfolioSyncCoordinator(
        registry: ref.read(cloudServiceRegistryProvider),
        portfolioRepository: _repository,
      ).syncNow();
      final items = collectiblesNewestFirst(await _repository.getItems());
      state = state.copyWith(items: items, isLoading: false);
      _evaluatePriceAlerts();
      return mergedCount;
    } catch (_) {
      final items = collectiblesNewestFirst(await _repository.getItems());
      state = state.copyWith(items: items, isLoading: false);
      return 0;
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
    } catch (_) {
      final items = collectiblesNewestFirst(await _repository.getItems());
      state = state.copyWith(items: items, isLoading: false);
    }
  }

  Future<void> _syncUpdatedCloudItem(CollectibleItem item) async {
    try {
      await CloudPortfolioSyncCoordinator(
        registry: ref.read(cloudServiceRegistryProvider),
        portfolioRepository: _repository,
      ).syncUpdatedItem(item);
      final items = collectiblesNewestFirst(await _repository.getItems());
      state = state.copyWith(items: items, isLoading: false);
    } catch (_) {
      final items = collectiblesNewestFirst(await _repository.getItems());
      state = state.copyWith(items: items, isLoading: false);
    }
  }

  Future<void> _syncCloudValuationSnapshot(CollectibleItem item) async {
    try {
      await CloudPortfolioSyncCoordinator(
        registry: ref.read(cloudServiceRegistryProvider),
        portfolioRepository: _repository,
      ).syncValuationSnapshot(item);
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
