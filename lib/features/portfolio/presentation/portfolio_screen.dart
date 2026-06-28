import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_widgets.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _PortfolioSortMode {
  newest(label: 'Newest'),
  value(label: 'Value'),
  confidence(label: 'Confidence');

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
    final portfolioState = ref.watch(portfolioControllerProvider);
    final portfolioController = ref.read(portfolioControllerProvider.notifier);
    final visibleItems = _visibleItems(portfolioState.items);
    final averageConfidence = _averageConfidence(portfolioState.items);

    return AppScaffold(
      title: 'Portfolio',
      subtitle: 'Track, search, and manage your collection.',
      child: AppResponsiveColumn(
        spacing: AppSpacing.xl,
        children: [
          PortfolioSummaryCard(
            totalValue: portfolioState.totalValue,
            itemCount: portfolioState.itemCount,
            averageConfidence: averageConfidence,
          ),
          if (portfolioState.isLoading && portfolioState.items.isEmpty)
            const Center(child: CircularProgressIndicator())
          else if (portfolioState.errorMessage != null)
            PortfolioErrorState(message: portfolioState.errorMessage!)
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
            if (visibleItems.isEmpty)
              PortfolioNoSearchResultsState(
                onResetSearch: () {
                  setState(() {
                    _searchQuery = '';
                  });
                },
              )
            else
              PortfolioItemsGrid(
                items: visibleItems,
                onRemoveItem: (id) =>
                    _confirmDelete(context, id, portfolioController),
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

  String _averageConfidence(List<CollectibleItem> items) {
    if (items.isEmpty) {
      return '0%';
    }

    final total = items.fold<double>(0, (sum, item) => sum + item.confidence);
    return '${((total / items.length) * 100).toStringAsFixed(0)}%';
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
    return AppResponsiveColumn(
      spacing: AppSpacing.md,
      children: [
        SearchField(
          key: ValueKey(
            searchQuery.isEmpty
                ? 'portfolio-search-empty'
                : 'portfolio-search-active',
          ),
          initialValue: searchQuery,
          hintText: 'Search title or category',
          onChanged: onSearchChanged,
        ),
        _StableSortSelector(selectedMode: sortMode, onChanged: onSortChanged),
      ],
    );
  }
}

class _StableSortSelector extends StatelessWidget {
  const _StableSortSelector({
    required this.selectedMode,
    required this.onChanged,
  });

  final _PortfolioSortMode selectedMode;
  final ValueChanged<_PortfolioSortMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (var index = 0; index < _PortfolioSortMode.values.length; index++)
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : AppSpacing.xs),
                child: _StableSortOption(
                  mode: _PortfolioSortMode.values[index],
                  isSelected: selectedMode == _PortfolioSortMode.values[index],
                  onPressed: () => onChanged(_PortfolioSortMode.values[index]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StableSortOption extends StatelessWidget {
  const _StableSortOption({
    required this.mode,
    required this.isSelected,
    required this.onPressed,
  });

  final _PortfolioSortMode mode;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: isSelected ? colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.small),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: Icon(
                    Icons.check,
                    size: 16,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : Colors.transparent,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    mode.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
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
