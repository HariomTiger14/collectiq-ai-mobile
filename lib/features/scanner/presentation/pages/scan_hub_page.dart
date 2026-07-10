import 'dart:async';

import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scanner_screen.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScanHubPage extends ConsumerStatefulWidget {
  const ScanHubPage({this.onViewPortfolio, super.key});

  final VoidCallback? onViewPortfolio;

  @override
  ConsumerState<ScanHubPage> createState() => _ScanHubPageState();
}

class _ScanHubPageState extends ConsumerState<ScanHubPage> {
  final ScrollController _scrollController = ScrollController();
  bool _muted = false;
  bool _hasRecoveredLostPickerData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasRecoveredLostPickerData) {
        return;
      }
      _hasRecoveredLostPickerData = true;
      unawaited(
        ref
            .read(scannerControllerProvider.notifier)
            .recoverLostPickerData(reason: 'scan-hub-startup'),
      );
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerControllerProvider);
    final hasActiveScan =
        scannerState.scanResult != null ||
        scannerState.captureImages.isNotEmpty ||
        scannerState.selectedImagePath != null ||
        scannerState.isLoading ||
        scannerState.isPreparingImage ||
        scannerState.errorMessage != null;

    if (hasActiveScan) {
      return ScannerScreen(onViewPortfolio: widget.onViewPortfolio);
    }

    final portfolioItems = ref
        .watch(portfolioControllerProvider)
        .orderedItems
        .take(5)
        .toList(growable: false);

    return Scaffold(
      key: const ValueKey('scan-hub-page'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth <= 360;
            final silhouetteHeight = constraints.maxHeight < 660
                ? 218.0
                : isCompact
                ? 238.0
                : 268.0;

            return CustomScrollView(
              key: const ValueKey('scan-hub-scroll-view'),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _ScanHubHero(scrollController: _scrollController),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    isCompact ? AppSpacing.lg : AppSpacing.xl,
                    AppSpacing.xl,
                    isCompact ? AppSpacing.lg : AppSpacing.xl,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      MotionReveal(
                        delay: PackLoxMotionTheme.revealStagger,
                        child: _CollectibleSilhouetteFrame(
                          height: silhouetteHeight,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _ScanHubActions(
                        muted: _muted,
                        onCapture: () => unawaited(_startCameraScan(context)),
                        onGallery: () => unawaited(_pickFromGallery(context)),
                        onMute: () => setState(() => _muted = !_muted),
                      ),
                      if (scannerState.errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        MotionReveal(
                          child: _ScanHubErrorMessage(
                            message: scannerState.errorMessage!,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      MotionReveal(
                        delay: PackLoxMotionTheme.revealStagger * 3,
                        child: Center(
                          child: TextButton.icon(
                            key: const ValueKey(
                              'scan-secondary-Use Sample Scan',
                            ),
                            onPressed: ref
                                .read(scannerControllerProvider.notifier)
                                .useSampleScan,
                            icon: const Icon(Icons.science_outlined),
                            label: const Text('Use Sample Scan'),
                          ),
                        ),
                      ),
                      if (portfolioItems.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        _RecentScansStrip(items: portfolioItems),
                      ],
                      SizedBox(height: isCompact ? AppSpacing.xl : 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _startCameraScan(BuildContext context) {
    return ref
        .read(scannerControllerProvider.notifier)
        .startCameraScan(context, imageRole: 'front');
  }

  Future<void> _pickFromGallery(BuildContext context) {
    return ref
        .read(scannerControllerProvider.notifier)
        .pickImageFromGallery(context: context, imageRole: 'front');
  }
}

class _ScanHubHero extends StatelessWidget {
  const _ScanHubHero({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final gradientColors = PackLoxGradients.build(
      GradientStyle.purpleDeepBlue,
      context,
    );

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;

        return MotionElasticHero(
          baseHeight: 198 + topInset,
          scrollOffset: scrollOffset,
          child: MotionParallax(
            scrollOffset: scrollOffset,
            child: MotionAmbientGradient(
              gradientBuilder: (t) {
                final shifted = [
                  Color.lerp(gradientColors[0], gradientColors[1], t)!,
                  Color.lerp(gradientColors[1], gradientColors[2], 1 - t)!,
                  gradientColors[2],
                ];
                return LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: shifted,
                );
              },
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadius.xxl),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: 0.24),
                      blurRadius: 36,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned(
                      right: -24,
                      top: -32,
                      child: HeroDecorativeCircle(
                        diameter: 138,
                        strokeWidth: 22,
                        opacity: Theme.of(context).brightness == Brightness.dark
                            ? 0.14
                            : 0.18,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        topInset + AppSpacing.lg,
                        AppSpacing.xl,
                        AppSpacing.lg,
                      ),
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: MotionReveal(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommended: Front / Obverse',
                                key: const ValueKey('scan-hub-hero-title'),
                                softWrap: true,
                                style: textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.05,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Detecting…',
                                key: const ValueKey('scan-hub-hero-subtitle'),
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onPrimary.withValues(
                                    alpha: 0.82,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs + 2),
                              Text(
                                'Start with the most recognizable face, label, or package front.',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimary.withValues(
                                    alpha: 0.68,
                                  ),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CollectibleSilhouetteFrame extends StatelessWidget {
  const _CollectibleSilhouetteFrame({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotionPulse(
      minScale: 0.995,
      maxScale: 1.012,
      minOpacity: 0.94,
      child: Container(
        key: const ValueKey('scan-hub-silhouette-frame'),
        height: height,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.24),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.16),
              blurRadius: 34,
              offset: const Offset(0, 18),
            ),
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.08),
                      colorScheme.tertiary.withValues(alpha: 0.06),
                      colorScheme.surfaceContainerLow.withValues(alpha: 0.20),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              width: height * 0.58,
              height: height * 0.70,
              child: CustomPaint(
                key: const ValueKey('scan-hub-silhouette-art'),
                painter: _CollectibleSilhouettePainter(colorScheme),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectibleSilhouettePainter extends CustomPainter {
  const _CollectibleSilhouettePainter(this.colorScheme);

  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final cardPaint = Paint()
      ..color = colorScheme.onSurface.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = colorScheme.primary.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final coinPaint = Paint()
      ..color = colorScheme.secondary.withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.10, 0, size.width * 0.68, size.height),
      const Radius.circular(AppRadius.lg),
    );
    canvas.drawRRect(cardRect, cardPaint);
    canvas.drawRRect(cardRect, strokePaint);

    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.62),
      size.width * 0.24,
      coinPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.62),
      size.width * 0.24,
      strokePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CollectibleSilhouettePainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}

class _ScanHubActions extends StatelessWidget {
  const _ScanHubActions({
    required this.muted,
    required this.onCapture,
    required this.onGallery,
    required this.onMute,
  });

  final bool muted;
  final VoidCallback onCapture;
  final VoidCallback onGallery;
  final VoidCallback onMute;

  @override
  Widget build(BuildContext context) {
    return MotionReveal(
      delay: PackLoxMotionTheme.revealStagger * 2,
      child: Row(
        key: const ValueKey('scan-hub-action-row'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SecondaryHubButton(
            key: const ValueKey('scan-hub-gallery-button'),
            legacyKey: const ValueKey('scan-secondary-Gallery'),
            icon: Icons.photo_library_outlined,
            label: 'Gallery',
            onPressed: onGallery,
          ),
          const SizedBox(width: AppSpacing.xl),
          _CaptureHubButton(onPressed: onCapture),
          const SizedBox(width: AppSpacing.xl),
          _SecondaryHubButton(
            key: const ValueKey('scan-hub-mute-button'),
            icon: muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            label: muted ? 'Muted' : 'Sound on',
            onPressed: onMute,
            iconOnly: true,
          ),
        ],
      ),
    );
  }
}

class _CaptureHubButton extends StatelessWidget {
  const _CaptureHubButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final colors = PackLoxGradients.build(GradientStyle.blueIndigo, context);

    return KeyedSubtree(
      key: const ValueKey('scan-primary-Scan with Camera'),
      child: MotionTapScale(
        onTap: onPressed,
        child: Tooltip(
          message: 'Capture',
          child: Container(
            key: const ValueKey('scan-hub-capture-button'),
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.26),
                  blurRadius: 30,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Icon(
              Icons.photo_camera_rounded,
              color: colorScheme.onPrimary,
              size: 34,
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryHubButton extends StatelessWidget {
  const _SecondaryHubButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconOnly = false,
    this.legacyKey,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool iconOnly;
  final Key? legacyKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final button = MotionTapScale(
      onTap: onPressed,
      child: Tooltip(
        message: label,
        child: Container(
          width: iconOnly ? 52 : 64,
          height: iconOnly ? 52 : 64,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: colorScheme.onSurface, size: 24),
        ),
      ),
    );

    final legacyKey = this.legacyKey;
    if (legacyKey == null) {
      return button;
    }
    return KeyedSubtree(key: legacyKey, child: button);
  }
}

class _ScanHubErrorMessage extends StatelessWidget {
  const _ScanHubErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: colorScheme.onErrorContainer,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentScansStrip extends StatelessWidget {
  const _RecentScansStrip({required this.items});

  final List<CollectibleItem> items;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return MotionReveal(
      delay: PackLoxMotionTheme.revealStagger * 3,
      child: Column(
        key: const ValueKey('scan-hub-recent-scans'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent scans',
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = items[index];
                return MotionTapScale(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CollectibleDetailPage(item: item),
                    ),
                  ),
                  child: Container(
                    key: ValueKey('scan-hub-recent-${item.id}'),
                    width: 92,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.24,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          child: PortfolioThumbnail(
                            imagePath: item.imagePath,
                            size: 58,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
