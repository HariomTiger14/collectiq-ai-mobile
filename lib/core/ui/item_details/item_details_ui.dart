import 'dart:ui';

import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_wordmark.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';

class ItemHeroImage extends StatelessWidget {
  const ItemHeroImage({
    super.key,
    required this.imageUrl,
    this.scrollController,
    this.title,
    this.category,
  });

  final String imageUrl;
  final ScrollController? scrollController;
  final String? title;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final listenable = scrollController ?? ScrollController();

    return AnimatedBuilder(
      animation: listenable,
      builder: (context, child) {
        final offset = scrollController?.hasClients ?? false
            ? scrollController!.offset
            : 0.0;

        return MotionElasticHero(
          baseHeight: 310,
          scrollOffset: offset,
          child: MotionParallax(
            scrollOffset: offset,
            depth: PackLoxMotionTheme.heroParallaxDepth * 1.6,
            child: child!,
          ),
        );
      },
      child: _ItemHeroSurface(
        imageUrl: imageUrl,
        title: title,
        category: category,
      ),
    );
  }
}

class _ItemHeroSurface extends StatelessWidget {
  const _ItemHeroSurface({required this.imageUrl, this.title, this.category});

  final String imageUrl;
  final String? title;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 310,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.18 : 0.12),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _heroImage(context),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: isDark ? 0.56 : 0.42),
                  Colors.black.withValues(alpha: isDark ? 0.78 : 0.64),
                ],
                stops: const [0.38, 0.72, 1],
              ),
            ),
          ),
          const _HeroShimmerOverlay(),
          if ((title ?? '').trim().isNotEmpty ||
              (category ?? '').trim().isNotEmpty)
            Positioned(
              left: 22,
              right: 22,
              bottom: 22,
              child: _HeroTextOverlay(title: title, category: category),
            ),
        ],
      ),
    );
  }

  Widget _heroImage(BuildContext context) {
    final normalizedPath = imageUrl.trim();
    if (normalizedPath.isEmpty || normalizedPath.startsWith('sample://')) {
      return const _ItemHeroPlaceholder();
    }

    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return Image.network(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _ItemHeroPlaceholder(),
      );
    }

    if (normalizedPath.startsWith('assets/')) {
      return Image.asset(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _ItemHeroPlaceholder(),
      );
    }

    return buildLocalPortfolioImage(
      imagePath: normalizedPath,
      fit: BoxFit.cover,
      placeholderBuilder: () => const _ItemHeroPlaceholder(),
    );
  }
}

class _HeroTextOverlay extends StatelessWidget {
  const _HeroTextOverlay({this.title, this.category});

  final String? title;
  final String? category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.24),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              PackLoxWordmark(
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimary.withValues(alpha: 0.78),
                  fontWeight: FontWeight.w800,
                ),
                packColor: colorScheme.onPrimary.withValues(alpha: 0.78),
                loxColor: colorScheme.primary,
              ),
              if ((title ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  title!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
              ],
              if ((category ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  category!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.82),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroShimmerOverlay extends StatefulWidget {
  const _HeroShimmerOverlay();

  @override
  State<_HeroShimmerOverlay> createState() => _HeroShimmerOverlayState();
}

class _HeroShimmerOverlayState extends State<_HeroShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.waveDuration,
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final shift = _controller.value;

          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-1.5 + shift * 2.5, -1),
                end: Alignment(-0.6 + shift * 2.5, 1),
                colors: [
                  Colors.white.withValues(alpha: 0),
                  Colors.white.withValues(alpha: 0.06),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemHeroPlaceholder extends StatelessWidget {
  const _ItemHeroPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.style_outlined, color: colorScheme.primary, size: 58),
      ),
    );
  }
}

class ItemCategoryHeader extends StatelessWidget {
  const ItemCategoryHeader({
    super.key,
    required this.title,
    this.subtitle = 'PackLox Item',
    this.gradientStyle = GradientStyle.tealEmerald,
  });

  final String title;
  final String subtitle;
  final GradientStyle gradientStyle;

  @override
  Widget build(BuildContext context) {
    return GradientHeader(
      title: title.trim().isEmpty ? 'Collectible' : title,
      subtitle: subtitle,
      gradientStyle: gradientStyle,
    );
  }
}

class ItemGlassMetadataCard extends StatelessWidget {
  const ItemGlassMetadataCard({
    super.key,
    required this.item,
    this.wishlistStatusLabel,
  });

