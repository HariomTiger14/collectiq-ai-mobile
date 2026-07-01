import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/telemetry/app_telemetry.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/services/sync_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return RegistrySyncService(registry: ref.watch(cloudServiceRegistryProvider));
});

class RegistrySyncService implements SyncService {
  const RegistrySyncService({required this.registry});

  final CloudServiceRegistry registry;

  @override
  Future<SyncStatus> currentStatus() async {
    final status = await registry.cloudPortfolioSyncService.getSyncStatus();
    if (!status.enabled) {
      return SyncStatus(
        state: SyncState.localOnly,
        message: status.message,
        isCloudBackupEnabled: false,
        authenticatedUserId: status.userId,
        lastSyncedAt: status.lastSyncedAt,
      );
    }

    return SyncStatus(
      state: SyncState.synced,
      message: status.message,
      isCloudBackupEnabled: true,
      authenticatedUserId: status.userId,
      lastSyncedAt: status.lastSyncedAt,
    );
  }

  @override
  Future<SyncStatus> markPending(List<CollectibleItem> localItems) async {
    return SyncStatus(
      state: SyncState.pending,
      message: 'Cloud sync is not enabled. Local changes are waiting.',
      isCloudBackupEnabled: false,
      pendingItemCount: localItems.length,
    );
  }

  @override
  Future<SyncStatus> syncLocalItems(List<CollectibleItem> localItems) async {
    final status = await registry.cloudPortfolioSyncService.getSyncStatus();
    if (!status.enabled) {
      return SyncStatus(
        state: SyncState.localOnly,
        message: status.message,
        isCloudBackupEnabled: false,
        pendingItemCount: localItems.length,
        authenticatedUserId: status.userId,
      );
    }

    try {
      for (final item in localItems) {
        await registry.cloudPortfolioSyncService.syncItem(item);
      }
      return SyncStatus(
        state: SyncState.synced,
        message: 'Cloud sync complete.',
        isCloudBackupEnabled: true,
        authenticatedUserId: status.userId,
        lastSyncedAt: DateTime.now(),
      );
    } on Object catch (_) {
      return SyncStatus(
        state: SyncState.failed,
        message: 'Cloud sync failed. Changes remain saved locally.',
        isCloudBackupEnabled: true,
        pendingItemCount: localItems.length,
        retryableItemCount: localItems.length,
        authenticatedUserId: status.userId,
      );
    }
  }

  @override
  Future<List<CollectibleItem>> downloadCloudItems() {
    return registry.cloudPortfolioSyncService.fetchItems();
  }
}

/// Placeholder sync state for future cloud backup.
class SyncControllerState {
  /// Creates sync controller state.
  const SyncControllerState({
    this.status = const SyncStatus(
      state: SyncState.localOnly,
      message: 'Cloud sync is not configured. Portfolio is saved locally.',
      isCloudBackupEnabled: false,
    ),
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
  late final AppTelemetryService _telemetry;

  @override
  SyncControllerState build() {
    _syncService = ref.watch(syncServiceProvider);
    _telemetry = ref.watch(appTelemetryServiceProvider);
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
          failedItemCount: 1,
        ),
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  /// Placeholder upload action for future cloud backup.
  Future<void> uploadLocalItems(List<CollectibleItem> items) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    _trackTelemetry(
      TelemetryEventNames.syncStarted,
      properties: {
        'operation': 'upload_local_items',
        'item_count': items.length,
      },
    );
    try {
      final status = await _syncService.syncLocalItems(items);
      _trackTelemetry(
        TelemetryEventNames.syncSuccess,
        properties: {
          'operation': 'upload_local_items',
          'state': status.state.name,
          'pending_count': status.pendingItemCount,
          'failed_count': status.failedItemCount,
        },
      );
      state = state.copyWith(status: status, isLoading: false);
    } on Object catch (error) {
      debugPrint('[Sync] upload local items failed: $error');
      _trackTelemetry(
        TelemetryEventNames.syncFailed,
        properties: {
          'operation': 'upload_local_items',
          'item_count': items.length,
        },
      );
      _recordTelemetryError(
        error,
        reason: 'cloud_sync_failure',
        properties: {'operation': 'upload_local_items'},
      );
      state = state.copyWith(
        status: SyncStatus(
          state: SyncState.failed,
          message: error.toString(),
          isCloudBackupEnabled: true,
          pendingItemCount: items.length,
          retryableItemCount: items.length,
        ),
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<List<CollectibleItem>> downloadCloudItems() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    _trackTelemetry(
      TelemetryEventNames.syncStarted,
      properties: const {'operation': 'download_cloud_items'},
    );
    try {
      final items = await _syncService.downloadCloudItems();
      final status = await _syncService.currentStatus();
      _trackTelemetry(
        TelemetryEventNames.syncSuccess,
        properties: {
          'operation': 'download_cloud_items',
          'item_count': items.length,
          'state': status.state.name,
        },
      );
      state = state.copyWith(status: status, isLoading: false);
      return items;
    } on Object catch (error) {
      debugPrint('[Sync] download cloud items failed: $error');
      _trackTelemetry(
        TelemetryEventNames.syncFailed,
        properties: const {'operation': 'download_cloud_items'},
      );
      _recordTelemetryError(
        error,
        reason: 'cloud_sync_failure',
        properties: const {'operation': 'download_cloud_items'},
      );
      state = state.copyWith(
        status: SyncStatus(
          state: SyncState.failed,
          message: error.toString(),
          isCloudBackupEnabled: true,
          failedItemCount: 1,
        ),
        isLoading: false,
        errorMessage: error.toString(),
      );
      return const [];
    }
  }

  void markManualSyncFailed(Object error, {int pendingItemCount = 0}) {
    debugPrint('[Sync] manual sync failed: $error');
    _trackTelemetry(
      TelemetryEventNames.syncFailed,
      properties: {
        'operation': 'manual_sync',
        'pending_count': pendingItemCount,
      },
    );
    _recordTelemetryError(
      error,
      reason: 'cloud_sync_failure',
      properties: const {'operation': 'manual_sync'},
    );
    state = state.copyWith(
      status: SyncStatus(
        state: SyncState.failed,
        message: 'Manual sync failed. Portfolio remains saved locally.',
        isCloudBackupEnabled: true,
        pendingItemCount: pendingItemCount,
        retryableItemCount: pendingItemCount,
      ),
      isLoading: false,
      errorMessage: error.toString(),
    );
  }

  void _trackTelemetry(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) {
    _telemetry.trackEvent(eventName, properties: properties);
  }

  void _recordTelemetryError(
    Object error, {
    String? reason,
    Map<String, Object?> properties = const {},
  }) {
    _telemetry.recordNonFatalError(
      error,
      reason: reason,
      properties: properties,
    );
  }
}

/// Provides sync presentation state.
final syncControllerProvider =
    NotifierProvider<SyncController, SyncControllerState>(SyncController.new);
