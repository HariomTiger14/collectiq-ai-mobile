import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_dashboard_widgets.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _quickActions = [
    DashboardAction(
      title: 'Scan Item',
      icon: Icons.document_scanner_outlined,
      color: AppColors.accent,
    ),
    DashboardAction(
      title: 'My Collection',
      icon: Icons.inventory_2_outlined,
      color: AppColors.secondaryAccent,
    ),
    DashboardAction(
      title: 'Watchlist',
      icon: Icons.visibility_outlined,
      color: Color(0xFF7C3AED),
    ),
    DashboardAction(
      title: 'Price Alerts',
      icon: Icons.notifications_active_outlined,
      color: AppColors.danger,
    ),
  ];

  static const _trendingCollectibles = [
    TrendingCollectible(
      name: 'Charizard Holo',
      estimatedValue: r'$4,850',
      percentageIncrease: '+18.4%',
      icon: Icons.local_fire_department_outlined,
      color: AppColors.accent,
    ),
    TrendingCollectible(
      name: 'Jordan Rookie',
      estimatedValue: r'$12,300',
      percentageIncrease: '+12.1%',
      icon: Icons.sports_basketball_outlined,
      color: AppColors.accent,
    ),
    TrendingCollectible(
      name: 'Silver Eagle',
      estimatedValue: r'$780',
      percentageIncrease: '+9.7%',
      icon: Icons.monetization_on_outlined,
      color: AppColors.accent,
    ),
    TrendingCollectible(
      name: 'Vintage Omega',
      estimatedValue: r'$3,420',
      percentageIncrease: '-2.1%',
      icon: Icons.watch_outlined,
      color: AppColors.accent,
    ),
    TrendingCollectible(
      name: 'First Edition',
      estimatedValue: r'$1,260',
      percentageIncrease: '+6.5%',
      icon: Icons.auto_stories_outlined,
      color: AppColors.accent,
    ),
  ];

  static const _recentScans = [
    RecentScan(
      name: 'Pikachu Illustrator Card',
      category: 'Trading Card',
      estimatedValue: r'$8,900',
      scannedAt: 'Today',
      icon: Icons.style_outlined,
    ),
    RecentScan(
      name: 'Rolex Submariner 1998',
      category: 'Watch',
      estimatedValue: r'$9,450',
      scannedAt: 'Yesterday',
      icon: Icons.watch_outlined,
    ),
    RecentScan(
      name: 'Signed Baseball',
      category: 'Memorabilia',
      estimatedValue: r'$640',
      scannedAt: 'Jun 24',
      icon: Icons.sports_baseball_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700
                ? AppSpacing.xxl
                : AppSpacing.lg;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xl,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeDashboardAppBar(),
                      SizedBox(height: AppSpacing.xxl),
                      WelcomeSection(),
                      SizedBox(height: AppSpacing.xl),
                      PortfolioSummaryCard(
                        portfolioValue: r'$42,680',
                        totalItems: '128',
                        monthlyChange: '+14.2%',
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      DashboardSectionHeader(title: 'Quick Actions'),
                      SizedBox(height: AppSpacing.md),
                      QuickActionsGrid(actions: _quickActions),
                      SizedBox(height: AppSpacing.xxl),
                      DashboardSectionHeader(title: 'Trending Collectibles'),
                      SizedBox(height: AppSpacing.md),
                      TrendingCollectiblesList(items: _trendingCollectibles),
                      SizedBox(height: AppSpacing.xxl),
                      DashboardSectionHeader(title: 'Recent Scans'),
                      SizedBox(height: AppSpacing.md),
                      RecentScansList(items: _recentScans),
                      SizedBox(height: AppSpacing.xxl),
                      PremiumBanner(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
