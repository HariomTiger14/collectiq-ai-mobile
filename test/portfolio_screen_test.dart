import 'dart:convert';

import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:collectiq_ai/core/currency/fx_rates_repository.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/portfolio/presentation/portfolio_screen.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/plan_limits.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('empty state has no fake metrics and keeps scan action active', (
    tester,
  ) async {
    var scanTapped = false;

    await _pumpPortfolio(
      tester,
      onScanPressed: () {
        scanTapped = true;
      },
    );

    expect(find.text('Portfolio'), findsOneWidget);
    expect(find.text('Start with your first item'), findsOneWidget);
    expect(
      find.textContaining('Your portfolio is waiting for saved collectibles.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('portfolio-metric-grid')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('home-action-portfolio-guided-scan')),
    );
    await tester.pump();
    expect(scanTapped, isTrue);
  });

  testWidgets('default state renders real bound values and saved items', (
    tester,
  ) async {
    _seedPortfolio([
      _item('card-1', 'Hot Wheels 15 Mazda MX-5 Miata', 18),
      _item('card-2', 'Silver Eagle 2015', 0, category: 'Coin'),
      _item(
        'card-3',
        'Mystery No Match',
        0,
        valuationStatus: 'no_market_match',
      ),
    ]);

    await _pumpPortfolio(tester);

    // The overview hero is suppressed in the normal populated view; the metrics
    // now lead directly under the title.
    expect(find.text('Your collection at a glance'), findsNothing);
    expect(find.text('Collection value'), findsOneWidget);
    expect(find.text('\$18.00'), findsOneWidget);
    expect(find.text('Collection items'), findsOneWidget);
    expect(find.text('3'), findsWidgets);
    expect(find.text('1 need value'), findsWidgets);
    expect(find.byKey(const ValueKey('portfolio-action-sort')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portfolio-action-filter')),
      findsOneWidget,
    );

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-intelligence-panel')),
    );
    expect(find.text('Portfolio intelligence'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portfolio-health-score')),
      findsOneWidget,
    );
    expect(find.text('Pricing coverage'), findsOneWidget);
    expect(find.text('2/3'), findsOneWidget);
    expect(find.text('Avg confidence'), findsOneWidget);
    expect(find.text('91%'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portfolio-intelligence-locked-preview')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-intelligence-attention-queue')),
      findsNothing,
    );

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-card-1')),
    );
    expect(find.text('Hot Wheels 15 Mazda MX-5 Miata'), findsOneWidget);
  });

  testWidgets('paid plan unlocks full portfolio intelligence', (tester) async {
    _seedPortfolio([
      _item('paid-card', 'Pokemon Charizard', 1850),
      _item(
        'paid-pending',
        'Hot Wheels Mystery',
        0,
        category: 'Toy Car',
        valuationStatus: 'provider_not_configured',
        confidence: 0.62,
      ),
    ]);

    await _pumpPortfolio(tester, paidFeatures: true);

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-intelligence-panel')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-intelligence-locked-preview')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('portfolio-intelligence-attention-queue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-intelligence-top-value')),
      findsOneWidget,
    );
    expect(find.text('Attention queue'), findsOneWidget);
    expect(find.text('Top value items'), findsOneWidget);
    expect(find.text('Needs trusted value'), findsOneWidget);
    expect(find.text('Upgrade plan'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('portfolio-intelligence-action-trustedValue')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Needs trusted value view applied.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-paid-pending')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-paid-card')),
      findsNothing,
    );
  });

  testWidgets(
    'tapping a shortcut filter shows a clearable chip, and clearing it '
    'returns the full portfolio without opening the Filter sheet (real '
    'gap: tapping "Low confidence" filtered the list with no visible way '
    'back except discovering the Filter sheet\'s Reset button)',
    (tester) async {
      _seedPortfolio([
        _item('confident-card', 'Pokemon Charizard', 1850, confidence: 0.9),
        _item(
          'weak-card',
          'Blurry Scan',
          40,
          category: 'Trading Card',
          confidence: 0.55,
        ),
      ]);

      await _pumpPortfolio(tester, paidFeatures: true);

      await _revealPortfolio(
        tester,
        find.byKey(const ValueKey('portfolio-intelligence-action-lowConfidence')),
      );

      // No chip before the shortcut is used.
      expect(
        find.byKey(const ValueKey('portfolio-active-filter-chip')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('portfolio-intelligence-action-lowConfidence')),
      );
      await tester.pumpAndSettle();

      // Applying the shortcut auto-scrolls the list -- scroll back to where
      // the chip lives (inside the Attention queue card itself, right next
      // to the row that triggered it) before asserting on it.
      await _revealPortfolio(
        tester,
        find.byKey(const ValueKey('portfolio-active-filter-chip')),
      );

      // Chip appears, labeled with the shortcut's own name, and the list is
      // filtered down to only the low-confidence item.
      expect(
        find.byKey(const ValueKey('portfolio-active-filter-chip')),
        findsOneWidget,
      );
      expect(find.text('Low confidence'), findsWidgets);

      // The chip renders inside the Attention queue card itself (not up
      // near the toolbar, unrelated to where the shortcut lives) -- and the
      // row that triggered it is visually flagged as the active one.
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey('portfolio-intelligence-attention-queue'),
          ),
          matching: find.byKey(const ValueKey('portfolio-active-filter-chip')),
        ),
        findsOneWidget,
      );
      final lowConfidenceRow = find.byWidgetPredicate(
        (widget) =>
            widget.runtimeType.toString() == '_PortfolioAttentionRow' &&
            (widget as dynamic).data.title == 'Low confidence',
      );
      expect((lowConfidenceRow.evaluate().single.widget as dynamic).isActive, isTrue);
      final trustedValueRow = find.byWidgetPredicate(
        (widget) =>
            widget.runtimeType.toString() == '_PortfolioAttentionRow' &&
            (widget as dynamic).data.title == 'Needs trusted value',
      );
      expect((trustedValueRow.evaluate().single.widget as dynamic).isActive, isFalse);
      await _revealPortfolio(
        tester,
        find.byKey(const ValueKey('portfolio-grid-item-weak-card')),
      );
      expect(
        find.byKey(const ValueKey('portfolio-grid-item-weak-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('portfolio-grid-item-confident-card')),
        findsNothing,
      );

      // Tapping the chip clears the filter directly -- no Filter sheet.
      await _revealPortfolio(
        tester,
        find.byKey(const ValueKey('portfolio-active-filter-chip')),
      );
      await tester.tap(
        find.byKey(const ValueKey('portfolio-active-filter-chip')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('portfolio-active-filter-chip')),
        findsNothing,
      );
      await _revealPortfolio(
        tester,
        find.byKey(const ValueKey('portfolio-grid-item-weak-card')),
      );
      expect(
        find.byKey(const ValueKey('portfolio-grid-item-weak-card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('portfolio-grid-item-confident-card')),
        findsOneWidget,
      );
    },
  );

  testWidgets('paid intelligence add-more recommendation opens scan flow', (
    tester,
  ) async {
    var scanTapped = false;
    _seedPortfolio([
      _item('paid-card', 'Pokemon Charizard', 1850),
      _item('paid-eagle', 'Silver Eagle 2015', 52, category: 'Coin'),
    ]);

    await _pumpPortfolio(
      tester,
      paidFeatures: true,
      onScanPressed: () {
        scanTapped = true;
      },
    );

    await _revealPortfolio(
      tester,
      find.byKey(
        const ValueKey('portfolio-recommendation-action-addMoreCollectibles'),
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey('portfolio-recommendation-action-addMoreCollectibles'),
      ),
    );
    await tester.pump();

    expect(scanTapped, isTrue);
  });

  testWidgets('free plan keeps advanced filters visibly locked', (
    tester,
  ) async {
    _seedPortfolio([_item('free-card', 'Free Plan Charizard', 1850)]);
    await _pumpPortfolio(tester);

    await _tapPortfolioToolbarButton(
      tester,
      const ValueKey('portfolio-action-filter'),
    );
    await tester.pumpAndSettle();

    // The real sort/filter sheet stays closed; the upgrade sheet is shown.
    expect(_portfolioSheet, findsNothing);
    expect(
      find.byKey(const ValueKey('upgrade-sheet-activate')),
      findsOneWidget,
    );
    expect(find.text('Filter your whole collection'), findsOneWidget);
  });

  testWidgets('unavailable valuation is distinct from genuine zero', (
    tester,
  ) async {
    _seedPortfolio([
      _item(
        'unavailable-card',
        'Unavailable Charizard',
        0,
        valuationStatus: 'no_market_match',
      ),
      _item(
        'zero-card',
        'Zero Value Token',
        0,
        valuationStatus: 'market_estimated',
      ),
    ]);

    await _pumpPortfolio(tester);

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-unavailable-card')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-zero-card')),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('portfolio-grid-item-unavailable-card')),
        matching: find.text('No match'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('portfolio-grid-item-zero-card')),
        matching: find.text('\$0.00'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('loading skeleton renders without placeholder data copy', (
    tester,
  ) async {
    await _pumpPortfolio(
      tester,
      previewScenario: PortfolioPreviewScenario.loading,
    );

    expect(find.text('Preparing portfolio'), findsOneWidget);
    expect(
      find.text('Preparing your saved items, values, and filters.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-loading-skeleton')),
      findsOneWidget,
    );
    expect(find.textContaining('placeholder data'), findsNothing);
  });

  testWidgets('error state exposes one active Retry CTA', (tester) async {
    await _pumpPortfolio(
      tester,
      previewScenario: PortfolioPreviewScenario.error,
    );

    expect(find.text('Portfolio could not load'), findsOneWidget);
    expect(find.text('Check your connection and try again.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byKey(const ValueKey('portfolio-retry')), findsOneWidget);
  });

  testWidgets(
    'partial state uses amber needs value and green confirmed status',
    (tester) async {
      await _pumpPortfolio(
        tester,
        previewScenario: PortfolioPreviewScenario.partial,
      );

      await _revealPortfolio(tester, find.text('Needs value'));
      final pendingText = tester.widget<Text>(
        find
            .descendant(
              of: find.byKey(
                const ValueKey('portfolio-grid-item-partial-comic'),
              ),
              matching: find.text('Needs value'),
            )
            .first,
      );
      expect(pendingText.style?.color, HomeTokens.warning);

      final valuedText = tester.widget<Text>(find.text('Valued').first);
      expect(valuedText.style?.color, HomeTokens.positive);
    },
  );

  testWidgets('cloud upload state does not hide a displayable valuation', (
    tester,
  ) async {
    _seedPortfolio([
      _item(
        'uploading-card',
        'Uploading Charizard',
        350,
        syncStatus: 'pendingUpload',
      ),
      _item(
        'needs-value-card',
        'Needs Value Card',
        0,
        valuationStatus: 'no_market_match',
      ),
    ]);

    await _pumpPortfolio(tester);

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-uploading-card')),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('portfolio-grid-item-uploading-card')),
        matching: find.text('Valued'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('portfolio-grid-item-uploading-card')),
        matching: find.text('\$350.00'),
      ),
      findsOneWidget,
    );

    await _revealPortfolio(tester, find.text('1 need value'));
    expect(find.text('1 need value'), findsWidgets);
  });

  testWidgets('filtered empty keeps portfolio context and clears filters', (
    tester,
  ) async {
    await _pumpPortfolio(
      tester,
      previewScenario: PortfolioPreviewScenario.filteredEmpty,
    );

    await _revealPortfolio(tester, find.text('No matches found'));
    expect(find.text('No matches found'), findsWidgets);
    expect(find.text('Your portfolio is waiting'), findsNothing);
    // Quiet empty state: no "clear search" action — the user clears the field.
    expect(find.text('Clear search'), findsNothing);
    expect(find.byKey(const ValueKey('portfolio-clear-search')), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      '',
    );
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-preview-charizard')),
    );
    expect(find.text('Base Set Charizard'), findsOneWidget);
  });

  testWidgets(
    'search field keeps focus across keystrokes (no per-char rebuild)',
    (tester) async {
      _seedPortfolio([
        _item('search-card', 'Pokemon Charizard', 1850),
        _item('search-coin', 'Silver Eagle', 52, category: 'Coin'),
      ]);

      await _pumpPortfolio(tester);

      final fieldFinder = find.byKey(const ValueKey('portfolio-search-field'));

      // Capture the field's State after the first character is in, then assert
      // it survives subsequent keystrokes. The old query-embedded key rebuilt
      // the field on every character (dropping focus); sibling sections changing
      // as results filter (metrics/hero) also used to reshuffle + rebuild it.
      await tester.enterText(fieldFinder, 'c');
      await tester.pump();
      final searchState = tester.state(fieldFinder);

      // Another matching keystroke — field must not be rebuilt.
      await tester.enterText(fieldFinder, 'ch');
      await tester.pump();
      expect(tester.state(fieldFinder), same(searchState));

      // Type into no-match territory: the metrics/export sections collapse and
      // the quiet empty state appears below. The anchored field must survive.
      await tester.enterText(fieldFinder, 'chzzz');
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('portfolio-filtered-empty-state-surface')),
        findsOneWidget,
      );
      expect(tester.state(fieldFinder), same(searchState));

      final editable = tester.widget<EditableText>(
        find.descendant(of: fieldFinder, matching: find.byType(EditableText)),
      );
      expect(editable.focusNode.hasFocus, isTrue);
    },
  );

  testWidgets('entering a search query shows matching results', (tester) async {
    _seedPortfolio([
      _item('search-card', 'Pokemon Charizard', 1850),
      _item('search-coin', 'Silver Eagle', 52, category: 'Coin'),
    ]);

    await _pumpPortfolio(tester);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      'charizard',
    );
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-coin')),
      findsNothing,
    );
    await _revealToolbarControl(
      tester,
      const ValueKey('portfolio-search-clear'),
    );
    expect(
      find.byKey(const ValueKey('portfolio-search-clear')),
      findsOneWidget,
    );
  });

  testWidgets('clearing a search query restores current result list', (
    tester,
  ) async {
    _seedPortfolio([
      _item('search-card', 'Pokemon Charizard', 1850),
      _item('search-coin', 'Silver Eagle', 52, category: 'Coin'),
    ]);

    await _pumpPortfolio(tester);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      'charizard',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('portfolio-search-clear')));
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-search-coin')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-coin')),
      findsOneWidget,
    );
  });

  testWidgets('search with no results shows polished empty state', (
    tester,
  ) async {
    _seedPortfolio([
      _item('search-card', 'Pokemon Charizard', 1850),
      _item('search-coin', 'Silver Eagle', 52, category: 'Coin'),
    ]);

    await _pumpPortfolio(tester);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      'zzzzz',
    );
    await tester.pumpAndSettle();

    await _revealPortfolio(tester, find.text('No matches found'));
    expect(find.text('No matches found'), findsWidgets);
    // Quiet empty state: search-only has no button; the user just edits/clears
    // the field. Metrics + export collapse so the message sits under the field.
    expect(find.text('Clear search'), findsNothing);
    expect(find.byKey(const ValueKey('portfolio-clear-search')), findsNothing);
    expect(find.byKey(const ValueKey('portfolio-clear-filters')), findsNothing);
    expect(find.text('Collection value'), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      '',
    );
    await tester.pumpAndSettle();
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-search-card')),
      findsOneWidget,
    );
  });

  testWidgets('opens combined filter and sort bottom sheet', (tester) async {
    _seedPortfolio([_item('sort-card', 'Pokemon Charizard', 1850)]);
    await _pumpPortfolio(
      tester,
      size: const Size(430, 1200),
      paidFeatures: true,
    );

    await _tapPortfolioToolbarButton(
      tester,
      const ValueKey('portfolio-action-sort'),
    );
    await tester.pumpAndSettle();

    expect(_portfolioSheet, findsOneWidget);
    expect(find.text('Sort and filter'), findsOneWidget);
    expect(find.text('Recently added'), findsOneWidget);
    expect(find.text('Value: high to low'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('portfolio-sort-option-status')),
      findsOneWidget,
    );
    expect(find.text('Valued'), findsWidgets);
    await _revealSheetControl(tester, const ValueKey('portfolio-filter-reset'));
    await _revealSheetControl(tester, const ValueKey('portfolio-filter-apply'));
  });

  testWidgets('selecting a sort option is staged until Apply', (tester) async {
    _seedPortfolio([
      _item('low-card', 'Low Value Card', 12),
      _item('high-card', 'High Value Card', 240),
    ]);
    await _pumpPortfolio(
      tester,
      size: const Size(430, 1200),
      paidFeatures: true,
    );

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-low-card')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-high-card')),
    );
    expect(
      _itemTop(tester, 'low-card'),
      lessThan(_itemTop(tester, 'high-card')),
    );
    await _tapPortfolioToolbarButton(
      tester,
      const ValueKey('portfolio-action-filter'),
    );

    await _tapSheetControl(
      tester,
      const ValueKey('portfolio-sort-option-valueHigh'),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-low-card')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-high-card')),
    );
    expect(
      _itemTop(tester, 'low-card'),
      lessThan(_itemTop(tester, 'high-card')),
    );

    await _tapPortfolioToolbarButton(
      tester,
      const ValueKey('portfolio-action-sort'),
    );
    await _tapSheetControl(
      tester,
      const ValueKey('portfolio-sort-option-valueHigh'),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-high-card')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-low-card')),
    );
    expect(
      _itemTop(tester, 'high-card'),
      lessThan(_itemTop(tester, 'low-card')),
    );
    await _revealToolbarControl(
      tester,
      const ValueKey('portfolio-action-sort'),
    );
    expect(find.text('High value'), findsOneWidget);
  });

  testWidgets('selecting a filter option applies to Portfolio results', (
    tester,
  ) async {
    _seedPortfolio([
      _item('valued-card', 'Valued Charizard', 1850),
      _item(
        'pending-coin',
        'Pending Silver Eagle',
        0,
        category: 'Coin',
        valuationStatus: 'provider_not_configured',
      ),
    ]);
    await _pumpPortfolio(
      tester,
      size: const Size(430, 1200),
      paidFeatures: true,
    );

    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-status-filter-pending')),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-pending-coin')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-valued-card')),
      findsNothing,
    );
    await _revealToolbarControl(
      tester,
      const ValueKey('portfolio-action-filter'),
    );
    expect(find.text('Filter (1)'), findsOneWidget);
  });

  testWidgets('reset restores sheet selections before Apply', (tester) async {
    _seedPortfolio([
      _item('valued-card', 'Valued Charizard', 1850),
      _item(
        'pending-coin',
        'Pending Silver Eagle',
        0,
        category: 'Coin',
        valuationStatus: 'provider_not_configured',
      ),
    ]);
    await _pumpPortfolio(tester, paidFeatures: true);

    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-status-filter-pending')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('portfolio-sort-option-valueHigh')),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-reset'));
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-pending-coin')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-valued-card')),
    );
    await _revealToolbarControl(
      tester,
      const ValueKey('portfolio-action-filter'),
    );
    expect(find.text('Filter'), findsOneWidget);
    expect(find.text('Recent'), findsOneWidget);
  });

  testWidgets('apply can drive the filtered-empty Portfolio state', (
    tester,
  ) async {
    _seedPortfolio([
      _item('valued-card', 'Valued Charizard', 1850),
      _item('valued-coin', 'Valued Silver Eagle', 52, category: 'Coin'),
    ]);
    await _pumpPortfolio(tester, paidFeatures: true);

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      'charizard',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();
    await _tapSheetControl(
      tester,
      const ValueKey('portfolio-category-filter-coins'),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    await _revealPortfolio(tester, find.text('No matches found'));
    expect(
      find.byKey(const ValueKey('portfolio-filtered-empty-state-surface')),
      findsOneWidget,
    );
    expect(find.text('No matches found'), findsWidgets);
    // Search + filters: no clear-search action, but filters keep a lightweight
    // text button since they can't be dismissed by editing the search field.
    expect(find.text('Clear search'), findsNothing);
    expect(find.text('Clear filters'), findsOneWidget);
  });

  testWidgets('search clear preserves applied filter and sort state', (
    tester,
  ) async {
    _seedPortfolio([
      _item('valued-card', 'Valued Charizard', 1850),
      _item('low-coin', 'Low Silver Eagle', 52, category: 'Coin'),
      _item('high-coin', 'High Silver Eagle', 250, category: 'Coin'),
    ]);
    await _pumpPortfolio(tester, paidFeatures: true);

    await tester.tap(find.byKey(const ValueKey('portfolio-action-filter')));
    await tester.pumpAndSettle();
    await _tapSheetControl(
      tester,
      const ValueKey('portfolio-sort-option-valueHigh'),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(
      tester,
      const ValueKey('portfolio-category-filter-coins'),
    );
    await tester.pumpAndSettle();
    await _tapSheetControl(tester, const ValueKey('portfolio-filter-apply'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      'charizard',
    );
    await tester.pumpAndSettle();
    await _revealPortfolio(tester, find.text('No matches found'));

    await tester.enterText(
      find.byKey(const ValueKey('portfolio-search-field')),
      '',
    );
    await tester.pumpAndSettle();

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-high-coin')),
    );
    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-low-coin')),
    );
    expect(
      find.byKey(const ValueKey('portfolio-grid-item-valued-card')),
      findsNothing,
    );
    expect(
      _itemTop(tester, 'high-coin'),
      lessThan(_itemTop(tester, 'low-coin')),
    );
    await _revealToolbarControl(
      tester,
      const ValueKey('portfolio-action-filter'),
    );
    expect(find.text('Filter (1)'), findsOneWidget);
    expect(find.text('High value'), findsOneWidget);
  });

  testWidgets('item rows open existing Detail route', (tester) async {
    _seedPortfolio([_item('detail-card', 'Detail Charizard', 1850)]);
    await _pumpPortfolio(tester);

    await _revealPortfolio(
      tester,
      find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
    );
    await tester.tap(
      find.byKey(const ValueKey('portfolio-grid-item-detail-card')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Detail Charizard'), findsWidgets);
  });

  testWidgets(
    'Portfolio delete confirm removes item and can show empty state',
    (tester) async {
      _seedPortfolio([_item('remove-card', 'Remove Charizard', 1850)]);
      await _pumpPortfolio(tester);

      await _openDetailActions(tester, 'remove-card');
      await tester.tap(
        find.byKey(const ValueKey('collectible-detail-delete-action')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('collectible-delete-confirm-action')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('portfolio-grid-item-remove-card')),
        findsNothing,
      );
      expect(find.text('Start with your first item'), findsOneWidget);
    },
  );

  testWidgets(
    'narrow and large text layouts keep Portfolio controls reachable',
    (tester) async {
      _seedPortfolio([_item('narrow-card', 'Narrow Layout Charizard', 1850)]);
      await _pumpPortfolio(
        tester,
        size: const Size(320, 760),
        textScaler: const TextScaler.linear(1.25),
      );

      expect(
        find.byKey(const ValueKey('portfolio-search-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('portfolio-action-sort')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('portfolio-action-filter')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Portfolio preview screen selects in-memory scenario', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.dark,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.dark,
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).push(PortfolioStatePreviewScreen.route()),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('home-action-portfolio-preview-partial')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Portfolio State Preview'), findsNothing);
  });

  group('free-tier collectible counter', () {
    // The default preview portfolio has 3 saved items -- used as the fixed
    // "current usage" for these tests, varying only the cap.
    testWidgets('below cap: shows live usage, not a lock', (tester) async {
      await _pumpPortfolio(
        tester,
        previewScenario: PortfolioPreviewScenario.defaultData,
        planLimits: _freePlanLimits(maxPortfolioItems: 10),
      );
      await _revealPortfolio(
        tester,
        find.byKey(const ValueKey('free-collectible-counter')),
      );

      expect(find.text('3 of 10 free collectibles saved'), findsOneWidget);
      expect(
        find.text('Free collection full — upgrade to save more'),
        findsNothing,
      );
    });

    testWidgets('at cap: shows the full-collection message and a lock', (
      tester,
    ) async {
      await _pumpPortfolio(
        tester,
        previewScenario: PortfolioPreviewScenario.defaultData,
        planLimits: _freePlanLimits(maxPortfolioItems: 3),
      );
      await _revealPortfolio(
        tester,
        find.byKey(const ValueKey('free-collectible-counter')),
      );

      expect(
        find.text('Free collection full — upgrade to save more'),
        findsOneWidget,
      );
    });

    testWidgets('Pro (unlimited) plan: counter is not shown at all', (
      tester,
    ) async {
      await _pumpPortfolio(
        tester,
        previewScenario: PortfolioPreviewScenario.defaultData,
        paidFeatures: true,
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('free-collectible-counter')),
        findsNothing,
      );
      expect(find.textContaining('free collectibles'), findsNothing);
    });
  });
}

PlanLimits _freePlanLimits({required int maxPortfolioItems}) {
  return PlanLimits(
    plan: SubscriptionPlan.free,
    scanLimit: const UsageLimit(monthlyFreeScanLimit: 10),
    maxPortfolioItems: maxPortfolioItems,
    maxPhotosPerItem: 2,
    maxActivePriceAlerts: 1,
    monthlyPriceRefreshes: 10,
    canUseFullValueHistory: false,
    canExportPortfolio: false,
    canUseAdvancedFilters: false,
    canBulkRefreshValues: false,
    canUsePortfolioIntelligence: false,
  );
}

class _FakeFxRatesRepository implements FxRatesRepository {
  const _FakeFxRatesRepository();

  @override
  Future<FxRateSnapshot> fetchRates({DateTime? fromDate, DateTime? toDate}) async {
    return FxRateSnapshot.empty;
  }
}

Future<void> _pumpPortfolio(
  WidgetTester tester, {
  Size size = const Size(430, 844),
  TextScaler textScaler = TextScaler.noScaling,
  PortfolioPreviewScenario? previewScenario,
  VoidCallback? onScanPressed,
  bool paidFeatures = false,
  PlanLimits? planLimits,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (planLimits != null)
          activePlanLimitsProvider.overrideWithValue(planLimits)
        else if (paidFeatures)
          activePlanLimitsProvider.overrideWithValue(
            PlanLimits.forPlan(
              plan: SubscriptionPlan.pro,
              freeScanLimit: const UsageLimit(monthlyFreeScanLimit: 25),
            ),
          ),
        fxRatesRepositoryProvider.overrideWithValue(
          const _FakeFxRatesRepository(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: textScaler),
          child: Scaffold(
            body: PortfolioScreen(
              previewScenario: previewScenario,
              onScanPressed: onScanPressed,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Future<void> _revealPortfolio(WidgetTester tester, Finder finder) async {
  final scroll = find.byType(CustomScrollView);
  for (var attempt = 0; attempt < 12; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pump();
      return;
    }
    await tester.drag(scroll.first, const Offset(0, -260));
    await tester.pump();
  }
  for (var attempt = 0; attempt < 12; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder.first);
      await tester.pump();
      return;
    }
    await tester.drag(scroll.first, const Offset(0, 260));
    await tester.pump();
  }
  expect(finder, findsOneWidget);
}

Future<void> _tapPortfolioToolbarButton(
  WidgetTester tester,
  ValueKey<String> key,
) async {
  await _revealToolbarControl(tester, key);
  await tester.tap(find.byKey(key));
  await tester.pumpAndSettle();
}

Future<void> _revealToolbarControl(
  WidgetTester tester,
  ValueKey<String> key,
) async {
  final finder = find.byKey(key);
  final scroll = find.byType(CustomScrollView);
  for (var attempt = 0; attempt < 12; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(scroll.first, const Offset(0, 260));
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
}

Future<void> _openDetailActions(WidgetTester tester, String id) async {
  await _revealPortfolio(
    tester,
    find.byKey(ValueKey('portfolio-grid-item-$id')),
  );
  await tester.tap(find.byKey(ValueKey('portfolio-grid-item-$id')));
  await tester.pumpAndSettle();
  await _revealPortfolio(tester, find.text('Actions Menu'));
}

Future<void> _revealSheetControl(
  WidgetTester tester,
  ValueKey<String> key,
) async {
  final finder = find.byKey(key);
  for (var attempt = 0; attempt < 8; attempt += 1) {
    if (finder.evaluate().isNotEmpty) {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      return;
    }
    await tester.drag(_portfolioSheet, const Offset(0, -180));
    await tester.pumpAndSettle();
  }
  expect(finder, findsOneWidget);
}

Future<void> _tapSheetControl(WidgetTester tester, ValueKey<String> key) async {
  await _revealSheetControl(tester, key);
  await tester.tap(find.byKey(key));
}

Finder get _portfolioSheet {
  return find.byKey(const ValueKey('portfolio-premium-filter-sheet-surface'));
}

double _itemTop(WidgetTester tester, String id) {
  return tester.getTopLeft(find.byKey(ValueKey('portfolio-grid-item-$id'))).dy;
}

void _seedPortfolio(List<Map<String, Object?>> items) {
  SharedPreferences.setMockInitialValues({
    'portfolio_items': jsonEncode(items),
  });
}

Map<String, Object?> _item(
  String id,
  String title,
  double value, {
  String category = 'Trading Card',
  String imagePath = 'sample://card',
  String valuationStatus = 'market_estimated',
  String syncStatus = 'synced',
  double confidence = 0.91,
}) {
  return {
    'id': id,
    'title': title,
    'category': category,
    'estimatedValue': value,
    'confidence': confidence,
    'condition': 'Near Mint',
    'recommendation': 'Keep protected.',
    'imagePath': imagePath,
    'galleryImages': <Object>[],
    'createdAt': '2026-07-01T00:00:00.000Z',
    'syncStatus': syncStatus,
    'valuationStatus': valuationStatus,
    'valuationSource': valuationStatus,
    'marketSummary': {
      'averagePrice': value,
      'medianPrice': value,
      'lowPrice': value,
      'highPrice': value,
      'salesCount': 1,
      'trendLabel': 'Stable',
      'confidence': 0.80,
      'lastUpdated': '2026-07-01T00:00:00.000Z',
      'sources': ['test'],
      'comps': <Object>[],
    },
  };
}
