import 'dart:ui';

import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

class AboutHeroHeader extends StatelessWidget {
  const AboutHeroHeader({
    required this.scrollController,
    this.gradientStyle = GradientStyle.blueIndigo,
    this.onBack,
    super.key,
  });

  final ScrollController scrollController;
  final GradientStyle gradientStyle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _aboutGradientColors(context, gradientStyle);

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        final parallax = scrollOffset.clamp(0, 120).toDouble();

        return MotionElasticHero(
          baseHeight: 172,
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
                  height: 172,
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
                            Icons.inventory_2_rounded,
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
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'About PackLox',
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
                                  'Smart Collections. Beautifully Organized.',
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
                        if (onBack != null)
                          Align(
                            alignment: Alignment.topLeft,
                            child: _HeaderBackButton(onTap: onBack!),
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

class _HeaderBackButton extends StatefulWidget {
  const _HeaderBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_HeaderBackButton> createState() => _HeaderBackButtonState();
}

class _HeaderBackButtonState extends State<_HeaderBackButton> {
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

class AboutAppIconCard extends StatelessWidget {
  const AboutAppIconCard({
    required this.version,
    required this.buildNumber,
    this.appIcon,
    super.key,
  });

  final Widget? appIcon;
  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Reveal(
      offset: 18,
      child: _FrostedSurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                MotionPulse(
                  minScale: 0.96,
                  maxScale: 1.06,
                  minOpacity: 0.72,
                  child: Container(
                    width: 116,
                    height: 116,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withValues(alpha: 0.14),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.18),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
                appIcon ?? const _PackLoxAppIcon(size: 92),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'PackLox',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Version $version ($buildNumber)',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AboutInfoTile extends StatelessWidget {
  const AboutInfoTile({
    required this.title,
    required this.subtitle,
    this.icon = Icons.info_outline_rounded,
    this.trailingIcon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return _AboutTileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailingIcon: trailingIcon,
    );
  }
}

class AboutLinkTile extends StatelessWidget {
  const AboutLinkTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.icon = Icons.link_rounded,
    super.key,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _AboutTileShell(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailingIcon: Icons.open_in_new_rounded,
      isLink: true,
      onTap: onTap,
    );
  }
}

class AboutBrandCard extends StatefulWidget {
  const AboutBrandCard({super.key});

  @override
  State<AboutBrandCard> createState() => _AboutBrandCardState();
}

class _AboutBrandCardState extends State<AboutBrandCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _Reveal(
      offset: 14,
      child: _FrostedSurface(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const _PackLoxAppIcon(size: 54),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Built for collectors who care about the details.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _BrandLine(
              icon: Icons.lock_outline_rounded,
              label: 'Private by default',
            ),
            const SizedBox(height: 12),
            const _BrandLine(
              icon: Icons.inventory_2_outlined,
              label: 'Built for careful collectors',
            ),
            const SizedBox(height: 12),
            const _BrandLine(
              icon: Icons.query_stats_rounded,
              label: 'Ready for organized portfolios',
            ),
            const SizedBox(height: 22),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: _controller.value.clamp(0.0, 1.0),
                    child: child,
                  );
                },
                child: Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.tertiary,
                        colorScheme.secondary,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutTileShell extends StatefulWidget {
  const _AboutTileShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingIcon,
    this.isLink = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final IconData? trailingIcon;
  final bool isLink;
  final VoidCallback? onTap;

  @override
  State<_AboutTileShell> createState() => _AboutTileShellState();
}

class _AboutTileShellState extends State<_AboutTileShell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canTap = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: MotionTapScale(
        onTap: widget.onTap,
        enabled: canTap,
        scale: 0.985,
        child: AnimatedContainer(
          duration: PackLoxMotionTheme.medium,
          curve: PackLoxMotionTheme.hoverCurve,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.primary.withValues(
                    alpha: PackLoxMotionTheme.hoverOpacity,
                  )
                : isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.42),
                      colorScheme.secondaryContainer.withValues(alpha: 0.24),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isLink
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: widget.isLink
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 12),
                Icon(
                  widget.trailingIcon,
                  color: widget.isLink
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandLine extends StatelessWidget {
  const _BrandLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: colorScheme.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PackLoxAppIcon extends StatelessWidget {
  const _PackLoxAppIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.tertiary,
            colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.22),
            blurRadius: size * 0.26,
            offset: Offset(0, size * 0.12),
          ),
        ],
      ),
      child: Icon(
        Icons.inventory_2_rounded,
        color: colorScheme.onPrimary,
        size: size * 0.52,
      ),
    );
  }
}

class _FrostedSurface extends StatelessWidget {
  const _FrostedSurface({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                : colorScheme.surface.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.24),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.14 : 0.08,
                ),
                blurRadius: isDark ? 18 : 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.child, this.offset = 14});

  final Widget child;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return MotionReveal(offset: offset, child: child);
  }
}

List<Color> _aboutGradientColors(BuildContext context, GradientStyle style) {
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
    GradientStyle.blueIndigo ||
    GradientStyle.tealEmerald => PackLoxMotionTheme.ambientBlueIndigo,
  };
}
