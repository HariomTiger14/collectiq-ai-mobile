import 'package:collectiq_ai/core/ui/product_language/packlox_entry_tile.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_hero.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:flutter/material.dart';

/// S01 orchestration values; component geometry lives in Product Language.
abstract final class ScannerS01VisualValues {
  static const pagePadding = 24.0;
  static const compactPagePadding = 16.0;
  static const headerHeroGap = 32.0;
  static const heroSectionGap = 24.0;
  static const sectionFirstTileGap = 12.0;
  static const tileGap = 6.0;
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
  final String period, firstName;
  final VoidCallback? onNotifications;
  final PackLoxEntryTile cameraTile, galleryTile, sampleTile;

  @override
  Widget build(BuildContext context) => ScannerFocusTheme(
    child: Scaffold(
      key: const ValueKey('scan-hub-page'),
      backgroundColor: PackLoxTokens.background,
      body: ScannerBackground(
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final padding = constraints.maxWidth <= 360
                  ? ScannerS01VisualValues.compactPagePadding
                  : ScannerS01VisualValues.pagePadding;
              return SingleChildScrollView(
                key: const ValueKey('scan-hub-scroll-view'),
                padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PackLoxHeader(
                      greetingText: period,
                      firstName: firstName,
                      onNotifications: onNotifications,
                    ),
                    const SizedBox(
                      key: ValueKey('scan-hub-header-hero-gap'),
                      height: ScannerS01VisualValues.headerHeroGap,
                    ),
                    const PackLoxHero(
                      variant: PackLoxHeroVariant.scanner,
                      eyebrow: 'PackLox Scanner',
                      title: 'Ready when your item is.',
                      subtitle:
                          'Position one item in clear light. PackLox will guide the rest.',
                      icon: Icons.center_focus_strong_outlined,
                    ),
                    const SizedBox(
                      key: ValueKey('scan-hub-hero-section-gap'),
                      height: ScannerS01VisualValues.heroSectionGap,
                    ),
                    const Text(
                      'Choose an option',
                      style: TextStyle(
                        color: PackLoxTokens.textPrimary,
                        fontSize: 16,
                        height: 1.375,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
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
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
