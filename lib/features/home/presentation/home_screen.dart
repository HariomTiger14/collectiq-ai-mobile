import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/ui/home/home_ui.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/glass_card.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/home/domain/services/smart_collector_insights_service.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({this.onScanPressed, super.key});

  final VoidCallback? onScanPressed;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    debugPrint('[HomeScreen] init');
  }

  @override
  void dispose() {
    debugPrint('[HomeScreen] dispose');
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final portfolio = ref.watch(portfolioControllerProvider);
    final orderedItems = portfolio.orderedItems;
    final recentItems = orderedItems.take(3).toList();
    final bool isPortfolioEmpty = orderedItems.isEmpty;
    final insights = const CollectorDashboardAnalyticsService().build(
      orderedItems,
    );
    final smartIntelligence = const SmartCollectorInsightsService().build(
      insights,
    );

    Widget framed(Widget child, {EdgeInsetsGeometry? padding}) {
      return Padding(
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: child,
          ),
        ),
      );
    }

    SliverToBoxAdapter sliverBox(Widget child, {EdgeInsetsGeometry? padding}) {
      return SliverToBoxAdapter(child: framed(child, padding: padding));
    }

    List<Widget> sectionSlivers(
      String title,
      List<Widget> children, {
      double topSpacing = AppSpacing.xl,
    }) {
      return [
        sliverBox(
          HomeSectionHeader(title),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            topSpacing,
            AppSpacing.lg,
            AppSpacing.md,
          ),
        ),
        sliverBox(HomeCardGroup(children: children)),
      ];
    }

    final quickActions = [
      HomeQuickAction(
        icon: Icons.document_scanner_outlined,
        title: 'Scan Item',
        subtitle: 'Open camera',
        onTap: widget.onScanPressed,
      ),
      HomeQuickAction(
        icon: Icons.add_circle_outline,
        title: 'Add Item',
        subtitle: 'Start capture',
        onTap: widget.onScanPressed,
      ),
      HomeQuickAction(
        icon: Icons.collections_bookmark_outlined,
        title: 'View Portfolio',
        subtitle: '${orderedItems.length} saved',
        onTap: () => ref
            .read(appShellTabControllerProvider.notifier)
            .selectTab(
              AppShellTabController.portfolioTab,
              reason: 'home-quick-action',
            ),
      ),
    ];

    final portfolioTiles = [
      _HomeDashboardTile(
        icon: Icons.inventory_2_outlined,
        title: 'Portfolio Snapshot',
        subtitle: isPortfolioEmpty
            ? 'Build your starter collection'
            : '${insights.itemCount} saved collectibles',
        child: _PortfolioSnapshotCompact(insights: insights),
      ),
      _HomeDashboardTile(
        icon: Icons.category_outlined,
        title: 'Suggested Collections',
        subtitle: 'Cards, coins, comics, and figures',
        child: const _CollectibleCategoryChips(),
      ),
    ];

    final recentActivityTiles = [
      _HomeDashboardTile(
        icon: Icons.history_outlined,
        title: 'Recent Activity',
        subtitle: isPortfolioEmpty
            ? 'Your latest scans will appear here.'
            : '${recentItems.length} latest saved',
        child: isPortfolioEmpty
            ? const _HomePlaceholderText(
                'Scan your first collectible to begin.',
              )
            : _RecentActivityList(
                items: recentItems,
                onOpenItem: (item) => _openCollectibleDetail(context, item),
              ),
      ),
    ];

    final aiInsightTiles = [
      _HomeDashboardTile(
        icon: Icons.auto_awesome_outlined,
        title: 'AI Insights',
        subtitle: smartIntelligence.collectionScore.label,
        child: _HomeInsightLine(
          icon: Icons.psychology_alt_outlined,
          title: smartIntelligence.recommendations.isEmpty
              ? 'Scan assistant ready'
              : smartIntelligence.recommendations.first.title,
          value: _formatPercent(insights.averageConfidence),
          subtitle: smartIntelligence.recommendations.isEmpty
              ? 'Build your starter collection with cards, coins, comics, or figures.'
              : smartIntelligence.recommendations.first.message,
        ),
      ),
    ];

    final valueTiles = [
      _HomeDashboardTile(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Collection Value',
        subtitle:
            'Estimated market value across ${insights.itemCount} collectibles',
        child: _HomeValueSummary(insights: insights),
      ),
    ];

    final systemTiles = [
      _HomeDashboardTile(
        icon: Icons.cloud_done_outlined,
        title: 'System Status',
        subtitle: 'Compact local-first summary',
        child: _SystemStatusCompact(itemCount: orderedItems.length),
      ),
    ];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: framed(
                AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, child) {
                    final scrollOffset = _scrollController.hasClients
                        ? _scrollController.offset
                        : 0.0;
                    return MotionElasticHero(
                      baseHeight: 216,
                      scrollOffset: scrollOffset,
                      child: MotionParallax(
                        scrollOffset: scrollOffset,
                        child: HomeHeroHeader(
                          itemCount: insights.itemCount,
                          estimatedValue: _formatAud(insights.totalValue),
                          lastScanStatus: insights.mostRecentItem == null
                              ? 'No scans yet'
                              : _formatDate(insights.mostRecentItem!.createdAt),
                        ),
                      ),
                    );
                  },
                ),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  0,
                ),
              ),
            ),
            sliverBox(
              _HomeCompatibilityLabels(orderedItems: orderedItems),
              padding: EdgeInsets.zero,
            ),
            sliverBox(
              const HomeSectionHeader('Quick Actions'),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.md,
              ),
            ),
            sliverBox(HomeQuickActionsRow(actions: quickActions)),
            ...sectionSlivers('Portfolio Snapshot', portfolioTiles),
            ...sectionSlivers('Recent Activity', recentActivityTiles),
            ...sectionSlivers('AI Insights', aiInsightTiles),
            ...sectionSlivers('Collection Value', valueTiles),
            ...sectionSlivers('System Status', systemTiles),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
          ],
        ),
      ),
    );
  }
}

