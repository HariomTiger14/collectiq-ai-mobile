import 'dart:io';

import 'package:collectiq_ai/core/theme/design_system.dart';
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
        title: const Text('Collectible Details'),
        actions: [
          if (onDelete != null)
            IconButton(
              onPressed: () => onDelete!(item.id),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete item',
            ),
        ],
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
                  _DetailCard(item: item),
                  const SizedBox(height: AppSpacing.xl),
                  const _PriceHistorySection(),
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

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.item});

  final CollectibleItem item;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _DetailMetricsGrid(
            metrics: [
              _DetailMetricData(label: 'Category', value: item.category),
              _DetailMetricData(
                label: 'Estimated Value',
                value: _formatAud(item.estimatedValue),
              ),
              _DetailMetricData(
                label: 'Confidence',
                value: '${(item.confidence * 100).toStringAsFixed(0)}%',
              ),
              _DetailMetricData(label: 'Condition', value: item.condition),
              _DetailMetricData(
                label: 'Date Saved',
                value: _formatDate(item.createdAt),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Notes',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(item.recommendation, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DetailMetricData {
  const _DetailMetricData({required this.label, required this.value});

  final String label;
  final String value;
}

class _DetailMetricsGrid extends StatelessWidget {
  const _DetailMetricsGrid({required this.metrics});

  final List<_DetailMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final spacing = AppSpacing.md;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _DetailMetric(label: metric.label, value: metric.value),
              ),
          ],
        );
      },
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
          _PriceMetricsGrid(
            metrics: [
              _PriceMetricData(
                label: 'Current Value',
                value: _formatAud(currentValue.toDouble()),
              ),
              _PriceMetricData(
                label: '6-month Change',
                value:
                    '+${_formatAud(change.toDouble())} (${changePercent.toStringAsFixed(0)}%)',
              ),
              _PriceMetricData(
                label: 'Highest Value',
                value: _formatAud(highestValue.toDouble()),
              ),
              _PriceMetricData(
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

class _PriceMetricData {
  const _PriceMetricData({required this.label, required this.value});

  final String label;
  final String value;
}

class _PriceMetricsGrid extends StatelessWidget {
  const _PriceMetricsGrid({required this.metrics});

  final List<_PriceMetricData> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 2 : 1;
        final spacing = AppSpacing.md;
        final itemWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: itemWidth,
                child: _PriceMetric(label: metric.label, value: metric.value),
              ),
          ],
        );
      },
    );
  }
}

class _PriceMetric extends StatelessWidget {
  const _PriceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            _showDetailSnackBar(context, 'Re-analysis coming next');
          },
          icon: const Icon(Icons.auto_awesome_outlined),
          label: const Text('Re-analyze'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () {
            _showDetailSnackBar(context, 'Price tracking coming next');
          },
          icon: const Icon(Icons.show_chart_outlined),
          label: const Text('Track Price'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () {
            _showDetailSnackBar(context, 'Marketplace listing coming next');
          },
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Sell Item'),
        ),
        if (onDelete != null) ...[
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () => onDelete!(itemId),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Item'),
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
