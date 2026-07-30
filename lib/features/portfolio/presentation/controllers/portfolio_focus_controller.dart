import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-shot navigation intents that let another surface (e.g. the Home
/// "N items need a valuation" strip) open the Portfolio tab pre-filtered.
///
/// The requesting widget sets the intent right before switching to the
/// Portfolio tab; the Portfolio screen reads it once on open, applies the
/// matching filter, then clears it so the focus never re-triggers on a
/// later manual visit.
enum PortfolioFocus {
  /// Show only items that still need a valuation ("Needs value" filter).
  needsValuation,
}

final portfolioFocusProvider =
    NotifierProvider<PortfolioFocusController, PortfolioFocus?>(
      PortfolioFocusController.new,
    );

class PortfolioFocusController extends Notifier<PortfolioFocus?> {
  @override
  PortfolioFocus? build() => null;

  /// Queue a focus intent for the next Portfolio open.
  void request(PortfolioFocus focus) => state = focus;

  /// Clear any pending intent. Call after the intent has been applied (from a
  /// post-frame callback — never during build/initState, which Riverpod
  /// forbids for provider mutations).
  void clear() {
    if (state != null) {
      state = null;
    }
  }
}
