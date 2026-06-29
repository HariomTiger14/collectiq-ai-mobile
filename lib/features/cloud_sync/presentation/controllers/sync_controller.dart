import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/cloud_sync/data/repositories/mock_cloud_portfolio_repository.dart';
import 'package:collectiq_ai/features/cloud_sync/data/repositories/supabase_cloud_portfolio_repository.dart';
import 'package:collectiq_ai/features/cloud_sync/data/services/local_first_sync_service.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/repositories/cloud_portfolio_repository.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/services/sync_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the cloud portfolio repository.
final cloudPortfolioRepositoryProvider = Provider<CloudPortfolioRepository>((
  ref,
) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  if (!supabaseService.isConfigured) {
    return const MockCloudPortfolioRepository();
  }

  return SupabaseCloudPortfolioRepository(supabaseService: supabaseService);
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return LocalFirstSyncService(
    repository: ref.watch(cloudPortfolioRepositoryProvider),
  );
});

/// Placeholder sync state for future cloud backup.
class SyncControllerState {
  /// Creates sync controller state.
  const SyncControllerState({
    this.status = MockCloudPortfolioRepository.localOnlyStatus,
    this.isLoading = false,
    this.errorMessage,
  });

  /// Current sync status.
  final SyncStatus status;

  /// Whether a sync operation is running.
  final bool isLoading;

  /// User-safe sync error.
  final String? errorMessage;

  /// Creates a copy with updated fields.
  SyncControllerState copyWith({
    SyncStatus? status,
    bool? isLoading,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SyncControllerState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}

/// Coordinates placeholder cloud sync state.
class SyncController extends Notifier<SyncControllerState> {
  late final SyncService _syncService;

  @override
  SyncControllerState build() {
    _syncService = ref.watch(syncServiceProvider);
    Future.microtask(loadStatus);
    return const SyncControllerState();
  }

  /// Loads current sync status.
  Future<void> loadStatus() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final status = await _syncService.currentStatus();
      state = state.copyWith(status: status, isLoading: false);
    } on Object catch (error) {
      debugPrint('[Sync] load status failed: $error');
      state = state.copyWith(
        status: SyncStatus(
          state: SyncState.failed,
          message: error.toString(),
          isCloudBackupEnabled: true,
        ),
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  /// Placeholder upload action for future cloud backup.
  Future<void> uploadLocalItems(List<CollectibleItem> items) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final status = await _syncService.syncLocalItems(items);
      state = state.copyWith(status: status, isLoading: false);
    } on Object catch (error) {
      debugPrint('[Sync] upload local items failed: $error');
      state = state.copyWith(
        status: SyncStatus(
          state: SyncState.failed,
          message: error.toString(),
          isCloudBackupEnabled: true,
          pendingItemCount: items.length,
        ),
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<List<CollectibleItem>> downloadCloudItems() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final items = await _syncService.downloadCloudItems();
      final status = await _syncService.currentStatus();
      state = state.copyWith(status: status, isLoading: false);
      return items;
    } on Object catch (error) {
      debugPrint('[Sync] download cloud items failed: $error');
      state = state.copyWith(
        status: SyncStatus(
          state: SyncState.failed,
          message: error.toString(),
          isCloudBackupEnabled: true,
        ),
        isLoading: false,
        errorMessage: error.toString(),
      );
      return const [];
    }
  }
}

/// Provides sync presentation state.
final syncControllerProvider =
    NotifierProvider<SyncController, SyncControllerState>(SyncController.new);
