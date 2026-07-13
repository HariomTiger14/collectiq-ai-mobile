import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';

class PortfolioThumbnail extends StatelessWidget {
  const PortfolioThumbnail({
    required this.imagePath,
    this.size = 110,
    super.key,
  });

  final String imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: _PortfolioItemImage(
        key: ValueKey('portfolio-thumbnail-$imagePath-$size'),
        imagePath: imagePath,
        size: size,
      ),
    );
  }
}

/// Displays aggregate portfolio metrics.
class PortfolioSummaryCard extends StatelessWidget {
  /// Creates a portfolio summary card.
  const PortfolioSummaryCard({
    required this.totalValue,
    required this.itemCount,
    required this.averageConfidence,
    required this.categoryCount,
    required this.topAssetTitle,
    super.key,
  });

  /// Total estimated portfolio value.
  final double totalValue;

  /// Number of saved items.
  final int itemCount;

  final double averageConfidence;
  final int categoryCount;
  final String topAssetTitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('portfolio-compact-snapshot'),
      children: [
        _CompactValueSummary(value: _formatAud(totalValue)),
        const SizedBox(height: AppSpacing.sm),
        _CompactMetricGrid(
          metrics: [
            _CompactMetric(
              label: 'Items',
              value: itemCount.toString(),
              icon: Icons.inventory_2_outlined,
            ),
            _CompactMetric(
              label: 'Categories',
              value: categoryCount.toString(),
              icon: Icons.category_outlined,
            ),
            _CompactMetric(
              label: 'Avg confidence',
              value: '${(averageConfidence * 100).toStringAsFixed(0)}%',
              icon: Icons.verified_outlined,
            ),
            _CompactMetric(
              label: 'Top asset',
              value: topAssetTitle,
              icon: Icons.workspace_premium_outlined,
              maxValueLines: 2,
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactValueSummary extends StatelessWidget {
  const _CompactValueSummary({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: AppGradients.premium,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppElevation.level1,
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total collection value',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white.withValues(alpha: 0.78),
          ),
        ],
      ),
    );
  }
}

class _CompactMetric {
  const _CompactMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.maxValueLines = 1,
  });

  final String label;
  final String value;
  final IconData icon;
  final int maxValueLines;
}

class _CompactMetricGrid extends StatelessWidget {
  const _CompactMetricGrid({required this.metrics});

