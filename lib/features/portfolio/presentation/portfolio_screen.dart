import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final portfolioState = ref.watch(portfolioControllerProvider);
    final portfolioController = ref.read(portfolioControllerProvider.notifier);

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Portfolio',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Track saved collectibles and estimated value.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      PortfolioSummaryCard(
                        totalValue: portfolioState.totalValue,
                        itemCount: portfolioState.itemCount,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (portfolioState.isLoading &&
                          portfolioState.items.isEmpty)
                        const Center(child: CircularProgressIndicator())
                      else if (portfolioState.errorMessage != null)
                        PortfolioErrorState(
                          message: portfolioState.errorMessage!,
                        )
                      else if (portfolioState.items.isEmpty)
                        const PortfolioEmptyState()
                      else
                        PortfolioItemsGrid(
                          items: portfolioState.items,
                          onRemoveItem: portfolioController.removeItem,
                          onOpenItem: (item) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    CollectibleDetailPage(item: item),
                              ),
                            );
                          },
                        ),
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
