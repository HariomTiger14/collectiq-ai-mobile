import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';

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

  /// Average AI confidence across saved items.
  final String averageConfidence;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveSplit(
      primary: MetricTile(
        label: 'Total collection value',
        value: _formatAud(totalValue),
        icon: Icons.account_balance_wallet_outlined,
        valueColor: AppColors.estimatedValueGold,
      ),
      secondary: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 520) {
            return AppResponsiveColumn(
              spacing: AppSpacing.md,
              children: [
                MetricTile(
                  label: 'Total items',
                  value: itemCount.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
                MetricTile(
                  label: 'Average confidence',
                  value: averageConfidence,
                  icon: Icons.verified_outlined,
                  valueColor: AppColors.confidenceBlue,
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Total items',
                  value: itemCount.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: MetricTile(
                  label: 'Average confidence',
                  value: averageConfidence,
                  icon: Icons.verified_outlined,
                  valueColor: AppColors.confidenceBlue,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Empty state shown before items are saved to the portfolio.
class PortfolioEmptyState extends StatelessWidget {
  /// Creates the portfolio empty state.
  const PortfolioEmptyState({this.onScanPressed, super.key});

  /// Opens the scanner tab.
  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.inventory_2_outlined,
      title: 'No collectibles yet.',
      message: 'Scan and save your first item to start your collector library.',
      action: PrimaryButton(
        label: 'Scan Collectible',
        icon: Icons.document_scanner_outlined,
        onPressed: onScanPressed,
      ),
    );
  }
}

/// Empty state shown when search filters hide all saved items.
class PortfolioNoSearchResultsState extends StatelessWidget {
  /// Creates a no search results state.
  const PortfolioNoSearchResultsState({required this.onResetSearch, super.key});

  /// Clears the active search query.
  final VoidCallback onResetSearch;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.search_off,
      title: 'No matching collectibles',
      message: 'Try a different title or category.',
      action: SecondaryButton(
        label: 'Reset Search',
        icon: Icons.refresh,
        onPressed: onResetSearch,
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
    return EmptyState(
      icon: Icons.error_outline,
      title: message,
      message: 'Please try again in a moment.',
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
    super.key,
  });

  /// Saved portfolio items.
  final List<CollectibleItem> items;

  /// Called when a user removes an item.
  final ValueChanged<String> onRemoveItem;

  /// Called when a user opens an item.
  final ValueChanged<CollectibleItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveColumn(
      spacing: AppSpacing.md,
      children: [
        for (var index = 0; index < items.length; index++)
          _PortfolioListAnimation(
            delay: Duration(milliseconds: 36 * index),
            child: _PortfolioItemCard(
              item: items[index],
              onTap: () => onOpenItem(items[index]),
              onRemove: () => onRemoveItem(items[index].id),
            ),
          ),
      ],
    );
  }
}

class _PortfolioItemCard extends StatelessWidget {
  const _PortfolioItemCard({
    required this.item,
    required this.onTap,
    required this.onRemove,
  });

  final CollectibleItem item;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: PortfolioThumbnail(
                size: 110,
                placeholderIcon: Icons.image_not_supported_outlined,
                child: _thumbnailForPath(item.imagePath),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _PortfolioItemDetails(item: item, onRemove: onRemove),
            ),
          ],
        ),
      ),
    );
  }
}

Widget? _thumbnailForPath(String imagePath) {
  final normalizedPath = imagePath.trim();
  if (normalizedPath.isEmpty || normalizedPath.startsWith('sample://')) {
    return null;
  }

  if (normalizedPath.startsWith('http://') ||
      normalizedPath.startsWith('https://')) {
    return Image.network(
      normalizedPath,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  if (normalizedPath.startsWith('assets/')) {
    return Image.asset(
      normalizedPath,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    );
  }

  return buildLocalPortfolioImage(
    imagePath: normalizedPath,
    fit: BoxFit.cover,
    placeholderBuilder: () => const SizedBox.shrink(),
  );
}

class _PortfolioItemDetails extends StatelessWidget {
  const _PortfolioItemDetails({required this.item, required this.onRemove});

  final CollectibleItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Remove item',
                padding: EdgeInsets.zero,
              ),
            ),
          ],
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
        const Spacer(),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ValueBadge(value: _formatAud(item.estimatedValue)),
            ConfidenceBadge(
              confidence: '${(item.confidence * 100).toStringAsFixed(0)}%',
            ),
            StatusChip(
              label: _formatDate(item.createdAt),
              icon: Icons.calendar_today_outlined,
            ),
          ],
        ),
      ],
    );
  }
}

class _PortfolioListAnimation extends StatelessWidget {
  const _PortfolioListAnimation({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slideDuration + delay,
      curve: AppMotion.standardCurve,
      builder: (context, value, child) {
        final progress = delay == Duration.zero
            ? value
            : (value - 0.12).clamp(0.0, 1.0);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - progress)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
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
