import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_comp.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/features/wishlist/presentation/controllers/wishlist_providers.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
                        : 'Value range: ${_formatMoney(item.pricing!.lowEstimate, item.pricing!.currency)} - ${_formatMoney(item.pricing!.highEstimate, item.pricing!.currency)}',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _WishlistStatusSection(item: item),
                  const SizedBox(height: AppSpacing.xl),
                  _DetailSections(item: item),
                  const SizedBox(height: AppSpacing.xl),
                  _PriceAlertSection(item: item),
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
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(colorScheme),
      );
    }

    if (normalizedPath.startsWith('assets/')) {
      return Image.asset(
        normalizedPath,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(colorScheme),
      );
    }

    return Image.file(
      File(normalizedPath),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _placeholder(colorScheme),
    );
  }

  Widget _placeholder(ColorScheme colorScheme) {
    return Center(
      child: Icon(Icons.style_outlined, size: 56, color: colorScheme.primary),
    );
  }
}

class _WishlistStatusSection extends ConsumerWidget {
  const _WishlistStatusSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(wishlistStatusForItemProvider(item.id));

    return AppProfileSection(
      title: 'Wishlist Status',
      children: [
        Text(
          'Track whether this collectible is owned, wanted, or still missing.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        selectedStatus.when(
          data: (status) => _WishlistStatusSelector(
            selectedStatus: status,
            onChanged: (nextStatus) => _saveStatus(context, ref, nextStatus),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => _WishlistStatusSelector(
            selectedStatus: WishlistStatus.owned,
            onChanged: (nextStatus) => _saveStatus(context, ref, nextStatus),
          ),
        ),
      ],
    );
  }

  Future<void> _saveStatus(
    BuildContext context,
    WidgetRef ref,
    WishlistStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(wishlistRepositoryProvider)
        .saveStatus(item: item, status: status);
    ref.invalidate(wishlistEntriesProvider);
    ref.invalidate(wishlistStatusForItemProvider(item.id));
    messenger.showSnackBar(
      SnackBar(content: Text('Wishlist status set to ${status.label}')),
    );
  }
}

class _WishlistStatusSelector extends StatelessWidget {
  const _WishlistStatusSelector({
    required this.selectedStatus,
    required this.onChanged,
  });

