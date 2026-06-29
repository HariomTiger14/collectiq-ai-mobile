import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings screen for account and sync placeholders.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final syncState = ref.watch(syncControllerProvider);
    final imageSyncState = ref.watch(imageSyncControllerProvider);
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
                        icon: Icons.person_outline,
                        title: 'Continue as Guest',
                        subtitle:
                            'Use camera, scans, and local portfolio without an account.',
                        trailing: authState.isSignedIn ? 'Off' : 'Active',
                      ),
                      _SettingsRow(
                        icon: Icons.login_outlined,
                        title: authState.isSignedIn ? 'Account' : 'Sign In',
                        subtitle: authState.isSignedIn
                            ? authState.user!.displayName
                            : 'Optional Supabase account sign in is prepared.',
                        trailing: authState.statusLabel,
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
                    title: 'AI & Scanning',
                    children: const [
                      _SettingsRow(
                        icon: Icons.auto_awesome_outlined,
                        title: 'AI model',
                        subtitle:
                            'Uses the configured backend recognition provider.',
                        trailing: 'Auto',
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
                    title: 'Cloud Sync',
                    children: [
                      _SettingsRow(
                        icon: Icons.cloud_done_outlined,
                        title: 'Cloud status',
                        subtitle:
                            'Image uploads run in the background when cloud storage is configured.',
                        trailing: imageSyncState.cloudStatus,
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
                        trailing: imageSyncState.snapshot.pendingCount
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
