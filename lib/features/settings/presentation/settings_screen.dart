import 'dart:async';

import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/network/api_client.dart' as network;
import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/modern_settings_row.dart';
import 'package:collectiq_ai/features/about/presentation/about_screen.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/screens/auth_screens.dart';
import 'package:collectiq_ai/features/auth/services/auth_deep_link_service.dart';
import 'package:collectiq_ai/features/cloud/presentation/cloud_sync_screen.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/diagnostics/services/diagnostics_providers.dart';
import 'package:collectiq_ai/features/home/presentation/pages/home_page.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_notification_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:collectiq_ai/features/portfolio/domain/services/demo_collectible_seed_service.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _showDeveloperSurfaces = bool.fromEnvironment(
  'PACKLOX_SHOW_DEVELOPER_TOOLS',
);

/// Settings screen for account, app preferences, and supported local/cloud state.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key, this.qaInitialScrollOffset = 0});

  /// Initial scroll offset used only by direct visual QA capture routes.
  final double qaInitialScrollOffset;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _scrollController = ScrollController();
  bool _isUpdatingDemoData = false;

  @override
  void initState() {
    super.initState();
    if (widget.qaInitialScrollOffset > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }
        final position = _scrollController.position;
        _scrollController.jumpTo(
          widget.qaInitialScrollOffset.clamp(
            position.minScrollExtent,
            position.maxScrollExtent,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
    final demoSeedEnabled = ref.watch(demoSeedEnabledProvider);
    final notificationState = ref.watch(
      priceAlertNotificationControllerProvider,
    );
    final isSitEnvironment =
        cloudRegistry.config.environment == AppEnvironment.sit;
    final showDeveloperTools = _showDeveloperSurfaces;
    final now = DateTime.now();
    Widget framed(Widget child, {EdgeInsetsGeometry? padding}) {
      return Padding(
        padding:
            padding ??
            const EdgeInsets.symmetric(horizontal: HomeTokens.pageGutter),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: HomeTokens.maxContentWidth,
            ),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      );
    }

    SliverToBoxAdapter sliverBox(Widget child, {EdgeInsetsGeometry? padding}) {
      return SliverToBoxAdapter(child: framed(child, padding: padding));
    }

    List<Widget> sectionSlivers(
      List<Widget> children, {
      double topSpacing = 18,
    }) {
      return [
        sliverBox(
          SettingsCardGroup(children: children),
          padding: EdgeInsets.fromLTRB(
            HomeTokens.pageGutter,
            topSpacing,
            HomeTokens.pageGutter,
            0,
          ),
        ),
      ];
    }

    final primaryTiles = [
      _SettingsRow(
        icon: Icons.account_circle_outlined,
        title: 'Account',
        subtitle: authState.isSignedIn
            ? authState.user?.email ?? 'Signed in'
            : 'Sign in to enable cloud backup.',
        trailing: authState.isSignedIn ? 'Signed in' : 'Sign in',
        onTap: authState.isSignedIn
            ? null
            : () => Navigator.of(context).push(AuthWelcomeScreen.route()),
      ),
      _SettingsRow(
        icon: Icons.inventory_2_outlined,
        title: 'Collection & Backup',
        subtitle: canRunCloudSync
            ? syncState.errorMessage ?? syncState.status.message
            : 'Your collection is local on this device.',
        trailing: canRunCloudSync ? syncState.status.statusLabel : 'Local only',
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CloudSyncScreen()),
        ),
      ),
      _SettingsRow(
        icon: Icons.notifications_none_outlined,
        title: 'Price Alerts',
        subtitle: notificationState.settingsSubtitle,
        trailing: notificationState.settingsStatusLabel,
      ),
      _SettingsRow(
        icon: Icons.palette_outlined,
        title: 'Appearance',
        subtitle: 'PackLox follows your device theme.',
        trailing: 'System',
        message: 'Theme follows your device setting.',
      ),
    ];

    final demoDataTiles = [
      const _SettingsRow(
        icon: Icons.science_outlined,
        title: 'Demo portfolio data',
        subtitle:
            'Local-only mock collectibles for demos, UI testing, search, filter, and sort.',
        trailing: '500 items',
      ),
      _DemoDataSeedPanel(
        isBusy: _isUpdatingDemoData,
        onSeed: _seedDemoPortfolio,
        onClear: _clearDemoPortfolio,
      ),
    ];

    final infoTiles = [
      const _SettingsRow(
        icon: Icons.lock_outline,
        title: 'Privacy',
        subtitle: 'Images stay local unless cloud is configured.',
        trailing: 'Local',
      ),
      _SettingsRow(
        icon: Icons.info_outline_rounded,
        title: 'About PackLox',
        subtitle: 'Version 1.0.0 (1)',
        trailing: 'Open',
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const AboutScreen())),
      ),
      const _SettingsRow(
        icon: Icons.help_outline_rounded,
        title: 'Help & Feedback',
        subtitle: 'Support channels are not connected yet.',
        trailing: 'Soon',
        message: 'Help and feedback are coming soon.',
      ),
    ];

    final dangerTiles = [
      _SettingsRow(
        icon: Icons.restart_alt_outlined,
        title: 'Reset Onboarding',
        subtitle: 'Replay the welcome guide on the next launch.',
        trailing: 'Confirm',
        onTap: () => _confirmDangerAction(
          context,
          title: 'Reset Onboarding?',
          message:
              'The welcome guide will show the next time you open PackLox.',
          confirmLabel: 'Reset',
          action: () => _resetOnboarding(context),
        ),
      ),
      _SettingsRow(
        icon: Icons.cleaning_services_outlined,
        title: 'Clear Local Collection',
        subtitle: 'Remove portfolio items stored locally on this device.',
        trailing: 'Confirm',
        onTap: () => _confirmDangerAction(
          context,
          title: 'Clear Local Collection?',
          message:
              'This removes local portfolio items from this device. Cloud account deletion is not supported here.',
          confirmLabel: 'Clear',
          action: _clearLocalCollection,
        ),
      ),
      if (authState.isSignedIn)
        _SettingsRow(
          icon: Icons.logout_outlined,
          title: 'Sign Out',
          subtitle: 'Sign out of cloud auth. Local data stays on device.',
          trailing: 'Account',
          onTap: () => ref.read(authControllerProvider.notifier).signOut(),
        ),
    ];

    return Scaffold(
      backgroundColor: HomeTokens.background,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: framed(
                IdentityBlock(authState: authState),
                padding: const EdgeInsets.fromLTRB(
                  HomeTokens.pageGutter,
                  HomeTokens.pageGutter,
                  HomeTokens.pageGutter,
                  0,
                ),
              ),
            ),
            if (!authState.isSignedIn)
              sliverBox(
                _AccountPromptCard(
                  onTap: () =>
                      Navigator.of(context).push(AuthWelcomeScreen.route()),
                ),
                padding: const EdgeInsets.fromLTRB(
                  HomeTokens.pageGutter,
                  18,
                  HomeTokens.pageGutter,
                  0,
                ),
              ),
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
            ...sectionSlivers(primaryTiles),
            if (demoSeedEnabled) ...sectionSlivers(demoDataTiles),
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
            ...sectionSlivers(infoTiles, topSpacing: 14),
            ...sectionSlivers(dangerTiles, topSpacing: 14),
            const SliverToBoxAdapter(child: SizedBox(height: 128)),
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

  Future<void> _seedDemoPortfolio() async {
    if (_isUpdatingDemoData) {
      return;
    }
    setState(() => _isUpdatingDemoData = true);
    try {
      final count = await ref
          .read(portfolioControllerProvider.notifier)
          .seedDemoItems();
      if (mounted) {
        _showSettingsSnackBar('Seeded $count demo/mock collectibles locally.');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingDemoData = false);
      }
    }
  }

  Future<void> _clearDemoPortfolio() async {
    if (_isUpdatingDemoData) {
      return;
    }
    setState(() => _isUpdatingDemoData = true);
    try {
      final count = await ref
          .read(portfolioControllerProvider.notifier)
          .clearDemoItems();
      if (mounted) {
        _showSettingsSnackBar('Cleared $count demo/mock collectibles.');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingDemoData = false);
      }
    }
  }

  Future<void> _clearLocalCollection() async {
    await ref.read(portfolioControllerProvider.notifier).clearPortfolio();
    if (mounted) {
      _showSettingsSnackBar('Local collection cleared on this device.');
    }
  }

  Future<void> _confirmDangerAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required FutureOr<void> Function() action,
  }) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final textTheme = Theme.of(sheetContext).textTheme;
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: colorScheme.error.withValues(alpha: 0.34),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.34),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: colorScheme.error.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          color: colorScheme.error,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    message,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: FilledButton(
                          key: const ValueKey('settings-danger-confirm-button'),
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                          ),
                          child: Text(confirmLabel),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await action();
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

