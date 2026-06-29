/// Cloud sync lifecycle states.
enum SyncState {
  /// Cloud sync is not configured; local mode is active.
  localOnly,

  /// Sync is available and current.
  synced,

  /// Sync work is pending.
  pending,

  /// Sync is currently running.
  syncing,

  /// Sync failed.
  failed,

  /// Local and cloud records require user resolution.
  conflict,
}

/// Current portfolio cloud sync status.
class SyncStatus {
  /// Creates immutable sync status.
  const SyncStatus({
    required this.state,
    required this.message,
    required this.isCloudBackupEnabled,
    this.authenticatedUserId,
    this.lastSyncedAt,
    this.pendingItemCount = 0,
  });

  /// Current sync state.
  final SyncState state;

  /// Human-readable sync message.
  final String message;

  /// Whether cloud backup is enabled.
  final bool isCloudBackupEnabled;

  /// Supabase authenticated user id when a real auth session exists.
  final String? authenticatedUserId;

  /// Last successful sync timestamp.
  final DateTime? lastSyncedAt;

  /// Number of items waiting to sync.
  final int pendingItemCount;

  /// Whether cloud sync is genuinely connected to an authenticated user.
  bool get isCloudConnected {
    final userId = authenticatedUserId?.trim();
    return isCloudBackupEnabled &&
        state == SyncState.synced &&
        userId != null &&
        userId.isNotEmpty;
  }

  /// Short Settings label.
  String get statusLabel {
    if (state == SyncState.synced &&
        isCloudBackupEnabled &&
        !isCloudConnected) {
      return 'Auth required';
    }

    return switch (state) {
      SyncState.localOnly => 'Local only',
      SyncState.synced => 'Synced',
      SyncState.pending => 'Pending',
      SyncState.syncing => 'Syncing',
      SyncState.failed => 'Needs attention',
      SyncState.conflict => 'Conflict',
    };
  }
}
