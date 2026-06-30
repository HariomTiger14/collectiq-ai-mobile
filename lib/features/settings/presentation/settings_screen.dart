import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/services/ai_providers.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_conflict.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/diagnostics/services/diagnostics_providers.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
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
    final portfolioState = ref.watch(portfolioControllerProvider);
    final aiProviderConfig = ref.watch(aiAnalysisProviderConfigProvider);
    final diagnostics = ref.watch(providerDiagnosticsProvider);
    final subscriptionState = ref.watch(subscriptionControllerProvider);
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
                      const _SettingsRow(
                        icon: Icons.g_mobiledata_outlined,
                        title: 'Google Sign-In',
                        subtitle:
                            'OAuth provider placeholder. No Google keys are bundled.',
                        trailing: 'Coming soon',
                      ),
                      const _SettingsRow(
                        icon: Icons.apple,
                        title: 'Apple Sign-In',
                        subtitle:
                            'OAuth provider placeholder. No Apple keys are bundled.',
                        trailing: 'Coming soon',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingsCard(
                    title: 'App Preferences',
                    children: const [
                      _SettingsRow(
                        icon: Icons.palette_outlined,
                        title: 'Theme',
                        subtitle: 'System theme is used for now.',
                        trailing: 'System',
                      ),
                      _SettingsRow(
                        icon: Icons.notifications_none_outlined,
                        title: 'Notifications',
                        subtitle:
                            'Price alerts and scan updates are placeholders.',
                        trailing: 'Off',
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
                        subtitle:
                            'No Stripe or Google Play Billing integration yet.',
                        trailing: subscriptionState.paymentStatusLabel,
                      ),
                      _SettingsRow(
                        icon: Icons.trending_up_outlined,
                        title: SubscriptionPlan.pro.displayName,
                        subtitle:
                            'Future paid plan for higher usage and cloud features.',
                        trailing: SubscriptionPlan.pro.statusLabel,
                      ),
                      _SettingsRow(
                        icon: Icons.diamond_outlined,
                        title: SubscriptionPlan.premium.displayName,
                        subtitle:
                            'Future premium plan for advanced collector tools.',
                        trailing: SubscriptionPlan.premium.statusLabel,
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
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed:
                              syncState.isLoading || imageSyncState.isUploading
                              ? null
                              : () => _manualSync(ref, portfolioState.items),
                          icon: const Icon(Icons.sync_outlined),
                          label: Text(
                            syncState.isLoading || imageSyncState.isUploading
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
                    children: const [
                      _SettingsRow(
                        icon: Icons.phone_android_outlined,
                        title: 'Local images',
                        subtitle:
                            'Captured and uploaded images stay on this device by default.',
                        trailing: 'Active',
                      ),
                      _SettingsRow(
                        icon: Icons.cloud_queue_outlined,
                        title: 'Supabase Storage',
                        subtitle:
                            'Cloud image storage is prepared for future sync.',
                        trailing: 'Ready',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingsCard(
                    title: 'Data & Privacy',
                    children: const [
                      _SettingsRow(
                        icon: Icons.storage_outlined,
                        title: 'Offline portfolio',
                        subtitle:
                            'Camera, gallery, analyze, save, and portfolio stay available without sign in.',
                        trailing: 'Active',
                      ),
                      _SettingsRow(
                        icon: Icons.file_download_outlined,
                        title: 'Export portfolio',
                        subtitle:
                            'Portfolio export will be available in a future release.',
                        trailing: 'Soon',
                      ),
                      _SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy policy',
                        subtitle:
                            'Review privacy details when cloud accounts are enabled.',
                        trailing: 'View',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _SettingsCard(
                    title: 'About',
                    children: const [
                      _SettingsRow(
                        icon: Icons.article_outlined,
                        title: 'Terms',
                        subtitle:
                            'Terms placeholder for the production release.',
                        trailing: 'View',
                      ),
                      _SettingsRow(
                        icon: Icons.info_outline,
                        title: 'App version',
                        subtitle: 'CollectIQ AI mobile preview.',
                        trailing: '0.1.0',
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
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
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
          constraints: const BoxConstraints(maxWidth: 92),
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
    );
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

Future<void> _manualSync(
  WidgetRef ref,
  List<CollectibleItem> localItems,
) async {
  debugPrint('[Sync] manual sync start');
  debugPrint('[Sync] local item count: ${localItems.length}');
  try {
    final syncController = ref.read(syncControllerProvider.notifier);
    await syncController.uploadLocalItems(localItems);
    await ref.read(imageSyncControllerProvider.notifier).processQueue();

    final downloadedItems = await syncController.downloadCloudItems();
    debugPrint('[Sync] downloaded item count: ${downloadedItems.length}');
    final localItemsById = {for (final item in localItems) item.id: item};
    final allowNewCloudItems = localItemsById.isEmpty;
    final portfolioController = ref.read(portfolioControllerProvider.notifier);
    for (final item in downloadedItems) {
      final localItem = localItemsById[item.id];
      if (localItem == null && !allowNewCloudItems) {
        debugPrint(
          '[Sync] skipping unknown cloud item to avoid resurrecting a '
          'locally deleted collectible: ${item.id}',
        );
        continue;
      }

      final resolvedItem = localItem == null
          ? item
          : SyncConflict(localItem: localItem, cloudItem: item).resolve();
      if (localItem == null ||
          resolvedItem.createdAt.isAfter(localItem.createdAt)) {
        debugPrint('[Sync] merging cloud item: ${resolvedItem.id}');
        await portfolioController.upsertSyncedItem(resolvedItem);
      }
    }
    await ref.read(imageSyncControllerProvider.notifier).loadSnapshot();
    debugPrint('[Sync] manual sync complete');
  } on Object catch (error, stackTrace) {
    debugPrint('[Sync] manual sync caught exception: $error');
    debugPrint('$stackTrace');
    ref
        .read(syncControllerProvider.notifier)
        .markManualSyncFailed(error, pendingItemCount: localItems.length);
    await ref.read(imageSyncControllerProvider.notifier).loadSnapshot();
  }
}
