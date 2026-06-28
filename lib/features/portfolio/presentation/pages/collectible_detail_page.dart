import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';

/// Detail page for a saved portfolio collectible.
class CollectibleDetailPage extends StatelessWidget {
  /// Creates a collectible detail page.
  const CollectibleDetailPage({required this.item, this.onDelete, super.key});

  /// Item displayed on the detail page.
  final CollectibleItem item;

  /// Called when the user asks to delete the item.
  final Future<bool> Function(String itemId)? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: AppResponsiveColumn(
        spacing: AppSpacing.xl,
        children: [
          const _DetailNavigationHeader(),
          _HeroImage(item: item),
          _AssetHeader(item: item),
          _EstimatedValueCard(item: item),
          _DetailsCard(item: item),
          _NotesCard(item: item),
          _ActionButtons(onDelete: onDelete, itemId: item.id),
        ],
      ),
    );
  }
}

class _DetailNavigationHeader extends StatelessWidget {
  const _DetailNavigationHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIconButton(
          icon: Icons.arrow_back,
          tooltip: 'Back to portfolio',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: AppSpacing.md),
        const Expanded(child: SectionHeader(title: 'Collectible Details')),
      ],
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: _imageForPath(colorScheme),
        ),
      ),
    );
  }

  Widget _imageForPath(ColorScheme colorScheme) {
    final normalizedPath = item.imagePath.trim();
    if (normalizedPath.isEmpty || normalizedPath.startsWith('sample://')) {
      return _placeholder(colorScheme);
    }

    if (normalizedPath.startsWith('http://') ||
        normalizedPath.startsWith('https://')) {
      return Image.network(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(colorScheme),
      );
    }

    if (normalizedPath.startsWith('assets/')) {
      return Image.asset(
        normalizedPath,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(colorScheme),
      );
    }

    return buildLocalPortfolioImage(
      imagePath: normalizedPath,
      fit: BoxFit.cover,
      placeholderBuilder: () => _placeholder(colorScheme),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Container(
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: Center(
        child: Icon(Icons.style_outlined, size: 56, color: colorScheme.primary),
      ),
    );
  }
}

class _AssetHeader extends StatelessWidget {
  const _AssetHeader({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.category,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ConfidenceBadge(
                confidence: '${(item.confidence * 100).toStringAsFixed(0)}%',
              ),
              StatusChip(
                label: item.condition,
                icon: Icons.workspace_premium_outlined,
              ),
              StatusChip(
                label: _formatDate(item.createdAt),
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EstimatedValueCard extends StatelessWidget {
  const _EstimatedValueCard({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      backgroundColor: AppColors.estimatedValueGold.withValues(alpha: 0.1),
      borderColor: AppColors.estimatedValueGold.withValues(alpha: 0.18),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.estimatedValueGold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Icon(
              Icons.paid_outlined,
              color: AppColors.estimatedValueGold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Value',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _formatAud(item.estimatedValue),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineMedium?.copyWith(
                    color: AppColors.estimatedValueGold,
                    fontWeight: FontWeight.w900,
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

class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: AppResponsiveColumn(
        spacing: AppSpacing.md,
        children: [
          const SectionHeader(title: 'Asset Details'),
          MetricTile(
            label: 'Category',
            value: item.category,
            icon: Icons.category_outlined,
          ),
          MetricTile(
            label: 'Confidence',
            value: '${(item.confidence * 100).toStringAsFixed(0)}%',
            icon: Icons.verified_outlined,
            valueColor: AppColors.confidenceBlue,
          ),
          MetricTile(
            label: 'Condition',
            value: item.condition,
            icon: Icons.workspace_premium_outlined,
          ),
          MetricTile(
            label: 'Date Saved',
            value: _formatDate(item.createdAt),
            icon: Icons.calendar_today_outlined,
          ),
        ],
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Notes'),
          const SizedBox(height: AppSpacing.md),
          Text(item.recommendation, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.itemId, this.onDelete});

  final String itemId;
  final Future<bool> Function(String itemId)? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppResponsiveColumn(
      spacing: AppSpacing.md,
      children: [
        PrimaryButton(
          label: 'Re-analyze',
          icon: Icons.auto_awesome_outlined,
          onPressed: () {
            _showDetailSnackBar(context, 'Re-analysis coming next');
          },
        ),
        SecondaryButton(
          label: 'Track Price',
          icon: Icons.show_chart_outlined,
          onPressed: () {
            _showDetailSnackBar(context, 'Price tracking coming next');
          },
        ),
        SecondaryButton(
          label: 'Sell Item',
          icon: Icons.storefront_outlined,
          onPressed: () {
            _showDetailSnackBar(context, 'Marketplace listing coming next');
          },
        ),
        if (onDelete != null)
          AppCard(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.error.withValues(alpha: 0.08),
            borderColor: Theme.of(
              context,
            ).colorScheme.error.withValues(alpha: 0.2),
            child: SecondaryButton(
              label: 'Delete Item',
              icon: Icons.delete_outline,
              onPressed: () => onDelete!(itemId),
            ),
          ),
      ],
    );
  }
}

void _showDetailSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

String _formatAud(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return 'AUD $withCommas';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
