import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    this.onScanPressed,
    this.onImportPhotoPressed,
    this.onPortfolioPressed,
    super.key,
  });

  final VoidCallback? onScanPressed;
  final VoidCallback? onImportPhotoPressed;
  final VoidCallback? onPortfolioPressed;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = ref.watch(portfolioControllerProvider);
    final items = portfolio.orderedItems;
    final insights = const CollectorDashboardAnalyticsService().build(items);
    final recentItems = items.take(4).toList(growable: false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth <= 360
                ? AppSpacing.lg
                : AppSpacing.xl;

            return CustomScrollView(
              key: const PageStorageKey<String>('home-scroll-position'),
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    child: _PremiumHomeHero(
                      scrollController: _scrollController,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    topPadding: AppSpacing.xl,
                    child: _StatsSurface(insights: insights),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    topPadding: AppSpacing.xl,
                    child: _QuickActionsSection(
                      onScanPressed: widget.onScanPressed,
                      onImportPhotoPressed:
                          widget.onImportPhotoPressed ?? widget.onScanPressed,
                      onPortfolioPressed: widget.onPortfolioPressed,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    topPadding: AppSpacing.xl,
                    child: _PortfolioOverviewSection(insights: insights),
                  ),
                ),
                if (insights.itemCount < 3)
                  SliverToBoxAdapter(
                    child: _HomeFrame(
                      horizontalPadding: horizontalPadding,
                      topPadding: AppSpacing.md,
                      child: _SmallPortfolioCta(
                        onPressed: widget.onScanPressed,
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    topPadding: AppSpacing.xl,
                    child: _RecentActivitySection(
                      items: recentItems,
                      onScanPressed: widget.onScanPressed,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HomeFrame(
                    horizontalPadding: horizontalPadding,
                    topPadding: AppSpacing.xl,
                    bottomPadding: AppSpacing.xxl,
                    child: _AiInsightsSection(insights: insights),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeFrame extends StatelessWidget {
  const _HomeFrame({
    required this.child,
    required this.horizontalPadding,
    this.topPadding = AppSpacing.lg,
    this.bottomPadding = 0,
  });

  final Widget child;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        topPadding,
        horizontalPadding,
        bottomPadding,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

class _PremiumHomeHero extends StatelessWidget {
  const _PremiumHomeHero({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final gradientColors = PackLoxGradients.build(
      GradientStyle.blueIndigo,
      context,
    );

    return AnimatedBuilder(
      animation: scrollController,
      builder: (context, child) {
        final scrollOffset = scrollController.hasClients
            ? scrollController.offset
            : 0.0;
        return MotionElasticHero(
          key: const ValueKey('home-hero-motion'),
          baseHeight: 320,
          scrollOffset: scrollOffset,
          child: MotionParallax(
            scrollOffset: scrollOffset,
            child: MotionAmbientGradient(
              gradientBuilder: (t) => LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(gradientColors[0], gradientColors[1], t)!,
                  Color.lerp(gradientColors[1], gradientColors[2], 1 - t)!,
                  gradientColors[2],
                ],
              ),
              child: Container(
                constraints: const BoxConstraints(minHeight: 320),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.94,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surfaceContainerHighest,
                      colorScheme.surfaceContainerHighest,
                      colorScheme.primaryContainer.withValues(alpha: 0.18),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppElevation.level2,
                ),
                child: SafeArea(
                  top: true,
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                      horizontal: AppSpacing.lg,
                    ),
                    child: MotionReveal(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good evening',
                            style: textTheme.titleSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Your Collection Hub',
                              style: textTheme.displayLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                height: 1.06,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Scan, value, and track your collectibles.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsSurface extends StatelessWidget {
  const _StatsSurface({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    return MotionReveal(
      child: _PremiumSurface(
        key: const ValueKey('home-stats-surface'),
        low: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 360;
            return Row(
              children: [
                Expanded(
                  child: MotionTapScale(
                    child: _StatColumn(
                      icon: Icons.inventory_2_outlined,
                      value: _formatItemCount(insights.itemCount),
                      label: 'Items',
                      compact: compact,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MotionTapScale(
                    child: _StatColumn(
                      icon: Icons.payments_outlined,
                      value: _formatCurrency(insights.totalValue),
                      label: 'Total value',
                      compact: compact,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: MotionTapScale(
                    child: _StatColumn(
                      icon: Icons.history_rounded,
                      value: insights.mostRecentItem == null
                          ? 'Ready to scan'
                          : _formatRelativeScanTime(
                              insights.mostRecentItem!.createdAt,
                            ),
                      label: 'Last scan',
                      compact: compact,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.compact,
  });

  final IconData icon;
  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: compact ? AppIconSizes.sm : AppIconSizes.md,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection({
    this.onScanPressed,
    this.onImportPhotoPressed,
    this.onPortfolioPressed,
  });

  final VoidCallback? onScanPressed;
  final VoidCallback? onImportPhotoPressed;
  final VoidCallback? onPortfolioPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final actions = [
      _ActionSpec(
        key: const ValueKey('home-quick-action-Scan'),
        icon: Icons.document_scanner_outlined,
        label: 'Scan',
        subtitle: 'Capture now',
        onTap: onScanPressed,
        color: colorScheme.primary,
      ),
      _ActionSpec(
        key: const ValueKey('home-quick-action-Import Photo'),
        icon: Icons.photo_library_outlined,
        label: 'Import',
        subtitle: 'From gallery',
        onTap: onImportPhotoPressed,
        color: AppColors.secondaryAccent,
      ),
      _ActionSpec(
        key: const ValueKey('home-quick-action-Portfolio'),
        icon: Icons.inventory_2_outlined,
        label: 'Portfolio',
        subtitle: 'Open library',
        onTap: onPortfolioPressed,
        color: AppColors.violet,
      ),
      const _ActionSpec(
        key: ValueKey('home-quick-action-PI'),
        icon: Icons.auto_awesome_outlined,
        label: 'PI (Soon)',
        subtitle: 'Trends',
        color: Color(0xFFF59E0B),
      ),
    ];

    return _SectionSurface(
      title: 'Quick Actions',
      dividerKey: const ValueKey('home-section-divider-actions'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = AppSpacing.lg;
          final columns = constraints.maxWidth >= 680 ? 4 : 2;
          final width =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;
          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < actions.length; i++)
                SizedBox(
                  width: width.clamp(120.0, 220.0),
                  child: MotionReveal(
                    delay: Duration(milliseconds: i * 40),
                    child: _QuickActionTile(action: actions[i]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionSpec {
  const _ActionSpec({
    required this.key,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  final Key key;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.action});

  final _ActionSpec action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = action.onTap != null;

    return MotionTapScale(
      key: action.key,
      enabled: enabled,
      onTap: action.onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.58),
          ),
          boxShadow: AppElevation.level1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(action.icon, color: action.color, size: 22),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    action.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              action.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (!enabled) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Planned',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PortfolioOverviewSection extends StatelessWidget {
  const _PortfolioOverviewSection({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    final topAsset = insights.highestValueItem;

    return _SectionSurface(
      title: 'Portfolio Overview',
      dividerKey: const ValueKey('home-section-divider-overview'),
      high: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            _formatCurrency(insights.totalValue),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _OverviewChip(label: 'Items', value: '${insights.itemCount}'),
              _OverviewChip(
                label: 'Categories',
                value: _formatCategoryTypes(_categoryCount(insights)),
              ),
              _OverviewChip(
                label: 'Trend',
                value: _formatMonthlyChange(insights),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.48),
          ),
          const SizedBox(height: AppSpacing.md),
          _TopAssetPreview(item: topAsset),
        ],
      ),
    );
  }
}

class _OverviewChip extends StatelessWidget {
  const _OverviewChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopAssetPreview extends StatelessWidget {
  const _TopAssetPreview({required this.item});

  final CollectibleItem? item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotionElasticHero(
      baseHeight: 76,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          children: [
            if (item == null)
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.workspace_premium_outlined,
                  color: colorScheme.primary,
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: PortfolioThumbnail(imagePath: item!.imagePath, size: 52),
              ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Top asset',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item?.title ??
                        'Start with one scan to build your collection timeline.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentActivitySection extends StatelessWidget {
  const _RecentActivitySection({required this.items, this.onScanPressed});

  final List<CollectibleItem> items;
  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    return _SectionSurface(
      title: 'Recent Activity',
      dividerKey: const ValueKey('home-section-divider-activity'),
      child: items.isEmpty
          ? _EmptyInlineCallout(
              message: 'No recent activity yet. Scan your first collectible.',
              actionLabel: 'Scan',
              onPressed: onScanPressed,
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const SizedBox(height: AppSpacing.md),
                  MotionReveal(
                    delay: Duration(milliseconds: i * 40),
                    child: _RecentActivityTile(item: items[i]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotionTapScale(
      onTap: () => _openCollectibleDetail(context, item),
      child: Container(
        key: ValueKey('home-recent-${item.id}'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.46),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: PortfolioThumbnail(imagePath: item.imagePath, size: 52),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    item.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        item.condition,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        _formatSavedRelative(item.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  _formatCurrency(item.estimatedValue),
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiInsightsSection extends StatelessWidget {
  const _AiInsightsSection({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    final confidence = insights.isEmpty
        ? null
        : _formatPercent(insights.averageConfidence);
    final status = insights.isEmpty ? 'Learning' : _aiInsightStatus(insights);

    return _SectionSurface(
      title: 'AI Insights',
      dividerKey: const ValueKey('home-section-divider-insights'),
      child: TweenAnimationBuilder<double>(
        key: const ValueKey('home-ai-insights-glow'),
        tween: Tween(begin: 0.75, end: 1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              gradient: LinearGradient(
                colors: [
                  AppColors.violet.withValues(alpha: 0.10 * value),
                  Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.04 * value),
                ],
              ),
            ),
            child: child,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              AnimatedScale(
                key: const ValueKey('home-ai-insights-icon-motion'),
                duration: const Duration(milliseconds: 150),
                scale: 1,
                child: Icon(
                  Icons.auto_awesome_outlined,
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Portfolio Confidence • $status${confidence == null ? '' : ' ($confidence)'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _portfolioAwareInsight(insights),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionSurface extends StatelessWidget {
  const _SectionSurface({
    required this.title,
    required this.child,
    required this.dividerKey,
    this.high = false,
  });

  final String title;
  final Widget child;
  final Key dividerKey;
  final bool high;

  @override
  Widget build(BuildContext context) {
    return MotionReveal(
      child: _PremiumSurface(
        high: high,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              key: dividerKey,
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.46),
            ),
            const SizedBox(height: AppSpacing.lg),
            child,
          ],
        ),
      ),
    );
  }
}

class _PremiumSurface extends StatelessWidget {
  const _PremiumSurface({
    required this.child,
    this.low = false,
    this.high = false,
    super.key,
  });

  final Widget child;
  final bool low;
  final bool high;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(high ? AppSpacing.xl : AppSpacing.lg),
      decoration: BoxDecoration(
        color: low
            ? colorScheme.surfaceContainerLow
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(high ? AppRadius.xl : AppRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.52),
        ),
        boxShadow: high ? AppElevation.level2 : AppElevation.level1,
      ),
      child: child,
    );
  }
}

class _SmallPortfolioCta extends StatelessWidget {
  const _SmallPortfolioCta({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return _PremiumSurface(
      key: const ValueKey('home-small-portfolio-cta'),
      low: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Text(
            'Ready to grow your collection?',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          );
          final action = FilledButton(
            onPressed: onPressed,
            child: const Text('Scan New Collectible'),
          );
          if (constraints.maxWidth < 360) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                content,
                const SizedBox(height: AppSpacing.md),
                action,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: content),
              const SizedBox(width: AppSpacing.md),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _EmptyInlineCallout extends StatelessWidget {
  const _EmptyInlineCallout({
    required this.message,
    required this.actionLabel,
    this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: AppSpacing.md),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}

void _openCollectibleDetail(BuildContext context, CollectibleItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CollectibleDetailPage(item: item)));
}

String _formatCurrency(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

String _formatItemCount(int count) {
  return '$count ${count == 1 ? 'item' : 'items'}';
}

String _formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(0)}%';
}

int _categoryCount(CollectorDashboardAnalytics insights) {
  return insights.categoryDistribution.values
      .where((count) => count > 0)
      .length;
}

String _formatCategoryTypes(int count) {
  return '$count ${count == 1 ? 'type' : 'types'}';
}

String _formatMonthlyChange(CollectorDashboardAnalytics insights) {
  final snapshots = insights.monthlySnapshots;
  if (snapshots.length < 2) {
    return 'Tracking';
  }
  final previous = snapshots[snapshots.length - 2].totalValue;
  final current = snapshots.last.totalValue;
  final change = current - previous;
  final sign = change >= 0 ? '+' : '-';
  return '$sign${_formatCurrency(change.abs())}';
}

String _formatRelativeScanTime(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final difference = reference.difference(date);
  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    return '${difference.inMinutes}m ago';
  }
  if (_isSameDay(date, reference)) {
    return 'Today';
  }
  if (_isSameDay(date, reference.subtract(const Duration(days: 1)))) {
    return 'Yesterday';
  }
  return '${difference.inDays}d ago';
}

String _formatSavedRelative(DateTime date, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  if (_isSameDay(date, reference)) {
    return 'Saved today';
  }
  if (_isSameDay(date, reference.subtract(const Duration(days: 1)))) {
    return 'Saved yesterday';
  }
  final days = reference
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  return 'Saved $days days ago';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _aiInsightStatus(CollectorDashboardAnalytics insights) {
  if (insights.itemCount == 0) {
    return 'Learning';
  }
  if (insights.averageConfidence >= 0.80 ||
      insights.collectionHealth.score >= 80) {
    return 'Excellent';
  }
  if (insights.averageConfidence >= 0.65) {
    return 'Healthy';
  }
  return 'Review';
}

String _portfolioAwareInsight(CollectorDashboardAnalytics insights) {
  if (insights.isEmpty) {
    return 'Scan one collectible to unlock valuation, rarity clues, and recommendations.';
  }
  final highest = insights.highestValueItem;
  if (highest != null && highest.estimatedValue > 0) {
    return '${highest.title} is currently your highest value collectible.';
  }
  return 'Add more scans for stronger collection intelligence.';
}
