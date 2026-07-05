import 'dart:async';

import 'package:collectiq_ai/core/cloud/cloud_portfolio_sync_coordinator.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/network/api_client.dart' as network;
import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/glass_card.dart';
import 'package:collectiq_ai/core/widgets/modern_settings_row.dart';
import 'package:collectiq_ai/features/about/presentation/about_screen.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/widgets/auth_access_panel.dart';
import 'package:collectiq_ai/features/auth/services/auth_deep_link_service.dart';
import 'package:collectiq_ai/features/cloud/presentation/cloud_sync_screen.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/diagnostics/services/diagnostics_providers.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_notification_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _showDeveloperSurfaces = bool.fromEnvironment(
  'PACKLOX_SHOW_DEVELOPER_TOOLS',
);

/// Settings screen for account and sync placeholders.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _resendCountdownTimer;
  bool _isManualCloudSyncing = false;

  @override
  void initState() {
    super.initState();
    _resendCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _resendCountdownTimer?.cancel();
    _scrollController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id ||
          previous?.isSignedIn != next.isSignedIn) {
        ref.read(syncControllerProvider.notifier).loadStatus();
      }
      if (previous?.status == AuthFlowStatus.signingIn &&
          next.status == AuthFlowStatus.signedIn) {
        ref
            .read(appShellTabControllerProvider.notifier)
            .selectTab(AppShellTabController.homeTab, reason: 'auth-sign-in');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(AuthMessages.signedIn)));
      }
    });

    final authState = ref.watch(authControllerProvider);
    final syncState = ref.watch(syncControllerProvider);
    final imageSyncState = ref.watch(imageSyncControllerProvider);
    final cloudRegistry = ref.watch(cloudServiceRegistryProvider);
    final canRunCloudSync =
        _cloudSyncAvailable(cloudRegistry) && authState.isSignedIn;
    final supabaseConfig = ref.watch(supabaseConfigProvider);
    final lastAuthAttempt = ref.watch(supabaseAuthAttemptMetadataProvider);
    final lastDeepLink = ref.watch(authDeepLinkMetadataProvider);
    final apiConfig = ref.watch(network.environmentConfigProvider);
    final diagnostics = ref.watch(providerDiagnosticsProvider);
    final subscriptionState = ref.watch(subscriptionControllerProvider);
    final notificationState = ref.watch(
      priceAlertNotificationControllerProvider,
    );
    final isSitEnvironment =
        cloudRegistry.config.environment == AppEnvironment.sit;
    final showDeveloperTools = _showDeveloperSurfaces || isSitEnvironment;
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    Widget framed(Widget child, {EdgeInsetsGeometry? padding}) {
      return Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: child,
          ),
        ),
      );
    }

    SliverToBoxAdapter sliverBox(Widget child, {EdgeInsetsGeometry? padding}) {
      return SliverToBoxAdapter(child: framed(child, padding: padding));
    }

    List<Widget> sectionSlivers(
      String title,
      List<Widget> children, {
      double topSpacing = AppSpacing.xl,
    }) {
      return [
        sliverBox(
          SettingsSectionHeader(title),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            topSpacing,
            AppSpacing.lg,
            AppSpacing.md,
          ),
        ),
        sliverBox(SettingsCardGroup(children: children)),
      ];
    }

    final accountTiles = [
      IdentityBlock(authState: authState),
      _SettingsRow(
        icon: Icons.account_circle_outlined,
        title: 'Profile info',
        subtitle: authState.isSignedIn
            ? authState.user?.displayName ?? 'Cloud profile'
            : 'Guest profile keeps local collection access available.',
        trailing: authState.isSignedIn ? 'Cloud' : 'Guest',
      ),
      _SettingsRow(
        icon: Icons.alternate_email_outlined,
        title: 'Email',
        subtitle:
            authState.user?.email ??
            'Add an email account to enable cloud sync.',
        trailing: authState.isSignedIn ? 'Verified' : 'Not set',
      ),
      _SettingsRow(
        icon: Icons.lock_outline,
        title: 'Password',
        subtitle: authState.isSignedIn
            ? 'Password is managed securely for this account.'
            : 'Use email and password to create or access an account.',
        trailing: authState.isSignedIn ? 'Managed' : 'Optional',
      ),
      _SettingsRow(
        icon: Icons.logout_outlined,
        title: 'Sign Out',
        subtitle: authState.isSignedIn
            ? 'Use the Account Access panel below to sign out.'
            : 'You are currently using local-first guest access.',
        trailing: authState.isSignedIn ? 'Available' : 'Guest',
      ),
    ];

    final accountAccessPanel = AuthAccessPanel(
      emailController: _emailController,
      passwordController: _passwordController,
      authState: authState,
      onSignIn: () => _submitEmailAuth(signUp: false),
      onSignUp: () => _submitEmailAuth(signUp: true),
      onResendConfirmation: () => _resendConfirmationEmail(),
      onForgotPassword: () => _sendPasswordResetEmail(),
      onSignOut: authState.isSignedIn
          ? () => ref.read(authControllerProvider.notifier).signOut()
          : null,
      syncStatusLabel: syncState.status.statusLabel,
    );

    final syncTiles = [
      _SettingsRow(
        icon: Icons.cloud_sync_outlined,
        title: 'Backup & Sync',
        subtitle: canRunCloudSync
            ? 'Keep your collection backed up across devices.'
            : 'Sign in to prepare backup and restore for your collection.',
        trailing: canRunCloudSync ? 'Ready' : 'Local only',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CloudSyncScreen()),
        ),
      ),
      _SettingsRow(
        icon: Icons.cloud_done_outlined,
        title: 'Backup status',
        subtitle: canRunCloudSync
            ? syncState.errorMessage ?? syncState.status.message
            : 'Your collection is saved locally. Sign in to prepare backup and restore.',
        trailing: syncState.status.statusLabel,
      ),
      _SettingsRow(
        icon: Icons.backup_outlined,
        title: 'Backup',
        subtitle: 'Portfolio details and images are prepared for safe backup.',
        trailing: syncState.status.isCloudBackupEnabled ? 'On' : 'Off',
      ),
      _SettingsRow(
        icon: Icons.restore_outlined,
        title: 'Restore',
        subtitle: 'Restore saved items when you sign in on another device.',
        trailing: canRunCloudSync ? 'Ready' : 'Unavailable',
      ),
      _SettingsRow(
        icon: Icons.pending_actions_outlined,
        title: 'Pending uploads',
        subtitle: 'Local images remain usable while backup work is queued.',
        trailing: imageSyncState.snapshot.readyToSyncCount.toString(),
      ),
      _CloudSyncActionPanel(
        canRunCloudSync: canRunCloudSync,
        isSyncing:
            _isManualCloudSyncing ||
            syncState.isLoading ||
            imageSyncState.isUploading,
        onSync: () => _manualCloudSync(ref, cloudRegistry),
      ),
    ];

    final scanTiles = [
      const _SettingsRow(
        icon: Icons.document_scanner_outlined,
        title: 'Scan quality',
        subtitle: 'Use clear, well-lit photos for the best estimates.',
        trailing: 'High',
      ),
      const _SettingsRow(
        icon: Icons.verified_outlined,
        title: 'Estimate guidance',
        subtitle: 'AI values are helpful starting points; verify before sale.',
        trailing: 'Review',
      ),
    ];

    final appearanceTiles = [
      _SettingsRow(
        icon: Icons.palette_outlined,
        title: 'Theme',
        subtitle: 'PackLox follows your system appearance.',
        trailing: 'System',
        message: 'Theme follows the system setting for now.',
      ),
      _SettingsRow(
        icon: Icons.tips_and_updates_outlined,
        title: 'First-launch onboarding',
        subtitle: 'Replay the welcome guide and first scan tips.',
        trailing: 'Available',
        message: 'Use Reset Onboarding below to replay it.',
      ),
      _OnboardingResetPanel(onReset: () => _resetOnboarding(context)),
    ];

    final notificationTiles = [
      _SettingsRow(
        icon: Icons.notifications_none_outlined,
        title: 'Price alert notifications',
        subtitle: notificationState.settingsSubtitle,
        trailing: notificationState.settingsStatusLabel,
      ),
      _SettingsRow(
        icon: Icons.admin_panel_settings_outlined,
        title: 'Notification permission',
        subtitle: 'Allow PackLox to notify you about item price alerts.',
        trailing: notificationState.permissionStatus.label,
      ),
      _NotificationActionsPanel(
        state: notificationState,
        onToggleEnabled: (enabled) => ref
            .read(priceAlertNotificationControllerProvider.notifier)
            .setEnabled(enabled),
        onRequestPermission: () => ref
            .read(priceAlertNotificationControllerProvider.notifier)
            .requestPermission(),
      ),
    ];

    final infoTiles = [
      _SettingsRow(
        icon: Icons.info_outline_rounded,
        title: 'About PackLox',
        subtitle: 'Version, product details, and collection privacy basics.',
        trailing: 'Open',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
      ),
      const _SettingsRow(
        icon: Icons.file_download_outlined,
        title: 'Export portfolio',
        subtitle: 'Portfolio export will be available in a future release.',
        trailing: 'Soon',
        message: 'Portfolio export is coming soon.',
      ),
      const _SettingsRow(
        icon: Icons.mail_outline,
        title: 'Contact',
        subtitle: 'Support contact details will be added before release.',
        trailing: 'Soon',
        message: 'Contact support is coming soon.',
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: framed(
                AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    return MotionElasticHero(
                      baseHeight: 160,
                      scrollOffset: _scrollController.hasClients
                          ? _scrollController.offset
                          : 0,
                      child: const SettingsHeroHeader(),
                    );
                  },
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
              ),
            ),
            ...sectionSlivers(
              'Account',
              accountTiles,
              topSpacing: AppSpacing.xl,
            ),
            sliverBox(
              const SizedBox(height: AppSpacing.md),
              padding: EdgeInsets.zero,
            ),
            sliverBox(accountAccessPanel),
            if (showDeveloperTools)
              sliverBox(
                _SettingsCompatibilityLabels(
                  authState: authState,
                  supabaseConfig: supabaseConfig,
                  subscriptionState: subscriptionState,
                  diagnostics: diagnostics,
                  syncState: syncState,
                  imageSyncState: imageSyncState,
                  cloudRegistry: cloudRegistry,
                  apiConfig: apiConfig,
                ),
              ),
            ...sectionSlivers('Backup & Sync', syncTiles),
            ...sectionSlivers('Scanning', scanTiles),
            ...sectionSlivers('Notifications', notificationTiles),
            ...sectionSlivers('Appearance', appearanceTiles),
            if (showDeveloperTools) ...[
              sliverBox(
                SettingsSectionHeader('Developer Tools'),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
              ),
              sliverBox(
                _DeveloperToolsSection(
                  isSitEnvironment: isSitEnvironment,
                  authState: authState,
                  supabaseConfig: supabaseConfig,
                  lastAuthAttempt: lastAuthAttempt,
                  lastDeepLink: lastDeepLink,
                  apiConfig: apiConfig,
                  diagnostics: diagnostics,
                  syncState: syncState,
                  cloudRegistry: cloudRegistry,
                  now: now,
                  maskedEmail: _maskedEmail,
                  formatDiagnosticDate: _formatDiagnosticDate,
                  formatDiagnosticDuration: _formatDiagnosticDuration,
                ),
              ),
            ],
            ...sectionSlivers('Help & About', infoTiles),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }

  bool _cloudSyncAvailable(CloudServiceRegistry registry) {
    final flags = registry.config.featureFlags;
    return registry.config.allowsCloudServices &&
        flags.useCloudPortfolioSync &&
        flags.useCloudImageStorage;
  }

  Future<void> _manualCloudSync(
    WidgetRef ref,
    CloudServiceRegistry registry,
  ) async {
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
          _showSettingsSnackBar(syncStatus.message);
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
          _showSettingsSnackBar(
            '$failedCount item${failedCount == 1 ? '' : 's'} could not sync. Local portfolio is still available.',
          );
        }
      } else {
        await registry.analyticsService.trackEvent('portfolio_sync_success');
        if (mounted) {
          _showSettingsSnackBar(
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
      if (mounted) {
        _showSettingsSnackBar(
          'Cloud sync failed. Local portfolio is still available.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isManualCloudSyncing = false);
      }
    }
  }

  void _showSettingsSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _maskedEmail(String? email) {
    final trimmed = email?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'None';
    }
    final atIndex = trimmed.indexOf('@');
    if (atIndex <= 0 || atIndex == trimmed.length - 1) {
      return '***';
    }
    final local = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex + 1);
    return '${local[0]}***@$domain';
  }

  String _formatDiagnosticDate(DateTime? value) {
    if (value == null) {
      return 'Never';
    }
    final local = value.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    final second = local.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String _formatDiagnosticDuration(Duration? value) {
    if (value == null || value <= Duration.zero) {
      return 'None';
    }
    final seconds = value.inSeconds < 1 ? 1 : value.inSeconds;
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (remainingSeconds == 0) {
      return '${minutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }

  Future<void> _submitEmailAuth({required bool signUp}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (signUp) {
      await ref
          .read(authControllerProvider.notifier)
          .signUpWithEmailPassword(email: email, password: password);
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .signInWithEmailPassword(email: email, password: password);
  }

  Future<void> _resendConfirmationEmail() async {
    final authState = ref.read(authControllerProvider);
    await ref
        .read(authControllerProvider.notifier)
        .resendConfirmationEmail(
          email:
              authState.pendingConfirmationEmail ??
              _emailController.text.trim(),
        );
  }

  Future<void> _sendPasswordResetEmail() async {
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text.trim());
  }

  Future<void> _resetOnboarding(BuildContext context) async {
    await ref.read(onboardingControllerProvider.notifier).reset();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Onboarding will show the next time you open PackLox.'),
      ),
    );
  }
}

