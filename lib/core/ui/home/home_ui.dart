import 'dart:ui';

import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:flutter/material.dart';

class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({
    super.key,
    required this.scrollController,
    this.gradientStyle = GradientStyle.blueIndigo,
  });

  final ScrollController scrollController;
  final GradientStyle gradientStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _colorsFor(context, gradientStyle);

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        final parallax = scrollOffset.clamp(0, 96).toDouble();
        final overscroll = scrollOffset < 0 ? (-scrollOffset / 700) : 0.0;

        return Transform.translate(
          offset: Offset(0, -parallax * 0.10),
          child: Transform.scale(
            scale: 1 + overscroll.clamp(0, 0.05),
            alignment: Alignment.topCenter,
            child: Container(
              height: 184,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 26),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withValues(alpha: isDark ? 0.22 : 0.28),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -18 + parallax * 0.10,
                    top: -24,
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.onPrimary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Transform.translate(
                      offset: Offset(0, parallax * 0.04),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PackLox',
                            style: textTheme.headlineMedium?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your smart collection hub',
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeGlassTile extends StatefulWidget {
  const HomeGlassTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  State<HomeGlassTile> createState() => _HomeGlassTileState();
}

class _HomeGlassTileState extends State<HomeGlassTile> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) {
                setState(() => _pressed = false);
                widget.onTap?.call();
              },
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.96 : 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 148,
                height: 126,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.35,
                        )
                      : colorScheme.surface.withValues(alpha: 0.56),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: colorScheme.primary.withValues(
                      alpha: _hovered ? 0.22 : 0.12,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(
                        alpha: _hovered ? 0.08 : 0.04,
                      ),
                      blurRadius: 22,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primaryContainer.withValues(
                              alpha: 0.52,
                            ),
                            colorScheme.secondaryContainer.withValues(
                              alpha: 0.30,
                            ),
                          ],
                        ),
                      ),
                      child: Icon(widget.icon, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
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
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedIconTile extends StatefulWidget {
  const AnimatedIconTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  State<AnimatedIconTile> createState() => _AnimatedIconTileState();
}

class _AnimatedIconTileState extends State<AnimatedIconTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTapUp: widget.onTap == null
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: _pressed ? 0.9 : 1,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _pressed ? 0.97 : 1,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final pulse = _controller.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.92),
                      colorScheme.tertiary.withValues(alpha: 0.78),
                    ],
                    begin: Alignment(-1 + pulse * 0.4, -1),
                    end: const Alignment(1, 1),
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.22),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.onPrimary.withValues(alpha: 0.14),
                  ),
                  child: Icon(
                    widget.icon,
                    color: colorScheme.onPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: colorScheme.onPrimary.withValues(
                                  alpha: 0.78,
                                ),
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Color> _colorsFor(BuildContext context, GradientStyle style) {
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
