import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_wordmark.dart';
import 'package:flutter/material.dart';

class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({
    super.key,
    this.greeting = 'Welcome back',
    this.itemCount = 0,
    this.estimatedValue = r'$0',
    this.lastScanStatus = 'Ready to scan',
  });

  final String greeting;
  final int itemCount;
  final String estimatedValue;
  final String lastScanStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textScale = MediaQuery.textScalerOf(context).scale(1);

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.premium,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(
                  alpha: isDark ? 0.22 : 0.30,
                ),
                blurRadius: AppSpacing.xxl,
                offset: const Offset(0, AppSpacing.lg),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: isDark ? 0.05 : 0.18),
                        Colors.transparent,
                        colorScheme.secondary.withValues(alpha: 0.16),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -AppSpacing.xxl,
                top: -AppSpacing.xl,
                child: Container(
                  width: 148,
                  height: 148,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                      width: AppSpacing.xl,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompactWidth = constraints.maxWidth < 340;
                    final isCompactHeight = constraints.maxHeight < 202;
                    final isCompactText = textScale > 1.1;
                    final useCompactLayout =
                        isCompactWidth || isCompactHeight || isCompactText;
                    final horizontalPadding = useCompactLayout
                        ? AppSpacing.lg
                        : AppSpacing.xl;
                    final topPadding = useCompactLayout
                        ? AppSpacing.md
                        : AppSpacing.lg;
                    final bottomPadding = useCompactLayout
                        ? AppSpacing.sm
                        : AppSpacing.md;
                    final titleStyle =
                        (useCompactLayout
                                ? Theme.of(context).textTheme.headlineSmall
                                : Theme.of(context).textTheme.headlineMedium)
                            ?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            );
                    final bodyStyle =
                        (useCompactLayout
                                ? Theme.of(context).textTheme.bodyMedium
                                : Theme.of(context).textTheme.bodyLarge)
                            ?.copyWith(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.84,
                              ),
                              fontWeight: FontWeight.w500,
                            );

                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        topPadding,
                        horizontalPadding,
                        bottomPadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  greeting,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: colorScheme.onPrimary.withValues(
                                      alpha: 0.76,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.pill,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.20),
                                  ),
                                ),
                                child: PackLoxWordmark(
                                  style: AppTextStyles.caption.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  packColor: colorScheme.onPrimary,
                                  loxColor: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Your Collection Hub',
                            maxLines: useCompactLayout ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                          SizedBox(
                            height: useCompactLayout
                                ? AppSpacing.xs
                                : AppSpacing.sm,
                          ),
                          Text(
                            'Scan, value, and track your collectibles.',
                            maxLines: useCompactLayout ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: bodyStyle,
                          ),
                          SizedBox(
                            height: useCompactLayout
                                ? AppSpacing.md
                                : AppSpacing.md,
                          ),
                          if (useCompactLayout)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _HeroMetric(
                                    label: 'Items',
                                    value:
                                        '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                    compact: true,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _HeroMetric(
                                    label: 'Value',
                                    value: estimatedValue,
                                    compact: true,
                                    emphasized: true,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: _HeroMetric(
                                    label: 'Last scan',
                                    value: lastScanStatus,
                                    compact: true,
                                  ),
                                ),
                              ],
                            )
                          else
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                _HeroMetric(
                                  label: 'Items',
                                  value:
                                      '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                                  width: 108,
                                ),
                                _HeroMetric(
                                  label: 'Value',
                                  value: estimatedValue,
                                  width: 136,
                                  emphasized: true,
                                ),
                                _HeroMetric(
                                  label: 'Last scan',
                                  value: lastScanStatus,
                                  width: 128,
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    this.compact = false,
    this.emphasized = false,
    this.width,
  });

  final String label;
  final String value;
  final bool compact;
  final bool emphasized;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      constraints: BoxConstraints(minHeight: compact ? 48 : 56),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: emphasized ? 0.34 : 0.18),
        ),
        boxShadow: emphasized
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.72),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: compact ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: (compact ? AppTextStyles.caption : AppTextStyles.body)
                .copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: emphasized ? FontWeight.w900 : FontWeight.w800,
                ),
          ),
        ],
      ),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 148,
            height: 132,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
                  : colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.58),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(
                    alpha: _hovered ? 0.14 : 0.07,
                  ),
                  blurRadius: _hovered ? 32 : 24,
                  offset: const Offset(0, 16),
                ),
              ],
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.05 : 0.30),
                  colorScheme.primary.withValues(alpha: 0.04),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primaryContainer.withValues(alpha: 0.52),
                        colorScheme.secondaryContainer.withValues(alpha: 0.30),
                      ],
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: colorScheme.primary,
                    size: AppIconSizes.lg,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
              : colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.58),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.16 : 0.10),
              blurRadius: 38,
              offset: const Offset(0, 22),
            ),
          ],
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: isDark ? 0.05 : 0.28),
              colorScheme.primary.withValues(alpha: 0.03),
            ],
          ),
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
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
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
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF07111F),
                      colorScheme.primary.withValues(alpha: 0.92),
                      colorScheme.tertiary.withValues(alpha: 0.84),
                    ],
                    begin: Alignment(-1 + pulse * 0.4, -1),
                    end: const Alignment(1, 1),
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.28),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    color: colorScheme.onPrimary.withValues(alpha: 0.14),
                    border: Border.all(
                      color: colorScheme.onPrimary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: colorScheme.onPrimary,
                    size: AppIconSizes.lg,
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
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