  final WishlistStatus selectedStatus;
  final ValueChanged<WishlistStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final status in WishlistStatus.values) ...[
          _WishlistStatusOption(
            status: status,
            selected: selectedStatus == status,
            onTap: () => onChanged(status),
          ),
          if (status != WishlistStatus.values.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _WishlistStatusOption extends StatelessWidget {
  const _WishlistStatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final WishlistStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _wishlistStatusColor(context, status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.1)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? color : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(_wishlistStatusIcon(status), color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  status.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
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
                label:
                    'Market trend: ${item.marketSummary?.trendLabel ?? 'Stable'}',
                icon: Icons.trending_up_outlined,
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
        if (item.marketSummary != null) ...[
          _MarketIntelligenceSection(summary: item.marketSummary!),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (collectibleDetails.isNotEmpty) ...[
          AppProfileSection(
            title: 'Key Attributes',
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
        _PriceHistorySection(item: item),
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

class _MarketIntelligenceSection extends StatelessWidget {
  const _MarketIntelligenceSection({required this.summary});

  final MarketSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = _marketCurrency(summary);

    return AppProfileSection(
      title: 'Market Summary',
      children: [
        AppCompactMetadata(
          items: [
            AppMetadataItem(
              label: 'Average Price',
              value: _formatMoney(summary.averagePrice, currency),
            ),
            AppMetadataItem(
              label: 'Median Price',
              value: _formatMoney(summary.medianPrice, currency),
            ),
            AppMetadataItem(
              label: 'Market Range',
              value:
                  '${_formatMoney(summary.lowPrice, currency)} - ${_formatMoney(summary.highPrice, currency)}',
            ),
            AppMetadataItem(
              label: 'Sales Count',
              value: '${summary.salesCount}',
            ),
            AppMetadataItem(label: 'Trend', value: summary.trendLabel),
            AppMetadataItem(
              label: 'Confidence',
              value: '${(summary.confidence * 100).toStringAsFixed(0)}%',
            ),
            AppMetadataItem(
              label: 'Sources',
              value: summary.sources.join(', '),
            ),
            AppMetadataItem(
              label: 'Last Updated',
              value: _formatPricingDate(summary.lastUpdated),
            ),
          ],
        ),
        if (summary.comps.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Recent comparable sales',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ComparableSalesVisualList(
            comps: summary.comps.take(5).toList(growable: false),
            currency: currency,
          ),
        ],
      ],
    );
  }
}

class _ComparableSalesVisualList extends StatelessWidget {
  const _ComparableSalesVisualList({
    required this.comps,
    required this.currency,
  });

  final List<MarketComp> comps;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final highest = comps
        .map((comp) => comp.soldPrice)
        .fold<double>(0, (current, next) => current > next ? current : next);

    return Column(
      children: [
        for (final comp in comps) ...[
          _ComparableSaleVisualRow(
            comp: comp,
            highestPrice: highest,
            displayCurrency: currency,
          ),
          if (comp != comps.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ComparableSaleVisualRow extends StatelessWidget {
  const _ComparableSaleVisualRow({
    required this.comp,
    required this.highestPrice,
    required this.displayCurrency,
  });

  final MarketComp comp;
  final double highestPrice;
  final String displayCurrency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final widthFactor = highestPrice <= 0
        ? 0.0
        : (comp.soldPrice / highestPrice).clamp(0.08, 1.0);

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
          Row(
            children: [
              Expanded(
                child: Text(
                  comp.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatMoney(comp.soldPrice, comp.currency),
                style: textTheme.labelLarge?.copyWith(
                  color: _valueGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: widthFactor,
              minHeight: 8,
              backgroundColor: colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              semanticsLabel:
                  'Comparable sale ${_formatMoney(comp.soldPrice, displayCurrency)}',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${comp.source} / ${comp.condition} / ${_formatPricingDate(comp.soldDate)}',
            maxLines: 2,
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
  const _PriceHistorySection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prices = _pricesFor(item);
    final currentValue = prices.last.value;
    final lowestValue = prices
        .map((point) => point.value)
        .reduce((current, next) => current < next ? current : next);
    final highestValue = prices
        .map((point) => point.value)
        .reduce((current, next) => current > next ? current : next);
    final change = currentValue - prices.first.value;
    final changePercent = prices.first.value == 0
        ? 0
        : change / prices.first.value * 100;

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
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Item value summary with accessible labels and local trend estimates.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ItemValueSummaryVisual(item: item),
          const SizedBox(height: AppSpacing.xl),
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
          _PriceBars(points: prices, highestValue: highestValue),
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

class _ItemValueSummaryVisual extends StatelessWidget {
  const _ItemValueSummaryVisual({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pricing = item.pricing;
    final current = pricing?.estimatedMarketValue ?? item.estimatedValue;
    final low = pricing?.lowEstimate ?? current * 0.82;
    final high = pricing?.highEstimate ?? current * 1.18;
    final span = high - low;
    final position = span <= 0 ? 0.5 : ((current - low) / span).clamp(0.0, 1.0);

    return Semantics(
      label:
          'Item value summary. Current value ${_formatMoney(current, pricing?.currency ?? 'AUD')}. Range ${_formatMoney(low, pricing?.currency ?? 'AUD')} to ${_formatMoney(high, pricing?.currency ?? 'AUD')}.',
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _valueGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.stacked_line_chart_outlined,
                    color: _valueGold,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Value Summary',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatMoney(current, pricing?.currency ?? 'AUD'),
                        style: textTheme.titleLarge?.copyWith(
                          color: _valueGold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: position,
                minHeight: 10,
                backgroundColor: colorScheme.outlineVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(_valueGold),
                semanticsLabel: 'Current value position in estimated range',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Text(
                  'Low ${_formatMoney(low, pricing?.currency ?? 'AUD')}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'High ${_formatMoney(high, pricing?.currency ?? 'AUD')}',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
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

List<_PricePoint> _pricesFor(CollectibleItem item) {
  final current = (item.pricing?.estimatedMarketValue ?? item.estimatedValue)
      .round()
      .clamp(1, 1000000000)
      .toInt();
  final factors = [
    1200 / 1850,
    1350 / 1850,
    1480 / 1850,
    1620 / 1850,
    1760 / 1850,
    1.0,
  ];
  final values = factors
      .map((factor) => (current * factor).round().clamp(1, 1000000000).toInt())
      .toList(growable: false);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  return [
    for (var index = 0; index < months.length; index++)
      _PricePoint(month: months[index], value: values[index]),
  ];
}

class _PriceAlertSection extends ConsumerWidget {
  const _PriceAlertSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(itemPriceAlertsProvider(item.id));

    return AppProfileSection(
      title: 'Price Alerts',
      children: [
        Text(
          'Track value changes locally. Push notifications are not enabled yet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _CreateAlertButtons(item: item),
        const SizedBox(height: AppSpacing.lg),
        alerts.when(
          data: (itemAlerts) => itemAlerts.isEmpty
              ? const _NoAlertsMessage()
              : Column(
                  children: [
                    for (final alert in itemAlerts) ...[
                      _PriceAlertRow(alert: alert),
                      if (alert != itemAlerts.last)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(
            'Unable to load local alerts right now.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _CreateAlertButtons extends ConsumerWidget {
  const _CreateAlertButtons({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _AlertActionButton(
          label: 'Alert if value rises 10%',
          icon: Icons.trending_up_outlined,
          onPressed: () => _createAlert(
            context,
            ref,
            item,
            PriceAlertRuleType.percentageIncrease,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AlertActionButton(
          label: 'Alert if value drops 10%',
          icon: Icons.trending_down_outlined,
          onPressed: () => _createAlert(
            context,
            ref,
            item,
            PriceAlertRuleType.percentageDecrease,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AlertActionButton(
          label: 'Remind when pricing is stale',
          icon: Icons.schedule_outlined,
          onPressed: () => _createAlert(
            context,
            ref,
            item,
            PriceAlertRuleType.stalePricingReminder,
          ),
        ),
      ],
    );
  }

  Future<void> _createAlert(
    BuildContext context,
    WidgetRef ref,
    CollectibleItem item,
    PriceAlertRuleType type,
  ) async {
    final repository = ref.read(priceAlertRepositoryProvider);
    await repository.saveAlert(buildPriceAlert(item: item, type: type));
    ref.invalidate(itemPriceAlertsProvider(item.id));
    ref.invalidate(priceAlertSummaryProvider);
    if (context.mounted) {
      _showDetailSnackBar(context, 'Price alert created');
    }
  }
}

class _AlertActionButton extends StatelessWidget {
  const _AlertActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _NoAlertsMessage extends StatelessWidget {
  const _NoAlertsMessage();

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
      child: Row(
        children: [
          Icon(Icons.notifications_none_outlined, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No alerts for this collectible yet. Create a local alert below to watch price moves or stale pricing.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceAlertRow extends ConsumerWidget {
  const _PriceAlertRow({required this.alert});

  final PriceAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final triggered = alert.status == PriceAlertStatus.triggered;
    final color = triggered ? AppColors.success : colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                triggered
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
                color: color,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alertRuleLabel(alert.rule),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      alert.message ?? alert.status.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                alert.status.label,
                style: textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (triggered) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resetAlert(context, ref, alert),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _deleteAlert(context, ref, alert),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resetAlert(
    BuildContext context,
    WidgetRef ref,
    PriceAlert alert,
  ) async {
    final repository = ref.read(priceAlertRepositoryProvider);
    await repository.saveAlert(
      alert.copyWith(
        status: PriceAlertStatus.active,
        updatedAt: DateTime.now(),
        clearMessage: true,
        clearTriggeredAt: true,
      ),
    );
    ref.invalidate(itemPriceAlertsProvider(alert.itemId));
    ref.invalidate(priceAlertSummaryProvider);
    if (context.mounted) {
      _showDetailSnackBar(context, 'Price alert reset');
    }
  }

  Future<void> _deleteAlert(
    BuildContext context,
    WidgetRef ref,
    PriceAlert alert,
  ) async {
    final repository = ref.read(priceAlertRepositoryProvider);
    await repository.deleteAlert(alert.id);
    ref.invalidate(itemPriceAlertsProvider(alert.itemId));
    ref.invalidate(priceAlertSummaryProvider);
    if (context.mounted) {
      _showDetailSnackBar(context, 'Price alert deleted');
    }
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

String _alertRuleLabel(PriceAlertRule rule) {
  switch (rule.type) {
    case PriceAlertRuleType.priceRisesAboveAmount:
      return 'Rises above ${_formatAud(rule.amount ?? 0)}';
    case PriceAlertRuleType.priceDropsBelowAmount:
      return 'Drops below ${_formatAud(rule.amount ?? 0)}';
    case PriceAlertRuleType.percentageIncrease:
      return 'Increases by ${_formatRulePercent(rule.percentage)}';
    case PriceAlertRuleType.percentageDecrease:
      return 'Decreases by ${_formatRulePercent(rule.percentage)}';
    case PriceAlertRuleType.stalePricingReminder:
      return 'Stale pricing reminder';
  }
}

String _formatRulePercent(double? value) {
  return '${((value ?? 0) * 100).toStringAsFixed(0)}%';
}

const _valueGold = Color(0xFFD97706);

String _marketCurrency(MarketSummary summary) {
  if (summary.comps.isEmpty) {
    return 'AUD';
  }

  return summary.comps.first.currency;
}
