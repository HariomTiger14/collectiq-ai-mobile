import 'dart:io';

import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/ui/hero/gradient_hero_header.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';
import 'package:collectiq_ai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Account overview: identity, a collection snapshot, account details, and
/// session controls. Reached from the Settings "Account" row.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AccountScreen());
  }

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final profileState = ref.watch(profileControllerProvider);
    final portfolio = ref.watch(portfolioControllerProvider);
    final subscription = ref.watch(subscriptionControllerProvider);
    final profile = profileState.hasValue ? profileState.requireValue : null;

    final user = authState.user;
    final name = (profile?.displayName.trim().isNotEmpty ?? false)
        ? profile!.displayName.trim()
        : (user?.displayName.trim().isNotEmpty ?? false)
        ? user!.displayName.trim()
        : CollectorProfile.defaultDisplayName;
    final email = user?.email;

    final valuedItems = portfolio.items.where((i) => i.hasTrustedValuation);
    final trackedValue = valuedItems.fold<double>(
      0,
      (sum, item) => sum + item.estimatedValue,
    );
    final collectingSince = _collectingSince(portfolio.items);

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
          key: const ValueKey('account-screen'),
          backgroundColor: HomeTokens.background,
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: GradientHeroHeader(
                  scrollController: _scrollController,
                  icon: Icons.person_rounded,
                  title: 'Account',
                  subtitle: 'Your PackLox profile and collection',
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
                      _AccountIdentityHeader(
                        name: name,
                        email: email,
                        avatarPath: profile?.avatarPath,
                        isSignedIn: authState.isSignedIn,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      HomeSectionSurface(
                        keySeed: 'account-collection',
                        title: 'Your collection',
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final tileWidth =
                                (constraints.maxWidth - AppSpacing.sm) / 2;
                            return Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                SizedBox(
                                  width: tileWidth,
                                  child: HomeMetricTile(
                                    label: 'Items tracked',
                                    value: '${portfolio.itemCount}',
                                    supportingText:
                                        '${valuedItems.length} valued',
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: HomeMetricTile(
                                    label: 'Value tracked',
                                    value: _formatMoney(trackedValue),
                                    supportingText: 'Estimated',
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      HomeSectionSurface(
                        keySeed: 'account-details',
                        title: 'Account',
                        child: Column(
                          children: [
                            _AccountDetailRow(
                              label: 'Email',
                              value: email ?? 'Not connected',
                            ),
                            _AccountDetailRow(
                              label: 'Plan',
                              value: subscription.entitlements.plan.displayName,
                            ),
                            _AccountDetailRow(
                              label: 'Currency',
                              value:
                                  profile?.preferredCurrency ??
                                  CollectorProfile.defaultPreferredCurrency,
                            ),
                            if (collectingSince != null)
                              _AccountDetailRow(
                                label: 'Collecting since',
                                value: collectingSince,
                                isLast: true,
                              ),
                          ],
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

String? _collectingSince(List<CollectibleItem> items) {
  if (items.isEmpty) {
    return null;
  }
  var earliest = items.first.createdAt;
  for (final item in items) {
    if (item.createdAt.isBefore(earliest)) {
      earliest = item.createdAt;
    }
  }
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[earliest.month - 1]} ${earliest.year}';
}

String _formatMoney(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

class _AccountIdentityHeader extends StatelessWidget {
  const _AccountIdentityHeader({
    required this.name,
    required this.email,
    required this.avatarPath,
    required this.isSignedIn,
  });

  final String name;
  final String? email;
  final String? avatarPath;
  final bool isSignedIn;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statusColor = isSignedIn ? HomeTokens.positive : HomeTokens.accent;
    final avatarFile = (avatarPath == null || avatarPath!.isEmpty)
        ? null
        : File(avatarPath!);
    final initial = name.trim().isNotEmpty
        ? name.trim().substring(0, 1).toUpperCase()
        : 'P';

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                HomeTokens.accentStrong.withValues(alpha: 0.85),
                HomeTokens.accent.withValues(alpha: 0.58),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: HomeTokens.border, width: 2),
          ),
          child: avatarFile != null && avatarFile.existsSync()
              ? Image.file(avatarFile, fit: BoxFit.cover)
              : Center(
                  child: Text(
                    initial,
                    style: textTheme.titleLarge?.copyWith(
                      color: HomeTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleLarge?.copyWith(
                  color: HomeTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                email ?? (isSignedIn ? 'Signed in' : 'Local access'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodySmall?.copyWith(
                  color: HomeTokens.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
      ],
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  const _AccountDetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    color: HomeTokens.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 7,
                child: Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: HomeTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(color: HomeTokens.border.withValues(alpha: 0.44), height: 12),
      ],
    );
  }
}
