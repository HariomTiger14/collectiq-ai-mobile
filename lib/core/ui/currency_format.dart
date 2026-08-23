import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

/// Below this, a dollar change displays as "$0.00" either way (2-decimal
/// display, see [formatCollectionValue]) -- so it isn't a real gain or
/// loss as far as the user can see, just rounding/floating-point noise.
/// Shared by every surface that decides whether to color a change red/green
/// or label an item a "mover" (the portfolio value badge, its chart's
/// y-axis floor, and the Movers card), so they can never disagree about
/// what counts as "no real change".
const meaningfulValueChangeThreshold = 0.005;

/// Compact collection-value formatting shared by the Home and Portfolio value
/// surfaces (hero total, metric tiles, per-item value labels).
///
/// Honesty first: this formats an amount in the currency the value is *already*
/// in — it never converts between currencies (no fabricated FX). Values arrive
/// pre-converted from the pricing backend when a display currency was requested
/// (see `ScanPricingQuoteService`), so the currency carried on each item is the
/// truth. `AUD` renders as a bare `$` to preserve the app's established compact
/// style; every other currency gets a disambiguating prefix so a USD/GBP value
/// can never masquerade as plain dollars.
String formatCollectionValue(
  double value, {
  String currencyCode = 'AUD',
  bool showDecimals = true,
}) {
  final amount = _withThousands(value, showDecimals);
  switch (currencyCode.trim().toUpperCase()) {
    case 'AUD':
    case '':
      return '\$$amount';
    case 'USD':
      return 'US\$$amount';
    case 'CAD':
      return 'C\$$amount';
    case 'NZD':
      return 'NZ\$$amount';
    case 'GBP':
      return '£$amount';
    case 'EUR':
      return '€$amount';
    case 'JPY':
      return '¥$amount';
    default:
      return '${currencyCode.trim().toUpperCase()} $amount';
  }
}

/// The currency an item's value is expressed in (its pricing currency), falling
/// back to AUD when the item carries no explicit currency.
String currencyForItem(CollectibleItem item) {
  final code = item.pricing?.currency.trim().toUpperCase();
  return (code == null || code.isEmpty) ? 'AUD' : code;
}

/// The dominant pricing currency among an item set's *valued* items — the
/// honest currency to label an aggregate total with (summing across mixed
/// currencies is meaningless, so we surface the currency the bulk of the value
/// is actually in). Falls back when nothing is valued yet.
String dominantDisplayCurrency(
  Iterable<CollectibleItem> items, {
  String fallback = 'AUD',
}) {
  final counts = <String, int>{};
  for (final item in items) {
    if (!item.hasTrustedValuation) {
      continue;
    }
    final code = item.pricing?.currency.trim().toUpperCase();
    if (code == null || code.isEmpty) {
      continue;
    }
    counts[code] = (counts[code] ?? 0) + 1;
  }
  if (counts.isEmpty) {
    return fallback.trim().toUpperCase();
  }
  final sorted = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      return byCount == 0 ? a.key.compareTo(b.key) : byCount;
    });
  return sorted.first.key;
}

String _withThousands(double value, bool showDecimals) {
  final base = showDecimals
      ? value.toStringAsFixed(2)
      : value.round().toString();
  final parts = base.split('.');
  final whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
  return parts.length > 1 ? '$whole.${parts[1]}' : whole;
}