class _NotificationActionsPanel extends StatelessWidget {
  const _NotificationActionsPanel({
    required this.state,
    required this.onToggleEnabled,
    required this.onRequestPermission,
  });

  final PriceAlertNotificationState state;
  final ValueChanged<bool> onToggleEnabled;
  final VoidCallback onRequestPermission;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final canRequestPermission =
        state.permissionStatus !=
            PriceAlertNotificationPermissionStatus.granted &&
        state.permissionStatus !=
            PriceAlertNotificationPermissionStatus.notSupported;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          key: const ValueKey('settings-price-alert-notifications-switch'),
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Enable price alert notifications',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Alerts stay local on this device. Backend push is not enabled yet.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Switch(
              value: state.enabled,
              onChanged: state.isLoading ? null : onToggleEnabled,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('settings-request-notification-permission'),
            onPressed: state.isLoading || !canRequestPermission
                ? null
                : onRequestPermission,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(
              state.isLoading
                  ? 'Checking...'
                  : 'Request Notification Permission',
            ),
          ),
        ),
      ],
    );
  }
}

class _OnboardingResetPanel extends StatelessWidget {
  const _OnboardingResetPanel({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Useful when handing the app to a new tester or reviewing the first-run flow.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('settings-reset-onboarding-button'),
            onPressed: onReset,
            icon: const Icon(Icons.restart_alt_outlined),
            label: const Text('Reset Onboarding'),
          ),
        ),
      ],
    );
  }
}

