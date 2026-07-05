import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/home/home_ui.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/glass_card.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
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
    _updateHeroScrollOffset();
  }

  void _updateHeroScrollOffset() {
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
    final orderedItems = portfolio.orderedItems;
    final recentItems = orderedItems.take(3).toList();
    final bool isPortfolioEmpty = orderedItems.isEmpty;
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
        subtitle: 'Identify a collectible',
        onTap: widget.onScanPressed,
      ),
      HomeQuickAction(
        icon: Icons.add_box_outlined,
        title: 'Add Manually',
        subtitle: 'Soon',
      ),
      HomeQuickAction(
        icon: Icons.manage_search_outlined,
        title: 'Search Database',
        subtitle: 'Soon',
      ),
      HomeQuickAction(
        icon: Icons.upload_file_outlined,
        title: 'Import Collection',
        subtitle: 'Soon',
      ),
    ];

    final portfolioTiles = [
      _HomeDashboardTile(
        icon: Icons.inventory_2_outlined,
        title: 'Portfolio Snapshot',
        subtitle: isPortfolioEmpty
            ? 'Your collection starts with your first scan.'
            : '${insights.itemCount} saved collectibles',
        child: _PortfolioSnapshotCompact(insights: insights),
      ),
    ];

    final recentActivityTiles = [
      _HomeDashboardTile(
        icon: Icons.history_outlined,
        title: 'Recent Activity',
        subtitle: isPortfolioEmpty
            ? 'Your latest discoveries will appear here.'
            : '${recentItems.length} latest saved',
        child: isPortfolioEmpty
            ? const _HomePlaceholderText(
                'Your latest discoveries will appear here.',
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
        title: 'AI Insight',
        subtitle: isPortfolioEmpty
            ? 'Valuation and rarity guidance'
            : insights.collectionHealth.label,
        child: _HomeInsightLine(
          icon: Icons.psychology_alt_outlined,
          title: 'AI Insight',
          value: isPortfolioEmpty
              ? 'Ready'
              : _formatPercent(insights.averageConfidence),
          subtitle: isPortfolioEmpty
              ? 'Scan one collectible to unlock valuation, rarity clues, and collection recommendations.'
              : insights.insights.first.message,
        ),
      ),
    ];

    final valueTiles = [
      _HomeDashboardTile(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Collection Value',
        subtitle: 'Estimated value and top asset',
        child: _HomeValueSummary(insights: insights),
      ),
    ];

    final systemTiles = [
      _HomeDashboardTile(
        icon: Icons.cloud_done_outlined,
        title: 'System Status',
        subtitle: 'Local-first essentials',
        child: _SystemStatusCompact(itemCount: orderedItems.length),
      ),
    ];

    final starterCategoryTiles = [
      const _HomeDashboardTile(
        icon: Icons.category_outlined,
        title: 'Starter Categories',
        subtitle: 'Collector lanes PackLox understands',
        child: _CollectibleCategoryChips(),
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
                      baseHeight: 216,
                      scrollOffset: scrollOffset,
                      child: MotionParallax(
                        scrollOffset: scrollOffset,
                        child: HomeHeroHeader(
                          itemCount: insights.itemCount,
                          estimatedValue: _formatAud(insights.totalValue),
                          lastScanStatus: insights.mostRecentItem == null
                              ? 'Ready to scan'
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
            ...sectionSlivers('Starter Categories', starterCategoryTiles),
            ...sectionSlivers('AI Insight', aiInsightTiles),
            ...sectionSlivers('Collection Value', valueTiles),
            ...sectionSlivers('System Status', systemTiles),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
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
                      child: _homeSurface(
                        context,
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
    final isEnabled = action.onTap != null;

    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: isEnabled ? 1 : 0.72,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withValues(alpha: 0.56),
                          colorScheme.secondaryContainer.withValues(
                            alpha: 0.34,
                          ),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Icon(
                      action.icon,
                      color: colorScheme.primary,
                      size: AppIconSizes.sm,
                    ),
                  ),
                  const Spacer(),
                  if (isEnabled)
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                      size: AppIconSizes.sm,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        'Soon',
                        style: AppTextStyles.caption.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3.copyWith(color: colorScheme.onSurface),
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
            child: _homeSurface(context, child: children[index]),
          ),
      ],
    );
  }
}

Widget _homeSurface(BuildContext context, {required Widget child}) {
  return GlassCard(child: child);
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
                label: 'Total items',
                value: insights.itemCount.toString(),
              ),
            ),
            SizedBox(
              width: width,
              child: _CompactMetricTile(
                icon: Icons.category_outlined,
                label: 'Categories',
                value: _categoryCount(insights).toString(),
              ),
            ),
            SizedBox(
              width: width,
              child: _CompactMetricTile(
                icon: Icons.payments_outlined,
                label: 'Estimated value',
                value: _formatAud(insights.totalValue),
              ),
            ),
            SizedBox(
              width: width,
              child: _CompactMetricTile(
                icon: Icons.workspace_premium_outlined,
                label: 'Top asset',
                value: insights.highestValueItem?.title ?? 'None yet',
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
      (Icons.watch_outlined, 'Watches'),
      (Icons.mark_email_unread_outlined, 'Stamps'),
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
    return _CompactStatusList(
      rows: [
        _StatusRowData(
          icon: Icons.lock_outline,
          label: 'Portfolio',
          value: 'Local',
        ),
        _StatusRowData(
          icon: Icons.storage_outlined,
          label: 'Storage',
          value: itemCount == 0 ? 'Ready' : '$itemCount items',
        ),
        const _StatusRowData(
          icon: Icons.sync_outlined,
          label: 'Sync',
          value: 'Local-first',
        ),
      ],
    );
  }
}

class _StatusRowData {
  const _StatusRowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

class _CompactStatusList extends StatelessWidget {
  const _CompactStatusList({required this.rows});

  final List<_StatusRowData> rows;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        for (var index = 0; index < rows.length; index++) ...[
          Row(
            children: [
              Icon(rows[index].icon, color: colorScheme.primary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  rows[index].label,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                rows[index].value,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (index != rows.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(height: 1),
            ),
        ],
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
          'Month change: ${_formatMonthlyChange(insights)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleSmall?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
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

int _categoryCount(CollectorDashboardAnalytics insights) {
  return insights.categoryDistribution.values
      .where((count) => count > 0)
      .length;
}

String _formatMonthlyChange(CollectorDashboardAnalytics insights) {
  final snapshots = insights.monthlySnapshots;
  if (snapshots.length < 2) {
    return 'No trend yet';
  }

  final previous = snapshots[snapshots.length - 2].totalValue;
  final current = snapshots.last.totalValue;
  final change = current - previous;
  final sign = change >= 0 ? '+' : '-';
  return '$sign${_formatAud(change.abs())}';
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
