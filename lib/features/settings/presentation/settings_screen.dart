import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppScaffold(
      title: 'Settings',
      subtitle: 'Manage your app preferences and account options.',
      child: AppResponsiveColumn(
        spacing: AppSpacing.xl,
        children: [
          _SettingsSection(
            title: 'Account',
            rows: [
              _SettingsRow(
                icon: Icons.person_outline,
                title: 'Profile / Account',
                subtitle: 'Manage your collector profile and account details.',
                status: 'Coming soon',
              ),
            ],
          ),
          _SettingsSection(
            title: 'App Preferences',
            rows: [
              _SettingsRow(
                icon: Icons.dark_mode_outlined,
                title: 'Theme',
                subtitle: 'Choose light, dark, or system appearance.',
                status: 'System',
              ),
              _SettingsRow(
                icon: Icons.notifications_none_outlined,
                title: 'Notifications',
                subtitle: 'Control scan alerts and portfolio reminders.',
                status: 'Off',
              ),
            ],
          ),
          _SettingsSection(
            title: 'AI & Scanning',
            rows: [
              _SettingsRow(
                icon: Icons.auto_awesome_outlined,
                title: 'AI Model',
                subtitle: 'Select recognition model and scan behavior.',
                status: 'Mock',
              ),
            ],
          ),
          _SettingsSection(
            title: 'Data & Privacy',
            rows: [
              _SettingsRow(
                icon: Icons.file_download_outlined,
                title: 'Export Portfolio',
                subtitle: 'Download your saved collectibles data.',
                status: 'Soon',
              ),
              _SettingsRow(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'Review how CollectIQ AI handles your data.',
              ),
              _SettingsRow(
                icon: Icons.description_outlined,
                title: 'Terms',
                subtitle: 'Read terms of use and collector disclaimers.',
              ),
            ],
          ),
          _SettingsSection(
            title: 'About',
            rows: [
              _SettingsRow(
                icon: Icons.info_outline,
                title: 'App Version',
                subtitle: 'CollectIQ AI mobile preview.',
                status: '0.1.0',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.rows});

  final String title;
  final List<_SettingsRow> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppResponsiveColumn(
      spacing: AppSpacing.md,
      children: [
        SectionHeader(title: title),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                rows[index],
                if (index != rows.length - 1)
                  Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg,
                    color: colorScheme.outlineVariant,
                  ),
              ],
            ],
          ),
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
    this.status,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.medium),
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
                    fontWeight: FontWeight.w800,
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
          if (status != null)
            StatusChip(label: status!)
          else
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
