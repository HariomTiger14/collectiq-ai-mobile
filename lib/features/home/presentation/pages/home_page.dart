import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/portfolio_snapshot.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/home/presentation/controllers/home_dashboard_providers.dart';
import 'package:collectiq_ai/features/home/presentation/controllers/portfolio_history_controller.dart';
import 'package:collectiq_ai/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:collectiq_ai/features/notifications/presentation/pages/notification_inbox_screen.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_focus_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
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

  void _openNotificationInbox(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationInboxScreen(),
      ),
    );
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
    // Real value history + movers come from persisted daily snapshots. Skip in
    // preview/QA mode (the provider writes snapshots) so previews stay offline
    // and deterministic.
    final performance = isPreview
        ? null
        : ref
              .watch(portfolioPerformanceProvider(portfolio.items))
              .asData
              ?.value;
    final triggeredAlertCount = isPreview
        ? 0
        : ref.watch(homeTriggeredAlertCountProvider).asData?.value ?? 0;
    final homeData = _HomeViewData.fromInsights(
      const CollectorDashboardAnalyticsService().build(portfolio.orderedItems),
      performance: performance,
      triggeredAlertCount: triggeredAlertCount,
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
                  child: HomeBrandLockup(
                    showAlert: homeData.hasRealMetrics,
                    alertCount: isPreview
                        ? homeData.triggeredAlertCount
                        : (ref
                                  .watch(unreadNotificationCountProvider)
                                  .asData
                                  ?.value ??
                              0),
                    onAlertPressed: () => _openNotificationInbox(context),
                  ),
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
                    topPadding: AppSpacing.lg,
                    child: _PortfolioValueHero(
                      data: homeData,
                      onReview:
                          widget.onPortfolioPressed ??
                          (widget.onScanPressed == null
                              ? null
                              : _handleScanPressed),
                    ),
                  ),
                  if (homeData.hasAttention)
                    HomeSection(
                      topPadding: AppSpacing.lg,
                      child: _AttentionStrip(
                        data: homeData,
                        onTap: widget.onPortfolioPressed == null
                            ? null
                            : () {
                                if (homeData.unvaluedCount > 0) {
                                  ref
                                      .read(portfolioFocusProvider.notifier)
                                      .request(PortfolioFocus.needsValuation);
                                }
                                widget.onPortfolioPressed!();
                              },
                      ),
                    ),
                  if (homeData.hasMovers)
                    HomeSection(
                      topPadding: AppSpacing.xl,
                      child: _PortfolioMoversSection(data: homeData),
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
                    child: _CollectionHealthSection(data: homeData),
                  ),
                  if (homeData.mostRecentItem != null)
                    HomeSection(
                      topPadding: AppSpacing.xl,
                      child: _HomeActionStack(
                        actions: [
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
    if (data.hasValuedItems) {
      return 'Here\'s how your collection is tracking.';
    }
    return 'Add a valuation to start tracking value.';
  }
  return 'All ${data.itemCount} ${data.itemCount == 1 ? 'item is' : 'items are'} valued and protected.';
}

class _PortfolioValueHero extends StatefulWidget {
  const _PortfolioValueHero({required this.data, this.onReview});

  final _HomeViewData data;
  final VoidCallback? onReview;

  @override
  State<_PortfolioValueHero> createState() => _PortfolioValueHeroState();
}

class _PortfolioValueHeroState extends State<_PortfolioValueHero> {
  _HomePeriod _period = _HomePeriod.month1;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final textTheme = Theme.of(context).textTheme;
    final hasValue = data.hasValuedItems;
    final total = data.itemCount;
    final trusted = data.valuedItemCount;
    final review = data.unvaluedCount;

    final series = data.valueSeries;
    final hasHistory = series.length >= 2;
    final historyDays = hasHistory
        ? series.last.date.difference(series.first.date).inDays
        : 0;
    final effectivePeriod = _isPeriodAvailable(_period, historyDays)
        ? _period
        : _HomePeriod.values.lastWhere(
            (period) => _isPeriodAvailable(period, historyDays),
            orElse: () => _HomePeriod.max,
          );
    final windowPoints = hasHistory
        ? _pointsForPeriod(series, effectivePeriod)
        : const <TrendSnapshot>[];
    final showChart = windowPoints.length >= 2;

    final baseline = showChart ? windowPoints.first.totalValue : 0.0;
    final latest = showChart
        ? windowPoints.last.totalValue
        : data.totalValuedAmount;
    final change = latest - baseline;
    final percent = baseline == 0 ? 0.0 : change / baseline;
    final isUp = change >= 0;

    final String deltaText;
    // The period ("1M") renders as a quiet suffix so the change reads first.
    final String? deltaPeriodLabel;
    final Color deltaColor;
    final IconData deltaIcon;
    if (!hasValue) {
      deltaText = 'Awaiting first valuation';
      deltaPeriodLabel = null;
      deltaColor = HomeTokens.textSecondary;
      deltaIcon = Icons.timeline_rounded;
    } else if (!showChart) {
      deltaText = 'Building value history';
      deltaPeriodLabel = null;
      deltaColor = HomeTokens.textSecondary;
      deltaIcon = Icons.timeline_rounded;
    } else {
      deltaText =
          '${_signedCurrency(change)} · ${(percent.abs() * 100).toStringAsFixed(1)}%';
      deltaPeriodLabel = effectivePeriod.label;
      deltaColor = isUp ? HomeTokens.positive : HomeTokens.negative;
      deltaIcon = isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded;
    }

    return HomeSurface(
      keyPrefix: 'home',
      keySeed: 'portfolio-value-hero',
      semanticLabel: hasValue
          ? 'Portfolio value ${_formatCurrency(data.totalValuedAmount)}'
          : 'Portfolio value pending',
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      radius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portfolio value',
            style: textTheme.labelLarge?.copyWith(
              color: const Color(0xFF67B6FF),
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasValue
                ? _formatCurrency(data.totalValuedAmount)
                : 'Add valued items',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: HomeTokens.textPrimary,
              fontSize: hasValue ? 40 : 28,
              fontWeight: FontWeight.w900,
              height: 1,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(deltaIcon, size: 16, color: deltaColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: deltaText,
                    style: textTheme.bodyMedium?.copyWith(
                      color: deltaColor,
                      fontWeight: FontWeight.w800,
                    ),
                    children: deltaPeriodLabel == null
                        ? null
                        : [
                            TextSpan(
                              text: '  $deltaPeriodLabel',
                              style: textTheme.bodyMedium?.copyWith(
                                color: HomeTokens.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (showChart) ...[
            const SizedBox(height: 16),
            _GainLossChart(
              key: const ValueKey('home-value-hero-trend'),
              values: [for (final point in windowPoints) point.totalValue],
              baseline: baseline,
            ),
            const SizedBox(height: 8),
            _PeriodSelector(
              selected: effectivePeriod,
              historyDays: historyDays,
              onSelected: (period) => setState(() => _period = period),
            ),
          ],
          const SizedBox(height: 18),
          const Divider(height: 1, thickness: 1, color: HomeTokens.border),
          const SizedBox(height: 14),
          Text(
            '$trusted of $total items trusted',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _TrustBar(trusted: trusted, review: review),
          const SizedBox(height: 14),
          SizedBox(
            key: const ValueKey('home-value-hero-cta'),
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: widget.onReview,
              icon: const Icon(Icons.inventory_2_outlined, size: 19),
              label: const Text('Review portfolio'),
              style: FilledButton.styleFrom(
                backgroundColor: HomeTokens.accentStrong,
                disabledBackgroundColor: HomeTokens.accentStrong.withValues(
                  alpha: .38,
                ),
                foregroundColor: HomeTokens.textPrimary,
                disabledForegroundColor: HomeTokens.textPrimary.withValues(
                  alpha: .68,
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gain/loss trend: area is filled green where the value sits at or above the
/// period-start baseline and red where it sits below it.
class _GainLossChart extends StatelessWidget {
  const _GainLossChart({
    required this.values,
    required this.baseline,
    super.key,
  });

  final List<double> values;
  final double baseline;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return const SizedBox(height: 84);
    }
    return SizedBox(
      height: 84,
      width: double.infinity,
      child: CustomPaint(
        painter: _GainLossPainter(values: values, baseline: baseline),
      ),
    );
  }
}

class _GainLossPainter extends CustomPainter {
  const _GainLossPainter({required this.values, required this.baseline});

  final List<double> values;
  final double baseline;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) {
      return;
    }
    var minValue = baseline;
    var maxValue = baseline;
    for (final value in values) {
      if (value < minValue) minValue = value;
      if (value > maxValue) maxValue = value;
    }
    if (maxValue == minValue) {
      maxValue += 1;
      minValue -= 1;
    }
    const topInset = 8.0;
    const bottomInset = 8.0;
    final usable = size.height - topInset - bottomInset;
    double yFor(double value) =>
        topInset + usable * (1 - (value - minValue) / (maxValue - minValue));
    final baselineY = yFor(baseline);
    final dx = size.width / (values.length - 1);
    final points = [
      for (var i = 0; i < values.length; i++) Offset(i * dx, yFor(values[i])),
    ];

    final areaPath = Path()..moveTo(points.first.dx, baselineY);
    for (final point in points) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath
      ..lineTo(points.last.dx, baselineY)
      ..close();
    final fullRect = Offset.zero & size;

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, baselineY));
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HomeTokens.positive.withValues(alpha: 0.34),
            HomeTokens.positive.withValues(alpha: 0),
          ],
        ).createShader(fullRect),
    );
    canvas.restore();

    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, baselineY, size.width, size.height));
    canvas.drawPath(
      areaPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            HomeTokens.negative.withValues(alpha: 0.32),
            HomeTokens.negative.withValues(alpha: 0),
          ],
        ).createShader(fullRect),
    );
    canvas.restore();

    final dashPaint = Paint()
      ..color = HomeTokens.textMuted.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    const dashWidth = 4.0;
    const dashGap = 4.0;
    var startX = 0.0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, baselineY),
        Offset(startX + dashWidth, baselineY),
        dashPaint,
      );
      startX += dashWidth + dashGap;
    }

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      linePath.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = HomeTokens.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final endColor = values.last >= baseline
        ? HomeTokens.positive
        : HomeTokens.negative;
    canvas.drawCircle(points.last, 3.5, Paint()..color = endColor);
    canvas.drawCircle(
      points.last,
      6,
      Paint()..color = endColor.withValues(alpha: 0.22),
    );
  }

  @override
  bool shouldRepaint(covariant _GainLossPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.baseline != baseline;
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selected,
    required this.historyDays,
    required this.onSelected,
  });

  final _HomePeriod selected;
  final int historyDays;
  final ValueChanged<_HomePeriod> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final period in _HomePeriod.values)
          Expanded(child: _tab(textTheme, period)),
      ],
    );
  }

  Widget _tab(TextTheme textTheme, _HomePeriod period) {
    final available = _isPeriodAvailable(period, historyDays);
    final isSelected = period == selected && available;
    final color = !available
        ? HomeTokens.textMuted.withValues(alpha: 0.45)
        : isSelected
        ? HomeTokens.textPrimary
        : HomeTokens.textSecondary;
    return GestureDetector(
      onTap: available ? () => onSelected(period) : null,
      behavior: HitTestBehavior.opaque,
      child: Container(
        key: ValueKey('home-period-${period.label}'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? HomeTokens.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          period.label,
          textAlign: TextAlign.center,
          style: textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _TrustBar extends StatelessWidget {
  const _TrustBar({required this.trusted, required this.review});

  final int trusted;
  final int review;

  @override
  Widget build(BuildContext context) {
    final total = trusted + review;
    final trustedFlex = total == 0 ? 0 : trusted.clamp(0, total);
    final reviewFlex = total == 0 ? 1 : review.clamp(0, total);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (trustedFlex > 0)
              Expanded(
                flex: trustedFlex,
                child: const ColoredBox(color: HomeTokens.positive),
              ),
            if (reviewFlex > 0)
              Expanded(
                flex: reviewFlex,
                child: const ColoredBox(color: HomeTokens.warning),
              ),
          ],
        ),
      ),
    );
  }
}

