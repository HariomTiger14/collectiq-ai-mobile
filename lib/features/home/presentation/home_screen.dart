import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_dashboard_widgets.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({this.onScanPressed, super.key});

  final VoidCallback? onScanPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final portfolioState = ref.watch(portfolioControllerProvider);
    final recentItems = [...portfolioState.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return AppScaffold(
      child: AppResponsiveColumn(
        spacing: AppSpacing.xl,
        children: [
          const HomeGreeting(),
          DashboardFadeSlide(
            child: CollectionValueHero(totalValue: portfolioState.totalValue),
          ),
          HomeQuickStats(
            itemCount: portfolioState.itemCount,
            averageConfidence: _averageConfidence(portfolioState.items),
            lastScan: recentItems.isEmpty
                ? 'Not yet'
                : formatDashboardDate(recentItems.first.createdAt),
          ),
          PrimaryButton(
            label: 'Scan Collectible',
            icon: Icons.document_scanner_outlined,
            onPressed: onScanPressed,
          ),
          SectionHeader(
            title: 'Recent Activity',
            subtitle: recentItems.isEmpty
                ? 'Your latest saved collectibles will appear here.'
                : 'Latest saved collectibles from your portfolio.',
          ),
          if (recentItems.isEmpty)
            EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No collectibles scanned yet.',
              message: 'Start with a quick scan to build your collection.',
              action: PrimaryButton(
                label: 'Start Scanning',
                icon: Icons.document_scanner_outlined,
                onPressed: onScanPressed,
              ),
            )
          else
            RecentActivityList(items: recentItems.take(3).toList()),
        ],
      ),
    );
  }

  String _averageConfidence(List<CollectibleItem> items) {
    if (items.isEmpty) {
      return '0%';
    }

    final total = items.fold<double>(0, (sum, item) => sum + item.confidence);
    return '${((total / items.length) * 100).toStringAsFixed(0)}%';
  }
}
