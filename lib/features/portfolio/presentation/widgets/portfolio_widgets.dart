import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
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
    super.key,
  });

  /// Total estimated portfolio value.
  final double totalValue;

  /// Number of saved items.
  final int itemCount;

  final double averageConfidence;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppPriceHero(
          label: 'Total collection value',
          value: _formatAud(totalValue),
          subtitle: 'Estimated market value across your saved collectibles',
        ),
        const SizedBox(height: AppSpacing.md),
        AppResponsiveMetricGroup(
          metrics: [
            AppMetricData(
              label: 'Items',
              value: itemCount.toString(),
              icon: Icons.inventory_2_outlined,
            ),
            AppMetricData(
              label: 'Avg confidence',
              value: '${(averageConfidence * 100).toStringAsFixed(0)}%',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
      ],
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
          Icon(Icons.search_off, size: 44, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No matching collectibles',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Try a different title or category.',
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
                label: const Text('Reset Search'),
              ),
            ),
          ],
        ],
      ),
    );
  }
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
    final trendLabel = item.marketSummary?.trendLabel ?? 'Stable';

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
              icon: Icons.trending_up_outlined,
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
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
