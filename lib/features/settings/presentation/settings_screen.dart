import 'package:collectiq_ai/core/cloud/cloud_portfolio_sync_coordinator.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/network/api_client.dart' as network;
import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/services/ai_providers.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
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
  bool _isManualCloudSyncing = false;

  @override
  void dispose() {
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
    });

    final authState = ref.watch(authControllerProvider);
    final syncState = ref.watch(syncControllerProvider);
    final imageSyncState = ref.watch(imageSyncControllerProvider);
    final cloudRegistry = ref.watch(cloudServiceRegistryProvider);
    final canRunCloudSync = _cloudSyncAvailable(cloudRegistry);
    final supabaseConfig = ref.watch(supabaseConfigProvider);
    final apiConfig = ref.watch(network.environmentConfigProvider);
    final aiProviderConfig = ref.watch(aiAnalysisProviderConfigProvider);
    final diagnostics = ref.watch(providerDiagnosticsProvider);
    final subscriptionState = ref.watch(subscriptionControllerProvider);
    final notificationState = ref.watch(
      priceAlertNotificationControllerProvider,
    );
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Settings',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Manage account and cloud sync options.',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingsCard(
                    title: 'SIT Readiness',
                    children: [
                      _SettingsRow(
                        icon: Icons.route_outlined,
                        title: 'Environment',
                        subtitle:
                            cloudRegistry.config.environment ==
                                AppEnvironment.sit
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
                        icon: Icons.person_outline,
                        title: 'Auth status',
                        subtitle: authState.isSignedIn
                            ? authState.user?.email ??
                                  authState.user?.id ??
                                  'Signed in'
                            : 'Signed out. Sign in with email/password before cloud sync.',
                        trailing: authState.isSignedIn
                            ? 'Signed in'
                            : 'Signed out',
                      ),
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
                        icon: Icons.schedule_outlined,
                        title: 'Last sync status',
                        subtitle:
                            syncState.errorMessage ?? syncState.status.message,
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
                            'CollectIQ AI stays fully usable in local-first mode.',
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
                            (authState.isSignedIn
                                ? authState.user!.displayName
                                : 'Cloud sign-in is optional and prepared for a future release.'),
                        trailing: authState.errorMessage != null
                            ? 'Needs attention'
                            : authState.statusLabel,
                      ),
                      _AuthEmailPanel(
                        emailController: _emailController,
                        passwordController: _passwordController,
                        authState: authState,
                        onSignIn: () => _submitEmailAuth(signUp: false),
                        onSignUp: () => _submitEmailAuth(signUp: true),
                        onSignOut: authState.isSignedIn
                            ? () => ref
                                  .read(authControllerProvider.notifier)
                                  .signOut()
                            : null,
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
                              priceAlertNotificationControllerProvider.notifier,
                            )
                            .setEnabled(enabled),
                        onRequestPermission: () => ref
                            .read(
                              priceAlertNotificationControllerProvider.notifier,
                            )
                            .requestPermission(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingsCard(
                    title: 'Plan & Usage',
                    children: [
                      _SettingsRow(
                        icon: Icons.workspace_premium_outlined,
                        title: 'Current plan',
                        subtitle:
                            'CollectIQ AI is local-first. Paid plans are placeholders.',
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
                      if (aiProviderConfig.type == AiAnalysisProviderType.mock)
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
                        title: AiAnalysisProviderType.openAiVision.displayName,
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
                        title: AiAnalysisProviderType.geminiVision.displayName,
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
                        subtitle: 'CollectIQ AI mobile preview.',
                        trailing: '0.1.0',
                        message: 'CollectIQ AI mobile preview 0.1.0.',
                      ),
                    ],
                  ),
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

  Future<void> _resetOnboarding(BuildContext context) async {
    await ref.read(onboardingControllerProvider.notifier).reset();
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Onboarding will show the next time you open CollectIQ AI.',
        ),
      ),
    );
  }
}

class _AuthEmailPanel extends StatelessWidget {
  const _AuthEmailPanel({
    required this.emailController,
    required this.passwordController,
    required this.authState,
    required this.onSignIn,
    required this.onSignUp,
    required this.onSignOut,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final AuthState authState;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLoading = authState.isLoading;
    final signedInEmail = authState.user?.email;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.56),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.email_outlined, color: colorScheme.primary),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email / Password',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    authState.isSignedIn
                        ? signedInEmail ?? authState.user!.displayName
                        : 'Optional Supabase account. Local mode remains available.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              authState.isSignedIn ? 'Signed in' : 'Ready',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const ValueKey('settings-auth-email-field'),
          controller: emailController,
          enabled: !isLoading,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'collector@example.com',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          key: const ValueKey('settings-auth-password-field'),
          controller: passwordController,
          enabled: !isLoading,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          decoration: const InputDecoration(
            labelText: 'Password',
            hintText: 'Minimum 6 characters',
          ),
        ),
        if (authState.errorMessage != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            authState.errorMessage!,
            style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('settings-auth-sign-in-button'),
            onPressed: isLoading ? null : onSignIn,
            icon: const Icon(Icons.login_outlined),
            label: Text(isLoading ? 'Working...' : 'Sign In'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const ValueKey('settings-auth-sign-up-button'),
            onPressed: isLoading ? null : onSignUp,
            icon: const Icon(Icons.person_add_alt_outlined),
            label: const Text('Sign Up'),
          ),
        ),
        if (authState.isSignedIn) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              key: const ValueKey('settings-auth-sign-out-button'),
              onPressed: isLoading ? null : onSignOut,
              icon: const Icon(Icons.logout_outlined),
              label: const Text('Sign Out'),
            ),
          ),
        ],
      ],
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

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(height: AppSpacing.xl, color: colorScheme.outlineVariant),
          ],
        ],
      ),
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: () => _showRowMessage(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 104),
                child: Text(
                  trailing,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
