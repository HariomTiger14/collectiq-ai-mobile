import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';

/// Displays aggregate portfolio metrics.
class PortfolioSummaryCard extends StatelessWidget {
  /// Creates a portfolio summary card.
  const PortfolioSummaryCard({
    required this.totalValue,
    required this.itemCount,
    super.key,
  });

  /// Total estimated portfolio value.
  final double totalValue;

  /// Number of saved items.
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [...AppElevation.level1, ...AppElevation.accentGlow],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 560 ? 2 : 1;
          final spacing = columns == 1 ? AppSpacing.md : AppSpacing.lg;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              SizedBox(
                width: itemWidth,
                child: _PortfolioMetric(
                  label: 'Total Value',
                  value: _formatAud(totalValue),
                  icon: Icons.account_balance_wallet_outlined,
                ),
              ),
              SizedBox(
                width: itemWidth,
                child: _PortfolioMetric(
                  label: 'Total Items',
                  value: itemCount.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PortfolioMetric extends StatelessWidget {
  const _PortfolioMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Empty state shown before items are saved to the portfolio.
class PortfolioEmptyState extends StatelessWidget {
  /// Creates the portfolio empty state.
  const PortfolioEmptyState({super.key});

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
            'Analyze a scan and save it to start your portfolio.',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
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
  const PortfolioNoSearchResultsState({super.key});

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
    return Column(
      children: [
        for (final item in items) ...[
          SizedBox(
            width: double.infinity,
            child: _PortfolioItemCard(
              item: item,
              onTap: () => onOpenItem(item),
              onRemove: () => onRemoveItem(item.id),
            ),
          ),
          if (item != items.last) const SizedBox(height: AppSpacing.lg),
        ],
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
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: AppElevation.level1,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PortfolioItemImage(imagePath: item.imagePath),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _PortfolioItemDetails(item: item)),
              const SizedBox(width: AppSpacing.md),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Remove item',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PortfolioItemImage extends StatelessWidget {
  const _PortfolioItemImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final image = _imageForPath();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        width: 110,
        height: 110,
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
        errorBuilder: (_, _, _) => const _PortfolioImagePlaceholder(),
      );
    }

    if (normalizedPath.startsWith('assets/')) {
      return Image.asset(
        normalizedPath,
        fit: BoxFit.cover,
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
  const _PortfolioItemDetails({required this.item});

  final CollectibleItem item;

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
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${item.category} / ${item.condition}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _PortfolioItemMetricsGrid(
          metrics: [
            _PortfolioItemMetricData(
              label: 'Value',
              value: _formatAud(item.estimatedValue),
              isEmphasized: true,
            ),
            _PortfolioItemMetricData(
              label: 'Confidence',
              value: '${(item.confidence * 100).toStringAsFixed(0)}%',
            ),
            _PortfolioItemMetricData(
              label: 'Saved',
              value: _formatDate(item.createdAt),
            ),
          ],
        ),
      ],
    );
  }
}

class _PortfolioItemMetricData {
  const _PortfolioItemMetricData({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;
}

class _PortfolioItemMetricsGrid extends StatelessWidget {
  const _PortfolioItemMetricsGrid({required this.metrics});

  final List<_PortfolioItemMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 430 ? 3 : 1;
        final spacing = columns == 1 ? AppSpacing.sm : AppSpacing.md;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: AppSpacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _PortfolioItemMetric(
                  label: metric.label,
                  value: metric.value,
                  isEmphasized: metric.isEmphasized,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PortfolioItemMetric extends StatelessWidget {
  const _PortfolioItemMetric({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(
            color: isEmphasized ? colorScheme.primary : colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
