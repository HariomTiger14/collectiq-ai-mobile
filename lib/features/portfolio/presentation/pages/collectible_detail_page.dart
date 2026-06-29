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
    final collectibleDetails = _metadataRows(item);

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
          _DetailRow(label: 'Category', value: item.category),
          _DetailRow(
            label: 'Estimated Value',
            value: _formatAud(item.estimatedValue),
          ),
          _DetailRow(
            label: 'Confidence',
            value: '${(item.confidence * 100).toStringAsFixed(0)}%',
          ),
          _DetailRow(label: 'Condition', value: item.condition),
          _DetailRow(label: 'Date Saved', value: _formatDate(item.createdAt)),
          if (collectibleDetails.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Profile Details',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final detail in collectibleDetails)
              _DetailRow(label: detail.label, value: detail.value),
          ],
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

  List<_MetadataDetail> _metadataRows(CollectibleItem item) {
    return [
      _MetadataDetail('Year', item.year),
      _MetadataDetail('Brand', item.brand),
      _MetadataDetail('Set', item.setName),
      _MetadataDetail('Series', item.series),
      _MetadataDetail('Card #', item.cardNumber),
      _MetadataDetail('Player/Character', item.playerOrCharacter),
      _MetadataDetail('Rarity', item.rarity),
      _MetadataDetail('Estimated Grade', item.estimatedGrade),
      _MetadataDetail('Language', item.language),
      _MetadataDetail('Edition', item.edition),
      _MetadataDetail('Country', item.country),
      _MetadataDetail('Mint', item.mint),
      _MetadataDetail('Material', item.material),
      _MetadataDetail('Profile Notes', item.notes),
    ].where((detail) => detail.value.trim().isNotEmpty).toList();
  }
}

class _MetadataDetail {
  const _MetadataDetail(this.label, String? value) : value = value ?? '';

  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _PriceMetric(
                label: 'Current Value',
                value: _formatAud(currentValue.toDouble()),
              ),
              _PriceMetric(
                label: '6-month Change',
                value:
                    '+${_formatAud(change.toDouble())} (${changePercent.toStringAsFixed(0)}%)',
              ),
              _PriceMetric(
                label: 'Highest Value',
                value: _formatAud(highestValue.toDouble()),
              ),
              _PriceMetric(
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

class _PriceMetric extends StatelessWidget {
  const _PriceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      width: 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
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
        FilledButton(
          onPressed: () {
            _showDetailSnackBar(context, 'Re-analysis coming next');
          },
          child: const Text('Re-analyze'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () {
            _showDetailSnackBar(context, 'Price tracking coming next');
          },
          child: const Text('Track Price'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton(
          onPressed: () {
            _showDetailSnackBar(context, 'Marketplace listing coming next');
          },
          child: const Text('Sell Item'),
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
