import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/ui/currency_format.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';
import 'package:collectiq_ai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Why the paywall is being shown — drives the contextual headline so the
/// upgrade prompt speaks to the exact moment the user hit.
enum PaywallReason {
  collectionFull,
  priceHistory,
  advancedFilters,
  export,
  portfolioIntelligence,
  morePhotos,
  moreAlerts,
  moreRefreshes,
  generic,
}

/// Presents the single-tier (Pro) upgrade sheet. Contextual to [reason].
Future<void> showUpgradeSheet(
  BuildContext context, {
  PaywallReason reason = PaywallReason.generic,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _UpgradeSheet(reason: reason),
  );
}

class _UpgradeSheet extends ConsumerWidget {
  const _UpgradeSheet({required this.reason});

  final PaywallReason reason;

  static const _fallbackPrice = 'AUD 9.99 / month';

  static const _benefits = <(IconData, String)>[
    (Icons.all_inclusive_rounded, 'Unlimited collectibles'),
    (Icons.show_chart_rounded, 'Per-item price history & trends'),
    (Icons.insights_rounded, 'Portfolio intelligence'),
    (Icons.ios_share_rounded, 'Export & advanced filters'),
    (Icons.notifications_active_outlined, 'Unlimited alerts & refreshes'),
  ];

  /// Resolves the headline. For the collection-full wall — the primary
  /// conversion moment — it leads with the value the user has already built
  /// ("you've secured $X"), which converts harder than a generic limit notice.
  /// Falls back to the static copy when there's no value yet.
  ({String title, String subtitle}) _resolveCopy(WidgetRef ref) {
    if (reason == PaywallReason.collectionFull) {
      final total = ref.watch(portfolioControllerProvider).totalValue;
      if (total > 0) {
        final profileAsync = ref.watch(profileControllerProvider);
        final currency = profileAsync.hasValue
            ? profileAsync.requireValue.preferredCurrency
            : CollectorProfile.defaultPreferredCurrency;
        final formatted = formatCollectionValue(total, currencyCode: currency);
        return (
          title: "You've secured $formatted in collectibles",
          subtitle:
              'Upgrade to Pro to save your whole collection and keep tracking '
              'its value — no limits.',
        );
      }
    }
    return _copy;
  }

  ({String title, String subtitle}) get _copy {
    return switch (reason) {
      PaywallReason.collectionFull => (
        title: "You've reached your 10 free collectibles",
        subtitle: 'Upgrade to Pro to save your whole collection — no limits.',
      ),
      PaywallReason.priceHistory => (
        title: 'See how this item has moved',
        subtitle: "Unlock this item's full price history and trends with Pro.",
      ),
      PaywallReason.advancedFilters => (
        title: 'Filter your whole collection',
        subtitle: 'Advanced filters and sorting are included with Pro.',
      ),
      PaywallReason.export => (
        title: 'Export your collection',
        subtitle: 'Download a CSV of your collection with Pro.',
      ),
      PaywallReason.portfolioIntelligence => (
        title: 'Unlock portfolio intelligence',
        subtitle:
            'See the full attention queue, top movers, and refresh priorities.',
      ),
      PaywallReason.morePhotos => (
        title: 'Add more photos',
        subtitle: 'Pro lets you add up to 12 photos per collectible.',
      ),
      PaywallReason.moreAlerts => (
        title: 'Set more price alerts',
        subtitle: 'Pro gives you unlimited price alerts.',
      ),
      PaywallReason.moreRefreshes => (
        title: "You've used your free refreshes",
        subtitle: 'Pro re-checks your values as often as you like.',
      ),
      PaywallReason.generic => (
        title: 'Go unlimited with PackLox Pro',
        subtitle: 'Unlock your whole collection and every collector tool.',
      ),
    };
  }

  BillingProduct? _proProduct(SubscriptionState state) {
    for (final product in state.products) {
      if (product.plan == SubscriptionPlan.pro) {
        return product;
      }
    }
    return null;
  }

  Future<void> _activate(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await ref
        .read(subscriptionControllerProvider.notifier)
        .purchasePlan(SubscriptionPlan.pro);
    if (!context.mounted) {
      return;
    }
    final isPro =
        ref.read(subscriptionControllerProvider).entitlements.plan !=
        SubscriptionPlan.free;
    if (isPro) {
      navigator.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Welcome to PackLox Pro 🎉')),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(subscriptionControllerProvider);
    final price = _proProduct(state)?.price ?? _fallbackPrice;
    final isBusy = state.isLoading;
    final copy = _resolveCopy(ref);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.sm),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: HomeTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: HomeTokens.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: HomeTokens.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: HomeTokens.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: HomeTokens.accent.withValues(alpha: 0.34),
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_outlined,
                    color: HomeTokens.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'PackLox Pro',
                    style: textTheme.titleMedium?.copyWith(
                      color: HomeTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  price,
                  style: textTheme.labelLarge?.copyWith(
                    color: HomeTokens.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              copy.title,
              style: textTheme.titleLarge?.copyWith(
                color: HomeTokens.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              copy.subtitle,
              style: textTheme.bodyMedium?.copyWith(
                color: HomeTokens.textSecondary,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final (icon, label) in _benefits) ...[
              _BenefitRow(icon: icon, label: label),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('upgrade-sheet-activate'),
                onPressed: isBusy ? null : () => _activate(context, ref),
                style: FilledButton.styleFrom(
                  backgroundColor: HomeTokens.accentStrong,
                  foregroundColor: HomeTokens.textPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(
                  isBusy ? 'Activating…' : 'Upgrade to Pro',
                  style: textTheme.titleSmall?.copyWith(
                    color: HomeTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                key: const ValueKey('upgrade-sheet-dismiss'),
                onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Maybe later',
                  style: textTheme.labelLarge?.copyWith(
                    color: HomeTokens.textMuted,
                    fontWeight: FontWeight.w700,
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

class _BenefitRow extends StatelessWidget {
  const _BenefitRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: HomeTokens.positive),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