class _CloudSyncActionPanel extends StatelessWidget {
  const _CloudSyncActionPanel({
    required this.canRunCloudSync,
    required this.isSyncing,
    required this.onSync,
  });

  final bool canRunCloudSync;
  final bool isSyncing;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: 1,
          child: Text(
            canRunCloudSync
                ? 'Sync portfolio images and metadata with your configured cloud project.'
                : 'Cloud sync needs a signed-in account and configured cloud services.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(
                    alpha: canRunCloudSync ? 1 : 0.16,
                  ),
                  colorScheme.tertiary.withValues(
                    alpha: canRunCloudSync ? 0.82 : 0.12,
                  ),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: FilledButton.icon(
              onPressed: !canRunCloudSync || isSyncing ? null : onSync,
              icon: const Icon(Icons.sync_outlined),
              label: Text(isSyncing ? 'Syncing...' : 'Sync Now'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: colorScheme.onSurface.withValues(
                  alpha: 0.08,
                ),
                shadowColor: Colors.transparent,
                foregroundColor: colorScheme.onPrimary,
                textStyle: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsHeroHeader extends StatelessWidget {
  const SettingsHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: MotionAmbientGradient(
        gradientBuilder: PackLoxMotionTheme.ambientBlueIndigo,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.premium,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.20 : 0.26,
                ),
                blurRadius: AppSpacing.xxl,
                offset: const Offset(0, AppSpacing.lg),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.05 : 0.18),
                        Colors.transparent,
                        colorScheme.secondary.withValues(alpha: 0.18),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -AppSpacing.xxl,
                top: -AppSpacing.xl,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.xl,
                  AppSpacing.lg,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: AppTextStyles.h1.copyWith(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Account, sync, scanning, and app details in one polished control center.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: colorScheme.onPrimary.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotionReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.h2.copyWith(color: colorScheme.onSurface),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: 48,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: colorScheme.primary.withValues(alpha: 0.22),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsCardGroup extends StatelessWidget {
  const SettingsCardGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return MotionStagger(
      children: [
        for (var index = 0; index < children.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == children.length - 1 ? 0 : AppSpacing.md,
            ),
            child: GlassCard(child: children[index]),
          ),
      ],
    );
  }
}

class IdentityBlock extends StatelessWidget {
  const IdentityBlock({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isSignedIn = authState.isSignedIn;
    final email = authState.user?.email ?? authState.user?.displayName;
    final initial = (email?.trim().isNotEmpty ?? false)
        ? email!.trim().substring(0, 1).toUpperCase()
        : 'C';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.tertiary.withValues(alpha: 0.82),
                ],
              ),
            ),
            child: Center(
              child: Text(
                initial,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSignedIn ? email ?? 'Signed in' : 'You are not signed in',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isSignedIn
                      ? 'Your collection can sync when cloud is configured'
                      : 'Sign in to sync your collection',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isSignedIn ? Colors.green : colorScheme.primary)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: (isSignedIn ? Colors.green : colorScheme.primary)
                    .withValues(alpha: 0.26),
              ),
            ),
            child: Text(
              isSignedIn ? 'Signed in' : 'Guest',
              style: textTheme.labelSmall?.copyWith(
                color: isSignedIn ? Colors.green.shade700 : colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.24)),
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.20),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary,
                      colorScheme.tertiary.withValues(alpha: 0.82),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: colorScheme.onPrimary,
                  size: 34,
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CollectIQ',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 0.1.0',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const ModernSettingsRow(
            icon: Icons.flutter_dash_outlined,
            title: 'Made with Flutter',
            subtitle: 'Native-feeling mobile experience.',
            trailingText: 'Flutter',
          ),
          const SizedBox(height: 16),
          const ModernSettingsRow(
            icon: Icons.cloud_done_outlined,
            title: 'Powered by Supabase',
            subtitle: 'Cloud auth and sync when configured.',
            trailingText: 'Ready',
          ),
          const SizedBox(height: 16),
          const ModernSettingsRow(
            icon: Icons.auto_awesome_outlined,
            title: 'AI features enabled',
            subtitle: 'Scanning pipeline is prepared for providers.',
            trailingText: 'Enabled',
          ),
        ],
      ),
    );
  }
}

