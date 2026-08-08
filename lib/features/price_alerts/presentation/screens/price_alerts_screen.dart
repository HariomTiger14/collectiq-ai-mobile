import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/ui/home/home_ui.dart';
import 'package:collectiq_ai/core/ui/hero/gradient_hero_header.dart';
import 'package:collectiq_ai/core/ui/hero/gradient_list_row.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_notification_controller.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every price alert across the whole portfolio, reached from Settings.
/// Alerts are created from a collectible's own detail page -- this screen is
/// read/manage-only (view every alert in one place, reset, delete, jump to
/// the item that owns it).
class PriceAlertsScreen extends ConsumerStatefulWidget {
  const PriceAlertsScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const PriceAlertsScreen());
  }

  @override
  ConsumerState<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends ConsumerState<PriceAlertsScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alertsAsync = ref.watch(allPriceAlertsProvider);
    final notificationState = ref.watch(
      priceAlertNotificationControllerProvider,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: HomeTokens.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Theme(
        data: AppTheme.dark,
        child: Scaffold(
          key: const ValueKey('price-alerts-screen'),
          backgroundColor: HomeTokens.background,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: GradientHeroHeader(
                  scrollController: _scrollController,
                  icon: Icons.notifications_active_rounded,
                  title: 'Price Alerts',
                  subtitle: 'Watch value moves across your collection',
                  gradientStyle: GradientStyle.purpleDeepBlue,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  HomeTokens.pageGutter,
                  AppSpacing.xl,
                  HomeTokens.pageGutter,
                  AppSpacing.xxl,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NotificationStatusRow(state: notificationState),
                      const SizedBox(height: AppSpacing.xl),
                      alertsAsync.when(
                        data: (alerts) => alerts.isEmpty
                            ? const SectionCard(
                                title: 'Your Alerts',
                                child: _EmptyAlertsMessage(),
                              )
                            : _GroupedAlertSections(alerts: alerts),
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.xl,
                          ),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => SectionCard(
                          title: 'Your Alerts',
                          child: Text(
                            'Unable to load your price alerts right now.',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: HomeTokens.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationStatusRow extends StatelessWidget {
  const _NotificationStatusRow({required this.state});

  final PriceAlertNotificationState state;

  @override
  Widget build(BuildContext context) {
    return GradientListRow(
      icon: state.permissionStatus.canNotify
          ? Icons.notifications_active_outlined
          : Icons.notifications_off_outlined,
      title: 'Notifications',
      subtitle: state.settingsSubtitle,
      trailingText: state.settingsStatusLabel,
      trailingTone: state.settingsStatusNeedsAttention
          ? GradientRowTone.warning
          : state.settingsStatusLabel == 'On'
          ? GradientRowTone.positive
          : GradientRowTone.neutral,
    );
  }
}

/// Splits alerts into "Needs Attention" (triggered/notified -- something
/// actually happened, worth a look) and "Active" (still just watching) so
/// the one distinction that's actually actionable surfaces first, without
/// needing any sort/filter controls or extra state.
class _GroupedAlertSections extends StatelessWidget {
  const _GroupedAlertSections({required this.alerts});

  final List<PriceAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final needsAttention = alerts.where((alert) => alert.isTriggered).toList();
    final active = alerts.where((alert) => !alert.isTriggered).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsAttention.isNotEmpty) ...[
          SectionCard(
            title: 'Needs Attention',
            child: _AlertRowList(alerts: needsAttention),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (active.isNotEmpty)
          SectionCard(title: 'Watching', child: _AlertRowList(alerts: active)),
      ],
    );
  }
}

class _AlertRowList extends StatelessWidget {
  const _AlertRowList({required this.alerts});

  final List<PriceAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return MotionStagger(
      children: [
        for (final alert in alerts) ...[
          _AlertListRow(alert: alert),
          if (alert != alerts.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _EmptyAlertsMessage extends StatelessWidget {
  const _EmptyAlertsMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceRaised,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: HomeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            color: HomeTokens.textMuted,
            size: 28,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No price alerts yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Open any collectible in your portfolio and use its Price '
            'Alerts section to watch for a value change or stale pricing.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HomeTokens.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertListRow extends ConsumerWidget {
  const _AlertListRow({required this.alert});

  final PriceAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    // isTriggered covers both the freshly-triggered state and the post-push
    // "notified" terminal state, so a reset stays offered until the alert
    // is actually cleared -- not just for the brief triggered window before
    // a push goes out.
    final triggered = alert.isTriggered;
    final color = triggered ? HomeTokens.positive : HomeTokens.accent;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _openItem(context, ref),
      child: Container(
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
                Expanded(
                  child: Text(
                    alert.itemTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: HomeTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: HomeTokens.textMuted,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  triggered
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_none_outlined,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _ruleLabel(alert.rule),
                    softWrap: true,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: HomeTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    alert.status.label,
                    style: textTheme.labelMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            if (alert.message != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                alert.message!,
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: HomeTokens.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (triggered)
                  FilledButton(
                    onPressed: () => _resetAlert(context, ref),
                    style: FilledButton.styleFrom(
                      // Same emerald as the Pro plan pill on Settings
                      // (see _proGradientColors in settings_screen.dart),
                      // for a consistent "positive" green across the app.
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: HomeTokens.textPrimary,
                    ),
                    child: const Text('Reset'),
                  ),
                FilledButton(
                  onPressed: () => _deleteAlert(context, ref),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: HomeTokens.textPrimary,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openItem(BuildContext context, WidgetRef ref) {
    final items = ref.read(portfolioControllerProvider).items;
    final matches = items.where((item) => item.id == alert.itemId);
    if (matches.isEmpty) {
      _showSnackBar(context, 'This item is no longer in your portfolio.');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CollectibleDetailPage(item: matches.first),
      ),
    );
  }

  Future<void> _resetAlert(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(priceAlertRepositoryProvider);
    await repository.saveAlert(
      alert.copyWith(
        status: PriceAlertStatus.active,
        updatedAt: DateTime.now(),
        clearMessage: true,
        clearTriggeredAt: true,
      ),
    );
    ref.invalidate(allPriceAlertsProvider);
    ref.invalidate(itemPriceAlertsProvider(alert.itemId));
    ref.invalidate(priceAlertSummaryProvider);
    if (context.mounted) {
      _showSnackBar(context, 'Price alert reset');
    }
  }

  Future<void> _deleteAlert(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(priceAlertRepositoryProvider);
    await repository.deleteAlert(alert.id);
    ref.invalidate(allPriceAlertsProvider);
    ref.invalidate(itemPriceAlertsProvider(alert.itemId));
    ref.invalidate(priceAlertSummaryProvider);
    if (context.mounted) {
      _showSnackBar(context, 'Price alert deleted');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

String _ruleLabel(PriceAlertRule rule) {
  switch (rule.type) {
    case PriceAlertRuleType.priceRisesAboveAmount:
      return 'Rises above ${_formatMoney(rule.amount ?? 0)}';
    case PriceAlertRuleType.priceDropsBelowAmount:
      return 'Drops below ${_formatMoney(rule.amount ?? 0)}';
    case PriceAlertRuleType.percentageIncrease:
      return 'Increases by ${_formatPercent(rule.percentage)}';
    case PriceAlertRuleType.percentageDecrease:
      return 'Decreases by ${_formatPercent(rule.percentage)}';
    case PriceAlertRuleType.stalePricingReminder:
      return 'Stale pricing reminder';
  }
}

String _formatPercent(double? value) {
  return '${((value ?? 0) * 100).toStringAsFixed(0)}%';
}

String _formatMoney(double value) {
  if (value <= 0) {
    return 'value unavailable';
  }
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rounded.length; i++) {
    if (i > 0 && (rounded.length - i) % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(rounded[i]);
  }
  return '\$$buffer';
}
