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
                    topPadding: AppSpacing.xxl,
                    child: _ScannerReticle(),
                  ),
                  HomeSection(
                    topPadding: AppSpacing.xxl,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                        const SizedBox(height: 18),
                        const _ScannerTrustNote(),
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
        const SizedBox(height: 12),
        Text(
          'Capture one item — PackLox identifies it, prices it, and files the evidence.',
          maxLines: 2,
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

/// Animated scanner viewfinder that anchors the hub visually. Replaces the old
/// text-heavy hero card. Honors reduce-motion by resting mid-sweep.
class _ScannerReticle extends StatefulWidget {
  const _ScannerReticle();

  @override
  State<_ScannerReticle> createState() => _ScannerReticleState();
}

class _ScannerReticleState extends State<_ScannerReticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.stop();
      _controller.value = 0.5;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        key: const ValueKey('scan-hub-reticle'),
        height: 210,
        decoration: BoxDecoration(
          color: HomeTokens.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: HomeTokens.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 1.1,
                      colors: [
                        HomeTokens.accent.withValues(alpha: .16),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Center(
                child: Icon(
                  Icons.center_focus_strong_rounded,
                  size: 40,
                  color: HomeTokens.accent.withValues(alpha: .55),
                ),
              ),
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _ReticlePainter(progress: _controller.value),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  const _ReticlePainter({required this.progress});

  final double progress;

  static const _line = Color(0xFF67B6FF);

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 34.0;
    final rect = Rect.fromLTRB(
      inset,
      26,
      size.width - inset,
      size.height - 26,
    );
    const cornerLen = 22.0;
    final bracket = Paint()
      ..color = _line
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas
      ..drawPath(
        Path()
          ..moveTo(rect.left, rect.top + cornerLen)
          ..lineTo(rect.left, rect.top)
          ..lineTo(rect.left + cornerLen, rect.top),
        bracket,
      )
      ..drawPath(
        Path()
          ..moveTo(rect.right - cornerLen, rect.top)
          ..lineTo(rect.right, rect.top)
          ..lineTo(rect.right, rect.top + cornerLen),
        bracket,
      )
      ..drawPath(
        Path()
          ..moveTo(rect.left, rect.bottom - cornerLen)
          ..lineTo(rect.left, rect.bottom)
          ..lineTo(rect.left + cornerLen, rect.bottom),
        bracket,
      )
      ..drawPath(
        Path()
          ..moveTo(rect.right - cornerLen, rect.bottom)
          ..lineTo(rect.right, rect.bottom)
          ..lineTo(rect.right, rect.bottom - cornerLen),
        bracket,
      );

    // Sweeping scan line with a soft trailing band.
    final y = rect.top + 6 + (rect.height - 12) * progress;
    final band = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.transparent, _line, Colors.transparent],
      ).createShader(Rect.fromLTWH(rect.left, y - 7, rect.width, 14));
    canvas
      ..drawRect(
        Rect.fromLTWH(rect.left, y - 7, rect.width, 14),
        Paint()..color = _line.withValues(alpha: .06),
      )
      ..drawRect(Rect.fromLTWH(rect.left, y - 1.5, rect.width, 3), band);
  }

  @override
  bool shouldRepaint(_ReticlePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ScannerTrustNote extends StatelessWidget {
  const _ScannerTrustNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('scan-hub-trust-note'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_outlined,
          size: 16,
          color: HomeTokens.categoryMore,
        ),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            'Priced from real market data — not AI guesses.',
            maxLines: 2,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
