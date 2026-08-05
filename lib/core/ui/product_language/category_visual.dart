import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/shared/domain/collectible_category.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Single source of truth for how a canonical collectible category is drawn:
/// its illustrated SVG mark (when one exists), a Material-icon fallback for
/// contexts that can't render the SVG, and its accent color. Home's category
/// tiles and Discover's quick filters both render from this so the same
/// category always looks the same wherever it appears, instead of each
/// screen keeping its own icon/color mapping that can drift out of sync.
class CategoryVisual {
  const CategoryVisual({
    required this.icon,
    required this.color,
    this.assetPath,
  });

  /// Material-icon fallback (e.g. for contexts that can't render an SVG, or
  /// while it loads).
  final IconData icon;

  /// Category accent color — stable per category identity, not by list
  /// position, so a chip/tile always matches its category across screens.
  final Color color;

  /// Illustrated SVG mark, when this category has dedicated artwork. Null
  /// falls back to [icon] alone.
  final String? assetPath;
}

// Only 4 accent colors, reused across related categories — matching Home's
// existing "Supported categories" reference band (home_page.dart,
// _supportedCategories), which is the authoritative choice: it does NOT
// give every category a unique hue, it groups them under these 4.
const _cardsColor = Color(0xFF22D3EE); // HomeTokens.categoryCards
const _coinsColor = Color(0xFFF4B740); // HomeTokens.categoryCoins
const _figuresColor = Color(0xFF9B7CFF); // HomeTokens.categoryFigures
const _moreColor = Color(0xFF00D88A); // HomeTokens.categoryMore
const _otherColor = Color(0xFF64748B);

/// Looks up the shared visual for a category label. Pass the label through
/// [canonicalCategory] first if it's raw/user-entered text. Icon and color
/// choices mirror home_page.dart's `_supportedCategories` reference band
/// exactly, so a category looks the same there as it does here.
CategoryVisual categoryVisualFor(String canonicalLabel) {
  switch (canonicalLabel) {
    case 'Cards':
      return const CategoryVisual(
        icon: Icons.style_outlined,
        color: _cardsColor,
        assetPath: PackLoxAssets.categoryColorCards,
      );
    case 'Coins':
      return const CategoryVisual(
        icon: Icons.album_outlined,
        color: _coinsColor,
        assetPath: PackLoxAssets.categoryColorCoins,
      );
    case 'Comics':
      return const CategoryVisual(
        icon: Icons.menu_book_outlined,
        color: _figuresColor,
        assetPath: PackLoxAssets.categoryColorComics,
      );
    case 'Video Games':
      return const CategoryVisual(
        icon: Icons.sports_esports_outlined,
        color: _moreColor,
        assetPath: PackLoxAssets.categoryColorGames,
      );
    case 'LEGO':
      return const CategoryVisual(
        icon: Icons.extension_outlined,
        color: _moreColor,
        assetPath: PackLoxAssets.categoryColorLego,
      );
    case 'Funko':
      return const CategoryVisual(
        icon: Icons.smart_toy_outlined,
        color: _figuresColor,
        assetPath: PackLoxAssets.categoryColorFunko,
      );
    case 'Sneakers':
      return const CategoryVisual(
        icon: Icons.directions_walk_outlined,
        color: _figuresColor,
        assetPath: PackLoxAssets.categoryColorSneakers,
      );
    case 'Watches':
      // Not yet a supported pricing category (see "Pricing sources" —
      // WatchCharts is listed as a future provider), so there's no
      // illustrated mark or an established color grouping to match yet.
      return const CategoryVisual(icon: Icons.watch_outlined, color: _otherColor);
    case 'Sports':
      return const CategoryVisual(
        icon: Icons.sports_basketball_outlined,
        color: _cardsColor,
        assetPath: PackLoxAssets.categoryColorSports,
      );
    case 'Figures':
      // No standalone "Figures" entry in _supportedCategories — Funko Pop
      // is its closest real-world analog, so share that icon/color/mark.
      return const CategoryVisual(
        icon: Icons.smart_toy_outlined,
        color: _figuresColor,
        assetPath: PackLoxAssets.categoryColorFunko,
      );
    default:
      return const CategoryVisual(
        icon: Icons.grid_view_outlined,
        color: _otherColor,
      );
  }
}

/// Renders a [CategoryVisual] as a colored circle — the illustrated SVG mark
/// when one exists (with a soft matching glow), otherwise the Material-icon
/// fallback. Used anywhere a category needs to look the same: Home's
/// category tiles, Discover's quick filters, and anywhere else that adopts
/// this shared mapping instead of drawing its own icon.
class CategoryArtwork extends StatelessWidget {
  const CategoryArtwork({required this.visual, this.size = 44, super.key});

  final CategoryVisual visual;
  final double size;

  @override
  Widget build(BuildContext context) {
    final assetPath = visual.assetPath;
    if (assetPath == null) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: visual.color.withValues(alpha: 0.14),
        ),
        child: Icon(visual.icon, color: visual.color, size: size * 0.55),
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: visual.color.withValues(alpha: 0.16),
              blurRadius: size * 0.4,
              spreadRadius: 1,
            ),
          ],
        ),
        child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
      ),
    );
  }
}
