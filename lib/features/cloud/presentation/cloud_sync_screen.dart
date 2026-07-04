import 'package:collectiq_ai/core/cloud/cloud_portfolio_sync_coordinator.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/ui/cloud_sync/cloud_sync_ui.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CloudSyncScreen extends ConsumerStatefulWidget {
  const CloudSyncScreen({super.key});

  @override
  ConsumerState<CloudSyncScreen> createState() => _CloudSyncScreenState();
}

class _CloudSyncScreenState extends ConsumerState<CloudSyncScreen> {
  final _scrollController = ScrollController();
  bool _isManualCloudSyncing = false;
  double _scrollOffset = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    Future.microtask(() {
      if (!mounted) {
        return;
      }
      ref.read(syncControllerProvider.notifier).loadStatus();
      ref.read(imageSyncControllerProvider.notifier).loadSnapshot();
      ref.read(portfolioControllerProvider.notifier).loadItems();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final nextOffset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    if ((_scrollOffset - nextOffset).abs() < 1) {
      return;
    }
    setState(() => _scrollOffset = nextOffset);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id ||
          previous?.isSignedIn != next.isSignedIn) {
        ref.read(syncControllerProvider.notifier).loadStatus();
      }
    });

    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authControllerProvider);
    final syncState = ref.watch(syncControllerProvider);
    final imageSyncState = ref.watch(imageSyncControllerProvider);
    final portfolioState = ref.watch(portfolioControllerProvider);
    final registry = ref.watch(cloudServiceRegistryProvider);
    final supabaseConfig = ref.watch(supabaseConfigProvider);
    final canRunCloudSync =
        _cloudSyncAvailable(registry) && authState.isSignedIn;
    final isSyncing =
        _isManualCloudSyncing ||
        syncState.isLoading ||
        imageSyncState.isUploading ||
        syncState.status.state == SyncState.syncing;
    final status = isSyncing
        ? SyncStatus(
            state: SyncState.syncing,
            message: syncState.status.message,
            isCloudBackupEnabled: syncState.status.isCloudBackupEnabled,
            authenticatedUserId: syncState.status.authenticatedUserId,
            lastSyncedAt: syncState.status.lastSyncedAt,
            pendingItemCount: syncState.status.pendingItemCount,
            failedItemCount: syncState.status.failedItemCount,
            retryableItemCount: syncState.status.retryableItemCount,
          )
        : syncState.status;
    final pendingItems =
        status.pendingItemCount + imageSyncState.snapshot.readyToSyncCount;
    final backedUpItems = portfolioState.items
        .where((item) => item.syncStatus == CloudItemSyncStatus.synced)
        .length;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: CloudSyncHeroHeader(
                  scrollOffset: _scrollOffset,
                  gradientStyle: GradientStyle.blueIndigo,
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CloudSyncWaveAnimation(),
                          const SizedBox(height: 24),
                          CloudSyncStatusCard(
                            lastSync:
                                status.lastSyncedAt ??
                                imageSyncState.snapshot.lastSyncAt,
                            syncState: status.state,
                            itemsBackedUp: backedUpItems,
                            itemsPending: pendingItems,
                            message:
                                syncState.errorMessage ??
                                imageSyncState.errorMessage ??
                                status.message,
                          ),
                          const SizedBox(height: 32),
                          CloudSyncSectionCard(
                            title: 'Diagnostics',
                            child: MotionStagger(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: CloudSyncDiagnosticTile(
                                    icon: Icons.folder_outlined,
                                    title: 'Backup Location',
                                    subtitle: _backupLocation(
                                      canRunCloudSync: canRunCloudSync,
                                      status: status,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: CloudSyncDiagnosticTile(
                                    icon: Icons.storage_outlined,
                                    title: 'Storage Usage',
                                    subtitle: _storageUsageLabel(
                                      imageUploadedCount:
                                          imageSyncState.snapshot.uploadedCount,
                                      queuedCount: imageSyncState
                                          .snapshot
                                          .readyToSyncCount,
                                      failedCount:
                                          imageSyncState.snapshot.failedCount,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: CloudSyncDiagnosticTile(
                                    icon: Icons.dns_outlined,
                                    title: 'Supabase Project',
                                    subtitle: _supabaseProjectLabel(
                                      supabaseConfig,
                                      registry.config.environment,
                                    ),
                                  ),
                                ),
                                CloudSyncDiagnosticTile(
                                  icon: Icons.receipt_long_outlined,
                                  title: 'Sync Logs',
                                  subtitle: 'View recent sync activity',
                                  trailing: Icons.chevron_right_rounded,
                                  onTap: () => _showCloudSyncMessage(
                                    syncState.errorMessage ??
                                        imageSyncState.errorMessage ??
                                        status.message,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          CloudSyncActionButton(
                            label: 'Sync Now',
                            isLoading: isSyncing,
                            enabled: canRunCloudSync,
                            onPressed: () => _manualCloudSync(registry),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: IconButton(
                  tooltip: 'Back',
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _cloudSyncAvailable(CloudServiceRegistry registry) {
    final environment = registry.config.environment;
    final flags = registry.config.featureFlags;
    return environment.allowsNonProductionCloud &&
        flags.useCloudPortfolioSync &&
        flags.useCloudImageStorage;
  }

  Future<void> _manualCloudSync(CloudServiceRegistry registry) async {
    if (!_cloudSyncAvailable(registry) || _isManualCloudSyncing) {
      return;
    }

    setState(() => _isManualCloudSyncing = true);
    await registry.analyticsService.trackEvent('manual_sync_clicked');
    await registry.analyticsService.trackEvent('portfolio_sync_started');

    try {
      final syncStatus = await registry.cloudPortfolioSyncService
          .getSyncStatus();
      if (!syncStatus.enabled) {
        await ref.read(syncControllerProvider.notifier).loadStatus();
        if (mounted) {
          _showCloudSyncMessage(syncStatus.message);
        }
        return;
      }

      final portfolioRepository = ref.read(portfolioRepositoryProvider);
      final mergedCount = await CloudPortfolioSyncCoordinator(
        registry: registry,
        portfolioRepository: portfolioRepository,
      ).syncNow();
      final failedCount = (await portfolioRepository.getItems())
          .where((item) => item.syncStatus == CloudItemSyncStatus.failed)
          .length;
      await ref.read(portfolioControllerProvider.notifier).loadItems();
      await ref.read(imageSyncControllerProvider.notifier).loadSnapshot();
      await ref.read(syncControllerProvider.notifier).loadStatus();

      if (failedCount > 0) {
        await registry.analyticsService.trackEvent(
          'portfolio_sync_failed',
          properties: {'failed_count': failedCount},
        );
        if (mounted) {
          _showCloudSyncMessage(
            '$failedCount item${failedCount == 1 ? '' : 's'} could not sync. Local portfolio is still available.',
          );
        }
      } else {
        await registry.analyticsService.trackEvent('portfolio_sync_success');
        if (mounted) {
          _showCloudSyncMessage(
            mergedCount > 0
                ? 'Cloud sync complete. $mergedCount cloud item${mergedCount == 1 ? '' : 's'} merged.'
                : 'Cloud sync complete',
          );
        }
      }
    } on Object catch (error) {
      await registry.analyticsService.trackEvent(
        'portfolio_sync_failed',
        properties: {'error': error.runtimeType.toString()},
      );
      ref.read(syncControllerProvider.notifier).markManualSyncFailed(error);
      if (mounted) {
        _showCloudSyncMessage(
          'Cloud sync failed. Local portfolio is still available.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isManualCloudSyncing = false);
      }
    }
  }

  void _showCloudSyncMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _backupLocation({
  required bool canRunCloudSync,
  required SyncStatus status,
}) {
  if (status.isCloudConnected) {
    return 'Supabase cloud storage';
  }
  if (canRunCloudSync) {
    return 'PackLox cloud ready, authentication required';
  }
  return 'Local device storage';
}

String _storageUsageLabel({
  required int imageUploadedCount,
  required int queuedCount,
  required int failedCount,
}) {
  final parts = <String>[
    '$imageUploadedCount images backed up',
    '$queuedCount queued',
  ];
  if (failedCount > 0) {
    parts.add('$failedCount need attention');
  }
  return parts.join(' · ');
}

String _supabaseProjectLabel(
  SupabaseConfig config,
  AppEnvironment environment,
) {
  if (!config.isConfigured) {
    return '${environment.name.toUpperCase()} environment, Supabase not configured';
  }
  return config.baseUri?.host ?? 'Configured Supabase project';
}