class _DemoDataSeedPanel extends StatelessWidget {
  const _DemoDataSeedPanel({
    required this.isBusy,
    required this.onSeed,
    required this.onClear,
  });

  final bool isBusy;
  final VoidCallback onSeed;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enabled only by PACKLOX_DEMO_SEED. Demo records use fallback thumbnails and never call external services.',
          style: textTheme.bodySmall?.copyWith(color: HomeTokens.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('settings-seed-demo-data-button'),
            onPressed: isBusy ? null : onSeed,
            icon: const Icon(Icons.dataset_outlined),
            label: Text(isBusy ? 'Updating Demo Data...' : 'Seed Demo Data'),
            style: FilledButton.styleFrom(
              backgroundColor: HomeTokens.accentStrong,
              foregroundColor: HomeTokens.textPrimary,
              disabledBackgroundColor: HomeTokens.surfaceInteractive,
              disabledForegroundColor: HomeTokens.textMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('settings-clear-demo-data-button'),
            onPressed: isBusy ? null : onClear,
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Clear Demo Data'),
            style: OutlinedButton.styleFrom(
              foregroundColor: HomeTokens.textPrimary,
              disabledForegroundColor: HomeTokens.textMuted,
              side: const BorderSide(color: HomeTokens.border),
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return MotionReveal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: HomeTokens.textPrimary,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: 36,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: HomeTokens.accent.withValues(alpha: 0.58),
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
    return _SettingsSurface(
      child: MotionStagger(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 50, top: 8, bottom: 8),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: HomeTokens.border,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _AccountPromptCard extends StatelessWidget {
  const _AccountPromptCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
        decoration: BoxDecoration(
          color: HomeTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: HomeTokens.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: HomeTokens.positive.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: HomeTokens.positive.withValues(alpha: 0.38),
                ),
              ),
              child: const Icon(
                Icons.verified_user_outlined,
                color: HomeTokens.positive,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: textTheme.bodyMedium?.copyWith(
                    color: HomeTokens.textPrimary,
                    fontSize: 16,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
                  ),
                  children: const [
                    TextSpan(
                      text: 'Add an account to back up your collection. ',
                    ),
                    TextSpan(
                      text: 'Sign in',
                      style: TextStyle(color: HomeTokens.positive),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.close, color: HomeTokens.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

class _SettingsSurface extends StatelessWidget {
  const _SettingsSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: HomeTokens.border),
      ),
      child: child,
    );
  }
}

class IdentityBlock extends StatelessWidget {
  const IdentityBlock({super.key, required this.authState});

  final AuthState authState;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isSignedIn = authState.isSignedIn;
    final email = authState.user?.email ?? authState.user?.displayName;
    final headline = isSignedIn ? email ?? 'Collector' : 'Guest Collector';
    final initial = (email?.trim().isNotEmpty ?? false)
        ? email!.trim().substring(0, 1).toUpperCase()
        : 'P';
    final statusColor = isSignedIn ? HomeTokens.positive : HomeTokens.accent;

    return Column(
      key: const ValueKey('settings-account-overview-card'),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Align(alignment: Alignment.centerLeft, child: HomeBrandLockup()),
        const SizedBox(height: 26),
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                HomeTokens.accentStrong.withValues(alpha: 0.95),
                HomeTokens.accent.withValues(alpha: 0.70),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: HomeTokens.accent.withValues(alpha: 0.24),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial,
              style: textTheme.displaySmall?.copyWith(
                color: HomeTokens.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                headline,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(
                  color: HomeTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              isSignedIn ? Icons.check_circle : Icons.radio_button_checked,
              color: statusColor,
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          isSignedIn
              ? 'Cloud identity connected'
              : 'Local-first access is active',
          style: textTheme.bodyMedium?.copyWith(
            color: HomeTokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
            _SettingsRow(
              key: const ValueKey('settings-home-state-preview'),
              icon: Icons.dashboard_customize_outlined,
              title: 'Home State Preview',
              subtitle: 'Design QA states use mocked local data only.',
              trailing: 'Open',
              onTap: () =>
                  Navigator.of(context).push(HomeStatePreviewScreen.route()),
            ),
            const SizedBox(height: AppSpacing.lg),
            _SettingsRow(
              key: const ValueKey('settings-portfolio-state-preview'),
              icon: Icons.inventory_2_outlined,
              title: 'Portfolio State Preview',
              subtitle: 'Design QA states use mocked local data only.',
              trailing: 'Open',
              onTap: () => Navigator.of(
                context,
              ).push(PortfolioStatePreviewScreen.route()),
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
    super.key,
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