  final List<_CompactMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 620 ? 4 : 2;
        return GridView.builder(
          key: const ValueKey('portfolio-compact-metrics-grid'),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: columns == 4 ? 2.25 : 1.75,
          ),
          itemBuilder: (context, index) =>
              _CompactMetricTile(metric: metrics[index]),
        );
      },
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({required this.metric});

  final _CompactMetric metric;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(metric.icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.value,
                  maxLines: metric.maxValueLines,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state shown before items are saved to the portfolio.
class PortfolioEmptyState extends StatelessWidget {
  /// Creates the portfolio empty state.
  const PortfolioEmptyState({this.onScanPressed, super.key});

  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const ValueKey('portfolio-empty-state-surface'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: _packLoxRaisedSurfaceColor(colorScheme),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _packLoxSurfaceBorderColor(colorScheme)),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 44,
            color: colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No collectibles saved yet',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Start with Camera or Gallery, analyze the collectible, then save it here to track value, alerts, wishlist status, and goals.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onScanPressed,
              icon: const Icon(Icons.document_scanner_outlined),
              label: const Text('Scan Collectible'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state shown when search filters hide all saved items.
class PortfolioNoSearchResultsState extends StatelessWidget {
  /// Creates a no search results state.
  const PortfolioNoSearchResultsState({this.onResetFilters, super.key});

  final VoidCallback? onResetFilters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const ValueKey('portfolio-no-results-surface'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: _packLoxRaisedSurfaceColor(colorScheme),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: _packLoxSurfaceBorderColor(colorScheme)),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 44, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No collectibles found',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try adjusting your search or filters.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (onResetFilters != null) ...[
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Clear filters'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

Color _packLoxRaisedSurfaceColor(ColorScheme colorScheme) {
  return PackLoxTokens.surfaceRaised.withValues(
    alpha: colorScheme.brightness == Brightness.dark ? 0.94 : 0.90,
  );
}

Color _packLoxSurfaceBorderColor(ColorScheme colorScheme) {
  return PackLoxTokens.border.withValues(
    alpha: colorScheme.brightness == Brightness.dark ? 0.82 : 0.68,
  );
}

/// Error state shown when local portfolio loading fails.
class PortfolioErrorState extends StatelessWidget {
  /// Creates a portfolio error state.
  const PortfolioErrorState({required this.message, super.key});

  /// Error message to display.
  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 44, color: colorScheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Full-width list of saved portfolio items.
class PortfolioItemsGrid extends StatelessWidget {
  /// Creates a portfolio items list.
  const PortfolioItemsGrid({
    required this.items,
    required this.onRemoveItem,
    required this.onOpenItem,
    this.wishlistStatusByItemId = const {},
    super.key,
  });

  /// Saved portfolio items.
  final List<CollectibleItem> items;

  /// Called when a user removes an item.
  final ValueChanged<String> onRemoveItem;

  /// Called when a user opens an item.
  final ValueChanged<CollectibleItem> onOpenItem;

  final Map<String, WishlistStatus> wishlistStatusByItemId;

  @override
  Widget build(BuildContext context) {
    return MotionStagger(
      children: [
        for (var index = 0; index < items.length; index++)
          Padding(
            key: ValueKey('portfolio-item-${items[index].id}'),
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : AppSpacing.lg,
            ),
            child: SizedBox(
              width: double.infinity,
              child: _PortfolioItemCard(
                item: items[index],
                wishlistStatus: wishlistStatusByItemId[items[index].id],
                onTap: () => onOpenItem(items[index]),
                onRemove: () => onRemoveItem(items[index].id),
              ),
            ),
          ),
      ],
    );
  }
}

class PortfolioGridTile extends StatelessWidget {
  const PortfolioGridTile({
    required this.item,
    required this.onTap,
    this.onViewDetails,
    this.onEdit,
    this.onDelete,
    this.wishlistStatusLabel,
    super.key,
  });

  final CollectibleItem item;
  final VoidCallback onTap;
  final VoidCallback? onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final String? wishlistStatusLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 190;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: Ink(
              key: ValueKey('portfolio-grid-premium-surface-${item.id}'),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.72),
                ),
                boxShadow: AppElevation.level2,
              ),
              child: Padding(
                padding: EdgeInsets.all(
                  compact ? AppSpacing.md : AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PortfolioGridThumbnail(item: item),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      key: ValueKey('portfolio-grid-badges-${item.id}'),
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        PremiumBadge.category(
                          label: item.category,
                          icon: _categoryIcon(item.category),
                        ),
                        PremiumBadge.confidence(
                          label:
                              '${(item.confidence * 100).toStringAsFixed(0)}%',
                        ),
                        PremiumBadge.trend(
                          label: _trendLabel(item),
                          icon: _trendIcon(item),
                        ),
                        if (wishlistStatusLabel != null &&
                            wishlistStatusLabel!.trim().isNotEmpty)
                          PremiumBadge.wishlist(label: wishlistStatusLabel!),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Spacer(),
                    Row(
                      key: ValueKey('portfolio-grid-value-row-${item.id}'),
                      children: [
                        Expanded(
                          child: Text(
                            'Est. value',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _formatAud(item.estimatedValue),
                              maxLines: 1,
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.62,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        _PortfolioOverflowMenu(
                          onViewDetails: onViewDetails ?? onTap,
                          onEdit: onEdit,
                          onDelete: onDelete,
                        ),
                      ],
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

class _PortfolioGridThumbnail extends StatelessWidget {
  const _PortfolioGridThumbnail({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final normalizedPath = _displayImagePath(item);
    final hasImage =
        normalizedPath.isNotEmpty &&
        !normalizedPath.startsWith('sample://') &&
        !normalizedPath.startsWith('selected-image');

    return MotionReveal(
      key: ValueKey('portfolio-grid-thumbnail-reveal-${item.id}'),
      offset: 8,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AspectRatio(
        key: ValueKey('portfolio-grid-thumbnail-aspect-${item.id}'),
        aspectRatio: 1,
        child: DecoratedBox(
          key: ValueKey('portfolio-grid-thumbnail-frame-${item.id}'),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                hasImage
                    ? _PortfolioItemImage(
                        key: ValueKey('portfolio-grid-image-${item.id}'),
                        imagePath: normalizedPath,
                        size: double.infinity,
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.08),
                        ),
                        child: Icon(
                          _categoryIcon(item.category),
                          color: colorScheme.primary,
                          size: AppIconSizes.lg,
                        ),
                      ),
                DecoratedBox(
                  key: ValueKey('portfolio-grid-thumbnail-gradient-${item.id}'),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.10),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.10),
                      ],
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

class _PortfolioOverflowMenu extends StatelessWidget {
  const _PortfolioOverflowMenu({
    this.onViewDetails,
    this.onEdit,
    this.onDelete,
  });

  final VoidCallback? onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<_PortfolioMenuAction>(
      key: const ValueKey('portfolio-premium-overflow-menu'),
      tooltip: 'Item actions',
      color: colorScheme.surfaceContainerHighest,
      elevation: 12,
      shadowColor: colorScheme.shadow.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      icon: Icon(
        Icons.more_horiz,
        color: colorScheme.onSurfaceVariant,
        size: 20,
      ),
      iconSize: 20,
      padding: EdgeInsets.zero,
      onSelected: (value) {
        switch (value) {
          case _PortfolioMenuAction.view:
            onViewDetails?.call();
          case _PortfolioMenuAction.edit:
            onEdit?.call();
          case _PortfolioMenuAction.delete:
            onDelete?.call();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _PortfolioMenuAction.view,
          enabled: onViewDetails != null,
          child: const _PortfolioMenuItem(
            icon: Icons.open_in_new_outlined,
            label: 'View details',
          ),
        ),
        PopupMenuItem(
          value: _PortfolioMenuAction.edit,
          enabled: onEdit != null,
          child: const _PortfolioMenuItem(
            icon: Icons.edit_outlined,
            label: 'Edit',
          ),
        ),
        PopupMenuItem(
          value: _PortfolioMenuAction.delete,
          enabled: onDelete != null,
          child: _PortfolioMenuItem(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: colorScheme.error,
          ),
        ),
      ],
    );
  }
}

enum _PortfolioMenuAction { view, edit, delete }

class _PortfolioMenuItem extends StatelessWidget {
  const _PortfolioMenuItem({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(icon, color: effectiveColor, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: effectiveColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PortfolioItemCard extends StatelessWidget {
  const _PortfolioItemCard({
    required this.item,
    required this.wishlistStatus,
    required this.onTap,
    required this.onRemove,
  });

  final CollectibleItem item;
  final WishlistStatus? wishlistStatus;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: AppElevation.level1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PortfolioItemImage(
                key: ValueKey('portfolio-card-image-${item.id}'),
                imagePath: item.imagePath,
                size: 108,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PortfolioItemDetails(
                  item: item,
                  wishlistStatus: wishlistStatus,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Column(
                children: [
                  IconButton.filledTonal(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline, size: 18),
                    tooltip: 'Remove item',
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      minimumSize: const Size(36, 36),
                      fixedSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  Text(
                    'Open',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioItemImage extends StatelessWidget {
  const _PortfolioItemImage({
    required this.imagePath,
    this.size = 110,
    super.key,
  });

  final String imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = _imageForPath();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: image,
      ),
    );
  }

  Widget _imageForPath() {
    final normalizedPath = imagePath.trim();
    if (normalizedPath.isEmpty || normalizedPath.startsWith('sample://')) {
      return const _PortfolioImagePlaceholder();
    }

    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return Image.network(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _PortfolioImagePlaceholder(),
      );
    }

    if (normalizedPath.startsWith('assets/')) {
      return Image.asset(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => const _PortfolioImagePlaceholder(),
      );
    }

    return buildLocalPortfolioImage(
      imagePath: normalizedPath,
      fit: BoxFit.cover,
      placeholderBuilder: () => const _PortfolioImagePlaceholder(),
    );
  }
}

class _PortfolioImagePlaceholder extends StatelessWidget {
  const _PortfolioImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: colorScheme.primary,
        size: 32,
      ),
    );
  }
}

class _PortfolioItemDetails extends StatelessWidget {
  const _PortfolioItemDetails({required this.item, this.wishlistStatus});

  final CollectibleItem item;
  final WishlistStatus? wishlistStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final trendLabel = _trendLabel(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTwoLineTitle(
          item.title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          item.category,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _formatAud(item.estimatedValue),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            _PortfolioBadge(
              label: item.condition,
              icon: Icons.grade_outlined,
              color: AppColors.success,
            ),
            _PortfolioBadge(
              label: '${(item.confidence * 100).toStringAsFixed(0)}%',
              icon: Icons.verified_outlined,
              color: colorScheme.primary,
            ),
            _PortfolioBadge(
              label: trendLabel,
              icon: _trendIcon(item),
              color: AppColors.secondaryAccent,
            ),
            if (wishlistStatus != null)
              _PortfolioBadge(
                label: wishlistStatus!.label,
                icon: _wishlistStatusIcon(wishlistStatus!),
                color: _wishlistStatusColor(context, wishlistStatus!),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 13,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                'Saved ${_formatDate(item.createdAt)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PortfolioBadge extends StatelessWidget {
  const _PortfolioBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Wrap(
        spacing: 4,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Icon(icon, size: 13, color: color),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              label,
              softWrap: true,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _wishlistStatusIcon(WishlistStatus status) {
  return switch (status) {
    WishlistStatus.owned => Icons.check_circle_outline,
    WishlistStatus.wanted => Icons.bookmark_add_outlined,
    WishlistStatus.missing => Icons.playlist_add_check_outlined,
  };
}

Color _wishlistStatusColor(BuildContext context, WishlistStatus status) {
  return switch (status) {
    WishlistStatus.owned => AppColors.success,
    WishlistStatus.wanted => Theme.of(context).colorScheme.primary,
    WishlistStatus.missing => const Color(0xFFD97706),
  };
}

IconData _categoryIcon(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('coin')) {
    return Icons.monetization_on_outlined;
  }
  if (normalized.contains('comic')) {
    return Icons.menu_book_outlined;
  }
  if (normalized.contains('toy') || normalized.contains('figure')) {
    return Icons.toys_outlined;
  }
  if (normalized.contains('sports')) {
    return Icons.sports_basketball_outlined;
  }
  if (normalized.contains('watch')) {
    return Icons.watch_outlined;
  }
  if (normalized.contains('sneaker')) {
    return Icons.directions_run_outlined;
  }

  return Icons.style_outlined;
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
  return '\$$withCommas';
}

String _displayImagePath(CollectibleItem item) {
  final primaryPath = item.imagePath.trim();
  if (primaryPath.isNotEmpty) {
    return primaryPath;
  }
  for (final image in item.galleryImages) {
    if (image.isPrimary && image.path.trim().isNotEmpty) {
      return image.path.trim();
    }
  }
  for (final image in item.galleryImages) {
    if (image.path.trim().isNotEmpty) {
      return image.path.trim();
    }
  }
  return '';
}

String _trendLabel(CollectibleItem item) {
  final raw = item.marketSummary?.trendLabel.trim().toLowerCase() ?? '';
  if (raw.contains('ris') || raw.contains('up') || raw.contains('gain')) {
    return 'Rising';
  }
  if (raw.contains('cool') || raw.contains('fall') || raw.contains('down')) {
    return 'Cooling';
  }
  return 'Stable';
}

IconData _trendIcon(CollectibleItem item) {
  return switch (_trendLabel(item)) {
    'Rising' => Icons.trending_up_outlined,
    'Cooling' => Icons.trending_down_outlined,
    _ => Icons.trending_flat_outlined,
  };
}
