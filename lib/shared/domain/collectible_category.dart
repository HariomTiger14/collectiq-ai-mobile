/// Maps a raw, free-text collectible category (as stored on
/// [CollectibleItem.category], which may come from AI recognition, a manual
/// edit, or the catalog) to one of a small set of canonical display buckets.
///
/// Card game variants ("Pokemon Card", "Trading Card", "TCG") all collapse
/// into "Cards" so the same collection reads consistently everywhere it's
/// grouped or counted, instead of fragmenting into near-duplicate buckets.
String canonicalCategory(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) {
    return 'Other';
  }
  bool has(String token) => value.contains(token);
  if (has('card') ||
      has('tcg') ||
      has('pokemon') ||
      has('pokémon') ||
      has('magic') ||
      has('mtg') ||
      has('yu-gi') ||
      has('yugioh') ||
      has('one piece') ||
      has('trainer')) {
    return 'Cards';
  }
  if (has('coin') || has('numismat')) {
    return 'Coins';
  }
  if (has('comic')) {
    return 'Comics';
  }
  if (has('video game') ||
      has('game') ||
      has('cartridge') ||
      has('console')) {
    return 'Video Games';
  }
  if (has('lego')) {
    return 'LEGO';
  }
  if (has('funko')) {
    return 'Funko';
  }
  if (has('sneaker') ||
      has('shoe') ||
      has('streetwear') ||
      has('nike') ||
      has('jordan')) {
    return 'Sneakers';
  }
  if (has('watch')) {
    return 'Watches';
  }
  if (has('sport') ||
      has('jersey') ||
      has('autograph') ||
      has('memorabilia')) {
    return 'Sports';
  }
  if (has('figure') || has('toy')) {
    return 'Figures';
  }
  return _titleCase(raw.trim());
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}
