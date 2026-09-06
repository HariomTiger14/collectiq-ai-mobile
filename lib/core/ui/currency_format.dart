import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

/// Below this, a dollar change displays as "$0.00" either way (2-decimal
/// display, see [formatCollectionValue]) -- so it isn't a real gain or
/// loss as far as the user can see, just rounding/floating-point noise.
/// Shared by every surface that decides whether to color a change red/green
/// or label an item a "mover" (the portfolio value badge, its chart's
/// y-axis floor, and the Movers card), so they can never disagree about
/// what counts as "no real change".
const meaningfulValueChangeThreshold = 0.005;

/// The canonical money format for every collectible, portfolio, scan, alert
/// and catalog value in the app: `USD $30.65`, `AUD $30.65`, `CAD $30.65`,
/// `GBP £30.65`.
///
/// One format everywhere, and always an explicit ISO code. The app used to
/// carry five: `US$30.65`, `C$30.65`, a bare `$30.65` for AUD, `$200 AUD` on
/// Discover and `USD $200` on the detail page — the same amount reading
/// differently depending on which screen you were on. Worse, the bare `$` for
/// AUD and the `US$` for USD are a single character apart, which is a poor
/// way to distinguish two currencies that differ by ~40%.
///
/// Honesty first: this formats an amount in the currency the value is
/// *already* in — it never converts (no fabricated FX). Callers convert
/// first, and hand the resulting currency here; see `convertCurrentForDisplay`
/// in currency_conversion.dart, which returns both.
///
/// Not for subscription prices. Those come from App Store / Play Store
/// storefronts already formatted for the buyer's region, and must be shown
/// exactly as the store gives them.
String formatCollectionValue(
  double value, {
  String currencyCode = 'AUD',
  bool showDecimals = true,
}) {
  final amount = _withThousands(value, showDecimals);
  final code = currencyCode.trim().toUpperCase();
  final symbol = currencySymbolFor(code);
  return code.isEmpty ? '\$$amount' : '$code $symbol$amount';
}

/// The symbol to sit between an ISO code and the digits.
///
/// Deliberately the plain `$` for every dollar currency: the code in front is
/// what distinguishes them, so `US$` or `C$` here would say it twice.
String currencySymbolFor(String currencyCode) {
  switch (currencyCode.trim().toUpperCase()) {
    case 'GBP':
      return '£';
    case 'EUR':
      return '€';
    case 'JPY':
      return '¥';
    default:
      return '\$';
  }
}

/// The currency an item's value is expressed in (its pricing currency), falling
/// back to AUD when the item carries no explicit currency.
///
/// AUD rather than USD for the same reason as PricingInfo.fromJson: an item
/// with no currency at all is an older locally-stored record, written when
/// everything was AUD. Anything priced since carries its currency
/// explicitly, so this fallback never applies to provider data.
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
