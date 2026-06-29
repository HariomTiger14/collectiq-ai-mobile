import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _PortfolioSortMode {
  newest(label: 'Newest first'),
  value(label: 'Value high to low'),
  confidence(label: 'Confidence high to low');

  const _PortfolioSortMode({required this.label});

  final String label;
}

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({this.onScanPressed, super.key});

  final VoidCallback? onScanPressed;

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> {
  String _searchQuery = '';
  _PortfolioSortMode _sortMode = _PortfolioSortMode.newest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final portfolioState = ref.watch(portfolioControllerProvider);
    final portfolioController = ref.read(portfolioControllerProvider.notifier);
    final visibleItems = _visibleItems(portfolioState.items);

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
                        'Your collectible library',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      PortfolioSummaryCard(
                        totalValue: portfolioState.totalValue,
                        itemCount: portfolioState.itemCount,
                        averageConfidence: _averageConfidence(
                          portfolioState.items,
                        ),
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
                        PortfolioEmptyState(onScanPressed: widget.onScanPressed)
                      else ...[
                        _PortfolioControls(
                          searchQuery: _searchQuery,
                          sortMode: _sortMode,
                          onSearchChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                          },
                          onSortChanged: (value) {
                            setState(() {
                              _sortMode = value;
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (visibleItems.isEmpty)
                          const PortfolioNoSearchResultsState()
                        else
                          PortfolioItemsGrid(
                            items: visibleItems,
                            onRemoveItem: (id) => _confirmDelete(
                              context,
                              id,
                              portfolioController,
                            ),
                            onOpenItem: (item) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CollectibleDetailPage(
                                    item: item,
                                    onDelete: (id) async {
                                      final deleted = await _confirmDelete(
                                        context,
                                        id,
                                        portfolioController,
                                      );
                                      if (deleted && context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                      return deleted;
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
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

  List<CollectibleItem> _visibleItems(List<CollectibleItem> items) {
    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final filteredItems = normalizedQuery.isEmpty
        ? [...items]
        : items.where((item) {
            return item.title.toLowerCase().contains(normalizedQuery) ||
                item.category.toLowerCase().contains(normalizedQuery);
          }).toList();

    filteredItems.sort((left, right) {
      return switch (_sortMode) {
        _PortfolioSortMode.newest => right.createdAt.compareTo(left.createdAt),
        _PortfolioSortMode.value => right.estimatedValue.compareTo(
          left.estimatedValue,
        ),
        _PortfolioSortMode.confidence => right.confidence.compareTo(
          left.confidence,
        ),
      };
    });
    return filteredItems;
  }

  double _averageConfidence(List<CollectibleItem> items) {
    if (items.isEmpty) {
      return 0;
    }

    return items.fold<double>(0, (sum, item) => sum + item.confidence) /
        items.length;
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    String itemId,
    PortfolioController portfolioController,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete item?'),
          content: const Text(
            'This collectible will be removed from your portfolio.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return false;
    }

    await portfolioController.removeItem(itemId);
    return true;
  }
}

class _PortfolioControls extends StatelessWidget {
  const _PortfolioControls({
    required this.searchQuery,
    required this.sortMode,
    required this.onSearchChanged,
    required this.onSortChanged,
  });

  final String searchQuery;
  final _PortfolioSortMode sortMode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<_PortfolioSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final searchField = TextFormField(
          initialValue: searchQuery,
          onChanged: onSearchChanged,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            labelText: 'Search portfolio',
          ),
        );
        final sortSelector = _PortfolioSortSelector(
          sortMode: sortMode,
          onSortChanged: onSortChanged,
        );

        if (constraints.maxWidth >= 680) {
          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(width: 360, child: sortSelector),
            ],
          );
        }

        return Column(
          children: [
            searchField,
            const SizedBox(height: AppSpacing.md),
            sortSelector,
          ],
        );
      },
    );
  }
}

class _PortfolioSortSelector extends StatelessWidget {
  const _PortfolioSortSelector({
    required this.sortMode,
    required this.onSortChanged,
  });

  final _PortfolioSortMode sortMode;
  final ValueChanged<_PortfolioSortMode> onSortChanged;

  @override
  Widget build(BuildContext context) {
    return AppStableSegmentedSelector<_PortfolioSortMode>(
      selectedValue: sortMode,
      onChanged: onSortChanged,
      options: const [
        AppSegmentOption(value: _PortfolioSortMode.newest, label: 'Newest'),
        AppSegmentOption(value: _PortfolioSortMode.value, label: 'Value'),
        AppSegmentOption(
          value: _PortfolioSortMode.confidence,
          label: 'Confidence',
        ),
      ],
    );
  }
}
