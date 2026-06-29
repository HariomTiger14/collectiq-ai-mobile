import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Collectible Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ImagePreview(item: item),
                  const SizedBox(height: AppSpacing.xl),
                  _DetailHeader(item: item),
                  const SizedBox(height: AppSpacing.xl),
                  AppPriceHero(
                    label: 'Estimated market value',
                    value: _formatAud(item.estimatedValue),
                    subtitle: item.pricing == null
                        ? 'Based on the saved AI estimate'
                        : 'Market range and source details below',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _DetailSections(item: item),
                  const SizedBox(height: AppSpacing.xl),
                  _ActionButtons(onDelete: onDelete, itemId: item.id),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      clipBehavior: Clip.antiAlias,
      child: _imageForPath(colorScheme),
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
        errorBuilder: (_, _, _) => _placeholder(colorScheme),
      );
    }

    if (normalizedPath.startsWith('assets/')) {
      return Image.asset(
        normalizedPath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(colorScheme),
      );
    }

    return Image.file(
      File(normalizedPath),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _placeholder(colorScheme),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Center(
      child: Icon(Icons.style_outlined, size: 56, color: colorScheme.primary),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTwoLineTitle(
            item.title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.12,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _StatusBadge(
                label:
                    '${(item.confidence * 100).toStringAsFixed(0)}% confidence',
                icon: Icons.verified_outlined,
              ),
              _StatusBadge(
                label: item.condition,
                icon: Icons.auto_awesome_outlined,
              ),
              _StatusBadge(
                label: 'Saved ${_formatDate(item.createdAt)}',
                icon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailSections extends StatelessWidget {
  const _DetailSections({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final collectibleDetails = _metadataRows(item);

    return Column(
      children: [
        if (item.pricing != null) ...[
          AppProfileSection(
            title: 'Market Pricing',
            children: [
              AppCompactMetadata(
                items: [
                  AppMetadataItem(
                    label: 'Market Value',
                    value: _formatMoney(
                      item.pricing!.estimatedMarketValue,
                      item.pricing!.currency,
                    ),
                  ),
                  AppMetadataItem(
                    label: 'Estimated Range',
                    value:
                        '${_formatMoney(item.pricing!.lowEstimate, item.pricing!.currency)} - ${_formatMoney(item.pricing!.highEstimate, item.pricing!.currency)}',
                  ),
                  AppMetadataItem(
                    label: 'Pricing Source',
                    value: item.pricing!.pricingSource,
                  ),
                  AppMetadataItem(
                    label: 'Pricing Confidence',
                    value:
                        '${(item.pricing!.pricingConfidence * 100).toStringAsFixed(0)}%',
                  ),
                  AppMetadataItem(
                    label: 'Last Updated',
                    value: _formatPricingDate(item.pricing!.lastUpdated),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (collectibleDetails.isNotEmpty) ...[
          AppProfileSection(
            title: 'Profile Details',
            children: [AppCompactMetadata(items: collectibleDetails)],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (_hasAiReview(item)) ...[
          AppProfileSection(
            title: 'AI Review',
            children: [
              if ((item.primaryMatch ?? '').trim().isNotEmpty)
                AppLabelValueRow(
                  label: 'Primary Match',
                  value: item.primaryMatch!,
                ),
              if ((item.confidenceExplanation ?? '').trim().isNotEmpty)
                _DetailTextBlock(
                  title: 'Why this match?',
                  body: item.confidenceExplanation!,
                ),
              if ((item.detectionQuality ?? '').trim().isNotEmpty)
                _DetailTextBlock(
                  title: 'Detection Quality',
                  body: item.detectionQuality!,
                ),
              if ((item.aiReasoning ?? '').trim().isNotEmpty)
                _DetailTextBlock(
                  title: 'AI Reasoning',
                  body: item.aiReasoning!,
                ),
              if (item.alternativeMatches.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final match in item.alternativeMatches.take(3))
                  _AlternativeMatchRow(match: match),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        AppProfileSection(
          title: 'Recommendation',
          children: [
            Text(
              item.recommendation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const _PriceHistorySection(),
      ],
    );
  }

  bool _hasAiReview(CollectibleItem item) {
    return (item.primaryMatch ?? '').trim().isNotEmpty ||
        (item.confidenceExplanation ?? '').trim().isNotEmpty ||
        (item.detectionQuality ?? '').trim().isNotEmpty ||
        (item.aiReasoning ?? '').trim().isNotEmpty ||
        item.alternativeMatches.isNotEmpty;
  }

  List<AppMetadataItem> _metadataRows(CollectibleItem item) {
    return [
      _metadataItem('Year', item.year),
      _metadataItem('Brand', item.brand),
      _metadataItem('Set', item.setName),
      _metadataItem('Series', item.series),
      _metadataItem('Card #', item.cardNumber),
      _metadataItem('Player/Character', item.playerOrCharacter),
      _metadataItem('Rarity', item.rarity),
      _metadataItem('Estimated Grade', item.estimatedGrade),
      _metadataItem('Language', item.language),
      _metadataItem('Edition', item.edition),
      _metadataItem('Country', item.country),
      _metadataItem('Mint', item.mint),
      _metadataItem('Material', item.material),
      _metadataItem('Profile Notes', item.notes),
    ].where((detail) => detail.value.trim().isNotEmpty).toList();
  }

  AppMetadataItem _metadataItem(String label, String? value) {
    return AppMetadataItem(label: label, value: value ?? '');
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTextBlock extends StatelessWidget {
  const _DetailTextBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AlternativeMatchRow extends StatelessWidget {
  const _AlternativeMatchRow({required this.match});

  final CollectibleAlternativeMatch match;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTwoLineTitle(
                  match.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${(match.confidence * 100).toStringAsFixed(0)}%',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${match.category} / ${match.reason}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceHistorySection extends StatelessWidget {
  const _PriceHistorySection();

  static const _prices = [
    _PricePoint(month: 'Jan', value: 1200),
    _PricePoint(month: 'Feb', value: 1350),
    _PricePoint(month: 'Mar', value: 1480),
    _PricePoint(month: 'Apr', value: 1620),
    _PricePoint(month: 'May', value: 1760),
    _PricePoint(month: 'Jun', value: 1850),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final currentValue = _prices.last.value;
    final lowestValue = _prices
        .map((point) => point.value)
        .reduce((current, next) => current < next ? current : next);
    final highestValue = _prices
        .map((point) => point.value)
        .reduce((current, next) => current > next ? current : next);
    final change = currentValue - _prices.first.value;
    final changePercent = change / _prices.first.value * 100;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price History',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppResponsiveMetricGroup(
            metrics: [
              AppMetricData(
                label: 'Current Value',
                value: _formatAud(currentValue.toDouble()),
              ),
              AppMetricData(
                label: '6-month Change',
                value:
                    '+${_formatAud(change.toDouble())} (${changePercent.toStringAsFixed(0)}%)',
              ),
              AppMetricData(
                label: 'Highest Value',
                value: _formatAud(highestValue.toDouble()),
              ),
              AppMetricData(
                label: 'Lowest Value',
                value: _formatAud(lowestValue.toDouble()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _PriceBars(points: _prices, highestValue: highestValue),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              'Market trend looks positive. Consider holding or grading before selling.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePoint {
  const _PricePoint({required this.month, required this.value});

  final String month;
  final int value;
}

class _PriceBars extends StatelessWidget {
  const _PriceBars({required this.points, required this.highestValue});

  final List<_PricePoint> points;
  final int highestValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 156,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _formatAud(point.value.toDouble()),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 24,
                    height: 88 * point.value / highestValue,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    point.month,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (point != points.last) const SizedBox(width: AppSpacing.sm),
          ],
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppProfileSection(
      title: 'Actions',
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              _showDetailSnackBar(context, 'Re-analysis coming next');
            },
            child: const Text('Re-analyze'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              _showDetailSnackBar(context, 'Price tracking coming next');
            },
            child: const Text('Track Price'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              _showDetailSnackBar(context, 'Marketplace listing coming next');
            },
            child: const Text('Sell Item'),
          ),
        ),
        if (onDelete != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Divider(color: colorScheme.outlineVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Danger zone',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.error,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppDangerAction(
            label: 'Delete Item',
            onPressed: () => onDelete!(itemId),
          ),
        ],
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

String _formatMoney(double value, String currency) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '$currency $withCommas';
}

String _formatPricingDate(DateTime? date) {
  if (date == null) {
    return 'Unknown';
  }

  return _formatDate(date);
}
