import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/assets/packlox_assets.dart';
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
          floatingActionButton: widget.onScanPressed == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(
                    bottom: GlassBottomNavBar.bodyContentInset(context),
                  ),
                  child: FloatingActionButton(
                    key: const ValueKey('home-floating-scan-button'),
                    heroTag: 'home-floating-scan',
                    tooltip: 'Add item',
                    onPressed: _handleScanPressed,
                    backgroundColor: HomeTokens.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.photo_camera_outlined),
                  ),
                ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: SafeArea(
            bottom: false,
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
                    child: _CategoryExplorer(
                      onCategoryTap: (category) => _openCategoryOverview(
                        context,
                        category,
                        onScanPressed: widget.onScanPressed == null
                            ? null
                            : _handleScanPressed,
                      ),
                    ),
                  ),
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: _RecentItemsPreview(
                      data: homeData,
                      onOpenPortfolio: widget.onPortfolioPressed,
                      onScanPressed: widget.onScanPressed == null
                          ? null
                          : _handleScanPressed,
                    ),
                  ),
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: _InsightsPreview(
                      data: homeData,
                      onOpenInsights: widget.onPortfolioPressed,
                    ),
                  ),
                  const HomeSection(
                    topPadding: AppSpacing.xl,
                    bottomPadding: AppSpacing.xxl,
                    child: _ProviderFooter(),
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
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: _CategoryExplorer(
                      onCategoryTap: (category) => _openCategoryOverview(
                        context,
                        category,
                        onScanPressed: widget.onScanPressed == null
                            ? null
                            : _handleScanPressed,
                      ),
                    ),
                  ),
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: _RecentItemsPreview(
                      data: homeData,
                      onOpenPortfolio: widget.onPortfolioPressed,
                    ),
                  ),
                  HomeSection(
                    topPadding: AppSpacing.xl,
                    child: _InsightsPreview(
                      data: homeData,
                      onOpenInsights: widget.onPortfolioPressed,
                    ),
                  ),
                  HomeSection(
                    topPadding: AppSpacing.xl,
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
                  const HomeSection(
                    topPadding: AppSpacing.xl,
                    bottomPadding: AppSpacing.xxl,
                    child: _ProviderFooter(),
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

class _CategoryExplorer extends StatelessWidget {
  const _CategoryExplorer({required this.onCategoryTap});

  final ValueChanged<_SupportedCategory> onCategoryTap;

  @override
  Widget build(BuildContext context) {
    return HomeSectionSurface(
      keySeed: 'category-explorer',
      title: 'Supported categories',
      child: HomeCategoryGrid(
        categories: [
          for (final category in _supportedCategories)
            HomeCategoryTile(
              label: category.shortLabel,
              icon: category.icon,
              semanticMeaning: category.description,
              iconColor: category.color,
              assetPath: category.assetPath,
              onTap: () => onCategoryTap(category),
            ),
        ],
      ),
    );
  }
}

class _RecentItemsPreview extends StatelessWidget {
  const _RecentItemsPreview({
    required this.data,
    this.onOpenPortfolio,
    this.onScanPressed,
  });

  final _HomeViewData data;
  final VoidCallback? onOpenPortfolio;
  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
    final recentItems = data.recentItems.take(3).toList(growable: false);
    return HomeSectionSurface(
      keySeed: 'recent-items-preview',
      title: 'Recent items',
      actionLabel: data.isEmpty ? null : 'View all',
      onAction: data.isEmpty ? null : onOpenPortfolio,
      child: recentItems.isEmpty
          ? HomeActionRow(
              keySeed: 'recent-items-empty',
              icon: Icons.photo_camera_outlined,
              title: 'No items yet',
              subtitle: 'Start with your first scan.',
              onTap: onScanPressed,
            )
          : Column(
              children: [
                for (var index = 0; index < recentItems.length; index++) ...[
                  if (index > 0) const SizedBox(height: HomeTokens.cardGap),
                  HomeRecentItemCard(
                    id: recentItems[index].id,
                    title: recentItems[index].title,
                    category: recentItems[index].category,
                    imagePath:
                        recentItems[index].cloudImageUrl ??
                        recentItems[index].imagePath,
                    valueLabel: _valueLabelFor(recentItems[index]),
                    valueUnavailable: !_hasDisplayValue(recentItems[index]),
                    condition: recentItems[index].condition,
                    addedLabel: _confidenceLabel(recentItems[index]),
                    onTap: () =>
                        _openCollectibleDetail(context, recentItems[index]),
                  ),
                ],
              ],
            ),
    );
  }
}

class _InsightsPreview extends StatelessWidget {
  const _InsightsPreview({required this.data, this.onOpenInsights});

  final _HomeViewData data;
  final VoidCallback? onOpenInsights;

  @override
  Widget build(BuildContext context) {
    return HomeSectionSurface(
      keySeed: 'insights-preview',
      title: 'Insights preview',
      actionLabel: data.isEmpty ? null : 'Open',
      onAction: onOpenInsights,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth >= 330 ? 3 : 1;
          final compact = columns > 1;
          final width = columns == 1
              ? constraints.maxWidth
              : (constraints.maxWidth - HomeTokens.cardGap * (columns - 1)) /
                    columns;
          final topCategory = data.topCategories.isEmpty
              ? 'No category'
              : data.topCategories.first.label;
          final attentionLabel = data.unvaluedCount > 0
              ? '${data.unvaluedCount} pending'
              : data.itemCount > 0
              ? 'Healthy'
              : 'No items';
          return Wrap(
            spacing: HomeTokens.cardGap,
            runSpacing: HomeTokens.cardGap,
            children: [
              SizedBox(
                width: width,
                child: HomeMetricTile(
                  label: 'Collection value',
                  value: data.hasValuedItems
                      ? _formatCurrency(data.totalValuedAmount)
                      : 'Pending',
                  supportingText: data.hasValuedItems
                      ? '${data.valuedItemCount} valued'
                      : 'Add valued items',
                  compact: compact,
                ),
              ),
              SizedBox(
                width: width,
                child: HomeMetricTile(
                  label: 'Top category',
                  value: topCategory,
                  supportingText: data.topCategories.length > 1
                      ? '${data.topCategories.length} active'
                      : 'Category mix',
                  supportingColor: HomeTokens.categoryCards,
                  compact: compact,
                ),
              ),
              SizedBox(
                width: width,
                child: HomeMetricTile(
                  label: 'Collection health',
                  value: attentionLabel,
                  supportingText: data.hasPartialValuation
                      ? 'Needs valuation'
                      : 'Ready to build',
                  supportingColor: data.hasPartialValuation
                      ? HomeTokens.warning
                      : HomeTokens.positive,
                  compact: compact,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProviderFooter extends StatelessWidget {
  const _ProviderFooter();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return HomeSectionSurface(
      keySeed: 'provider-footer',
      title: 'Pricing sources',
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _ProviderPill(label: 'PriceCharting', tone: HomeTokens.accent),
          _ProviderPill(label: 'KicksDB', tone: HomeTokens.categoryMore),
          _ProviderPill(
            label: 'WatchCharts future',
            tone: HomeTokens.categoryCoins,
          ),
          Text(
            'No AI-invented values.',
            style: textTheme.labelMedium?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderPill extends StatelessWidget {
  const _ProviderPill({required this.label, required this.tone});

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: tone.withValues(alpha: .34)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: HomeTokens.textPrimary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _CategoryOverviewScreen extends StatelessWidget {
  const _CategoryOverviewScreen({required this.category, this.onScanPressed});

  final _SupportedCategory category;
  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context) {
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
            bottom: false,
            child: HomeStateContainer(
              storageKey: 'category-overview-${category.key}',
              sections: [
                HomeSection(
                  child: Row(
                    children: [
                      IconButton(
                        key: const ValueKey('category-overview-back'),
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: HomeTokens.textPrimary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      const HomeBrandLockup(),
                    ],
                  ),
                ),
                HomeSection(
                  topPadding: AppSpacing.lg,
                  child: HomeAuthorityHero(
                    eyebrow: 'Category overview',
                    title: category.label,
                    body: category.description,
                    ctaLabel: 'Scan ${category.shortLabel}',
                    icon: category.icon,
                    onPressed: onScanPressed == null
                        ? null
                        : () {
                            Navigator.of(context).maybePop();
                            onScanPressed?.call();
                          },
                  ),
                ),
                HomeSection(
                  topPadding: AppSpacing.xl,
                  child: HomeSectionSurface(
                    keySeed: 'category-provider-${category.key}',
                    title: 'Supported providers',
                    child: Text(
                      category.providers,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HomeTokens.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
                HomeSection(
                  topPadding: AppSpacing.xl,
                  bottomPadding: AppSpacing.xxl,
                  child: HomeSectionSurface(
                    keySeed: 'category-examples-${category.key}',
                    title: 'Example items',
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final example in category.examples)
                          _ProviderPill(label: example, tone: category.color),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportedCategory {
  const _SupportedCategory({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.providers,
    required this.examples,
    required this.icon,
    required this.assetPath,
    required this.color,
  });

  final String key;
  final String label;
  final String shortLabel;
  final String description;
  final String providers;
  final List<String> examples;
  final IconData icon;
  final String assetPath;
  final Color color;
}

class _CategoryCount {
  const _CategoryCount(this.label, this.count);

  final String label;
  final int count;
}

const _supportedCategories = [
  _SupportedCategory(
    key: 'cards',
    label: 'Trading Cards',
    shortLabel: 'Cards',
    description:
        'PackLox supports trading card categories where trusted catalog data is connected.',
    providers:
        'PriceCharting is connected for Pokémon, MTG, Yu-Gi-Oh, and One Piece card catalogs.',
    examples: ['Pokémon', 'MTG', 'Yu-Gi-Oh'],
    icon: Icons.style_outlined,
    assetPath: PackLoxAssets.categoryCards,
    color: HomeTokens.categoryCards,
  ),
  _SupportedCategory(
    key: 'pokemon',
    label: 'Pokémon Cards',
    shortLabel: 'Pokémon',
    description: 'Cards matched against trusted catalog data where available.',
    providers: 'PriceCharting is connected. TCGplayer is a future provider.',
    examples: ['Pikachu', 'Charizard', 'Trainer cards'],
    icon: Icons.style_outlined,
    assetPath: PackLoxAssets.categoryCards,
    color: HomeTokens.categoryCards,
  ),
  _SupportedCategory(
    key: 'mtg',
    label: 'Magic: The Gathering',
    shortLabel: 'MTG',
    description: 'Trading cards with deterministic catalog matching.',
    providers:
        'PriceCharting is connected. Specialist trading card sources may be added later.',
    examples: ['Set cards', 'Foils', 'Promos'],
    icon: Icons.auto_awesome_outlined,
    assetPath: PackLoxAssets.categoryCards,
    color: HomeTokens.categoryCards,
  ),
  _SupportedCategory(
    key: 'yugioh',
    label: 'Yu-Gi-Oh! Cards',
    shortLabel: 'Yu-Gi-Oh',
    description: 'Card identity, set, and number driven pricing checks.',
    providers: 'PriceCharting is connected for catalog-backed valuations.',
    examples: ['Monsters', 'Spells', 'Collector rares'],
    icon: Icons.style_outlined,
    assetPath: PackLoxAssets.categoryCards,
    color: HomeTokens.categoryCards,
  ),
  _SupportedCategory(
    key: 'one-piece',
    label: 'One Piece Cards',
    shortLabel: 'One Piece',
    description: 'Modern card catalog matching with clear unavailable states.',
    providers: 'PriceCharting is connected for supported catalog entries.',
    examples: ['Leaders', 'Alt arts', 'Promos'],
    icon: Icons.style_outlined,
    assetPath: PackLoxAssets.categoryCards,
    color: HomeTokens.categoryCards,
  ),
  _SupportedCategory(
    key: 'video-games',
    label: 'Video Games',
    shortLabel: 'Video Games',
    description: 'Games and editions with catalog-backed PriceCharting values.',
    providers: 'PriceCharting is connected for video games.',
    examples: ['Cartridges', 'Discs', 'Complete editions'],
    icon: Icons.sports_esports_outlined,
    assetPath: PackLoxAssets.categoryMore,
    color: HomeTokens.categoryMore,
  ),
  _SupportedCategory(
    key: 'comics',
    label: 'Comics',
    shortLabel: 'Comics',
    description:
        'Comic values use stricter identity checks for series, issue, and title confidence.',
    providers:
        'PriceCharting API is connected. Weak issue or homage-style matches are rejected.',
    examples: ['Issue number', 'Series title', 'Cover year'],
    icon: Icons.menu_book_outlined,
    assetPath: PackLoxAssets.categoryMore,
    color: HomeTokens.categoryFigures,
  ),
  _SupportedCategory(
    key: 'lego',
    label: 'LEGO',
    shortLabel: 'LEGO',
    description:
        'Building sets can be valued when PackLox can identify the exact set.',
    providers:
        'PriceCharting API is connected with set identity checks before showing a value.',
    examples: ['75192 Falcon', 'Retired sets', 'Sealed sets'],
    icon: Icons.extension_outlined,
    assetPath: PackLoxAssets.categoryMore,
    color: HomeTokens.categoryMore,
  ),
  _SupportedCategory(
    key: 'funko-pop',
    label: 'Funko Pop',
    shortLabel: 'Funko',
    description:
        'Vinyl figures can be priced when PackLox can distinguish the exact variant.',
    providers:
        'PriceCharting API is connected. Variant-sensitive matches use stricter trust checks.',
    examples: ['Spider-Man', 'Metallic variants', 'Numbered figures'],
    icon: Icons.smart_toy_outlined,
    assetPath: PackLoxAssets.categoryFigures,
    color: HomeTokens.categoryFigures,
  ),
  _SupportedCategory(
    key: 'coins',
    label: 'Coins',
    shortLabel: 'Coins',
    description:
        'Numismatic items can be valued when year, mint, and coin identity are clear.',
    providers:
        'PriceCharting API is connected. PackLox avoids values when identity evidence is weak.',
    examples: ['Lincoln cents', 'Morgan dollars', 'Graded coins'],
    icon: Icons.album_outlined,
    assetPath: PackLoxAssets.categoryCoins,
    color: HomeTokens.categoryCoins,
  ),
  _SupportedCategory(
    key: 'sports-cards',
    label: 'Sports Cards',
    shortLabel: 'Sports',
    description:
        'Sports card pricing needs player, year, set, or card number evidence.',
    providers:
        'PriceCharting API is connected with stricter identity checks for sports card matches.',
    examples: ['Player', 'Set/year', 'Card number'],
    icon: Icons.sports_basketball_outlined,
    assetPath: PackLoxAssets.categoryCards,
    color: HomeTokens.categoryCards,
  ),
  _SupportedCategory(
    key: 'sneakers',
    label: 'Sneakers / Streetwear',
    shortLabel: 'Sneakers',
    description:
        'Sneaker and streetwear values are checked against specialist sneaker market data.',
    providers:
        'KicksDB is connected for sneaker and streetwear pricing where a trusted market match is found.',
    examples: ['Nike', 'Jordan', 'StockX-backed comps'],
    icon: Icons.directions_walk_outlined,
    assetPath: PackLoxAssets.categoryFigures,
    color: HomeTokens.categoryFigures,
  ),
];

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
  List<_CategoryCount> get topCategories {
    final counts = <String, int>{};
    for (final item in items) {
      final label = item.category.trim().isEmpty
          ? 'Uncategorised'
          : item.category;
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        final countCompare = b.value.compareTo(a.value);
        return countCompare == 0 ? a.key.compareTo(b.key) : countCompare;
      });
    return [
      for (final entry in sorted.take(3))
        _CategoryCount(entry.key, entry.value),
    ];
  }

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

void _openCategoryOverview(
  BuildContext context,
  _SupportedCategory category, {
  VoidCallback? onScanPressed,
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => _CategoryOverviewScreen(
        category: category,
        onScanPressed: onScanPressed,
      ),
    ),
  );
}

bool _hasDisplayValue(CollectibleItem item) {
  return item.estimatedValue > 0 ||
      item.valuationStatus == ValuationStatus.marketEstimated ||
      item.valuationStatus == ValuationStatus.aiEstimated;
}

String _valueLabelFor(CollectibleItem item) {
  if (!_hasDisplayValue(item)) {
    return 'No price';
  }
  return _formatCurrency(item.estimatedValue);
}

String _confidenceLabel(CollectibleItem item) {
  final confidence = (item.confidence * 100).round().clamp(0, 100);
  if (confidence <= 0) {
    return 'Confidence pending';
  }
  return 'Confidence $confidence%';
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