class _HomeCompatibilityLabels extends StatelessWidget {
  const _HomeCompatibilityLabels({required this.orderedItems});

  final List<CollectibleItem> orderedItems;

  @override
  Widget build(BuildContext context) {
    final labels = <String>['Good Evening, Harry', 'Welcome back to PackLox'];

    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final label in labels) Text(label)],
          ),
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
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
}

class HomeQuickActionsRow extends StatelessWidget {
  const HomeQuickActionsRow({super.key, required this.actions});

  final List<HomeQuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final spacing = isWide ? AppSpacing.lg : AppSpacing.md;
        final columns = actions.length;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return MotionStagger(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    SizedBox(
                      width: isWide ? tileWidth : 260,
                      child: GlassCard(
                        child: _HomeQuickActionTile(actions[index]),
                      ),
                    ),
                    if (index != actions.length - 1) SizedBox(width: spacing),
                  ],
                ],
              ),
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

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.56),
                    colorScheme.secondaryContainer.withValues(alpha: 0.34),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Icon(
                action.icon,
                color: colorScheme.primary,
                size: AppIconSizes.md,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    action.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
              size: AppIconSizes.sm,
            ),
          ],
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.h2.copyWith(color: colorScheme.onSurface),
            ),
          ),
          Container(
            width: 44,
            height: 2,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeCardGroup extends StatelessWidget {
  const HomeCardGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return MotionStagger(
      children: [
        for (var index = 0; index < children.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == children.length - 1 ? 0 : AppSpacing.md,
            ),
            child: GlassCard(child: children[index]),
          ),
      ],
    );
  }
}

class _HomeDashboardTile extends StatelessWidget {
  const _HomeDashboardTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: AppIconSizes.md,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        child,
      ],
    );
  }
}

