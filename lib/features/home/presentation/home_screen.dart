import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/home/home_ui.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    this.onScanPressed,
    this.onImportPhotoPressed,
    this.onPortfolioPressed,
    super.key,
  });

  final VoidCallback? onScanPressed;
  final VoidCallback? onImportPhotoPressed;
  final VoidCallback? onPortfolioPressed;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static const _pagePadding = AppSpacing.lg;
  static const _sectionGap = 26.0;

  final _scrollController = ScrollController();
  final ValueNotifier<double> _heroScrollOffset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _heroScrollOffset.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final offset = _scrollController.offset;
    final quantizedOffset = _quantizeHeroScrollOffset(offset);
    if ((_heroScrollOffset.value - quantizedOffset).abs() < 0.1) {
      return;
    }
    _heroScrollOffset.value = quantizedOffset;
  }

  double _quantizeHeroScrollOffset(double offset) {
    if (offset < 0) {
      return offset;
    }
    const bucketSize = 24.0;
    return (offset / bucketSize).roundToDouble() * bucketSize;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final portfolio = ref.watch(portfolioControllerProvider);
    final authState = ref.watch(authControllerProvider);
    final orderedItems = portfolio.orderedItems;
    final recentItems = orderedItems.take(4).toList(growable: false);
    final insights = const CollectorDashboardAnalyticsService().build(
      orderedItems,
    );

    Widget framed(Widget child, {EdgeInsetsGeometry? padding}) {
      return Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: SizedBox(width: double.infinity, child: child),
          ),
        ),
      );
    }

    SliverToBoxAdapter sliverBox(Widget child, {EdgeInsetsGeometry? padding}) {
      return SliverToBoxAdapter(child: framed(child, padding: padding));
    }

    final quickActions = [
      HomeQuickAction(
        icon: Icons.document_scanner_outlined,
        title: 'Scan',
        subtitle: 'Identify an item',
        onTap: widget.onScanPressed,
        accentColor: colorScheme.primary,
      ),
      HomeQuickAction(
        icon: Icons.photo_library_outlined,
        title: 'Import Photo',
        subtitle: 'From gallery',
        onTap: widget.onImportPhotoPressed ?? widget.onScanPressed,
        accentColor: AppColors.secondaryAccent,
      ),
      HomeQuickAction(
        icon: Icons.inventory_2_outlined,
        title: 'Portfolio',
        subtitle: 'View collection',
        onTap: widget.onPortfolioPressed,
        accentColor: AppColors.violet,
      ),
      const HomeQuickAction(
        icon: Icons.query_stats_outlined,
        title: 'Trends',
        subtitle: 'Planned',
        accentColor: Color(0xFFF59E0B),
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          key: const PageStorageKey<String>('home-scroll-position'),
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: framed(
                ValueListenableBuilder<double>(
                  valueListenable: _heroScrollOffset,
                  builder: (context, scrollOffset, child) {
                    return MotionElasticHero(
                      key: const ValueKey('home-hero-motion'),
                      baseHeight: 198,
                      scrollOffset: scrollOffset,
                      child: MotionParallax(
                        scrollOffset: scrollOffset,
                        child: HomeHeroHeader(
                          greeting: _homeGreeting(
                            DateTime.now(),
                            displayName: _displayNameForGreeting(authState),
                          ),
                          itemCount: insights.itemCount,
                          estimatedValue: _formatCurrency(insights.totalValue),
                          lastScanStatus: insights.mostRecentItem == null
                              ? 'Ready to scan'
                              : _formatRelativeScanTime(
                                  insights.mostRecentItem!.createdAt,
                                ),
                        ),
                      ),
                    );
                  },
                ),
                padding: const EdgeInsets.fromLTRB(
                  _pagePadding,
                  _pagePadding,
                  _pagePadding,
                  0,
                ),
              ),
            ),
            sliverBox(
              _HomeSectionSurface(
                title: 'Quick Actions',
                variant: _HomeSurfaceVariant.actions,
                child: HomeQuickActionsGrid(actions: quickActions),
              ),
              padding: const EdgeInsets.fromLTRB(
                _pagePadding,
                _sectionGap,
                _pagePadding,
                0,
              ),
            ),
            if (insights.itemCount < 3)
              sliverBox(
                _HomeSurface(
                  variant: _HomeSurfaceVariant.cta,
                  child: _SmallPortfolioCta(onPressed: widget.onScanPressed),
                ),
                padding: const EdgeInsets.fromLTRB(
                  _pagePadding,
                  AppSpacing.md,
                  _pagePadding,
                  0,
                ),
              ),
            sliverBox(
              _HomeSectionSurface(
                title: 'Portfolio Overview',
                variant: _HomeSurfaceVariant.overview,
                child: PortfolioOverviewCard(
                  insights: insights,
                  onScanPressed: widget.onScanPressed,
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                _pagePadding,
                _sectionGap,
                _pagePadding,
                0,
              ),
            ),
            sliverBox(
              _HomeSectionSurface(
                title: 'Recent Activity',
                variant: _HomeSurfaceVariant.activity,
                child: RecentActivityPanel(
                  items: recentItems,
                  onScanPressed: widget.onScanPressed,
                  onOpenItem: (item) => _openCollectibleDetail(context, item),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(
                _pagePadding,
                _sectionGap,
                _pagePadding,
                0,
              ),
            ),
            sliverBox(
              _HomeSectionSurface(
                title: 'AI Insights',
                variant: _HomeSurfaceVariant.insights,
                child: AiInsightsCard(insights: insights),
              ),
              padding: const EdgeInsets.fromLTRB(
                _pagePadding,
                _sectionGap,
                _pagePadding,
                0,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }
}

class HomeQuickAction {
  const HomeQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
}

class HomeQuickActionsGrid extends StatelessWidget {
  const HomeQuickActionsGrid({super.key, required this.actions});

  final List<HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        const spacing = AppSpacing.lg;
        final availableWidth = (constraints.maxWidth - spacing * (columns - 1))
            .clamp(0.0, double.infinity);
        final width = availableWidth / columns;

        return MotionStagger(
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final action in actions)
                  SizedBox(width: width, child: _HomeQuickActionTile(action)),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _HomeQuickActionTile extends StatelessWidget {
  const _HomeQuickActionTile(this.action);

  final HomeQuickAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = action.onTap != null;

    return Material(
      key: ValueKey('home-quick-action-${action.title}'),
      color: Colors.transparent,
      child: _PressScale(
        enabled: isEnabled,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: isEnabled ? 1 : 0.72,
            child: Container(
              constraints: const BoxConstraints(minHeight: 96),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.50
                      : 0.74,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.82),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: action.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      action.icon,
                      color: action.accentColor,
                      size: AppIconSizes.md,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          action.subtitle,
                          maxLines: isEnabled ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isEnabled)
                    Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: _TinyStatusPill(
                        label: 'Soon',
                        color: action.accentColor,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeSectionHeader extends StatelessWidget {
  const HomeSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MotionReveal(
      child: Text(
        title,
        textAlign: TextAlign.left,
        style: AppTextStyles.body.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum _HomeSurfaceVariant { actions, overview, activity, insights, cta }

class _HomeSectionSurface extends StatelessWidget {
  const _HomeSectionSurface({
    required this.title,
    required this.child,
    this.variant = _HomeSurfaceVariant.overview,
  });

  final String title;
  final Widget child;
  final _HomeSurfaceVariant variant;

  @override
  Widget build(BuildContext context) {
    return _HomeSurface(
      variant: variant,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HomeSectionHeader(title),
          const SizedBox(height: AppSpacing.md),
          _SectionDivider(variant: variant),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _HomeSurface extends StatelessWidget {
  const _HomeSurface({
    required this.child,
    this.variant = _HomeSurfaceVariant.overview,
  });

  final Widget child;
  final _HomeSurfaceVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundAlpha = switch (variant) {
      _HomeSurfaceVariant.actions => isDark ? 0.50 : 0.88,
      _HomeSurfaceVariant.overview => isDark ? 0.46 : 0.96,
      _HomeSurfaceVariant.activity => isDark ? 0.42 : 0.92,
      _HomeSurfaceVariant.insights => isDark ? 0.40 : 0.90,
      _HomeSurfaceVariant.cta => isDark ? 0.48 : 0.94,
    };
    final radius = switch (variant) {
      _HomeSurfaceVariant.cta => AppRadius.lg,
      _ => AppRadius.xl,
    };
    final borderAlpha = switch (variant) {
      _HomeSurfaceVariant.insights => 0.58,
      _ => 0.76,
    };
    final shadows = switch (variant) {
      _HomeSurfaceVariant.insights => [
        BoxShadow(
          color: AppColors.violet.withValues(alpha: isDark ? 0.18 : 0.10),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
        ...AppElevation.level1,
      ],
      _ => AppElevation.level1,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            (isDark ? colorScheme.surfaceContainerHighest : colorScheme.surface)
                .withValues(alpha: backgroundAlpha),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: borderAlpha),
        ),
        boxShadow: shadows,
      ),
      child: Padding(
        padding: EdgeInsets.all(
          variant == _HomeSurfaceVariant.cta ? AppSpacing.md : AppSpacing.lg,
        ),
        child: child,
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider({required this.variant});

  final _HomeSurfaceVariant variant;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = variant == _HomeSurfaceVariant.insights
        ? AppColors.violet.withValues(alpha: 0.20)
        : colorScheme.outlineVariant.withValues(alpha: 0.58);

    return Container(
      key: ValueKey('home-section-divider-${variant.name}'),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0),
            color,
            color.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

class PortfolioOverviewCard extends StatelessWidget {
  const PortfolioOverviewCard({
    required this.insights,
    this.onScanPressed,
    super.key,
  });

  final CollectorDashboardAnalytics insights;
  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final topAsset = insights.highestValueItem?.title ?? 'None yet';
    final trend = _formatMonthlyChange(insights);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated value',
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _formatAud(insights.totalValue),
                      style: textTheme.displaySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        height: 0.96,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _TinyStatusPill(
              label: trend,
              color: trend == _trendFallback
                  ? colorScheme.onSurfaceVariant
                  : AppColors.success,
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSpacing.sm;
            final statWidth = ((constraints.maxWidth - spacing) / 2).clamp(
              0.0,
              double.infinity,
            );

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                _OverviewStat(
                  width: statWidth,
                  label: 'Items',
                  value: insights.itemCount.toString(),
                  icon: Icons.inventory_2_outlined,
                ),
                _OverviewStat(
                  width: statWidth,
                  label: 'Categories',
                  value: _formatCategoryTypes(_categoryCount(insights)),
                  icon: Icons.category_outlined,
                ),
                _OverviewStat(
                  width: statWidth,
                  label: 'Top asset',
                  value: topAsset,
                  icon: Icons.workspace_premium_outlined,
                ),
                _OverviewStat(
                  width: statWidth,
                  label: 'Trend',
                  value: trend,
                  icon: Icons.trending_up_outlined,
                ),
              ],
            );
          },
        ),
        if (insights.isEmpty) ...[
          const SizedBox(height: 10),
          _EmptyInlineCallout(
            message: 'Start with one scan to build your collection timeline.',
            actionLabel: 'Scan',
            onPressed: onScanPressed,
          ),
        ],
      ],
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  maxLines: label == 'Top asset' ? 2 : 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
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

class RecentActivityPanel extends StatelessWidget {
  const RecentActivityPanel({
    required this.items,
    required this.onOpenItem,
    this.onScanPressed,
    super.key,
  });

  final List<CollectibleItem> items;
  final ValueChanged<CollectibleItem> onOpenItem;
  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyInlineCallout(
        message: 'No recent activity yet. Scan your first collectible.',
        actionLabel: 'Scan',
        onPressed: onScanPressed,
      );
    }

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _FadeSlideIn(
            delay: Duration(milliseconds: 80 + index * 24),
            child: _RecentActivityRow(
              item: items[index],
              onTap: () => onOpenItem(items[index]),
            ),
          ),
          if (index != items.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Divider(height: 1.2, thickness: 1.1),
            ),
        ],
      ],
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.item, required this.onTap});

  final CollectibleItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      key: ValueKey('home-recent-${item.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            children: [
              PortfolioThumbnail(imagePath: item.imagePath, size: 60),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _ActivityBadge(label: item.category),
                        _ActivityBadge(label: item.condition),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatSavedRelative(item.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 88),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _formatAud(item.estimatedValue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.48,
                      ),
                      size: 17,
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

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class AiInsightsCard extends StatelessWidget {
  const AiInsightsCard({required this.insights, super.key});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final polishedStatusLabel = _aiInsightStatus(insights);
    final polishedConfidence = insights.isEmpty
        ? null
        : _formatPercent(insights.averageConfidence);
    final polishedStatus = insights.isEmpty
        ? 'Portfolio Confidence • Learning'
        : 'Portfolio Confidence • $polishedStatusLabel ($polishedConfidence)';
    final polishedMessage = _portfolioAwareInsight(insights);

    return TweenAnimationBuilder<double>(
      key: const ValueKey('home-ai-insights-glow'),
      tween: Tween(begin: 0.72, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            gradient: LinearGradient(
              colors: [
                AppColors.violet.withValues(alpha: 0.09 * value),
                colorScheme.primary.withValues(alpha: 0.035 * value),
                Colors.transparent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.10 * value),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AiInsightIcon(),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'AI Insights',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _TinyStatusPill(
                        label: polishedConfidence ?? polishedStatusLabel,
                        color: AppColors.violet,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    polishedStatus,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    polishedMessage,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
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

class _AiInsightIcon extends StatefulWidget {
  const _AiInsightIcon();

  @override
  State<_AiInsightIcon> createState() => _AiInsightIconState();
}

class _AiInsightIconState extends State<_AiInsightIcon> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        key: const ValueKey('home-ai-insights-icon-motion'),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.94 : 1,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.violet.withValues(alpha: 0.24),
                AppColors.secondaryAccent.withValues(alpha: 0.16),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.violet.withValues(alpha: 0.18)),
          ),
          child: const Icon(
            Icons.auto_awesome_outlined,
            color: AppColors.violet,
            size: AppIconSizes.md,
          ),
        ),
      ),
    );
  }
}

class _SmallPortfolioCta extends StatelessWidget {
  const _SmallPortfolioCta({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      key: const ValueKey('home-small-portfolio-cta'),
      builder: (context, constraints) {
        final icon = Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(
            Icons.add_a_photo_outlined,
            color: colorScheme.primary,
            size: AppIconSizes.md,
          ),
        );
        final title = Text(
          'Ready to grow your collection?',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        );
        final button = FilledButton(
          onPressed: onPressed,
          child: const Text('Scan New Collectible'),
        );

        if (constraints.maxWidth < 370) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  icon,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: title),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              button,
            ],
          );
        }

        return Row(
          children: [
            icon,
            const SizedBox(width: AppSpacing.md),
            Expanded(child: title),
            const SizedBox(width: AppSpacing.sm),
            button,
          ],
        );
      },
    );
  }
}

class _TinyStatusPill extends StatelessWidget {
  const _TinyStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.10),
            colorScheme.primaryContainer.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              Icons.add_a_photo_outlined,
              color: colorScheme.primary,
              size: AppIconSizes.md,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.enabled});

  final Widget child;
  final bool enabled;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || _pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: widget.child,
      ),
    );
  }
}