  final CollectibleItem item;
  final String? wishlistStatusLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rows = [
      _MetadataChipData('Value', _formatMoney(item.estimatedValue, 'AUD')),
      _MetadataChipData(
        'Confidence',
        '${(item.confidence * 100).toStringAsFixed(0)}% confidence',
      ),
      _MetadataChipData('Condition', item.condition),
      _MetadataChipData('Acquired', 'Saved ${_formatDate(item.createdAt)}'),
      _MetadataChipData(
        'Trend',
        'Market trend: ${item.marketSummary?.trendLabel ?? 'Stable'}',
      ),
      _MetadataChipData('Tags', _tagsFor(item).join(', ')),
      _MetadataChipData('Wishlist', wishlistStatusLabel ?? 'Owned'),
    ].where((row) => row.value.trim().isNotEmpty).toList();

    return MotionReveal(
      offset: 18,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.34)
                  : colorScheme.surface.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.24),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(
                    alpha: isDark ? 0.12 : 0.08,
                  ),
                  blurRadius: 28,
                  offset: const Offset(0, 16),
                ),
              ],
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [for (final row in rows) _MetadataChip(data: row)],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetadataChipData {
  const _MetadataChipData(this.label, this.value);

  final String label;
  final String value;
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.data});

  final _MetadataChipData data;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      constraints: const BoxConstraints(minWidth: 122),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class ItemAttributeRow extends StatefulWidget {
  const ItemAttributeRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailingIcon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData? trailingIcon;
  final VoidCallback? onTap;

  @override
  State<ItemAttributeRow> createState() => _ItemAttributeRowState();
}

class _ItemAttributeRowState extends State<ItemAttributeRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final interactive = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: MotionTapScale(
        onTap: widget.onTap,
        enabled: interactive,
        scale: 0.98,
        child: AnimatedContainer(
          duration: PackLoxMotionTheme.medium,
          curve: PackLoxMotionTheme.hoverCurve,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hovered
                ? colorScheme.primary.withValues(
                    alpha: PackLoxMotionTheme.hoverOpacity,
                  )
                : colorScheme.surface.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.subtitle.trim().isEmpty
                          ? 'Not specified'
                          : widget.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailingIcon != null) ...[
                const SizedBox(width: 12),
                Icon(
                  widget.trailingIcon,
                  color: colorScheme.onSurface.withValues(alpha: 0.72),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ItemActionBar extends StatelessWidget {
  const ItemActionBar({
    super.key,
    required this.onEdit,
    required this.onShare,
    this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionIconTile(
            icon: Icons.edit_outlined,
            label: 'Edit',
            onTap: onEdit,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionIconTile(
            icon: Icons.ios_share_outlined,
            label: 'Share',
            onTap: onShare,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionIconTile(
            icon: Icons.delete_outline,
            label: 'Delete',
            onTap: onDelete,
            isDestructive: true,
          ),
        ),
      ],
    );
  }
}

class _ActionIconTile extends StatefulWidget {
  const _ActionIconTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  State<_ActionIconTile> createState() => _ActionIconTileState();
}

class _ActionIconTileState extends State<_ActionIconTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.pulseDuration,
      lowerBound: 0,
      upperBound: 1,
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
    final baseColor = widget.isDestructive
        ? colorScheme.error
        : colorScheme.primary;
    final enabled = widget.onTap != null;

    return Tooltip(
      message: widget.label,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Opacity(
          opacity: enabled ? 1 : 0.52,
          child: MotionTapScale(
            onTap: widget.onTap,
            enabled: enabled,
            scale: 0.94,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final pulse = _controller.value;

                return AnimatedContainer(
                  duration: PackLoxMotionTheme.medium,
                  curve: PackLoxMotionTheme.hoverCurve,
                  height: 78,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(
                      alpha: _hovered ? 0.14 : 0.08 + pulse * 0.02,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: baseColor.withValues(
                        alpha: _hovered ? 0.28 : 0.14,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: baseColor.withValues(
                          alpha: _hovered ? 0.12 : 0.06 + pulse * 0.04,
                        ),
                        blurRadius: _hovered ? 26 : 20,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [baseColor, colorScheme.tertiary],
                    ).createShader(bounds),
                    child: Icon(widget.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
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

List<String> _tagsFor(CollectibleItem item) {
  return [item.category, item.brand, item.series, item.rarity, item.year]
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .take(3)
      .toList();
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatMoney(double value, String currency) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '$currency $withCommas';
}
