import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

/// A parameterized full-bleed gradient hero header, matching the visual
/// language of About/CloudSync's own hero headers (elastic overscroll
/// stretch, scroll parallax, ambient animated gradient) but with icon,
/// title, and subtitle supplied by the caller instead of hardcoded --
/// About/CloudSync's hero widgets bake their own copy in, so they can't be
/// reused directly for a third screen.
class GradientHeroHeader extends StatelessWidget {
  const GradientHeroHeader({
    required this.scrollController,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.gradientStyle = GradientStyle.blueIndigo,
    this.onBack,
    super.key,
  });

  final ScrollController scrollController;
  final IconData icon;
  final String title;
  final String subtitle;
  final GradientStyle gradientStyle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _heroGradientColors(context, gradientStyle);

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        final parallax = scrollOffset.clamp(0, 120).toDouble();

        return MotionElasticHero(
          // Taller than About's original 172 -- that value only ever had to
          // fit a single-line subtitle ("Smart Collections. Beautifully
          // Organized."). This header is reused across screens with their
          // own, longer subtitle copy that wraps to 2 lines (maxLines: 2),
          // so the fixed height needs enough headroom for that, not just
          // the shortest case.
          baseHeight: 196,
          scrollOffset: scrollOffset,
          child: MotionParallax(
            scrollOffset: scrollOffset,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
              child: MotionAmbientGradient(
                gradientBuilder: _ambientGradientFor(gradientStyle),
                child: Container(
                  height: 196,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.last.withValues(
                          alpha: isDark ? 0.18 : 0.26,
                        ),
                        blurRadius: isDark ? 18 : 34,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Stack(
                      children: [
                        Positioned(
                          right: -26 + parallax * 0.08,
                          top: -28,
                          child: Container(
                            width: 136,
                            height: 136,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.08,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 30 - parallax * 0.04,
                          bottom: -22,
                          child: Icon(
                            icon,
                            color: colorScheme.onPrimary.withValues(
                              alpha: 0.12,
                            ),
                            size: 92,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Transform.translate(
                            offset: Offset(
                              onBack == null ? 0 : 58,
                              parallax * 0.04,
                            ),
                            // Align/Transform.translate give an unconstrained
                            // width to their child, so without this the Text
                            // widgets below never feel pressure to wrap or
                            // ellipsize -- they just lay out on one long line
                            // and get visually clipped by the header's
                            // rounded edge instead of truncating cleanly.
                            // Reserves horizontal padding (24 each side),
                            // the back-button offset, and space for the
                            // decorative icon on the right.
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                // Clamped to 0: an unusually narrow/degenerate
                                // MediaQuery width (e.g. a test harness that
                                // overrides MediaQueryData without a size)
                                // would otherwise subtract past zero and hand
                                // ConstrainedBox a negative, invalid maxWidth.
                                maxWidth:
                                    (MediaQuery.sizeOf(context).width -
                                            48 -
                                            (onBack == null ? 0 : 58) -
                                            70)
                                        .clamp(0, double.infinity),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.headlineSmall?.copyWith(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w900,
                                      height: 1.05,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onPrimary.withValues(
                                        alpha: 0.82,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (onBack != null)
                          Align(
                            alignment: Alignment.topLeft,
                            child: _GradientHeroBackButton(onTap: onBack!),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GradientHeroBackButton extends StatefulWidget {
  const _GradientHeroBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_GradientHeroBackButton> createState() =>
      _GradientHeroBackButtonState();
}

class _GradientHeroBackButtonState extends State<_GradientHeroBackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: MotionTapScale(
        onTap: widget.onTap,
        scale: 0.94,
        child: AnimatedContainer(
          duration: PackLoxMotionTheme.fast,
          curve: PackLoxMotionTheme.hoverCurve,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.onPrimary.withValues(
              alpha: _hovered ? 0.20 : 0.14,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.onPrimary.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(
            Icons.arrow_back_rounded,
            color: colorScheme.onPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

List<Color> _heroGradientColors(BuildContext context, GradientStyle style) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return switch (style) {
    GradientStyle.blueIndigo =>
      isDark
          ? const [Color(0xFF1E40AF), Color(0xFF3730A3)]
          : const [Color(0xFF2563EB), Color(0xFF4F46E5)],
    GradientStyle.purpleDeepBlue =>
      isDark
          ? const [Color(0xFF6D28D9), Color(0xFF1E3A8A)]
          : const [Color(0xFF8B5CF6), Color(0xFF1D4ED8)],
    GradientStyle.tealEmerald =>
      isDark
          ? const [Color(0xFF0F766E), Color(0xFF047857)]
          : const [Color(0xFF14B8A6), Color(0xFF10B981)],
  };
}

Gradient Function(double) _ambientGradientFor(GradientStyle style) {
  return switch (style) {
    GradientStyle.purpleDeepBlue => PackLoxMotionTheme.ambientPurpleDeepBlue,
    GradientStyle.tealEmerald => PackLoxMotionTheme.ambientTealEmerald,
    GradientStyle.blueIndigo => PackLoxMotionTheme.ambientBlueIndigo,
  };
}