class _FadeSlideIn extends StatelessWidget {
  const _FadeSlideIn({required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 260 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final eased = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 8),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

void _openCollectibleDetail(BuildContext context, CollectibleItem item) {
  if (item.id.trim().isEmpty || item.title.trim().isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open this portfolio item.')),
    );
    return;
  }

  try {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => CollectibleDetailPage(item: item)),
    );
  } on Object {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open this portfolio item.')),
    );
  }
}

String _formatCurrency(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

String _formatAud(double value) => _formatCurrency(value);

String _formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(0)}%';
}

String _aiInsightStatus(CollectorDashboardAnalytics insights) {
  if (insights.itemCount == 0) {
    return 'Learning';
  }
  if (insights.itemCount <= 2) {
    return 'Building';
  }
  if (insights.averageConfidence >= 0.80 ||
      insights.collectionHealth.score >= 80) {
    return 'Excellent';
  }
  return 'Ready';
}

int _categoryCount(CollectorDashboardAnalytics insights) {
  return insights.categoryDistribution.values
      .where((count) => count > 0)
      .length;
}

String _formatMonthlyChange(CollectorDashboardAnalytics insights) {
  final snapshots = insights.monthlySnapshots;
  if (snapshots.length < 2) {
    return _trendFallback;
  }

  final previous = snapshots[snapshots.length - 2].totalValue;
  final current = snapshots.last.totalValue;
  final change = current - previous;
  final sign = change >= 0 ? '+' : '-';
  return '$sign${_formatAud(change.abs())}';
}