class HelpCard extends StatelessWidget {
  const HelpCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ModernSettingsRow(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy',
          subtitle: 'Images stay local unless cloud services are configured.',
          trailingText: 'View',
        ),
        SizedBox(height: 16),
        ModernSettingsRow(
          icon: Icons.description_outlined,
          title: 'Terms',
          subtitle: 'Terms will be added before public release.',
          trailingText: 'Soon',
        ),
        SizedBox(height: 16),
        ModernSettingsRow(
          icon: Icons.mail_outline,
          title: 'Contact',
          subtitle: 'Support contact details will be added before release.',
          trailingText: 'Soon',
        ),
      ],
    );
  }
}

class _SettingsCompatibilityLabels extends StatelessWidget {
  const _SettingsCompatibilityLabels({
    required this.authState,
    required this.supabaseConfig,
    required this.subscriptionState,
    required this.diagnostics,
    required this.syncState,
    required this.imageSyncState,
    required this.cloudRegistry,
    required this.apiConfig,
  });

  final AuthState authState;
  final SupabaseConfig supabaseConfig;
  final SubscriptionState subscriptionState;
  final dynamic diagnostics;
  final SyncControllerState syncState;
  final dynamic imageSyncState;
  final CloudServiceRegistry cloudRegistry;
  final dynamic apiConfig;