String _relativeAddedLabel(CollectibleItem item) {
  final difference = DateTime.now().difference(
    collectibleDisplayTimestamp(item),
  );
  if (difference.inMinutes < 1) {
    return 'Added just now';
  }
  if (difference.inMinutes < 60) {
    return 'Added ${difference.inMinutes}m ago';
  }
  if (difference.inHours < 24) {
    return 'Added ${difference.inHours}h ago';
  }
  if (difference.inDays == 1) {
    return 'Added yesterday';
  }
  if (difference.inDays < 7) {
    return 'Added ${difference.inDays}d ago';
  }
  return 'Added ${(difference.inDays / 7).floor()}w ago';
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
                    addedLabel: _relativeAddedLabel(recentItems[index]),
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
    assetPath: PackLoxAssets.categoryColorCards,
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
    assetPath: PackLoxAssets.categoryColorPokemon,
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
    assetPath: PackLoxAssets.categoryColorMtg,
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
    assetPath: PackLoxAssets.categoryColorYugioh,
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
    assetPath: PackLoxAssets.categoryColorOnePiece,
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
    assetPath: PackLoxAssets.categoryColorGames,
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
    assetPath: PackLoxAssets.categoryColorComics,
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
    assetPath: PackLoxAssets.categoryColorLego,
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
    assetPath: PackLoxAssets.categoryColorFunko,
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
    assetPath: PackLoxAssets.categoryColorCoins,
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
    assetPath: PackLoxAssets.categoryColorSports,
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
    assetPath: PackLoxAssets.categoryColorSneakers,
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

class _PortfolioMoversSection extends StatelessWidget {
  const _PortfolioMoversSection({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final gainer = data.topGainer;
    final loser = data.topLoser;
    return HomeSectionSurface(
      keySeed: 'portfolio-movers',
      title: 'Movers',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoUp =
              gainer != null && loser != null && constraints.maxWidth >= 330;
          final width = twoUp
              ? (constraints.maxWidth - HomeTokens.cardGap) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: HomeTokens.cardGap,
            runSpacing: HomeTokens.cardGap,
            children: [
              if (gainer != null)
                SizedBox(
                  width: width,
                  child: _moverTile(gainer, positive: true),
                ),
              if (loser != null)
                SizedBox(
                  width: width,
                  child: _moverTile(loser, positive: false),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _moverTile(PortfolioValueMover mover, {required bool positive}) {
    return HomeMetricTile(
      label: positive ? 'Top gainer' : 'Top loser',
      value: mover.title,
      supportingText: _signedCurrency(mover.absoluteChange),
      supportingColor: positive ? HomeTokens.positive : HomeTokens.negative,
      compact: true,
    );
  }
}

class _AttentionStrip extends StatelessWidget {
  const _AttentionStrip({required this.data, this.onTap});

  final _HomeViewData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final alertCount = data.triggeredAlertCount;
    final unvalued = data.unvaluedCount;
    final accent = alertCount > 0 ? HomeTokens.negative : HomeTokens.warning;
    final alertLine = alertCount > 0
        ? '$alertCount price ${alertCount == 1 ? 'alert' : 'alerts'} triggered'
        : null;
    final valuationLine = unvalued > 0
        ? '$unvalued ${unvalued == 1 ? 'item needs' : 'items need'} a valuation'
        : null;
    final primary = alertLine ?? valuationLine!;
    final secondary = alertLine != null ? valuationLine : null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: HomeSurface(
        keySeed: 'attention-strip',
        borderColor: accent.withValues(alpha: 0.5),
        semanticLabel: primary,
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(HomeTokens.controlRadius),
              ),
              child: Icon(
                alertCount > 0
                    ? Icons.notifications_active_outlined
                    : Icons.error_outline,
                color: accent,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: HomeTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (secondary != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium?.copyWith(
                        color: HomeTokens.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.chevron_right, color: HomeTokens.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _CollectionHealthSection extends StatelessWidget {
  const _CollectionHealthSection({required this.data});

  final _HomeViewData data;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shares = data.categoryShares;

    Widget buildBars() {
      if (shares.isEmpty) {
        return Text(
          'Add items to see your category mix.',
          style: textTheme.bodyMedium?.copyWith(
            color: HomeTokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < shares.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            _CategoryMixBar(
              label: shares[i].label,
              fraction: shares[i].fraction,
              count: shares[i].count,
              color: _categoryBarColor(i, shares[i].label),
            ),
          ],
        ],
      );
    }

    return HomeSectionSurface(
      keySeed: 'collection-health',
      title: 'Collection health',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final ring = _HealthRing(
            score: data.collectionHealth.score,
            label: data.collectionHealth.label,
          );
          if (constraints.maxWidth < 320) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ring,
                const SizedBox(height: AppSpacing.md),
                buildBars(),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ring,
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: buildBars()),
            ],
          );
        },
      ),
    );
  }
}

class _HealthRing extends StatelessWidget {
  const _HealthRing({required this.score, required this.label});

  final int score;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final clamped = score.clamp(0, 100);
    final color = clamped >= 85
        ? HomeTokens.positive
        : clamped >= 70
        ? HomeTokens.accent
        : clamped >= 50
        ? HomeTokens.warning
        : HomeTokens.negative;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          key: const ValueKey('home-health-ring'),
          width: 64,
          height: 64,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  value: clamped / 100,
                  strokeWidth: 6,
                  backgroundColor: HomeTokens.surfaceInteractive,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Text(
                '$clamped',
                style: textTheme.titleMedium?.copyWith(
                  color: HomeTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          label,
          textAlign: TextAlign.center,
          style: textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _CategoryMixBar extends StatelessWidget {
  const _CategoryMixBar({
    required this.label,
    required this.fraction,
    required this.count,
    required this.color,
  });

  final String label;
  final double fraction;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  color: HomeTokens.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '$count · ${(fraction * 100).round()}%',
              style: textTheme.labelSmall?.copyWith(
                color: HomeTokens.textMuted,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(HomeTokens.controlRadius),
          child: Container(
            height: 8,
            color: HomeTokens.border,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fraction.clamp(0.04, 1.0),
              child: Container(color: color),
            ),
          ),
        ),
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
    required this.valueSeries,
    required this.collectionHealth,
    this.triggeredAlertCount = 0,
    this.topGainer,
    this.topLoser,
  });

  final List<CollectibleItem> items;
  final int itemCount;
  final double totalValuedAmount;
  final int valuedItemCount;
  final int unvaluedCount;
  final List<CollectibleItem> recentItems;
  final List<TrendSnapshot> valueSeries;
  final PortfolioValueMover? topGainer;
  final PortfolioValueMover? topLoser;
  final CollectionHealthScore collectionHealth;
  final int triggeredAlertCount;

  /// Category mix from canonicalized real categories: card variants merge into
  /// "Cards", but distinct types (Video Games, LEGO, Sneakers, Watches, …) stay
  /// separate. Shows every category when there are few; collapses only the long
  /// tail into "Other" when there are many, so the compact card stays readable.
  List<_CategoryShare> get categoryShares {
    final counts = <String, int>{};
    for (final item in items) {
      final label = _canonicalCategory(item.category);
      counts[label] = (counts[label] ?? 0) + 1;
    }
    final total = counts.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) {
      return const <_CategoryShare>[];
    }
    final entries = counts.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount == 0 ? a.key.compareTo(b.key) : byCount;
      });

    _CategoryShare shareOf(String label, int count) =>
        _CategoryShare(label: label, count: count, fraction: count / total);

    const maxBars = 8;
    if (entries.length <= maxBars) {
      return [for (final entry in entries) shareOf(entry.key, entry.value)];
    }
    final otherCount = entries
        .skip(maxBars - 1)
        .fold<int>(0, (sum, entry) => sum + entry.value);
    return [
      for (final entry in entries.take(maxBars - 1))
        shareOf(entry.key, entry.value),
      shareOf('Other', otherCount),
    ];
  }

  bool get isEmpty => itemCount == 0;
  bool get hasValuedItems => valuedItemCount > 0;
  bool get hasPartialValuation => itemCount > 0 && unvaluedCount > 0;
  bool get hasRealMetrics => itemCount > 0;
  bool get hasStateAlert => hasPartialValuation;
  bool get hasMovers => topGainer != null || topLoser != null;
  bool get hasAttention =>
      itemCount > 0 && (unvaluedCount > 0 || triggeredAlertCount > 0);
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

  factory _HomeViewData.fromInsights(
    CollectorDashboardAnalytics insights, {
    PortfolioPerformance? performance,
    int triggeredAlertCount = 0,
  }) {
    final items = insights.items;
    final valuedItems = items.where(_hasDisplayValue).toList(growable: false);
    final totalValuedAmount = valuedItems.fold<double>(
      0,
      (sum, item) => sum + item.estimatedValue,
    );
    // Real persisted daily value history drives the trend chart + period delta.
    final dailySnapshots =
        performance?.dailySnapshots ?? const <PortfolioSnapshot>[];
    return _HomeViewData(
      items: items,
      itemCount: items.length,
      totalValuedAmount: totalValuedAmount,
      valuedItemCount: valuedItems.length,
      unvaluedCount: items.length - valuedItems.length,
      recentItems: items,
      valueSeries: _seriesFromSnapshots(dailySnapshots),
      topGainer: performance?.topGainer,
      topLoser: performance?.topLoser,
      collectionHealth: insights.collectionHealth,
      triggeredAlertCount: triggeredAlertCount,
    );
  }
}

class _CategoryShare {
  const _CategoryShare({
    required this.label,
    required this.count,
    required this.fraction,
  });

  final String label;
  final int count;
  final double fraction;
}

Color _categoryBarColor(int index, String label) {
  if (label == 'Other') {
    return HomeTokens.textMuted;
  }
  const palette = [
    HomeTokens.categoryCards,
    HomeTokens.categoryCoins,
    HomeTokens.categoryFigures,
    HomeTokens.categoryMore,
    HomeTokens.accent,
  ];
  return palette[index % palette.length];
}

/// Canonicalizes a raw collectible category label so obvious variants merge
/// (all card types → "Cards") while distinct real categories stay separate.
String _canonicalCategory(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) {
    return 'Other';
  }
  bool has(String token) => value.contains(token);
  if (has('card') ||
      has('tcg') ||
      has('pokemon') ||
      has('pokémon') ||
      has('magic') ||
      has('mtg') ||
      has('yu-gi') ||
      has('yugioh') ||
      has('one piece') ||
      has('trainer')) {
    return 'Cards';
  }
  if (has('coin') || has('numismat')) {
    return 'Coins';
  }
  if (has('comic')) {
    return 'Comics';
  }
  if (has('video game') ||
      has('game') ||
      has('cartridge') ||
      has('console')) {
    return 'Video Games';
  }
  if (has('lego')) {
    return 'LEGO';
  }
  if (has('funko')) {
    return 'Funko';
  }
  if (has('sneaker') ||
      has('shoe') ||
      has('streetwear') ||
      has('nike') ||
      has('jordan')) {
    return 'Sneakers';
  }
  if (has('watch')) {
    return 'Watches';
  }
  if (has('sport') ||
      has('jersey') ||
      has('autograph') ||
      has('memorabilia')) {
    return 'Sports';
  }
  if (has('figure') || has('toy')) {
    return 'Figures';
  }
  return _titleCase(raw.trim());
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

String _signedCurrency(double value) {
  if (value == 0) {
    return '\$0';
  }
  final prefix = value > 0 ? '+' : '-';
  return '$prefix${_formatCurrency(value.abs())}';
}

/// Real persisted daily value history (dated, oldest→newest). Empty until at
/// least one snapshot exists.
List<TrendSnapshot> _seriesFromSnapshots(List<PortfolioSnapshot> daily) {
  if (daily.isEmpty) {
    return const <TrendSnapshot>[];
  }
  final ordered = [...daily]
    ..sort((a, b) => a.periodStart.compareTo(b.periodStart));
  return [
    for (final snapshot in ordered)
      TrendSnapshot(
        period: TrendSnapshotPeriod.daily,
        date: snapshot.periodStart,
        totalValue: snapshot.totalPortfolioValue,
        itemCount: snapshot.totalItems,
        averageConfidence: 0,
      ),
  ];
}

enum _HomePeriod {
  day1('1D', 1),
  week1('7D', 7),
  month1('1M', 30),
  month3('3M', 90),
  month6('6M', 180),
  max('MAX', 1 << 20);

  const _HomePeriod(this.label, this.days);

  final String label;
  final int days;

  bool get isMax => this == _HomePeriod.max;
}

bool _isPeriodAvailable(_HomePeriod period, int historyDays) {
  return period.isMax || historyDays >= period.days;
}

List<TrendSnapshot> _pointsForPeriod(
  List<TrendSnapshot> series,
  _HomePeriod period,
) {
  if (period.isMax || series.length < 2) {
    return series;
  }
  final cutoff = series.last.date.subtract(Duration(days: period.days));
  final filtered = series
      .where((snapshot) => !snapshot.date.isBefore(cutoff))
      .toList();
  return filtered.length >= 2 ? filtered : series;
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