const _trendFallback = 'Tracking';

String _formatCategoryTypes(int count) {
  if (count <= 0) {
    return '0';
  }
  return '$count ${count == 1 ? 'type' : 'types'}';
}

String _homeGreeting(DateTime now, {String? displayName}) {
  final greeting = switch (now.hour) {
    >= 5 && < 12 => 'Good morning',
    >= 12 && < 18 => 'Good afternoon',
    >= 18 && < 23 => 'Good evening',
    _ => 'Welcome back',
  };
  final name = displayName?.trim();
  if (name == null || name.isEmpty || greeting == 'Welcome back') {
    return greeting;
  }
  return '$greeting, $name 👋';
}

String? _displayNameForGreeting(AuthState authState) {
  final user = authState.user;
  if (user == null || !user.isCloudBacked || user.isAnonymous) {
    return null;
  }
  final displayName = user.displayName.trim();
  if (displayName.isNotEmpty && displayName != 'Local Collector') {
    return displayName.split(RegExp(r'\s+')).first;
  }
  final email = user.email?.trim();
  if (email == null || email.isEmpty || !email.contains('@')) {
    return null;
  }
  return email.split('@').first;
}

String _formatRelativeScanTime(DateTime date, {DateTime? now}) {
  final difference = (now ?? DateTime.now()).difference(date);
  if (difference.inMinutes < 1) {
    return 'Just now';
  }
  if (difference.inMinutes < 60) {
    final minutes = difference.inMinutes;
    return '$minutes ${minutes == 1 ? 'min' : 'mins'} ago';
  }
  if (_isSameDay(date, now ?? DateTime.now())) {
    return 'Today';
  }
  if (_isSameDay(
    date,
    (now ?? DateTime.now()).subtract(const Duration(days: 1)),
  )) {
    return 'Yesterday';
  }
  final days = (now ?? DateTime.now())
      .difference(DateTime(date.year, date.month, date.day))
      .inDays;
  return '$days days ago';
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
      .inDays
      .clamp(2, 9999);
  return 'Saved $days days ago';
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _portfolioAwareInsight(CollectorDashboardAnalytics insights) {
  if (insights.isEmpty) {
    return 'Scan one collectible to unlock valuation, rarity clues, and recommendations.';
  }

  final highest = insights.highestValueItem;
  if (highest != null && highest.estimatedValue > 0) {
    return '${highest.title} is currently your highest value collectible.';
  }

  final categoryValue = <CollectorCategory, double>{};
  for (final item in insights.items) {
    final category = CollectorDashboardAnalyticsService.categoryForCollectible(
      item.category,
    );
    categoryValue[category] =
        (categoryValue[category] ?? 0) + item.estimatedValue;
  }
  final leadingCategory = categoryValue.entries
      .where((entry) => entry.value > 0)
      .fold<MapEntry<CollectorCategory, double>?>(
        null,
        (best, entry) =>
            best == null || entry.value > best.value ? entry : best,
      );
  if (leadingCategory != null &&
      insights.totalValue > 0 &&
      leadingCategory.value / insights.totalValue >= 0.5) {
    return '${leadingCategory.key.label} represent most of your tracked value.';
  }

  final gradingCandidates = insights.items
      .where((item) => item.estimatedValue >= 250 && item.confidence >= 0.80)
      .length;
  if (gradingCandidates > 0) {
    return gradingCandidates == 1
        ? 'One item may benefit from professional grading.'
        : '$gradingCandidates items may benefit from professional grading.';
  }

  final categoryCount = _categoryCount(insights);
  if (categoryCount > 1) {
    return 'Your tracked value is spread across $categoryCount categories.';
  }

  return 'Add more scans for stronger collection intelligence.';
}
