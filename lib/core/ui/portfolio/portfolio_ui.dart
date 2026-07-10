import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';

class PortfolioHeroHeader extends StatelessWidget {
  const PortfolioHeroHeader({
    super.key,
    this.scrollController,
    this.gradientStyle = GradientStyle.blueIndigo,
  });

  final ScrollController? scrollController;
  final GradientStyle gradientStyle;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final scrollOffset = scrollController?.hasClients ?? false
        ? scrollController!.offset
        : 0.0;
    final hero = MotionElasticHero(
      key: const ValueKey('portfolio-hero-motion'),
      baseHeight: 198 + topInset,
      scrollOffset: scrollOffset,
      child: MotionParallax(
        scrollOffset: scrollOffset,
        child: MotionAmbientGradient(
          gradientBuilder: _ambientGradientFor(gradientStyle),
          child: _PortfolioHeroSurface(gradientStyle: gradientStyle),
        ),
      ),
    );

    final controller = scrollController;
    if (controller == null) {
      return hero;
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final offset = controller.hasClients ? controller.offset : 0.0;
        return MotionElasticHero(
          key: const ValueKey('portfolio-hero-motion'),
          baseHeight: 198 + topInset,
          scrollOffset: offset,
          child: MotionParallax(
            scrollOffset: offset,
            child: MotionAmbientGradient(
              gradientBuilder: _ambientGradientFor(gradientStyle),
              child: _PortfolioHeroSurface(gradientStyle: gradientStyle),
            ),
          ),
        );
      },
    );
  }
}

class _PortfolioHeroSurface extends StatelessWidget {
  const _PortfolioHeroSurface({required this.gradientStyle});

  final GradientStyle gradientStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topInset = MediaQuery.paddingOf(context).top;

    return HeroSurfaceContainerHighest(
      key: const ValueKey('portfolio-hero-surface'),
      height: 198 + topInset,
      gradientStyle: gradientStyle,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        topInset + AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      decorativeChildren: [
        Positioned(
          right: -24,
          top: -32,
          child: HeroDecorativeCircle(
            key: const ValueKey('portfolio-hero-decorative-circle'),
            diameter: 138,
            strokeWidth: 22,
            opacity: isDark ? 0.14 : 0.18,
          ),
        ),
      ],
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Collections',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.headlineMedium?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track, organize and grow your collection',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your collectible library',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.68),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PortfolioActionTile extends StatefulWidget {
  const PortfolioActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.isPrimary = false,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isPrimary;
  final VoidCallback? onTap;

  @override
  State<PortfolioActionTile> createState() => _PortfolioActionTileState();
}

class _PortfolioActionTileState extends State<PortfolioActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = widget.isPrimary
        ? colorScheme.onPrimary
        : colorScheme.primary;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: MotionTapScale(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: PackLoxMotionTheme.medium,
            curve: PackLoxMotionTheme.hoverCurve,
            key: ValueKey(
              'portfolio-action-${widget.title.toLowerCase().replaceAll(' ', '-')}',
            ),
            height: 54,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: widget.isPrimary
                  ? colorScheme.primary
                  : isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
                  : colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: widget.isPrimary
                    ? colorScheme.primary.withValues(alpha: 0.82)
                    : Colors.white.withValues(alpha: isDark ? 0.14 : 0.58),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(
                    alpha: widget.isPrimary
                        ? (_hovered ? 0.28 : 0.18)
                        : _hovered
                        ? 0.14
                        : (isDark ? 0.06 : 0.08),
                  ),
                  blurRadius: _hovered ? 20 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  color: foregroundColor,
                  size: AppIconSizes.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: widget.isPrimary ? colorScheme.onPrimary : null,
                      fontWeight: FontWeight.w900,
                    ),
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

class CategoryHeader extends StatefulWidget {
  const CategoryHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.gradientStyle = GradientStyle.tealEmerald,
  });

  final String title;
  final String subtitle;
  final GradientStyle gradientStyle;

  @override
  State<CategoryHeader> createState() => _CategoryHeaderState();
}

class _CategoryHeaderState extends State<CategoryHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.pulseDuration,
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
    final colors = PackLoxGradients.build(widget.gradientStyle, context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = _controller.value;

        return Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 76),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(colors.first, colors.last, pulse * 0.18)!,
                Color.lerp(colors.last, colors.first, pulse * 0.12)!,
              ],
              begin: Alignment(-1 + pulse * 0.22, -1),
              end: Alignment(1 - pulse * 0.18, 1),
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: colors.last.withValues(alpha: 0.18 + pulse * 0.04),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimary.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class PortfolioSectionCard extends StatelessWidget {
  const PortfolioSectionCard({
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
      duration: PackLoxMotionTheme.medium,
      curve: PackLoxMotionTheme.revealCurve,
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
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
              : colorScheme.surface.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.58),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: isDark ? 0.16 : 0.10),
              blurRadius: 24,
              offset: const Offset(0, 12),
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
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class PortfolioGlassItemCard extends StatefulWidget {
  const PortfolioGlassItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onEdit,
    this.onShare,
    this.onDelete,
    this.wishlistStatusLabel,
    this.index = 0,
  });

  final CollectibleItem item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;
  final String? wishlistStatusLabel;
  final int index;

  @override
  State<PortfolioGlassItemCard> createState() => _PortfolioGlassItemCardState();
}

