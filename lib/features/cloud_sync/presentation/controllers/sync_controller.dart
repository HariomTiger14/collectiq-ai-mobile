import 'package:collectiq_ai/features/cloud_sync/data/repositories/mock_cloud_portfolio_repository.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/repositories/cloud_portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the cloud portfolio repository.
final cloudPortfolioRepositoryProvider = Provider<CloudPortfolioRepository>((
  ref,
) {
  return const MockCloudPortfolioRepository();
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
  late final CloudPortfolioRepository _repository;

  @override
  SyncControllerState build() {
    _repository = ref.watch(cloudPortfolioRepositoryProvider);
    Future.microtask(loadStatus);
    return const SyncControllerState();
  }

  /// Loads current sync status.
  Future<void> loadStatus() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final status = await _repository.getSyncStatus();
      state = state.copyWith(status: status, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load sync status.',
      );
    }
  }

  /// Placeholder upload action for future cloud backup.
  Future<void> uploadLocalItems(List<CollectibleItem> items) async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);
    try {
      final status = await _repository.uploadLocalItems(items);
      state = state.copyWith(status: status, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Cloud backup is not available yet.',
      );
    }
  }
}

/// Provides sync presentation state.
final syncControllerProvider =
    NotifierProvider<SyncController, SyncControllerState>(SyncController.new);
