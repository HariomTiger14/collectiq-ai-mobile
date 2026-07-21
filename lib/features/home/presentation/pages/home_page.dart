import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum HomePreviewScenario {
  empty('Empty/new collector'),
  defaultData('Default/signed-in'),
  loading('Loading'),
  error('Error/retry'),
  partial('Partial/syncing'),
  guest('Guest fallback');

  const HomePreviewScenario(this.label);

  final String label;

  String get subtitle {
    return switch (this) {
      HomePreviewScenario.empty => 'No saved items and no fake metrics.',
      HomePreviewScenario.defaultData => 'Representative local QA data only.',
      HomePreviewScenario.loading => 'Skeleton state without sample values.',
      HomePreviewScenario.error => 'Retry state without backend calls.',
      HomePreviewScenario.partial => 'Real items with pending valuations.',
      HomePreviewScenario.guest => 'Conditional guest fallback surface.',
    };
  }

  PortfolioState get portfolioState {
    return switch (this) {
      HomePreviewScenario.empty => const PortfolioState(),
      HomePreviewScenario.defaultData => PortfolioState(
        items: _previewItems(includeUnvalued: false),
      ),
      HomePreviewScenario.loading => const PortfolioState(isLoading: true),
      HomePreviewScenario.error => const PortfolioState(
        errorMessage: 'Check your connection and try again.',
      ),
      HomePreviewScenario.partial => PortfolioState(
        items: _previewItems(includeUnvalued: true),
      ),
      HomePreviewScenario.guest => const PortfolioState(),
    };
  }
}

final homePreviewScenarioProvider =
    NotifierProvider<HomePreviewScenarioController, HomePreviewScenario?>(
      HomePreviewScenarioController.new,
    );

class HomePreviewScenarioController extends Notifier<HomePreviewScenario?> {
  @override
  HomePreviewScenario? build() => null;

  void select(HomePreviewScenario? scenario) {
    state = scenario;
  }
}

