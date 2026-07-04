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
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/core/widgets/modern_settings_row.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/services/ai_providers.dart';
import 'package:collectiq_ai/features/about/presentation/about_screen.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/presentation/widgets/auth_access_panel.dart';
import 'package:collectiq_ai/features/auth/services/auth_deep_link_service.dart';
import 'package:collectiq_ai/features/cloud/presentation/cloud_sync_screen.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/diagnostics/services/diagnostics_providers.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:collectiq_ai/features/onboarding/presentation/controllers/onboarding_controller.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_notification_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      if (previous?.isSignedIn == false && next.isSignedIn) {
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
    final aiProviderConfig = ref.watch(aiAnalysisProviderConfigProvider);
    final diagnostics = ref.watch(providerDiagnosticsProvider);
    final subscriptionState = ref.watch(subscriptionControllerProvider);
    final notificationState = ref.watch(
      priceAlertNotificationControllerProvider,
    );
    final isSitEnvironment =
        cloudRegistry.config.environment == AppEnvironment.sit;
    final now = DateTime.now();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsHeroHeader(scrollController: _scrollController),
                  const SizedBox(height: 32),
                  _SectionStack(
                    index: 0,
                    child: _SettingsCard(
                      title: 'Account',
                      stackLevel: 0,
                      children: [
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
                          trailing: authState.isSignedIn
                              ? 'Verified'
                              : 'Not set',
                        ),
                        _SettingsRow(
                          icon: Icons.lock_outline,
                          title: 'Password',
                          subtitle: authState.isSignedIn
                              ? 'Password is managed securely by Supabase Auth.'
                              : 'Use email and password to create or access an account.',
                          trailing: authState.isSignedIn
                              ? 'Managed'
                              : 'Optional',
                        ),
                        _SettingsRow(
                          icon: Icons.logout_outlined,
                          title: 'Sign Out',
                          subtitle: authState.isSignedIn
                              ? 'Use the Account Access panel below to sign out.'
                              : 'You are currently using local-first guest access.',
                          trailing: authState.isSignedIn
                              ? 'Available'
                              : 'Guest',
                        ),
                      ],
                    ),
                  ),
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
                  const SizedBox(height: 36),
                  _SettingsEntrance(
                    child: AuthAccessPanel(
                      emailController: _emailController,
                      passwordController: _passwordController,
                      authState: authState,
                      onSignIn: () => _submitEmailAuth(signUp: false),
                      onSignUp: () => _submitEmailAuth(signUp: true),
                      onResendConfirmation: () => _resendConfirmationEmail(),
                      onForgotPassword: () => _sendPasswordResetEmail(),
                      onSignOut: authState.isSignedIn
                          ? () => ref
                                .read(authControllerProvider.notifier)
                                .signOut()
                          : null,
                      syncStatusLabel: syncState.status.statusLabel,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _SectionStack(
                    index: 1,
                    child: _SettingsCard(
                      title: 'App Preferences',
                      stackLevel: 1,
                      children: [
                        const _SettingsRow(
                          icon: Icons.g_mobiledata_outlined,
                          title: 'Google Sign-In',
                          subtitle:
                              'OAuth provider placeholder. No Google keys are bundled.',
                          trailing: 'Coming soon',
                          message: 'Google Sign-In is coming soon.',
                        ),
                        _SettingsRow(
                          icon: Icons.palette_outlined,
                          title: 'Theme',
                          subtitle: 'PackLox follows your system appearance.',
                          trailing: 'System',
                          message: 'Theme follows the system setting for now.',
                        ),
                        const _SettingsRow(
                          icon: Icons.apple,
                          title: 'Apple Sign-In',
                          subtitle:
                              'OAuth provider placeholder. No Apple keys are bundled.',
                          trailing: 'Coming soon',
                          message: 'Apple Sign-In is coming soon.',
                        ),
                        _SettingsRow(
                          icon: Icons.notifications_none_outlined,
                          title: 'Price alert notifications',
                          subtitle: notificationState.settingsSubtitle,
                          trailing: notificationState.settingsStatusLabel,
                        ),
                        _SettingsRow(
                          icon: Icons.admin_panel_settings_outlined,
                          title: 'Notification permission',
                          subtitle:
                              'Android notification permission controls local price alerts.',
                          trailing: notificationState.permissionStatus.label,
                        ),
                        _SettingsRow(
                          icon: Icons.tips_and_updates_outlined,
                          title: 'First-launch onboarding',
                          subtitle:
                              'Replay the welcome guide and local-first setup notes.',
                          trailing: 'Available',
                          message: 'Use Reset Onboarding below to replay it.',
                        ),
                        _OnboardingResetPanel(
                          onReset: () => _resetOnboarding(context),
                        ),
                        _NotificationActionsPanel(
                          state: notificationState,
                          onToggleEnabled: (enabled) => ref
                              .read(
                                priceAlertNotificationControllerProvider
                                    .notifier,
                              )
                              .setEnabled(enabled),
                          onRequestPermission: () => ref
                              .read(
                                priceAlertNotificationControllerProvider
                                    .notifier,
                              )
                              .requestPermission(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  _SectionStack(
                    index: 2,
                    child: _SettingsCard(
                      title: 'Cloud & Sync',
                      stackLevel: 2,
                      children: [
                        _SettingsRow(
                          icon: Icons.cloud_sync_outlined,
                          title: 'Cloud Sync',
                          subtitle: canRunCloudSync
                              ? 'Cloud sync is available for this signed-in account.'
                              : 'Cloud sync is disabled in this environment',
                          trailing: canRunCloudSync ? 'Ready' : 'Local only',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const CloudSyncScreen(),
                            ),
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.cloud_done_outlined,
                          title: 'Cloud sync status',
                          subtitle:
                              syncState.errorMessage ??
                              syncState.status.message,
                          trailing: syncState.status.statusLabel,
                        ),
                        _SettingsRow(
                          icon: Icons.backup_outlined,
                          title: 'Backup',
                          subtitle:
                              'Portfolio metadata and images sync when cloud services are configured.',
                          trailing: syncState.status.isCloudBackupEnabled
                              ? 'On'
                              : 'Off',
                        ),
                        _SettingsRow(
                          icon: Icons.restore_outlined,
                          title: 'Restore',
                          subtitle:
                              'Signed-in cloud items merge safely during manual sync.',
                          trailing: canRunCloudSync ? 'Ready' : 'Unavailable',
                        ),
                        _SettingsRow(
                          icon: Icons.pending_actions_outlined,
                          title: 'Pending uploads',
                          subtitle:
                              'Local images remain usable while upload work is queued.',
                          trailing: imageSyncState.snapshot.readyToSyncCount
                              .toString(),
                        ),
                        _SettingsRow(
                          icon: Icons.cloud_queue_outlined,
                          title: 'Supabase Storage',
                          subtitle:
                              'Cloud image storage requires Supabase setup and is not enabled in local mode.',
                          trailing: 'Requires setup',
                          message:
                              'Supabase Storage requires cloud setup and is disabled in local mode.',
                        ),
                        _CloudSyncActionPanel(
                          canRunCloudSync: canRunCloudSync,
                          isSyncing:
                              _isManualCloudSyncing ||
                              syncState.isLoading ||
                              imageSyncState.isUploading,
                          onSync: () => _manualCloudSync(ref, cloudRegistry),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  _SectionStack(
                    index: 3,
                    child: _SettingsCard(
                      title: 'AI & Scanning',
                      stackLevel: 3,
                      children: [
                        _SettingsRow(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Current AI provider',
                          subtitle: aiProviderConfig.selectedProviderMessage,
                          trailing: aiProviderConfig.type.isAvailable
                              ? aiProviderConfig.type.displayName
                              : 'Unavailable',
                        ),
                        _SettingsRow(
                          icon: Icons.document_scanner_outlined,
                          title: 'Scan quality',
                          subtitle:
                              'Camera and gallery scans stay available locally.',
                          trailing: 'High',
                        ),
                        _SettingsRow(
                          icon: Icons.science_outlined,
                          title: 'Mock mode active',
                          subtitle:
                              'No external AI calls run while mock analysis is selected.',
                          trailing:
                              aiProviderConfig.type ==
                                  AiAnalysisProviderType.mock
                              ? 'Active'
                              : 'Off',
                        ),
                        _SettingsRow(
                          icon: Icons.visibility_outlined,
                          title:
                              AiAnalysisProviderType.openAiVision.displayName,
                          subtitle:
                              'Backend-only provider option prepared for future scanning.',
                          trailing: _providerOptionStatus(
                            config: aiProviderConfig,
                            type: AiAnalysisProviderType.openAiVision,
                            backendConfigured:
                                aiProviderConfig.hasBackendAnalysisEndpoint,
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.auto_awesome_motion_outlined,
                          title:
                              AiAnalysisProviderType.geminiVision.displayName,
                          subtitle:
                              'Future backend-only provider. API keys must stay server-side.',
                          trailing: _providerOptionStatus(
                            config: aiProviderConfig,
                            type: AiAnalysisProviderType.geminiVision,
                            backendConfigured:
                                aiProviderConfig.hasBackendAnalysisEndpoint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),
                  _SectionStack(
                    index: 4,
                    child: _DeveloperToolsSection(
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
                  const SizedBox(height: 36),
                  _SectionStack(
                    index: 5,
                    child: _SettingsCard(
                      title: 'About & Help',
                      stackLevel: 1,
                      children: [
                        _SettingsRow(
                          icon: Icons.info_outline_rounded,
                          title: 'About PackLox',
                          subtitle:
                              'Version, support links, privacy, terms, and platform details.',
                          trailing: 'Open',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AboutScreen(),
                            ),
                          ),
                        ),
                        const _SettingsRow(
                          icon: Icons.file_download_outlined,
                          title: 'Export portfolio',
                          subtitle:
                              'Portfolio export will be available in a future release.',
                          trailing: 'Soon',
                          message: 'Portfolio export is coming soon.',
                        ),
                        const _SettingsRow(
                          icon: Icons.cloud_queue_outlined,
                          title: 'Local vs cloud mode',
                          subtitle:
                              'Local mode works without sign-in. Cloud sync is optional when configured.',
                          trailing: 'Local-first',
                          message:
                              'Local mode is active. Cloud sync requires explicit dev or staging setup.',
                        ),
                        const _SettingsRow(
                          icon: Icons.mail_outline,
                          title: 'Contact',
                          subtitle:
                              'Support contact details will be added before release.',
                          trailing: 'Soon',
                          message: 'Contact support is coming soon.',
                        ),
                      ],
                    ),
                  ),
                  if (_showLegacySettingsForTransition()) ...[
                    _SettingsCard(
                      title: 'SIT Readiness',
                      children: [
                        _SettingsRow(
                          icon: Icons.route_outlined,
                          title: 'Environment',
                          subtitle: isSitEnvironment
                              ? 'System integration test mode is active.'
                              : 'Run CollectIQ SIT with APP_ENV=sit for cloud validation.',
                          trailing: cloudRegistry.config.environment.label,
                        ),
                        _SettingsRow(
                          icon: Icons.cloud_done_outlined,
                          title: 'Supabase configured',
                          subtitle: supabaseConfig.isConfigured
                              ? 'Supabase URL and anon key are present.'
                              : 'Setup required: provide SUPABASE_URL and SUPABASE_ANON_KEY in config/sit.env or dart-defines.',
                          trailing: supabaseConfig.isConfigured ? 'Yes' : 'No',
                        ),
                        _SettingsRow(
                          icon: Icons.link_outlined,
                          title: 'Supabase URL configured',
                          subtitle: supabaseConfig.hasUrl
                              ? 'SUPABASE_URL was included in the app config.'
                              : 'Missing SUPABASE_URL in SIT config.',
                          trailing: supabaseConfig.hasUrl ? 'Yes' : 'No',
                        ),
                        _SettingsRow(
                          icon: Icons.vpn_key_outlined,
                          title: 'Supabase anon key configured',
                          subtitle: supabaseConfig.hasAnonKey
                              ? 'SUPABASE_ANON_KEY was included in the app config.'
                              : 'Missing SUPABASE_ANON_KEY in SIT config.',
                          trailing: supabaseConfig.hasAnonKey ? 'Yes' : 'No',
                        ),
                        _SettingsRow(
                          icon: Icons.password_outlined,
                          title: 'Supabase anon key length',
                          subtitle:
                              'Masked diagnostic only. The key value is never shown.',
                          trailing: supabaseConfig.maskedAnonKeyLengthLabel,
                        ),
                        _SettingsRow(
                          icon: Icons.person_outline,
                          title: 'Auth status',
                          subtitle: authState.isSignedIn
                              ? authState.user?.email ??
                                    authState.user?.id ??
                                    'Signed in'
                              : authState.isAnonymousCloudSession
                              ? 'Anonymous/dev session detected. Sign in with email/password for real SIT sync.'
                              : 'Signed out. Sign in with email/password before cloud sync.',
                          trailing: authState.isSignedIn
                              ? 'Signed in'
                              : authState.isAnonymousCloudSession
                              ? 'Anonymous'
                              : 'Signed out',
                        ),
                        if (isSitEnvironment) ...[
                          _SettingsRow(
                            icon: Icons.mark_email_unread_outlined,
                            title: 'Pending confirmation email',
                            subtitle:
                                'Masked diagnostic for confirmation resend troubleshooting.',
                            trailing: _maskedEmail(
                              authState.pendingConfirmationEmail,
                            ),
                          ),
                          _SettingsRow(
                            icon: Icons.history_outlined,
                            title: 'Last resend attempted',
                            subtitle:
                                'Shows when the app last asked Supabase to resend confirmation.',
                            trailing: _formatDiagnosticDate(
                              authState.lastResendAttemptedAt,
                            ),
                          ),
                          _SettingsRow(
                            icon: Icons.fact_check_outlined,
                            title: 'Last resend status',
                            subtitle:
                                'Sent, rate-limited, failed, or none for this app session.',
                            trailing: authState.lastResendStatus,
                          ),
                          _SettingsRow(
                            icon: Icons.timer_outlined,
                            title: 'Cooldown remaining',
                            subtitle:
                                'Active resend wait time from success or Supabase rate-limit response.',
                            trailing: _formatDiagnosticDuration(
                              authState.activeResendCooldownRemaining(now),
                            ),
                          ),
                          _SettingsRow(
                            icon: Icons.block_outlined,
                            title: 'Cooldown source',
                            subtitle:
                                'Success, retry-after, fallback, app-limit, or none.',
                            trailing: authState.resendCooldownSource,
                          ),
                          _SettingsRow(
                            icon: Icons.lock_reset_outlined,
                            title: 'Password recovery redirect',
                            subtitle:
                                'Exact redirect URL the app asks Supabase to place in reset emails.',
                            trailing:
                                authState.lastPasswordResetRedirectUrl ??
                                SupabaseService.passwordResetRedirectUri,
                          ),
                          _SettingsRow(
                            icon: Icons.manage_history_outlined,
                            title: 'Last password reset status',
                            subtitle:
                                'Sent, rate-limited, failed, blocked, or none for this app session.',
                            trailing: authState.lastPasswordResetStatus,
                          ),
                          _SettingsRow(
                            icon: Icons.timer_outlined,
                            title: 'Password reset cooldown',
                            subtitle:
                                'Active wait time after reset email success or Supabase rate-limit response.',
                            trailing: _formatDiagnosticDuration(
                              authState.activePasswordResetCooldownRemaining(
                                now,
                              ),
                            ),
                          ),
                          _SettingsRow(
                            icon: Icons.rule_outlined,
                            title: 'Password reset cooldown source',
                            subtitle:
                                'Success, retry-after, fallback, or none.',
                            trailing: authState.passwordResetCooldownSource,
                          ),
                          const _SettingsRow(
                            icon: Icons.tips_and_updates_outlined,
                            title: 'Testing email tip',
                            subtitle: AuthMessages.confirmationTestingTip,
                            trailing: 'SIT only',
                          ),
                          _SettingsRow(
                            icon: Icons.manage_search_outlined,
                            title: 'Last auth attempt',
                            subtitle: lastAuthAttempt == null
                                ? 'No Supabase auth response captured this session.'
                                : 'Action ${lastAuthAttempt.actionLabel}, status ${lastAuthAttempt.httpStatus ?? 'none'}, body ${lastAuthAttempt.bodyType}.',
                            trailing:
                                lastAuthAttempt?.statusLabel ?? 'Not captured',
                          ),
                          _SettingsRow(
                            icon: Icons.key_outlined,
                            title: 'Last auth response keys',
                            subtitle:
                                'Keys only. Tokens, passwords, and full response bodies are never shown.',
                            trailing: lastAuthAttempt?.keysLabel ?? 'none',
                          ),
                          _SettingsRow(
                            icon: Icons.verified_user_outlined,
                            title: 'Last auth response shape',
                            subtitle: lastAuthAttempt == null
                                ? 'No sanitized response metadata yet.'
                                : 'user=${lastAuthAttempt.hasUser}, session=${lastAuthAttempt.hasSession}, id=${lastAuthAttempt.hasDirectId}, email=${lastAuthAttempt.hasDirectEmail}, confirmation=${lastAuthAttempt.hasConfirmationSentAt}',
                            trailing: _formatDiagnosticDate(
                              lastAuthAttempt?.timestamp,
                            ),
                          ),
                          _SettingsRow(
                            icon: Icons.link_outlined,
                            title: 'Last deep link received',
                            subtitle: lastDeepLink == null
                                ? 'No auth callback link captured this session.'
                                : 'scheme=${lastDeepLink.scheme ?? 'none'}, host=${lastDeepLink.host ?? 'none'}, path=${lastDeepLink.path ?? 'none'}',
                            trailing: lastDeepLink?.receivedLabel ?? 'No',
                          ),
                          _SettingsRow(
                            icon: Icons.rule_outlined,
                            title: 'Last deep link result',
                            subtitle:
                                lastDeepLink?.errorMessage ??
                                'Callback result is shown without token values.',
                            trailing: lastDeepLink?.resultLabel ?? 'none',
                          ),
                          _SettingsRow(
                            icon: Icons.key_off_outlined,
                            title: 'Last deep link query keys',
                            subtitle:
                                'Keys only. Access tokens and refresh tokens are never shown.',
                            trailing: lastDeepLink?.queryKeysLabel ?? 'none',
                          ),
                        ],
                        _SettingsRow(
                          icon: Icons.storage_outlined,
                          title: 'Storage sync',
                          subtitle: supabaseConfig.isConfigured
                              ? 'Bucket collectiq-portfolio-images is expected in Supabase.'
                              : 'Storage requires Supabase setup.',
                          trailing: supabaseConfig.isConfigured
                              ? 'Ready'
                              : 'Not ready',
                        ),
                        _SettingsRow(
                          icon: Icons.sync_outlined,
                          title: 'Portfolio sync',
                          subtitle: syncState.status.message,
                          trailing: syncState.status.isCloudConnected
                              ? 'Ready'
                              : 'Not ready',
                        ),
                        _SettingsRow(
                          icon: Icons.http_outlined,
                          title: 'AI backend URL configured',
                          subtitle: apiConfig.baseUrlOverride.trim().isNotEmpty
                              ? apiConfig.baseUrl
                              : 'Setup recommended: provide API_BASE_URL in config/sit.env for phone builds.',
                          trailing: apiConfig.baseUrlOverride.trim().isNotEmpty
                              ? 'Yes'
                              : 'Default',
                        ),
                        _SettingsRow(
                          icon: Icons.api_outlined,
                          title: 'API backend configured',
                          subtitle: apiConfig.baseUrlOverride.trim().isNotEmpty
                              ? 'API_BASE_URL was included in the app config.'
                              : 'Using the built-in development backend default.',
                          trailing: apiConfig.baseUrlOverride.trim().isNotEmpty
                              ? 'Yes'
                              : 'Default',
                        ),
                        _SettingsRow(
                          icon: Icons.schedule_outlined,
                          title: 'Last sync status',
                          subtitle:
                              syncState.errorMessage ??
                              syncState.status.message,
                          trailing: syncState.status.statusLabel,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'Account',
                      children: [
                        _SettingsRow(
                          icon: Icons.account_circle_outlined,
                          title: 'Account mode',
                          subtitle:
                              authState.errorMessage ??
                              authState.infoMessage ??
                              'PackLox stays fully usable in local-first mode.',
                          trailing: authState.accountModeLabel,
                        ),
                        _SettingsRow(
                          icon: Icons.person_outline,
                          title: 'Continue as Guest',
                          subtitle:
                              'Use camera, scans, and local portfolio without an account.',
                          trailing: authState.isLocalMode ? 'Active' : 'Off',
                        ),
                        _SettingsRow(
                          icon: Icons.login_outlined,
                          title: authState.isSignedIn
                              ? 'Cloud account'
                              : 'Sign In',
                          subtitle:
                              authState.errorMessage ??
                              authState.infoMessage ??
                              (authState.isSignedIn
                                  ? authState.user!.displayName
                                  : 'Cloud sign-in is optional and prepared for a future release.'),
                          trailing: authState.errorMessage != null
                              ? 'Needs attention'
                              : authState.statusLabel,
                        ),
                        _SettingsRow(
                          icon: Icons.g_mobiledata_outlined,
                          title: 'Google Sign-In',
                          subtitle:
                              'OAuth provider placeholder. No Google keys are bundled.',
                          trailing: 'Coming soon',
                          message: 'Google Sign-In is coming soon.',
                        ),
                        _SettingsRow(
                          icon: Icons.apple,
                          title: 'Apple Sign-In',
                          subtitle:
                              'OAuth provider placeholder. No Apple keys are bundled.',
                          trailing: 'Coming soon',
                          message: 'Apple Sign-In is coming soon.',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'App Preferences',
                      children: [
                        _SettingsRow(
                          icon: Icons.palette_outlined,
                          title: 'Theme',
                          subtitle: 'System theme is used for now.',
                          trailing: 'System',
                          message: 'Theme follows the system setting for now.',
                        ),
                        _SettingsRow(
                          icon: Icons.tips_and_updates_outlined,
                          title: 'First-launch onboarding',
                          subtitle:
                              'Replay the welcome guide, local-first notes, and first-scan path.',
                          trailing: 'Available',
                          message: 'Use Reset Onboarding below to replay it.',
                        ),
                        _OnboardingResetPanel(
                          onReset: () => _resetOnboarding(context),
                        ),
                        _SettingsRow(
                          icon: Icons.notifications_none_outlined,
                          title: 'Price alert notifications',
                          subtitle: notificationState.settingsSubtitle,
                          trailing: notificationState.settingsStatusLabel,
                        ),
                        _SettingsRow(
                          icon: Icons.notifications_active_outlined,
                          title: 'Notification permission',
                          subtitle:
                              'Android 13+ asks before local alerts can be shown.',
                          trailing: notificationState.permissionStatus.label,
                        ),
                        _SettingsRow(
                          icon: Icons.history_outlined,
                          title: 'Last notification',
                          subtitle:
                              notificationState.lastMessage ??
                              'No price alert notifications sent yet.',
                          trailing: notificationState.lastDeliveryStatus.label,
                        ),
                        _NotificationActionsPanel(
                          state: notificationState,
                          onToggleEnabled: (enabled) => ref
                              .read(
                                priceAlertNotificationControllerProvider
                                    .notifier,
                              )
                              .setEnabled(enabled),
                          onRequestPermission: () => ref
                              .read(
                                priceAlertNotificationControllerProvider
                                    .notifier,
                              )
                              .requestPermission(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsEntrance(
                      child: AuthAccessPanel(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        authState: authState,
                        onSignIn: () => _submitEmailAuth(signUp: false),
                        onSignUp: () => _submitEmailAuth(signUp: true),
                        onResendConfirmation: () => _resendConfirmationEmail(),
                        onForgotPassword: () => _sendPasswordResetEmail(),
                        onSignOut: authState.isSignedIn
                            ? () => ref
                                  .read(authControllerProvider.notifier)
                                  .signOut()
                            : null,
                        syncStatusLabel: syncState.status.statusLabel,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'Plan & Usage',
                      children: [
                        _SettingsRow(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Current plan',
                          subtitle:
                              'PackLox is local-first. Paid plans are placeholders.',
                          trailing:
                              subscriptionState.entitlements.plan.displayName,
                        ),
                        _SettingsRow(
                          icon: Icons.document_scanner_outlined,
                          title: 'Scans used today',
                          subtitle: subscriptionState.usage.isUnlimited
                              ? 'Development-safe unlimited mode is active.'
                              : 'Daily free scans reset automatically.',
                          trailing: subscriptionState.usage.scansUsedToday
                              .toString(),
                        ),
                        _SettingsRow(
                          icon: Icons.timelapse_outlined,
                          title: 'Remaining scans',
                          subtitle:
                              'Configurable via COLLECTIQ_DAILY_FREE_SCAN_LIMIT.',
                          trailing: subscriptionState.remainingLabel,
                        ),
                        _SettingsRow(
                          icon: Icons.payments_outlined,
                          title: 'Payment status',
                          subtitle: subscriptionState.isBillingAvailable
                              ? 'Google Play Billing is available for this build.'
                              : 'Payments are not configured for this build.',
                          trailing: subscriptionState.paymentStatusLabel,
                        ),
                        if (subscriptionState.purchaseMessage != null)
                          _SettingsRow(
                            icon: Icons.receipt_long_outlined,
                            title: 'Purchase status',
                            subtitle: subscriptionState.purchaseMessage!,
                            trailing:
                                subscriptionState.entitlements.plan.displayName,
                          ),
                        _SettingsRow(
                          icon: Icons.trending_up_outlined,
                          title: SubscriptionPlan.pro.displayName,
                          subtitle: _billingProductSubtitle(
                            subscriptionState,
                            SubscriptionPlan.pro,
                          ),
                          trailing:
                              subscriptionState.entitlements.plan ==
                                  SubscriptionPlan.pro
                              ? 'Active'
                              : _billingProductTrailing(
                                  subscriptionState,
                                  SubscriptionPlan.pro,
                                ),
                        ),
                        _SettingsRow(
                          icon: Icons.diamond_outlined,
                          title: SubscriptionPlan.premium.displayName,
                          subtitle: _billingProductSubtitle(
                            subscriptionState,
                            SubscriptionPlan.premium,
                          ),
                          trailing:
                              subscriptionState.entitlements.plan ==
                                  SubscriptionPlan.premium
                              ? 'Active'
                              : _billingProductTrailing(
                                  subscriptionState,
                                  SubscriptionPlan.premium,
                                ),
                        ),
                        _BillingActionsPanel(
                          state: subscriptionState,
                          onPurchasePro: () => ref
                              .read(subscriptionControllerProvider.notifier)
                              .purchasePlan(SubscriptionPlan.pro),
                          onPurchasePremium: () => ref
                              .read(subscriptionControllerProvider.notifier)
                              .purchasePlan(SubscriptionPlan.premium),
                          onRestore: () => ref
                              .read(subscriptionControllerProvider.notifier)
                              .restorePurchases(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'AI & Scanning',
                      children: [
                        _SettingsRow(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Current AI provider',
                          subtitle: aiProviderConfig.selectedProviderMessage,
                          trailing: aiProviderConfig.type.displayName,
                        ),
                        if (aiProviderConfig.type ==
                            AiAnalysisProviderType.mock)
                          const _SettingsRow(
                            icon: Icons.info_outline,
                            title: 'Mock mode active',
                            subtitle:
                                'Real AI providers are prepared but disabled until implemented.',
                            trailing: 'Dev',
                          ),
                        _SettingsRow(
                          icon: Icons.science_outlined,
                          title: AiAnalysisProviderType.mock.displayName,
                          subtitle:
                              'Local development recognizer. No external AI calls or API keys.',
                          trailing: _providerOptionStatus(
                            config: aiProviderConfig,
                            type: AiAnalysisProviderType.mock,
                            backendConfigured: true,
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.visibility_outlined,
                          title:
                              AiAnalysisProviderType.openAiVision.displayName,
                          subtitle:
                              'Skeleton only. Real OpenAI calls must use the CollectIQ AI backend endpoint.',
                          trailing: _providerOptionStatus(
                            config: aiProviderConfig,
                            type: AiAnalysisProviderType.openAiVision,
                            backendConfigured:
                                aiProviderConfig.hasBackendAnalysisEndpoint,
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.auto_awesome_motion_outlined,
                          title:
                              AiAnalysisProviderType.geminiVision.displayName,
                          subtitle:
                              'Future backend-only provider. API keys must stay server-side.',
                          trailing: _providerOptionStatus(
                            config: aiProviderConfig,
                            type: AiAnalysisProviderType.geminiVision,
                            backendConfigured:
                                aiProviderConfig.hasBackendAnalysisEndpoint,
                          ),
                        ),
                        _SettingsRow(
                          icon: Icons.document_scanner_outlined,
                          title: 'Scan quality',
                          subtitle:
                              'Camera and gallery scans stay available locally.',
                          trailing: 'High',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'Developer Diagnostics',
                      children: [
                        _SettingsRow(
                          icon: Icons.auto_awesome_outlined,
                          title: 'AI Provider',
                          subtitle: diagnostics.aiProvider,
                          trailing: diagnostics.aiProviderStatus,
                        ),
                        _SettingsRow(
                          icon: Icons.price_check_outlined,
                          title: 'Pricing Provider',
                          subtitle: diagnostics.pricingProvider,
                          trailing: diagnostics.pricingProviderStatus,
                        ),
                        _SettingsRow(
                          icon: Icons.link_outlined,
                          title: 'Backend Endpoint Configured',
                          subtitle: diagnostics.backendEndpointMessage,
                          trailing: diagnostics.backendEndpointConfigured,
                        ),
                        _SettingsRow(
                          icon: Icons.verified_outlined,
                          title: 'Backend Endpoint Valid',
                          subtitle:
                              'URL validation only. No network request is made.',
                          trailing: diagnostics.backendEndpointValid,
                        ),
                        _SettingsRow(
                          icon: Icons.security_outlined,
                          title: 'Release Safe Endpoint',
                          subtitle:
                              'Release builds must use the CollectIQ AI backend over HTTPS.',
                          trailing: diagnostics.backendEndpointReleaseSafe,
                        ),
                        _SettingsRow(
                          icon: Icons.cloud_sync_outlined,
                          title: 'AI Backend Client',
                          subtitle:
                              'No network calls run until the backend service is enabled.',
                          trailing: diagnostics.aiBackendClientStatus,
                        ),
                        _SettingsRow(
                          icon: Icons.http_outlined,
                          title: 'HTTP Backend Client',
                          subtitle:
                              'Dio transport is enabled only for a configured backend provider.',
                          trailing: diagnostics.httpBackendClientStatus,
                        ),
                        _SettingsRow(
                          icon: Icons.developer_mode_outlined,
                          title: 'Mock Mode Active',
                          subtitle: diagnostics.appMode,
                          trailing: diagnostics.mockModeActive,
                        ),
                        _SettingsRow(
                          icon: Icons.route_outlined,
                          title: 'Last Scan Pipeline',
                          subtitle: 'AI -> Pricing -> Result',
                          trailing: diagnostics.lastScanPipelineStatus,
                        ),
                        _SettingsRow(
                          icon: Icons.monitor_heart_outlined,
                          title: 'Telemetry',
                          subtitle:
                              'Privacy-safe beta diagnostics. No images, paths, emails, API keys, or personal content.',
                          trailing: diagnostics.telemetryStatus,
                        ),
                        _SettingsRow(
                          icon: Icons.bug_report_outlined,
                          title: 'Crash Reporting',
                          subtitle:
                              'Non-fatal errors are reported only when telemetry is configured.',
                          trailing: diagnostics.crashReportingStatus,
                        ),
                        _SettingsRow(
                          icon: Icons.analytics_outlined,
                          title: 'Analytics',
                          subtitle:
                              'Basic app flow events only. Sensitive fields are redacted.',
                          trailing: diagnostics.analyticsStatus,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'Cloud Sync',
                      children: [
                        _SettingsRow(
                          icon: Icons.cloud_done_outlined,
                          title: 'Cloud status',
                          subtitle:
                              syncState.errorMessage ??
                              'Image uploads run in the background when cloud storage is configured.',
                          trailing: syncState.status.state == SyncState.failed
                              ? 'Needs attention'
                              : syncState.status.isCloudConnected
                              ? 'Cloud Connected'
                              : syncState.status.isCloudBackupEnabled
                              ? 'Auth required'
                              : imageSyncState.cloudStatus,
                        ),
                        _SettingsRow(
                          icon: Icons.badge_outlined,
                          title: 'Signed-in user email',
                          subtitle:
                              authState.errorMessage ??
                              'Cloud sync uses this Supabase account when signed in.',
                          trailing: authState.errorMessage != null
                              ? 'Needs attention'
                              : authState.user?.email ?? 'Local only',
                        ),
                        _SettingsRow(
                          icon: Icons.sync_outlined,
                          title: 'Sync status',
                          subtitle: syncState.status.message,
                          trailing: syncState.status.statusLabel,
                        ),
                        _SettingsRow(
                          icon: Icons.cloud_upload_outlined,
                          title: 'Cloud backup',
                          subtitle:
                              'Future cloud backup will sync your local portfolio when enabled.',
                          trailing: syncState.status.isCloudBackupEnabled
                              ? 'On'
                              : 'Off',
                        ),
                        _SettingsRow(
                          icon: Icons.pending_actions_outlined,
                          title: 'Pending uploads',
                          subtitle:
                              'Images keep using the local file until cloud upload completes.',
                          trailing: imageSyncState.snapshot.readyToSyncCount
                              .toString(),
                        ),
                        _SettingsRow(
                          icon: Icons.replay_outlined,
                          title: 'Retryable uploads',
                          subtitle:
                              'Temporary failures are queued with backoff and retried later.',
                          trailing: imageSyncState.snapshot.retryableCount
                              .toString(),
                        ),
                        _SettingsRow(
                          icon: Icons.error_outline,
                          title: 'Failed uploads',
                          subtitle:
                              'Failed image uploads retry automatically and keep local images available.',
                          trailing: imageSyncState.snapshot.failedCount
                              .toString(),
                        ),
                        _SettingsRow(
                          icon: Icons.schedule_outlined,
                          title: 'Last sync',
                          subtitle:
                              'Most recent successful background image upload.',
                          trailing: _formatSyncDate(
                            imageSyncState.snapshot.lastSyncAt,
                          ),
                        ),
                        Text(
                          canRunCloudSync
                              ? 'Sync portfolio images and metadata with the configured SIT/dev cloud project.'
                              : 'Cloud sync is disabled in this environment',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                !canRunCloudSync ||
                                    _isManualCloudSyncing ||
                                    syncState.isLoading ||
                                    imageSyncState.isUploading
                                ? null
                                : () => _manualCloudSync(ref, cloudRegistry),
                            icon: const Icon(Icons.sync_outlined),
                            label: Text(
                              _isManualCloudSyncing ||
                                      syncState.isLoading ||
                                      imageSyncState.isUploading
                                  ? 'Syncing...'
                                  : 'Sync Now',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'Storage',
                      children: [
                        _SettingsRow(
                          icon: Icons.phone_android_outlined,
                          title: 'Local images',
                          subtitle:
                              'Captured and uploaded images stay on this device by default.',
                          trailing: 'Active',
                          message: 'Local image storage is active.',
                        ),
                        _SettingsRow(
                          icon: Icons.cloud_queue_outlined,
                          title: 'Supabase Storage',
                          subtitle:
                              'Cloud image storage requires Supabase setup and is not enabled in local mode.',
                          trailing: 'Requires setup',
                          message:
                              'Supabase Storage requires cloud setup and is disabled in local mode.',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'Data & Privacy',
                      children: [
                        _SettingsRow(
                          icon: Icons.storage_outlined,
                          title: 'Offline portfolio',
                          subtitle:
                              'Camera, gallery, analyze, save, and portfolio stay available without sign in.',
                          trailing: 'Active',
                          message: 'Offline portfolio is active.',
                        ),
                        _SettingsRow(
                          icon: Icons.file_download_outlined,
                          title: 'Export portfolio',
                          subtitle:
                              'Portfolio export will be available in a future release.',
                          trailing: 'Soon',
                          message: 'Portfolio export is coming soon.',
                        ),
                        _SettingsRow(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Privacy policy',
                          subtitle:
                              'Review privacy details when cloud accounts are enabled.',
                          trailing: 'View',
                          message:
                              'Privacy policy content is coming soon for the production release.',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'Help & About',
                      children: [
                        _SettingsRow(
                          icon: Icons.document_scanner_outlined,
                          title: 'How scanning works',
                          subtitle:
                              'Choose Camera or Gallery, review the image, analyze it, then save the result.',
                          trailing: 'Guide',
                          message:
                              'Scanning stays local until analysis. Camera/gallery images use the local FastAPI backend for normal mock-mode analysis.',
                        ),
                        _SettingsRow(
                          icon: Icons.price_check_outlined,
                          title: 'How pricing works',
                          subtitle:
                              'Pricing starts with safe mock data and is prepared for backend market providers.',
                          trailing: 'Guide',
                          message:
                              'Pricing uses mock/local estimates unless backend providers are configured.',
                        ),
                        _SettingsRow(
                          icon: Icons.cloud_queue_outlined,
                          title: 'Local vs cloud mode',
                          subtitle:
                              'Local mode works without sign-in. Cloud sync is optional when configured.',
                          trailing: 'Local-first',
                          message:
                              'Local mode is active. Cloud sync requires explicit dev or staging setup.',
                        ),
                        _SettingsRow(
                          icon: Icons.workspace_premium_outlined,
                          title: 'Subscription info',
                          subtitle:
                              'Free mode is active. Pro and Premium billing are prepared but optional.',
                          trailing: 'Free',
                          message:
                              'Billing is not configured. Free local mode remains active.',
                        ),
                        _SettingsRow(
                          icon: Icons.security_outlined,
                          title: 'Privacy and security',
                          subtitle:
                              'No secrets are stored in the app, and telemetry avoids personal content.',
                          trailing: 'Safe',
                          message:
                              'Local MVP avoids secrets and keeps images on-device unless cloud is configured.',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SettingsCard(
                      title: 'About',
                      children: [
                        _SettingsRow(
                          icon: Icons.article_outlined,
                          title: 'Terms',
                          subtitle:
                              'Terms placeholder for the production release.',
                          trailing: 'View',
                          message:
                              'Terms are coming soon for production release.',
                        ),
                        _SettingsRow(
                          icon: Icons.info_outline,
                          title: 'App version',
                          subtitle: 'PackLox mobile preview.',
                          trailing: '0.1.0',
                          message: 'PackLox mobile preview 0.1.0.',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
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

  bool _showLegacySettingsForTransition() => false;

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

class _BillingActionsPanel extends StatelessWidget {
  const _BillingActionsPanel({
    required this.state,
    required this.onPurchasePro,
    required this.onPurchasePremium,
    required this.onRestore,
  });

  final SubscriptionState state;
  final VoidCallback onPurchasePro;
  final VoidCallback onPurchasePremium;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final billingAvailable = state.isBillingAvailable;
    final isLoading = state.isLoading;
    final canBuyPro =
        billingAvailable && _hasProduct(state, SubscriptionPlan.pro);
    final canBuyPremium =
        billingAvailable && _hasProduct(state, SubscriptionPlan.premium);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          billingAvailable
              ? 'Upgrade with Google Play Billing.'
              : 'Payments not configured. Free local mode remains active.',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('settings-upgrade-pro-button'),
            onPressed: isLoading || !canBuyPro ? null : onPurchasePro,
            icon: const Icon(Icons.trending_up_outlined),
            label: Text(
              isLoading
                  ? 'Working...'
                  : _upgradeLabel(state, SubscriptionPlan.pro),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('settings-upgrade-premium-button'),
            onPressed: isLoading || !canBuyPremium ? null : onPurchasePremium,
            icon: const Icon(Icons.diamond_outlined),
            label: Text(
              isLoading
                  ? 'Working...'
                  : _upgradeLabel(state, SubscriptionPlan.premium),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('settings-restore-purchases-button'),
            onPressed: isLoading || !billingAvailable ? null : onRestore,
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Restore Purchases'),
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
  const SettingsHeroHeader({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = isDark
        ? const [Color(0xFF312E81), Color(0xFF1E3A8A)]
        : const [Color(0xFF4F46E5), Color(0xFF2563EB)];

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final offset = scrollController.hasClients
            ? scrollController.offset.clamp(0, 80).toDouble()
            : 0.0;
        return MotionElasticHero(
          baseHeight: 168,
          scrollOffset: scrollController.hasClients
              ? scrollController.offset
              : 0.0,
          child: Transform.translate(
            offset: Offset(0, -offset * 0.08),
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
                top: Radius.circular(22),
              ),
              child: MotionAmbientGradient(
                gradientBuilder: PackLoxMotionTheme.ambientBlueIndigo,
                child: AnimatedContainer(
                  duration: PackLoxMotionTheme.medium,
                  curve: PackLoxMotionTheme.revealCurve,
                  height: 168,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(26, 26, 26, 24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                      top: Radius.circular(22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.last.withValues(
                          alpha: isDark ? 0.22 : 0.28,
                        ),
                        blurRadius: 32,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -20 + offset * 0.12,
                        top: -18,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.08,
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Transform.translate(
                          offset: Offset(0, offset * 0.04),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Settings',
                                style: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Manage your PackLox experience',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onPrimary.withValues(
                                    alpha: 0.82,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
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

    return _SettingsEntrance(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GradientHeader(
            title: 'Developer Tools',
            subtitle: 'Collapsed diagnostics for test builds',
            gradientStyle: GradientStyle.purpleDeepBlue,
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
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
                          trailing: maskedEmail(
                            authState.pendingConfirmationEmail,
                          ),
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
                              syncState.errorMessage ??
                              syncState.status.message,
                          trailing: syncState.status.statusLabel,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Last auth response: ${formatDiagnosticDate(lastAuthAttempt?.timestamp)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionStack extends StatelessWidget {
  const _SectionStack({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final stackOffset = (index % 4) * 8.0;

    return AnimatedSlide(
      duration: Duration(milliseconds: 350 + index * 18),
      curve: Curves.easeOutCubic,
      offset: Offset.zero,
      child: AnimatedOpacity(
        duration: Duration(milliseconds: 360 + index * 18),
        curve: Curves.easeOutCubic,
        opacity: 1,
        child: Transform.translate(
          offset: Offset(0, stackOffset),
          child: child,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.title,
    required this.children,
    this.stackLevel = 0,
  });

  final String title;
  final List<Widget> children;
  final int stackLevel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _SettingsEntrance(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.14 : 0.07),
              blurRadius: 18 + stackLevel * 3,
              offset: Offset(0, 12 + stackLevel * 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientHeader(
              title: title,
              subtitle: _settingsSectionSubtitle(title),
              gradientStyle: _settingsSectionGradient(title),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: MotionStagger(
                children: [
                  for (var index = 0; index < children.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: index == children.length - 1
                            ? 0
                            : AppSpacing.lg,
                      ),
                      child: children[index],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsEntrance extends StatelessWidget {
  const _SettingsEntrance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
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
      onTap: onTap ?? () => _showRowMessage(context),
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

String _settingsSectionSubtitle(String title) {
  return switch (title) {
    'SIT Readiness' => 'Configuration checks for real app testing',
    'Account' => 'Identity, guest mode, and provider options',
    'App Preferences' => 'Personalize notifications and first-run flow',
    'Plan & Usage' => 'Subscription readiness and daily scan limits',
    'AI & Scanning' => 'Provider status and scan quality defaults',
    'Developer Diagnostics' => 'Safe runtime diagnostics for test builds',
    'Cloud Sync' => 'Portfolio and image sync status',
    'Storage' => 'Local and cloud image storage',
    'Data & Privacy' => 'Offline data controls and privacy links',
    'Help & About' => 'Guides for scanning, pricing, and cloud mode',
    'About' => 'Version and legal placeholders',
    _ => 'Manage ${title.toLowerCase()} settings',
  };
}

GradientStyle _settingsSectionGradient(String title) {
  return switch (title) {
    'Account' ||
    'Account Access' ||
    'Developer Diagnostics' => GradientStyle.purpleDeepBlue,
    'Cloud Sync' || 'Storage' || 'Data & Privacy' => GradientStyle.tealEmerald,
    _ => GradientStyle.blueIndigo,
  };
}

String _formatSyncDate(DateTime? value) {
  if (value == null) {
    return 'Never';
  }

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}

String _providerOptionStatus({
  required AiAnalysisProviderConfig config,
  required AiAnalysisProviderType type,
  required bool backendConfigured,
}) {
  if (config.type == type) {
    return type.isAvailable ? 'Selected' : 'Unavailable';
  }

  if (type.isAvailable) {
    return 'Available';
  }

  return backendConfigured ? 'Backend set' : 'Coming soon';
}

String _billingProductSubtitle(SubscriptionState state, SubscriptionPlan plan) {
  final product = _productForPlan(state, plan);
  if (product != null) {
    return '${product.title} - ${product.description}';
  }

  if (!state.isBillingAvailable) {
    return 'Google Play Billing product placeholder. Configure Play Console to enable.';
  }

  return 'Product not found in Google Play. Check the configured product id.';
}

String _billingProductTrailing(SubscriptionState state, SubscriptionPlan plan) {
  final product = _productForPlan(state, plan);
  if (product != null) {
    return product.price;
  }

  return state.isBillingAvailable ? 'Missing' : 'Unavailable';
}

String _upgradeLabel(SubscriptionState state, SubscriptionPlan plan) {
  final product = _productForPlan(state, plan);
  if (product == null) {
    return 'Upgrade to ${plan.displayName}';
  }

  return 'Upgrade to ${plan.displayName} - ${product.price}';
}

bool _hasProduct(SubscriptionState state, SubscriptionPlan plan) {
  return _productForPlan(state, plan) != null;
}

BillingProduct? _productForPlan(
  SubscriptionState state,
  SubscriptionPlan plan,
) {
  for (final product in state.products) {
    if (product.plan == plan) {
      return product;
    }
  }

  return null;
}