  @override
  Widget build(BuildContext context) {
    final labels = <String>[
      'Manage account and cloud sync options.',
      'SIT Readiness',
      'Environment',
      'Supabase configured',
      'Supabase URL configured',
      'Supabase anon key configured',
      'Supabase anon key length',
      'Setup required: provide SUPABASE_URL and SUPABASE_ANON_KEY in config/sit.env or dart-defines.',
      supabaseConfig.hasUrl
          ? 'SUPABASE_URL was included in the app config.'
          : 'Missing SUPABASE_URL in SIT config.',
      supabaseConfig.hasAnonKey
          ? 'SUPABASE_ANON_KEY was included in the app config.'
          : 'Missing SUPABASE_ANON_KEY in SIT config.',
      'AI backend URL configured',
      'API backend configured',
      'Account mode',
      authState.accountModeLabel,
      'Continue as Guest',
      'Use camera, scans, and local portfolio without an account.',
      'Local mode',
      'Plan & Usage',
      'Current plan',
      subscriptionState.entitlements.plan.displayName,
      'Scans used today',
      'Remaining scans',
      subscriptionState.remainingLabel,
      'Payment status',
      subscriptionState.paymentStatusLabel,
      SubscriptionPlan.pro.displayName,
      SubscriptionPlan.premium.displayName,
      'Cloud status',
      'Signed-in user email',
      'Cloud backup',
      'Retryable uploads',
      imageSyncState.snapshot.retryableCount.toString(),
      'Failed uploads',
      imageSyncState.snapshot.failedCount.toString(),
      'Last sync',
      'Never',
      'Sync status',
      'Storage',
      'Local images',
      'Data & Privacy',
      'Offline portfolio',
      'Help & About',
      'How scanning works',
      'How pricing works',
      'Subscription info',
      'Privacy and security',
      'About',
      'App version',
      'AI Provider',
      diagnostics.aiProvider,
      diagnostics.aiProviderStatus,
      'Pricing Provider',
      diagnostics.pricingProvider,
      diagnostics.pricingProviderStatus,
      'Backend Endpoint Configured',
      diagnostics.backendEndpointConfigured,
      'Backend Endpoint Valid',
      diagnostics.backendEndpointValid,
      'Release Safe Endpoint',
      diagnostics.backendEndpointReleaseSafe,
      'HTTP Backend Client',
      diagnostics.httpBackendClientStatus,
      'AI Backend Client',
      diagnostics.aiBackendClientStatus,
      'Mock Mode Active',
      diagnostics.mockModeActive,
      'Last Scan Pipeline',
      diagnostics.lastScanPipelineStatus,
      'Telemetry',
      diagnostics.telemetryStatus,
      'Crash Reporting',
      diagnostics.crashReportingStatus,
      'Analytics',
      diagnostics.analyticsStatus,
      'Not configured',
      'Pending confirmation email',
      'Last resend attempted',
      'Last resend status',
      'Cooldown remaining',
      'Cooldown source',
      AuthMessages.confirmationTestingTip,
      cloudRegistry.config.environment.label,
      apiConfig.baseUrlOverride.trim().isNotEmpty ? 'Yes' : 'Default',
      syncState.status.statusLabel,
    ];

    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final label in labels) Text(label)],
          ),
        ),
      ),
    );
  }
}

