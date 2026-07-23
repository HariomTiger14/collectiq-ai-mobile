import 'package:collectiq_ai/core/ui/navigation/glass_bottom_nav_bar.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum SearchPreviewState { defaultView, active, results, empty }

class SearchScreen extends StatelessWidget {
  const SearchScreen({
    this.previewState = SearchPreviewState.defaultView,
    super.key,
  });

  final SearchPreviewState previewState;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = GlassBottomNavBar.scrollContentClearance(context);
    final query = switch (previewState) {
      SearchPreviewState.active => 'Char',
      SearchPreviewState.results => 'Charizard',
      SearchPreviewState.empty => 'vintage camera',
      SearchPreviewState.defaultView => '',
    };
    final hasResults = previewState == SearchPreviewState.results;
    final isEmpty = previewState == SearchPreviewState.empty;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: const ValueKey('search-screen'),
        backgroundColor: PackLoxTokens.background,
        body: SafeArea(
          bottom: false,
          child: CustomScrollView(
            key: const ValueKey('search-scroll-view'),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 28, 16, bottomPadding),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SearchHeader(),
                          const SizedBox(height: 22),
                          _SearchField(
                            query: query,
                            isActive: previewState == SearchPreviewState.active,
                          ),
                          const SizedBox(height: 18),
                          if (isEmpty)
                            const _SearchEmptyState()
                          else ...[
                            _SearchStatusCard(hasResults: hasResults),
                            const SizedBox(height: 18),
                            if (hasResults) ...[
                              const _SectionTitle('Likely matches'),
                              const SizedBox(height: 10),
                              const _ResultCard(
                                title: 'Charizard Base Set',
                                subtitle: 'Trading card • Pokemon',
                                value: '\$245',
                                confidence: 'High match',
                                accent: PackLoxTokens.cyan,
                              ),
                              const SizedBox(height: 10),
                              const _ResultCard(
                                title: 'Charizard ex',
                                subtitle: 'Trading card • Scarlet & Violet',
                                value: '\$78',
                                confidence: 'Similar name',
                                accent: PackLoxTokens.blue,
                              ),
                            ] else ...[
                              const _SectionTitle('Explore by category'),
                              const SizedBox(height: 10),
                              const _CategoryGrid(),
                            ],
                            if (hasResults) ...[
                              const SizedBox(height: 18),
                              const _SectionTitle('Market signals'),
                              const SizedBox(height: 10),
                              const _MarketSignalList(),
                            ],
                          ],
                        ],
                      ),
                    ),
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

class _SearchHeader extends StatelessWidget {
  const _SearchHeader();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover',
          style: textTheme.displaySmall?.copyWith(
            color: PackLoxTokens.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Search collectible names, categories, and market signals.',
          style: textTheme.titleMedium?.copyWith(
            color: PackLoxTokens.textSecondary,
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.query, required this.isActive});

  final String query;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      key: const ValueKey('discover-search-field'),
      decoration: BoxDecoration(
        color: PackLoxTokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isActive ? PackLoxTokens.blue : PackLoxTokens.border,
          width: isActive ? 1.6 : 1,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: PackLoxTokens.blue.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            color: isActive ? PackLoxTokens.blue : PackLoxTokens.textSecondary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              query.isEmpty ? 'Search the market' : query,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: query.isEmpty
                    ? PackLoxTokens.textSecondary
                    : PackLoxTokens.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (query.isNotEmpty)
            Icon(
              Icons.close_rounded,
              color: PackLoxTokens.textSecondary,
              size: 20,
            ),
        ],
      ),
    );
  }
}

class _SearchStatusCard extends StatelessWidget {
  const _SearchStatusCard({required this.hasResults});

  final bool hasResults;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: PackLoxTokens.blue.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              hasResults
                  ? Icons.manage_search_rounded
                  : Icons.auto_awesome_outlined,
              color: PackLoxTokens.cyan,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasResults ? '2 market matches found' : 'Search is ready',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: PackLoxTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasResults
                      ? 'Review similar collectibles before saving a scan.'
                      : 'Discovery is prepared for collectible lookup.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PackLoxTokens.textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      key: const ValueKey('discover-empty-state'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: PackLoxTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: PackLoxTokens.border),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              color: PackLoxTokens.cyan,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matches found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: PackLoxTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a product name, card set, figure line, or brand.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: PackLoxTokens.textSecondary,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid();

  static const _items = [
    _CategoryItem('Cards', Icons.style_outlined, PackLoxTokens.cyan),
    _CategoryItem('Coins', Icons.album_outlined, PackLoxTokens.amber),
    _CategoryItem('Figures', Icons.smart_toy_outlined, Color(0xFF9B7CFF)),
    _CategoryItem('More', Icons.grid_view_outlined, PackLoxTokens.success),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 420 ? 4 : 2;
        return GridView.builder(
          itemCount: _items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 4 ? 1.1 : 2.2,
          ),
          itemBuilder: (context, index) {
            final item = _items[index];
            return _SurfaceCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(item.icon, color: item.color),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: PackLoxTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MarketSignalList extends StatelessWidget {
  const _MarketSignalList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SignalRow(
          icon: Icons.trending_up_rounded,
          title: 'Pokemon singles',
          subtitle: 'Higher demand this week',
          accent: PackLoxTokens.success,
        ),
        SizedBox(height: 10),
        _SignalRow(
          icon: Icons.query_stats_rounded,
          title: 'Graded cards',
          subtitle: 'Check condition before comparing',
          accent: PackLoxTokens.cyan,
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.confidence,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String value;
  final String confidence;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.inventory_2_outlined, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: PackLoxTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PackLoxTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: PackLoxTokens.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                confidence,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  const _SignalRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: PackLoxTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: PackLoxTokens.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: PackLoxTokens.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: PackLoxTokens.textPrimary,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PackLoxTokens.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PackLoxTokens.border),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _CategoryItem {
  const _CategoryItem(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;
}