class HomeStatePreviewScreen extends ConsumerWidget {
  const HomeStatePreviewScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(
      builder: (_) => const HomeStatePreviewScreen(),
      settings: const RouteSettings(name: 'home-state-preview'),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedScenario = ref.watch(homePreviewScenarioProvider);
    return Theme(
      data: AppTheme.dark,
      child: Scaffold(
        backgroundColor: HomeTokens.background,
        appBar: AppBar(
          title: const Text('Home State Preview'),
          backgroundColor: HomeTokens.background,
          foregroundColor: HomeTokens.textPrimary,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                'Choose a local Home state to preview in the app shell.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: HomeTokens.textSecondary,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final scenario in HomePreviewScenario.values) ...[
                _HomePreviewScenarioTile(
                  scenario: scenario,
                  isSelected: selectedScenario == scenario,
                  onTap: () => _selectScenario(context, ref, scenario),
                ),
                const SizedBox(height: HomeTokens.cardGap),
              ],
              const SizedBox(height: AppSpacing.sm),
              _HomePreviewClearTile(
                isSelected: selectedScenario == null,
                onTap: () => _selectScenario(context, ref, null),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectScenario(
    BuildContext context,
    WidgetRef ref,
    HomePreviewScenario? scenario,
  ) {
    ref.read(homePreviewScenarioProvider.notifier).select(scenario);
    ref
        .read(appShellTabControllerProvider.notifier)
        .selectTab(AppShellTabController.homeTab, reason: 'home-preview');
    Navigator.of(context).pop();
  }
}

class _HomePreviewScenarioTile extends StatelessWidget {
  const _HomePreviewScenarioTile({
    required this.scenario,
    required this.isSelected,
    required this.onTap,
  });

  final HomePreviewScenario scenario;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomeActionRow(
      keySeed: 'preview-${scenario.name}',
      icon: isSelected ? Icons.check_circle_rounded : Icons.visibility_outlined,
      title: scenario.label,
      subtitle: scenario.subtitle,
      iconColor: isSelected ? HomeTokens.positive : HomeTokens.accent,
      onTap: onTap,
    );
  }
}

class _HomePreviewClearTile extends StatelessWidget {
  const _HomePreviewClearTile({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomeActionRow(
      keySeed: 'preview-clear',
      icon: isSelected ? Icons.check_circle_rounded : Icons.restart_alt_rounded,
      title: 'Clear preview / return to real data',
      subtitle: 'Use the live local portfolio state again.',
      iconColor: isSelected ? HomeTokens.positive : HomeTokens.warning,
      onTap: onTap,
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({
    this.onScanPressed,
    this.onSampleScanPressed,
    this.onImportPhotoPressed,
    this.onPortfolioPressed,
    this.previewScenario,
    this.qaInitialScrollOffset = 0,
    super.key,
  });

  final VoidCallback? onScanPressed;
  final VoidCallback? onSampleScanPressed;
  final VoidCallback? onImportPhotoPressed;
  final VoidCallback? onPortfolioPressed;
  final HomePreviewScenario? previewScenario;
  final double qaInitialScrollOffset;

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final ScrollController _scrollController;
  bool _scanRequestPending = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: widget.qaInitialScrollOffset,
      keepScrollOffset: false,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScanPressed() {
    if (_scanRequestPending) {
      return;
    }
    _scanRequestPending = true;
    widget.onScanPressed?.call();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scanRequestPending = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePreviewScenario =
        widget.previewScenario ?? ref.watch(homePreviewScenarioProvider);
    final isPreview = activePreviewScenario != null;
    final portfolio = isPreview
        ? activePreviewScenario.portfolioState
        : ref.watch(portfolioControllerProvider);
    final portfolioController = isPreview
        ? null
        : ref.read(portfolioControllerProvider.notifier);
    final homeData = _HomeViewData.fromInsights(
      const CollectorDashboardAnalyticsService().build(portfolio.orderedItems),
    );
    final hasBlockingError = portfolio.errorMessage != null && homeData.isEmpty;
    final isInitialLoading = portfolio.isLoading && homeData.isEmpty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: HomeTokens.background,
        systemNavigationBarDividerColor: HomeTokens.background,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Theme(
        data: AppTheme.dark,
        child: Scaffold(
          backgroundColor: HomeTokens.background,
          body: SafeArea(
            child: HomeStateContainer(
              controller: _scrollController,
              bottomClearance: GlassBottomNavBar.scrollContentClearance(
                context,
              ),
              sections: [
                HomeSection(
                  topPadding: AppSpacing.sm,
                  child: HomeBrandLockup(showAlert: homeData.hasStateAlert),
                ),
                HomeSection(
                  topPadding: AppSpacing.lg,
                  child: HomeTitleBlock(
                    subtitle: _subtitleFor(portfolio, homeData),
                  ),
                ),
                if (isInitialLoading)
                  const HomeSection(
                    topPadding: AppSpacing.xl,
                    child: HomeSkeletonBlock(),
                  )
                else if (hasBlockingError)
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: HomeErrorPanel(
                      message: 'Check your connection and try again.',
                      onRetry: isPreview
                          ? () {}
                          : portfolioController?.loadItems,
                    ),
                  )
                else if (homeData.isEmpty) ...[
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: HomeAuthorityHero(
                      eyebrow: 'New collector',
                      title: 'Your collection is waiting',
                      body:
                          'Start with a scan, then let PackLox build value history from real items.',
                      ctaLabel: 'Add first item',
                      icon: Icons.photo_camera_outlined,
                      onPressed: widget.onScanPressed == null
                          ? null
                          : _handleScanPressed,
                    ),
                  ),
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: _HomeActionStack(
                      actions: [
                        HomeActionRow(
                          keySeed: 'start-first-item',
                          icon: Icons.photo_camera_outlined,
                          title: 'Start with your first item',
                          subtitle: 'Scan or add a collectible to begin.',
                          onTap: widget.onScanPressed == null
                              ? null
                              : _handleScanPressed,
                        ),
                        HomeActionRow(
                          keySeed: 'guided-scan',
                          icon: Icons.add_rounded,
                          title: 'Try a guided scan',
                          subtitle:
                              'Use the scanner to capture details clearly.',
                          iconColor: HomeTokens.categoryMore,
                          onTap:
                              widget.onSampleScanPressed ??
                              (widget.onScanPressed == null
                                  ? null
                                  : _handleScanPressed),
                        ),
                        const HomeActionRow(
                          keySeed: 'supported-categories',
                          icon: Icons.category_outlined,
                          title: 'Browse supported categories',
                          subtitle: 'Cards, coins, figures, and more.',
                          iconColor: HomeTokens.categoryCoins,
                          informational: true,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: HomeAuthorityHero(
                      eyebrow: homeData.hasPartialValuation
                          ? 'Collection overview'
                          : 'Collection overview',
                      title: 'Know what your collection is worth',
                      body:
                          'Track collection health, recent scans, and the next useful action.',
                      ctaLabel: 'Scan next item',
                      icon: Icons.photo_camera_outlined,
                      onPressed: widget.onScanPressed == null
                          ? null
                          : _handleScanPressed,
                    ),
                  ),
                  if (homeData.hasRealMetrics)
                    HomeSection(
                      topPadding: AppSpacing.xl,
                      child: _MetricGrid(data: homeData),
                    ),
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    bottomPadding: AppSpacing.xxl,
                    child: _HomeActionStack(
                      actions: [
                        HomeActionRow(
                          keySeed: 'scan-collectible',
                          icon: Icons.photo_camera_outlined,
                          title: 'Scan a collectible',
                          subtitle:
                              'Identify, value, and protect the next item.',
                          onTap: widget.onScanPressed == null
                              ? null
                              : _handleScanPressed,
                        ),
                        HomeActionRow(
                          keySeed: 'market-insights',
                          icon: Icons.trending_up_rounded,
                          title: 'Market insights',
                          subtitle: homeData.hasValuedItems
                              ? 'Review recent changes across your collection.'
                              : 'Add valuations before insights appear.',
                          iconColor: HomeTokens.categoryFigures,
                          onTap: widget.onPortfolioPressed,
                        ),
                        if (homeData.mostRecentItem != null)
                          HomeActionRow(
                            keySeed: 'recent-scan',
                            icon: Icons.monitor_heart_outlined,
                            title: 'Recent scan',
                            subtitle: homeData.mostRecentItem!.title,
                            iconColor: HomeTokens.categoryMore,
                            onTap: () => _openCollectibleDetail(
                              context,
                              homeData.mostRecentItem!,
                            ),
                          ),
                        if (homeData.hasPartialValuation)
                          HomeActionRow(
                            keySeed: 'partial-valuation',
                            icon: Icons.priority_high_rounded,
                            title: 'Finish collection valuations',
                            subtitle:
                                '${homeData.unvaluedCount} ${homeData.unvaluedCount == 1 ? 'item needs' : 'items need'} a real valuation.',
                            iconColor: HomeTokens.warning,
                            onTap: widget.onPortfolioPressed,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _subtitleFor(PortfolioState portfolio, _HomeViewData data) {
  if (portfolio.isLoading && data.isEmpty) {
    return 'Preparing your collection overview.';
  }
  if (portfolio.errorMessage != null && data.isEmpty) {
    return 'We could not refresh your collection overview.';
  }
  if (data.isEmpty) {
    return 'Start your collection with a clear first scan.';
  }
  if (data.hasPartialValuation) {
    return 'Some collection values are still pending.';
  }
  return 'Your collection overview, recent scans, and next actions.';
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final metrics = <Widget>[
      if (data.hasValuedItems)
        HomeMetricTile(
          label: 'Collection value',
          value: _formatCurrency(data.totalValuedAmount),
          supportingText: data.hasPartialValuation
              ? 'Partial valuation'
              : 'Estimated trend',
          supportingColor: data.hasPartialValuation
              ? HomeTokens.warning
              : HomeTokens.positive,
        ),
      HomeMetricTile(
        label: 'Collection items',
        value: '${data.itemCount}',
        supportingText: data.hasPartialValuation
            ? '${data.valuedItemCount} valued'
            : 'Verified items',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 360 ? 2 : 1;
        final width = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - HomeTokens.cardGap) / 2;
        return Wrap(
          spacing: HomeTokens.cardGap,
          runSpacing: HomeTokens.cardGap,
          children: [
            for (final metric in metrics) SizedBox(width: width, child: metric),
          ],
        );
      },
    );
  }
}

class _HomeActionStack extends StatelessWidget {
  const _HomeActionStack({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: HomeTokens.cardGap),
          actions[i],
        ],
      ],
    );
  }
}

class _HomeViewData {
  const _HomeViewData({
    required this.items,
    required this.itemCount,
    required this.totalValuedAmount,
    required this.valuedItemCount,
    required this.unvaluedCount,
    required this.recentItems,
  });

  final List<CollectibleItem> items;
  final int itemCount;
  final double totalValuedAmount;
  final int valuedItemCount;
  final int unvaluedCount;
  final List<CollectibleItem> recentItems;

  bool get isEmpty => itemCount == 0;
  bool get hasValuedItems => valuedItemCount > 0;
  bool get hasPartialValuation => itemCount > 0 && unvaluedCount > 0;
  bool get hasRealMetrics => itemCount > 0;
  bool get hasStateAlert => hasPartialValuation;
  CollectibleItem? get mostRecentItem =>
      recentItems.isEmpty ? null : recentItems.first;

  factory _HomeViewData.fromInsights(CollectorDashboardAnalytics insights) {
    final items = insights.items;
    final valuedItems = items.where(_hasDisplayValue).toList(growable: false);
    final totalValuedAmount = valuedItems.fold<double>(
      0,
      (sum, item) => sum + item.estimatedValue,
    );
    return _HomeViewData(
      items: items,
      itemCount: items.length,
      totalValuedAmount: totalValuedAmount,
      valuedItemCount: valuedItems.length,
      unvaluedCount: items.length - valuedItems.length,
      recentItems: items,
    );
  }
}

void _openCollectibleDetail(BuildContext context, CollectibleItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CollectibleDetailPage(item: item)));
}

bool _hasDisplayValue(CollectibleItem item) {
  return item.estimatedValue > 0 ||
      item.valuationStatus == ValuationStatus.marketEstimated ||
      item.valuationStatus == ValuationStatus.aiEstimated;
}

String _formatCurrency(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

List<CollectibleItem> _previewItems({required bool includeUnvalued}) {
  final now = DateTime(2026, 7, 20, 12);
  final items = [
    _previewItem(
      id: 'preview-card',
      title: 'Preview Charizard',
      category: 'Trading Card',
      value: 1850,
      condition: 'Near Mint',
      createdAt: now,
      valuationStatus: ValuationStatus.marketEstimated,
    ),
    _previewItem(
      id: 'preview-coin',
      title: 'Preview Silver Eagle',
      category: 'Coin',
      value: 300,
      condition: 'Mint',
      createdAt: now.subtract(const Duration(days: 1)),
      valuationStatus: ValuationStatus.marketEstimated,
    ),
    _previewItem(
      id: 'preview-comic',
      title: 'Preview Variant Comic',
      category: 'Comic',
      value: 125,
      condition: 'Very Fine',
      createdAt: now.subtract(const Duration(days: 2)),
      valuationStatus: ValuationStatus.marketEstimated,
    ),
  ];

  if (includeUnvalued) {
    items.add(
      _previewItem(
        id: 'preview-pending',
        title: 'Preview Pending Figure',
        category: 'Figure',
        value: 0,
        condition: 'Excellent',
        createdAt: now.subtract(const Duration(days: 3)),
        valuationStatus: ValuationStatus.unavailable,
      ),
    );
  }

  return items;
}

CollectibleItem _previewItem({
  required String id,
  required String title,
  required String category,
  required double value,
  required String condition,
  required DateTime createdAt,
  required ValuationStatus valuationStatus,
}) {
  return CollectibleItem(
    id: id,
    title: title,
    category: category,
    estimatedValue: value,
    confidence: 0.92,
    condition: condition,
    recommendation: 'Preview-only design QA data.',
    imagePath: 'sample://$id',
    createdAt: createdAt,
    valuationStatus: valuationStatus,
    valuationSource: 'preview',
  );
}