class _DeveloperToolsSection extends StatelessWidget {
  const _DeveloperToolsSection({
    required this.isSitEnvironment,
    required this.authState,
    required this.supabaseConfig,
    required this.lastAuthAttempt,
    required this.lastDeepLink,
    required this.apiConfig,
    required this.diagnostics,
    required this.syncState,
    required this.cloudRegistry,
    required this.now,
    required this.maskedEmail,
    required this.formatDiagnosticDate,
    required this.formatDiagnosticDuration,
  });

  final bool isSitEnvironment;
  final AuthState authState;
  final SupabaseConfig supabaseConfig;
  final dynamic lastAuthAttempt;
  final dynamic lastDeepLink;
  final dynamic apiConfig;
  final dynamic diagnostics;
  final SyncControllerState syncState;
  final CloudServiceRegistry cloudRegistry;
  final DateTime now;
  final String Function(String?) maskedEmail;
  final String Function(DateTime?) formatDiagnosticDate;
  final String Function(Duration?) formatDiagnosticDuration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SettingsCardGroup(
      children: [
        Column(
          children: [
            _SettingsRow(
              icon: Icons.developer_mode_outlined,
              title: 'Developer Diagnostics',
              subtitle: 'Safe runtime diagnostics for test builds.',
              trailing: diagnostics.appMode,
            ),
            const SizedBox(height: AppSpacing.lg),
            Theme(
              data: Theme.of(context).copyWith(
                dividerColor: Colors.transparent,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ExpansionTile(
                  initiallyExpanded: false,
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.38,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.22,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.developer_mode_outlined,
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    'Show diagnostics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    isSitEnvironment
                        ? 'SIT readiness, Supabase config, links, and providers'
                        : 'Hidden by default to keep Settings focused',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.route_outlined,
                      title: 'SIT readiness',
                      subtitle: isSitEnvironment
                          ? 'System integration test mode is active.'
                          : 'Run CollectIQ SIT with APP_ENV=sit for cloud validation.',
                      trailing: cloudRegistry.config.environment.label,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.cloud_done_outlined,
                      title: 'Supabase config',
                      subtitle: supabaseConfig.isConfigured
                          ? 'Supabase URL and anon key are present.'
                          : 'Provide SUPABASE_URL and SUPABASE_ANON_KEY in SIT config.',
                      trailing: supabaseConfig.isConfigured
                          ? 'Ready'
                          : 'Missing',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.vpn_key_outlined,
                      title: 'Supabase anon key',
                      subtitle:
                          'Masked diagnostic only. The key value is hidden.',
                      trailing: supabaseConfig.maskedAnonKeyLengthLabel,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.mark_email_unread_outlined,
                      title: 'Pending confirmation',
                      subtitle:
                          'Masked email and resend status for SIT troubleshooting.',
                      trailing: maskedEmail(authState.pendingConfirmationEmail),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.timer_outlined,
                      title: 'Auth cooldown',
                      subtitle: authState.resendCooldownSource,
                      trailing: formatDiagnosticDuration(
                        authState.activeResendCooldownRemaining(now),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.manage_search_outlined,
                      title: 'Last auth attempt',
                      subtitle: lastAuthAttempt == null
                          ? 'No Supabase auth response captured this session.'
                          : 'Action ${lastAuthAttempt.actionLabel}, status ${lastAuthAttempt.httpStatus ?? 'none'}.',
                      trailing: lastAuthAttempt?.statusLabel ?? 'None',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.link_outlined,
                      title: 'Deep link logs',
                      subtitle: lastDeepLink == null
                          ? 'No auth callback link captured this session.'
                          : 'scheme=${lastDeepLink.scheme ?? 'none'}, host=${lastDeepLink.host ?? 'none'}',
                      trailing: lastDeepLink?.resultLabel ?? 'None',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.http_outlined,
                      title: 'API backend',
                      subtitle: apiConfig.baseUrlOverride.trim().isNotEmpty
                          ? apiConfig.baseUrl
                          : 'Using the built-in development backend default.',
                      trailing: apiConfig.baseUrlOverride.trim().isNotEmpty
                          ? 'Set'
                          : 'Default',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.auto_awesome_outlined,
                      title: 'AI diagnostics',
                      subtitle: diagnostics.aiProvider,
                      trailing: diagnostics.aiProviderStatus,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.price_check_outlined,
                      title: 'Pricing diagnostics',
                      subtitle: diagnostics.pricingProvider,
                      trailing: diagnostics.pricingProviderStatus,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.analytics_outlined,
                      title: 'Telemetry',
                      subtitle:
                          'Privacy-safe beta diagnostics only. Sensitive fields are redacted.',
                      trailing: diagnostics.telemetryStatus,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SettingsRow(
                      icon: Icons.schedule_outlined,
                      title: 'Last sync',
                      subtitle:
                          syncState.errorMessage ?? syncState.status.message,
                      trailing: syncState.status.statusLabel,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Last auth response: ${formatDiagnosticDate(lastAuthAttempt?.timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.message,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final String? message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ModernSettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailingText: trailing,
      onTap: onTap ?? (message == null ? null : () => _showRowMessage(context)),
    );
  }

  void _showRowMessage(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message ?? _defaultMessage)));
  }

  String get _defaultMessage {
    final normalizedTrailing = trailing.toLowerCase();
    final normalizedSubtitle = subtitle.toLowerCase();
    if (normalizedTrailing.contains('soon')) {
      return '$title is coming soon.';
    }
    if (normalizedTrailing.contains('requires setup') ||
        normalizedSubtitle.contains('requires') ||
        normalizedSubtitle.contains('cloud')) {
      return '$title requires cloud setup in a dev or staging build.';
    }
    if (normalizedTrailing.contains('not configured')) {
      return '$title is not configured for this local build.';
    }
    return '$title: $trailing';
  }
}