class _PortfolioGlassItemCardState extends State<PortfolioGlassItemCard> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MotionReveal(
      offset: 18,
      delay: Duration(
        milliseconds:
            PackLoxMotionTheme.revealStagger.inMilliseconds *
            widget.index.clamp(0, 6),
      ),
      child: MotionTapScale(
        onTap: widget.onTap,
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
                color: colorScheme.shadow.withValues(
                  alpha: isDark ? 0.16 : 0.10,
                ),
                blurRadius: 40,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 560;
              final content = _PortfolioItemContent(
                item: widget.item,
                isCompact: isCompact,
                wishlistStatusLabel: widget.wishlistStatusLabel,
                onEdit: widget.onEdit,
                onShare: widget.onShare,
                onDelete: widget.onDelete,
              );

              if (isCompact) {
                return content;
              }

              return content;
            },
          ),
        ),
      ),
    );
  }
}

class _PortfolioItemContent extends StatelessWidget {
  const _PortfolioItemContent({
    required this.item,
    required this.isCompact,
    this.wishlistStatusLabel,
    this.onEdit,
    this.onShare,
    this.onDelete,
  });

  final CollectibleItem item;
  final bool isCompact;
  final String? wishlistStatusLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final details = Expanded(
      child: _PortfolioItemDetails(
        item: item,
        wishlistStatusLabel: wishlistStatusLabel,
      ),
    );
    final image = _PortfolioItemImage(imagePath: item.imagePath);

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [image, const SizedBox(width: 14), details],
          ),
          const SizedBox(height: 16),
          _ItemActions(onEdit: onEdit, onShare: onShare, onDelete: onDelete),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        image,
        const SizedBox(width: 16),
        details,
        const SizedBox(width: 12),
        _ItemActions(onEdit: onEdit, onShare: onShare, onDelete: onDelete),
      ],
    );
  }
}

class _PortfolioItemImage extends StatelessWidget {
  const _PortfolioItemImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedPath = imagePath.trim();

    Widget image;
    if (normalizedPath.isEmpty || normalizedPath.startsWith('sample://')) {
      image = const _PortfolioImagePlaceholder();
    } else if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      image = Image.network(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _PortfolioImagePlaceholder(),
      );
    } else if (normalizedPath.startsWith('assets/')) {
      image = Image.asset(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _PortfolioImagePlaceholder(),
      );
    } else {
      image = buildLocalPortfolioImage(
        imagePath: normalizedPath,
        fit: BoxFit.cover,
        placeholderBuilder: () => const _PortfolioImagePlaceholder(),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 96,
        height: 112,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: image,
      ),
    );
  }
}

class _PortfolioImagePlaceholder extends StatelessWidget {
  const _PortfolioImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.primary,
        size: 30,
      ),
    );
  }
}

class _PortfolioItemDetails extends StatelessWidget {
  const _PortfolioItemDetails({required this.item, this.wishlistStatusLabel});

  final CollectibleItem item;
  final String? wishlistStatusLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          item.condition.isEmpty ? item.category : item.condition,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MetadataPill(label: _formatAud(item.estimatedValue)),
            _MetadataPill(label: 'Category ${item.category}'),
            _MetadataPill(label: 'Saved ${_formatDate(item.createdAt)}'),
            _MetadataPill(
              label: '${(item.confidence * 100).toStringAsFixed(0)}%',
            ),
            _MetadataPill(label: item.marketSummary?.trendLabel ?? 'Stable'),
            if (wishlistStatusLabel != null &&
                wishlistStatusLabel!.trim().isNotEmpty)
              _MetadataPill(label: wishlistStatusLabel!),
          ],
        ),
      ],
    );
  }
}

class _MetadataPill extends StatelessWidget {
  const _MetadataPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ItemActions extends StatelessWidget {
  const _ItemActions({this.onEdit, this.onShare, this.onDelete});

  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _AnimatedItemIconTile(
          icon: Icons.edit_outlined,
          tooltip: 'Edit item',
          onTap: onEdit,
        ),
        _AnimatedItemIconTile(
          icon: Icons.ios_share_outlined,
          tooltip: 'Share item',
          onTap: onShare,
        ),
        _AnimatedItemIconTile(
          icon: Icons.delete_outline,
          tooltip: 'Remove item',
          onTap: onDelete,
        ),
      ],
    );
  }
}

class _AnimatedItemIconTile extends StatefulWidget {
  const _AnimatedItemIconTile({
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  State<_AnimatedItemIconTile> createState() => _AnimatedItemIconTileState();
}

class _AnimatedItemIconTileState extends State<_AnimatedItemIconTile> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: widget.tooltip,
      child: MotionTapScale(
        onTap: widget.onTap,
        scale: 0.92,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.32),
            ),
          ),
          child: Icon(widget.icon, size: 18, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}

Gradient Function(double) _ambientGradientFor(GradientStyle style) {
  return switch (style) {
    GradientStyle.purpleDeepBlue => PackLoxMotionTheme.ambientPurpleDeepBlue,
    GradientStyle.blueIndigo ||
    GradientStyle.tealEmerald => PackLoxMotionTheme.ambientBlueIndigo,
  };
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatAud(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return 'AUD $withCommas';
}
