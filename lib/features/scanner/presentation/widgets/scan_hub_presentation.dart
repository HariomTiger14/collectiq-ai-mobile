import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ScannerPageScaffold extends StatelessWidget {
  const ScannerPageScaffold({
    required this.cameraTile,
    required this.galleryTile,
    this.sampleTile,
    super.key,
  });
  final Widget cameraTile, galleryTile;
  final Widget? sampleTile;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: HomeTokens.background,
        systemNavigationBarDividerColor: HomeTokens.background,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Theme(
        data: AppTheme.dark,
        child: Scaffold(
          key: const ValueKey('scan-hub-page'),
          backgroundColor: HomeTokens.background,
          body: SafeArea(
            bottom: false,
            child: ColoredBox(
              key: const ValueKey('scanner-dark-background'),
              color: HomeTokens.background,
              child: HomeStateContainer(
                key: const ValueKey('scan-hub-scroll-view'),
                storageKey: 'scan-hub-scroll-position',
                bottomClearance: GlassBottomNavBar.scrollContentClearance(
                  context,
                ),
                sections: [
                  const HomeSection(
                    topPadding: AppSpacing.sm,
                    child: HomeBrandLockup(),
                  ),
                  const HomeSection(
                    topPadding: AppSpacing.lg,
                    child: _ScannerTitleBlock(),
                  ),
                  const HomeSection(
                    topPadding: AppSpacing.xl,
                    child: _ScannerHeroCard(),
                  ),
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _ScannerSectionHeader(),
                        const SizedBox(
                          key: ValueKey('scan-hub-section-tile-gap'),
                          height: 12,
                        ),
                        cameraTile,
                        const SizedBox(
                          key: ValueKey('scan-hub-tile-gap-1'),
                          height: 10,
                        ),
                        galleryTile,
                        if (sampleTile != null) ...[
                          const SizedBox(
                            key: ValueKey('scan-hub-tile-gap-2'),
                            height: 10,
                          ),
                          sampleTile!,
                        ],
                      ],
                    ),
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

class _ScannerTitleBlock extends StatelessWidget {
  const _ScannerTitleBlock();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scan',
          key: const ValueKey('scan-hub-title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.displaySmall?.copyWith(
            color: HomeTokens.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Capture one collectible, then PackLox will identify, price, and save the evidence.',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            color: HomeTokens.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _ScannerHeroCard extends StatelessWidget {
  const _ScannerHeroCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return HomeSurface(
      keyPrefix: 'scan-hub',
      keySeed: 'hero-card',
      semanticLabel:
          'PackLox scanner. Start with one clear item. Use camera or gallery. PackLox will guide identity, condition notes, and trusted valuation.',
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
      radius: 24,
      backgroundColor: HomeTokens.surfaceRaised.withValues(alpha: .94),
      borderColor: HomeTokens.border,
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -42,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: HomeTokens.accent.withValues(alpha: .18),
                ),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'PackLox Scanner'.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelLarge?.copyWith(
                        color: const Color(0xFF67B6FF),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Start with one clear item.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.headlineMedium?.copyWith(
                        color: HomeTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.08,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Use camera or gallery. PackLox will guide identity, condition notes, and trusted valuation.',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: HomeTokens.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: HomeTokens.accent.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: HomeTokens.accent.withValues(alpha: .38),
                  ),
                ),
                child: const Icon(
                  Icons.center_focus_strong_rounded,
                  color: Color(0xFF67B6FF),
                  size: 30,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScannerSectionHeader extends StatelessWidget {
  const _ScannerSectionHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an option',
          style: textTheme.titleLarge?.copyWith(
            color: HomeTokens.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Camera is best for fresh evidence. Gallery works for existing photos.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodyMedium?.copyWith(
            color: HomeTokens.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}
