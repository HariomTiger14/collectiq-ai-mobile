import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:flutter/material.dart';

abstract final class ScannerS01VisualValues {
  static const pagePadding = 24.0;
  static const compactPagePadding = 16.0;
  static const topPadding = 24.0;
  static const compactTopPadding = 16.0;
  static const greetingNameGap = 8.0;
  static const headerHeroGap = 24.0;
  static const compactHeaderHeroGap = 16.0;
  static const heroMinHeight = 132.0;
  static const heroPreferredHeight = 144.0;
  static const heroMaxHeight = 168.0;
  static const heroAspectRatio = 2.38;
  static const heroTitleWidthRatio = 0.56;
  static const heroIconSize = 44.0;
  static const heroSectionGap = 24.0;
  static const sectionFirstTileGap = 12.0;
  static const tilePreferredHeight = 72.0;
  static const tileGap = 12.0;
  static const entryIconContainerSize = 40.0;
  static const entryIconSize = 22.0;
  static const entryIconTextGap = 16.0;
  static const entryTitleSubtitleGap = 4.0;
}

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
              final horizontalPadding = constraints.maxWidth <= 360
                  ? ScannerS01VisualValues.compactPagePadding
                  : ScannerS01VisualValues.pagePadding;
              return SingleChildScrollView(
                key: const ValueKey('scan-hub-scroll-view'),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  short
                      ? ScannerS01VisualValues.compactTopPadding
                      : ScannerS01VisualValues.topPadding,
                  horizontalPadding,
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
                    SizedBox(
                      key: const ValueKey('scan-hub-header-hero-gap'),
                      height: short
                          ? ScannerS01VisualValues.compactHeaderHeroGap
                          : ScannerS01VisualValues.headerHeroGap,
                    ),
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
                    const SizedBox(
                      key: ValueKey('scan-hub-hero-section-gap'),
                      height: ScannerS01VisualValues.heroSectionGap,
                    ),
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
        SizedBox(
          key: const ValueKey('scan-hub-greeting-name-gap'),
          height: MediaQuery.textScalerOf(
            context,
          ).scale(ScannerS01VisualValues.greetingNameGap),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                firstName,
                key: const ValueKey('scan-hub-title'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ScannerVisualTheme.textPrimary,
                  fontSize: 20,
                  height: 28 / 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '\u{1F44B}',
              style: TextStyle(
                color: ScannerVisualTheme.textPrimary,
                fontSize: 20,
                height: 28 / 20,
                fontWeight: FontWeight.w800,
              ),
            ),
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final ratioHeight =
          constraints.maxWidth / ScannerS01VisualValues.heroAspectRatio;
      final preferredHeight = ratioHeight.clamp(
        ScannerS01VisualValues.heroPreferredHeight,
        ScannerS01VisualValues.heroMaxHeight,
      );
      final permitsContentGrowth =
          MediaQuery.textScalerOf(context).scale(1.0) > 1.0;
      return Container(
        key: const ValueKey('scan-hub-hero-card'),
        constraints: BoxConstraints(
          minHeight: preferredHeight,
          maxHeight: permitsContentGrowth
              ? double.infinity
              : ScannerS01VisualValues.heroMaxHeight,
        ),
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
        child: LayoutBuilder(
          builder: (context, innerConstraints) => Row(
            children: [
              SizedBox(
                width: innerConstraints.maxWidth * 0.82,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      key: const ValueKey('scan-hub-hero-title-region'),
                      width:
                          innerConstraints.maxWidth *
                          ScannerS01VisualValues.heroTitleWidthRatio,
                      child: Text(
                        'Scan a\ncollectible.',
                        maxLines: 2,
                        softWrap: permitsContentGrowth,
                        overflow: TextOverflow.visible,
                        style: const TextStyle(
                          color: ScannerVisualTheme.textPrimary,
                          fontSize: 24,
                          height: 32 / 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Identify, value,\nand protect your items.',
                      maxLines: permitsContentGrowth ? 3 : 2,
                      softWrap: permitsContentGrowth,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        color: ScannerVisualTheme.textPrimary.withValues(
                          alpha: 0.82,
                        ),
                        fontSize: 14,
                        height: 20 / 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const ExcludeSemantics(
                child: Icon(
                  key: ValueKey('scan-hub-hero-icon'),
                  Icons.center_focus_strong_outlined,
                  size: ScannerS01VisualValues.heroIconSize,
                  color: ScannerVisualTheme.cyan,
                ),
              ),
            ],
          ),
        ),
      );
    },
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
      const SizedBox(
        key: ValueKey('scan-hub-section-first-tile-gap'),
        height: ScannerS01VisualValues.sectionFirstTileGap,
      ),
      cameraTile,
      const SizedBox(
        key: ValueKey('scan-hub-tile-gap-1'),
        height: ScannerS01VisualValues.tileGap,
      ),
      galleryTile,
      const SizedBox(
        key: ValueKey('scan-hub-tile-gap-2'),
        height: ScannerS01VisualValues.tileGap,
      ),
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
        minimumSize: const Size(0, ScannerS01VisualValues.tilePreferredHeight),
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
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            ScannerEntryIcon(icon: icon),
            const SizedBox(
              key: ValueKey('scan-hub-entry-icon-text-gap'),
              width: ScannerS01VisualValues.entryIconTextGap,
            ),
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
                  const SizedBox(
                    key: ValueKey('scan-hub-entry-title-subtitle-gap'),
                    height: ScannerS01VisualValues.entryTitleSubtitleGap,
                  ),
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
    key: const ValueKey('scan-hub-entry-icon-container'),
    width: ScannerS01VisualValues.entryIconContainerSize,
    height: ScannerS01VisualValues.entryIconContainerSize,
    decoration: BoxDecoration(
      color: ScannerVisualTheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: ScannerVisualTheme.border),
    ),
    child: Icon(
      icon,
      size: ScannerS01VisualValues.entryIconSize,
      color: ScannerVisualTheme.textPrimary,
    ),
  );
}
