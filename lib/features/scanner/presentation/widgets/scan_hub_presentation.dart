import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:flutter/material.dart';

class ScannerPageScaffold extends StatelessWidget {
  const ScannerPageScaffold({
    required this.period,
    required this.firstName,
    required this.onNotifications,
    required this.cameraTile,
    required this.galleryTile,
    required this.sampleTile,
    super.key,
  });
  final String period;
  final String firstName;
  final VoidCallback? onNotifications;
  final ScannerEntryTile cameraTile;
  final ScannerEntryTile galleryTile;
  final ScannerEntryTile sampleTile;

  @override
  Widget build(BuildContext context) => ScannerFocusTheme(
    child: Scaffold(
      key: const ValueKey('scan-hub-page'),
      backgroundColor: ScannerVisualTheme.background,
      body: ScannerBackground(
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final short = constraints.maxHeight < 680;
              return SingleChildScrollView(
                key: const ValueKey('scan-hub-scroll-view'),
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  short ? AppSpacing.sm : AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ScannerHeader(
                      period: period,
                      firstName: firstName,
                      onNotifications: onNotifications,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const ScannerHeroCard(),
                    const SizedBox.shrink(
                      key: ValueKey('scan-hub-collectible-visual'),
                      child: Column(
                        children: [
                          Text('Scan a collectible'),
                          Text(
                            'Take a clear photo and PackLox will help '
                            'identify, value, and save it.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ScannerOptionSection(
                      cameraTile: cameraTile,
                      galleryTile: galleryTile,
                      sampleTile: sampleTile,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}

class ScannerHeader extends StatelessWidget {
  const ScannerHeader({
    required this.period,
    required this.firstName,
    required this.onNotifications,
    super.key,
  });
  final String period;
  final String firstName;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: DynamicGreeting(period: period, firstName: firstName),
      ),
      const SizedBox(width: AppSpacing.sm),
      NotificationAction(onPressed: onNotifications),
    ],
  );
}

class DynamicGreeting extends StatelessWidget {
  const DynamicGreeting({
    required this.period,
    required this.firstName,
    super.key,
  });
  final String period;
  final String firstName;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: '$period, $firstName',
    excludeSemantics: true,
    child: Column(
      key: const ValueKey('scan-hub-heading-group'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period,
          style: const TextStyle(
            color: ScannerVisualTheme.textSecondary,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: MediaQuery.textScalerOf(context).scale(AppSpacing.xs)),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                '$firstName \u{1F44B}',
                key: const ValueKey('scan-hub-title'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ScannerVisualTheme.textPrimary,
                  fontSize: 20,
                  height: 26 / 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox.shrink(),
            const SizedBox.shrink(),
          ],
        ),
      ],
    ),
  );
}

class NotificationAction extends StatelessWidget {
  const NotificationAction({required this.onPressed, super.key});
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: onPressed != null,
    label: 'Notifications',
    excludeSemantics: true,
    child: Tooltip(
      message: 'Notifications',
      child: SizedBox.square(
        dimension: 48,
        child: IconButton(
          key: const ValueKey('scan-hub-notifications-button'),
          onPressed: onPressed,
          icon: const Icon(Icons.notifications_outlined),
          iconSize: 22,
          color: ScannerVisualTheme.textPrimary,
          disabledColor: ScannerVisualTheme.textSecondary,
        ),
      ),
    ),
  );
}

class ScannerHeroCard extends StatelessWidget {
  const ScannerHeroCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('scan-hub-hero-card'),
    constraints: const BoxConstraints(minHeight: 136),
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF123C8F), Color(0xFF082C67)],
      ),
      borderRadius: BorderRadius.circular(AppRadius.md),
      border: Border.all(color: const Color(0xFF2563EB)),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Scan a\ncollectible.',
                style: TextStyle(
                  color: ScannerVisualTheme.textPrimary,
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Identify, value, and\nprotect your items.',
                style: TextStyle(
                  color: ScannerVisualTheme.textPrimary.withValues(alpha: 0.82),
                  fontSize: 14,
                  height: 20 / 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        const ExcludeSemantics(
          child: Icon(
            Icons.center_focus_strong_outlined,
            size: 42,
            color: ScannerVisualTheme.cyan,
          ),
        ),
      ],
    ),
  );
}

class ScannerOptionSection extends StatelessWidget {
  const ScannerOptionSection({
    required this.cameraTile,
    required this.galleryTile,
    required this.sampleTile,
    super.key,
  });
  final ScannerEntryTile cameraTile;
  final ScannerEntryTile galleryTile;
  final ScannerEntryTile sampleTile;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const ScannerSectionHeading('Choose an option'),
      const SizedBox(height: AppSpacing.sm),
      cameraTile,
      const SizedBox(height: AppSpacing.sm),
      galleryTile,
      const SizedBox(height: AppSpacing.sm),
      sampleTile,
    ],
  );
}

class ScannerSectionHeading extends StatelessWidget {
  const ScannerSectionHeading(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: ScannerVisualTheme.textPrimary,
      fontSize: 16,
      height: 22 / 16,
      fontWeight: FontWeight.w700,
    ),
  );
}

class ScannerEntryTile extends StatelessWidget {
  const ScannerEntryTile({
    required this.semanticLabel,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.compatibilityKey,
    super.key,
  });
  final String semanticLabel;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Key? compatibilityKey;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: semanticLabel,
    excludeSemantics: true,
    child: FilledButton(
      key: compatibilityKey,
      onPressed: onTap,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 64),
        backgroundColor: ScannerVisualTheme.surfaceElevated,
        foregroundColor: ScannerVisualTheme.textPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: ScannerVisualTheme.border),
        ),
      ),
      child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                ScannerEntryIcon(icon: icon),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: ScannerVisualTheme.textPrimary,
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: ScannerVisualTheme.textSecondary,
                          fontSize: 12,
                          height: 16 / 12,
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

class ScannerEntryIcon extends StatelessWidget {
  const ScannerEntryIcon({required this.icon, super.key});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: ScannerVisualTheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: ScannerVisualTheme.border),
    ),
    child: Icon(icon, size: 22, color: ScannerVisualTheme.textPrimary),
  );
}