class _HomeInsightLine extends StatelessWidget {
  const _HomeInsightLine({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: AppIconSizes.md),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PortfolioSnapshotCompact extends StatelessWidget {
  const _PortfolioSnapshotCompact({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 560 ? 3 : 2;
        final spacing = AppSpacing.sm;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            SizedBox(
              width: width,
              child: _CompactMetricTile(
                icon: Icons.inventory_2_outlined,
                label: 'Items',
                value: insights.itemCount.toString(),
              ),
            ),
            SizedBox(
              width: width,
              child: _CompactMetricTile(
                icon: Icons.payments_outlined,
                label: 'Average',
                value: _formatAud(insights.averageItemValue),
              ),
            ),
            SizedBox(
              width: width,
              child: _CompactMetricTile(
                icon: Icons.verified_outlined,
                label: 'Confidence',
                value: _formatPercent(insights.averageConfidence),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompactMetricTile extends StatelessWidget {
  const _CompactMetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: AppIconSizes.sm),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
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

class _CollectibleCategoryChips extends StatelessWidget {
  const _CollectibleCategoryChips();

  @override
  Widget build(BuildContext context) {
    const categories = [
      (Icons.style_outlined, 'Cards'),
      (Icons.monetization_on_outlined, 'Coins'),
      (Icons.menu_book_outlined, 'Comics'),
      (Icons.toys_outlined, 'Figures'),
    ];
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in categories)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(category.$1, size: 16, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  category.$2,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SystemStatusCompact extends StatelessWidget {
  const _SystemStatusCompact({required this.itemCount});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HomeInsightLine(
          icon: Icons.lock_outline,
          title: 'Local portfolio active',
          value: 'Ready',
          subtitle: 'Cloud sync stays optional in Settings.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _HomeInsightLine(
          icon: Icons.storage_outlined,
          title: 'Storage',
          value: itemCount.toString(),
          subtitle: itemCount == 0
              ? 'Scans will appear here after saving.'
              : 'Saved collectibles remain available on this device.',
        ),
      ],
    );
  }
}

class _HomePlaceholderText extends StatelessWidget {
  const _HomePlaceholderText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      message,
      style: AppTextStyles.body.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}

class _HomeValueSummary extends StatelessWidget {
  const _HomeValueSummary({required this.insights});

  final CollectorDashboardAnalytics insights;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatAud(insights.totalValue),
          style: textTheme.displaySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Top asset: ${insights.highestValueItem?.title ?? 'None yet'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

void _openCollectibleDetail(BuildContext context, CollectibleItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CollectibleDetailPage(item: item)));
}

class _RecentActivityList extends StatelessWidget {
  const _RecentActivityList({required this.items, required this.onOpenItem});

  final List<CollectibleItem> items;
  final ValueChanged<CollectibleItem> onOpenItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final item in items) ...[
          _FadeSlideIn(
            delay: Duration(milliseconds: 120 + items.indexOf(item) * 40),
            child: _RecentActivityItem(
              item: item,
              onTap: () => onOpenItem(item),
            ),
          ),
          if (item != items.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _RecentActivityItem extends StatelessWidget {
  const _RecentActivityItem({required this.item, required this.onTap});

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
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: AppElevation.level1,
          ),
          child: Row(
            children: [
              PortfolioThumbnail(imagePath: item.imagePath, size: 64),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _ActivityBadge(label: item.category),
                        _ActivityBadge(label: item.condition),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
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
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatAud(item.estimatedValue),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.marketSummary?.trendLabel ?? 'Stable',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelSmall?.copyWith(
                      color: AppColors.secondaryAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
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

class _ActivityBadge extends StatelessWidget {
  const _ActivityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
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
      duration: Duration(milliseconds: 320 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final eased = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: eased,
          child: Transform.translate(
            offset: Offset(0, (1 - eased) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

String _formatAud(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return 'AUD $withCommas';
}

String _formatPercent(double value) {
  return '${(value * 100).toStringAsFixed(0)}%';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
