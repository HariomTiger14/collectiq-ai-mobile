import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/network/api_client.dart';
import 'package:collectiq_ai/core/network/api_constants.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/currency/fx_rate.dart';
import 'package:collectiq_ai/core/currency/fx_rates_provider.dart';
import 'package:collectiq_ai/core/currency/fx_rates_repository.dart';
import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/image_sync/domain/entities/image_upload_task.dart';
import 'package:collectiq_ai/features/image_sync/domain/entities/sync_queue_snapshot.dart';
import 'package:collectiq_ai/features/image_sync/domain/repositories/sync_queue_repository.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_valuation_snapshot_repository.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/plan_limits.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_limit.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/features/wishlist/domain/repositories/wishlist_repository.dart';
import 'package:collectiq_ai/features/wishlist/presentation/controllers/wishlist_providers.dart';
import 'package:collectiq_ai/qa_capture_app.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'approved detail surface renders compact header and inline sections',
    (tester) async {
      await _pumpDetail(tester, _authorityItem());

      expect(
        find.byKey(const ValueKey('collectible-detail-intelligence-panel')),
        findsOneWidget,
      );
      expect(find.text('Evidence looks healthy'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-authority-header')),
        findsOneWidget,
      );
      // The item leads directly now — no generic "Portfolio Detail" title block
      // and no repeated "Saved collectible" eyebrow. The name shows once, in the
      // overview below.
      expect(find.text('Portfolio Detail'), findsNothing);
      expect(
        find.byKey(const ValueKey('collectible-detail-authority-overview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('collectible-detail-title')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('collectible-detail-value-card')),
        findsWidgets,
      );
      expect(
        find.byKey(const ValueKey('collectible-detail-valued-state')),
        findsOneWidget,
      );
      expect(find.text('Valuation ready'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-inline-content')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('collectible-detail-authority-tabs')),
        findsNothing,
      );
      await _revealText(tester, 'Market & Value');
      expect(find.text('Market & Value'), findsOneWidget);
      expect(find.text('Value History'), findsOneWidget);
      expect(find.text('At scan'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Gain/Loss'), findsOneWidget);
      expect(find.text('USD \$200'), findsWidgets);
      expect(find.text('USD \$245'), findsWidgets);
      // Converted to the display currency (AUD, the default with no profile
      // override) at parity, not left in the item's own USD -- this is the
      // exact bug being fixed: a value/movement label must respect the
      // user's chosen display currency, not just the item's stored one.
      expect(find.text('+\$45 AUD'), findsOneWidget);
      expect(find.text('+22.5%'), findsOneWidget);
      await _revealText(tester, 'Pricing evidence');
      expect(find.text('Pricing evidence'), findsOneWidget);
      expect(find.text('Trusted market valuation'), findsWidgets);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('Provider'), findsWidgets);
      expect(find.text('Saved provider'), findsWidgets);
      expect(find.text('Currency'), findsWidgets);
      expect(find.text('Value range'), findsWidgets);
      expect(find.text('USD \$220 - \$270'), findsWidgets);
      expect(find.text('Portfolio record'), findsWidgets);
      expect(find.text('Collectible Details'), findsNothing);
    },
  );

  testWidgets(
    'overview gallery preserves saved image order and active preview switching',
    (tester) async {
      await _pumpDetail(tester, _authorityItem());

      // Image browsing lives in the overview hero + filmstrip at the top of the
      // screen; there is a single filmstrip (no duplicate in a gallery section).
      expect(
        find.byKey(const ValueKey('collectible-detail-gallery-filmstrip')),
        findsOneWidget,
      );

      final detailTile = find
          .byKey(const ValueKey('collectible-detail-gallery-sample://detail'))
          .last;
      await tester.ensureVisible(detailTile);
      await tester.pumpAndSettle();
      await tester.tap(detailTile);
      await tester.pumpAndSettle();

      // Selecting a thumbnail swaps the overview hero to that image.
      expect(
        find.byKey(const ValueKey('collectible-detail-hero-sample://detail')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'value card separates unavailable valuation from saved zero market value',
    (tester) async {
      // Unavailable: no trusted value → "No valuation saved" on the top card.
      await _pumpDetail(
        tester,
        _authorityItem(
          estimatedValue: 0,
          valuationStatus: ValuationStatus.unavailable,
        ),
      );
      expect(find.text('No valuation saved'), findsWidgets);
      expect(find.text('Estimated from saved market data'), findsNothing);

      // Saved zero market value: a trusted status with distinct copy.
      await _pumpDetail(
        tester,
        _authorityItem(
          estimatedValue: 0,
          valuationStatus: ValuationStatus.marketEstimated,
        ),
      );
      expect(find.text('Estimated from saved market data'), findsWidgets);
      expect(find.text('No valuation saved'), findsNothing);
    },
  );

  testWidgets('pricing trust explains unavailable market values', (
    tester,
  ) async {
    final item =
        _authorityItem(
          estimatedValue: 0,
          valuationStatus: ValuationStatus.noMarketMatch,
        ).copyWith(
          pricing: const PricingInfo(
            estimatedMarketValue: 0,
            lowEstimate: 0,
            highEstimate: 0,
            currency: 'USD',
            pricingSource: 'PriceCharting',
            pricingConfidence: 0.42,
            lastUpdated: null,
            valuationStatus: ValuationStatus.noMarketMatch,
            valuationSource: 'pricecharting',
            reasonCode: 'NO_MARKET_MATCH',
            valuationStrategy: 'catalog_lookup',
          ),
        );

    await _pumpDetail(tester, item);
    await _revealText(tester, 'Pricing evidence');

    expect(find.text('Pricing evidence'), findsOneWidget);
    expect(find.text('Unavailable'), findsOneWidget);
    expect(find.text('No trusted match yet'), findsWidgets);
    expect(
      find.text(
        'PackLox could not match this item to a trusted pricing source. Add the exact name, set, number, SKU, or condition and recheck value.',
      ),
      findsWidgets,
    );
    expect(find.text('Pricing confidence'), findsWidgets);
    expect(find.text('Not available'), findsWidgets);
    expect(find.text('Match basis'), findsNothing);
    expect(find.text('Reason'), findsWidgets);
  });

  testWidgets('favorite action persists wishlist status', (tester) async {
    final repository = _MemoryWishlistRepository();
    final item = _authorityItem();
    await _pumpDetail(tester, item, wishlistRepository: repository);

    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-favorite-action')),
    );
    await tester.pumpAndSettle();

    expect(await repository.getStatusForItem(item.id), WishlistStatus.wanted);
    expect(find.text('Added to wishlist'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-favorite-action')),
    );
    await tester.pumpAndSettle();

    expect(await repository.getStatusForItem(item.id), WishlistStatus.owned);
    expect(find.text('Removed from wishlist'), findsOneWidget);
  });

  testWidgets('pending detail state keeps valuation and image fallbacks clear', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _authorityItem(
        estimatedValue: 0,
        valuationStatus: ValuationStatus.noMarketMatch,
        imagePath: '',
        galleryImages: const [],
      ),
    );

    expect(
      find.byKey(const ValueKey('collectible-detail-pending-valuation-state')),
      findsOneWidget,
    );
    expect(find.text('Valuation pending'), findsWidgets);
    expect(find.text('Value unavailable'), findsWidgets);
    expect(
      find.byKey(const ValueKey('collectible-detail-missing-image-fallback')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey(
          'collectible-detail-state-art-${PackLoxAssets.portfolioDetailPendingValuation}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('fallback art distinguishes valued and missing image states', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _authorityItem(
        valuationStatus: ValuationStatus.marketEstimated,
        imagePath: '',
        galleryImages: const [],
      ),
    );

    expect(
      find.byKey(
        const ValueKey(
          'collectible-detail-state-art-${PackLoxAssets.portfolioDetailValuedItem}',
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('Valuation ready'), findsWidgets);

    await _pumpDetail(
      tester,
      _authorityItem(
        estimatedValue: 0,
        valuationStatus: ValuationStatus.unavailable,
        imagePath: '',
        galleryImages: const [],
      ),
    );

    expect(
      find.byKey(
        const ValueKey(
          'collectible-detail-state-art-${PackLoxAssets.portfolioDetailMissingImage}',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collectible-detail-unvalued-state')),
      findsOneWidget,
    );
    expect(find.text('Image needed'), findsOneWidget);
    expect(find.text('No valuation saved'), findsWidgets);
  });

  testWidgets('catalog placeholder item prompts user to add photos', (
    tester,
  ) async {
    await _pumpDetail(
      tester,
      _authorityItem(
        imagePath:
            'assets/packlox/icons/categories/3d/packlox_category_placeholder_card_v1.png',
        galleryImages: const [],
      ),
    );

    await _revealText(tester, 'Add your photos');

    expect(
      find.byKey(const ValueKey('collectible-detail-photo-evidence-prompt')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('collectible-detail-add-photo-action')),
      findsOneWidget,
    );
    expect(find.textContaining('saved from catalog search'), findsOneWidget);
  });

  testWidgets('adding a portfolio photo preserves existing gallery images', (
    tester,
  ) async {
    final item = _authorityItem();
    final repository = _MemoryPortfolioRepository([item]);
    final syncQueueRepository = _RecordingSyncQueueRepository();
    final galleryService = _FakeGalleryService(
      pickedImage: XFile('/source/new-front.jpg', name: 'new-front.jpg'),
      persistedImage: XFile('/persisted/new-front.jpg', name: 'new-front.jpg'),
    );

    await _pumpDetail(
      tester,
      item,
      portfolioRepository: repository,
      galleryService: galleryService,
      syncQueueRepository: syncQueueRepository,
      planLimits: _premiumPlanLimits,
    );

    await _revealText(tester, 'Image Gallery');
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-gallery-add-photo-action')),
    );
    await tester.pumpAndSettle();

    final updated = repository.items.single;
    expect(updated.imagePath, '/persisted/new-front.jpg');
    expect(updated.galleryImages, hasLength(3));
    expect(updated.galleryImages.last.path, '/persisted/new-front.jpg');
    expect(updated.galleryImages.last.isPrimary, isTrue);
    expect(
      updated.galleryImages.take(2).every((image) => image.isPrimary == false),
      isTrue,
    );
    expect(syncQueueRepository.tasks, hasLength(1));
    expect(syncQueueRepository.tasks.single.collectibleId, item.id);
    expect(
      syncQueueRepository.tasks.single.localPath,
      '/persisted/new-front.jpg',
    );
    expect(find.text('Photo added to portfolio item'), findsOneWidget);
  });

  testWidgets('unavailable refresh keeps saved valuation evidence', (
    tester,
  ) async {
    final item = _authorityItem();
    final repository = _MemoryPortfolioRepository([item]);

    await _pumpDetail(
      tester,
      item,
      portfolioRepository: repository,
      apiClient: _UnavailablePricingApiClient(),
    );

    await _revealText(tester, 'Actions Menu');
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-refresh-value-action')),
    );
    await tester.pumpAndSettle();

    final updated = repository.items.single;
    expect(updated.estimatedValue, item.estimatedValue);
    expect(
      updated.pricing?.estimatedMarketValue,
      item.pricing?.estimatedMarketValue,
    );
    expect(updated.pricing?.pricingSource, 'Saved provider');
    expect(updated.valuationStatus, ValuationStatus.marketEstimated);
    expect(updated.valueAtScan, item.valueAtScan);
    expect(
      find.text('No trusted match. Correct details and reprice.'),
      findsOneWidget,
    );
  });

  testWidgets('refresh value uses backend reprice contract', (tester) async {
    final item = _authorityItem();
    final repository = _MemoryPortfolioRepository([item]);
    final apiClient = _SuccessfulRepriceApiClient();
    final valuationSnapshots = _RecordingValuationSnapshotRepository();

    await _pumpDetail(
      tester,
      item,
      portfolioRepository: repository,
      apiClient: apiClient,
      valuationSnapshotRepository: valuationSnapshots,
    );

    await _revealText(tester, 'Actions Menu');
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-refresh-value-action')),
    );
    await tester.pumpAndSettle();

    expect(apiClient.lastPath, ApiConstants.pricingRepricePath);
    final payload = apiClient.lastPayload;
    expect(payload['itemId'], item.id);
    expect(payload['previousValue'], item.pricing?.estimatedMarketValue);
    expect(payload['previousCurrency'], item.pricing?.currency);
    expect(payload['correctionSource'], 'portfolio_manual_correction');
    final identity = payload['identity'] as Map<String, dynamic>;
    expect(identity['title'], item.title);
    expect(identity['category'], item.category);
    expect(identity['setName'], item.setName);
    expect(identity['cardNumber'], item.cardNumber);

    final updated = repository.items.single;
    expect(updated.estimatedValue, 310);
    expect(updated.valuationStatus, ValuationStatus.marketEstimated);
    expect(updated.valuationSource, 'PriceCharting');
    expect(updated.pricing?.pricingSource, 'PriceCharting');
    expect(updated.valueAtScan, item.valueAtScan);
    expect(updated.lastValueRefreshedAt, isNotNull);
    expect(valuationSnapshots.recordedItems, hasLength(1));
    expect(valuationSnapshots.recordedItems.single.id, item.id);
    expect(valuationSnapshots.snapshots, hasLength(1));
    expect(valuationSnapshots.snapshots.single.valueAud, 310);
    expect(
      valuationSnapshots.snapshots.single.pricingProvider,
      'PriceCharting',
    );
    expect(find.text('Portfolio value refreshed'), findsOneWidget);
  });

  testWidgets('refresh value skips duplicate history when value is unchanged', (
    tester,
  ) async {
    final item = _authorityItem(estimatedValue: 310).copyWith(
      pricing: const PricingInfo(
        estimatedMarketValue: 310,
        lowEstimate: 290,
        highEstimate: 340,
        currency: 'USD',
        pricingSource: 'PriceCharting',
        pricingConfidence: 0.88,
        lastUpdated: null,
        valuationStatus: ValuationStatus.marketEstimated,
        valuationSource: 'PriceCharting',
      ),
      valuationStatus: ValuationStatus.marketEstimated,
      valuationSource: 'PriceCharting',
      lastValueRefreshedAt: DateTime(2026, 7, 26),
    );
    final repository = _MemoryPortfolioRepository([item]);
    final apiClient = _SuccessfulRepriceApiClient(value: 310);
    final valuationSnapshots = _RecordingValuationSnapshotRepository();
    valuationSnapshots.snapshots.add(
      PortfolioValuationSnapshot(
        id: 'detail-authority-item-seeded',
        portfolioItemId: 'detail-authority-item',
        valueAud: 310,
        lowEstimateAud: 290,
        highEstimateAud: 340,
        displayString: 'USD \$310.00',
        valuationStatus: ValuationStatus.marketEstimated,
        pricingProvider: 'PriceCharting',
        confidenceScore: 0.88,
        pricedAt: DateTime(2026, 7, 26),
      ),
    );

    await _pumpDetail(
      tester,
      item,
      portfolioRepository: repository,
      apiClient: apiClient,
      valuationSnapshotRepository: valuationSnapshots,
    );

    await _revealText(tester, 'Actions Menu');
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-refresh-value-action')),
    );
    await tester.pumpAndSettle();

    expect(repository.items.single.lastValueRefreshedAt, isNotNull);
    expect(valuationSnapshots.recordedItems, isEmpty);
    expect(valuationSnapshots.snapshots, hasLength(1));
    expect(find.text('Portfolio value refreshed'), findsOneWidget);
  });

  testWidgets('correct and reprice uses backend reprice contract', (
    tester,
  ) async {
    final item = _authorityItem();
    final repository = _MemoryPortfolioRepository([item]);
    final apiClient = _SuccessfulRepriceApiClient();

    await _pumpDetail(
      tester,
      item,
      portfolioRepository: repository,
      apiClient: apiClient,
    );

    await _openEditSheet(tester);
    expect(find.text('Save & reprice'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      '1999 Pokemon Charizard Holo',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-category-field')),
      'Pokemon Card',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-set-field')),
      'Base Set',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-card-number-field')),
      '4/102',
    );
    await tester.tap(
      find.byKey(const ValueKey('edit-collectible-save-retry-pricing-button')),
    );
    await tester.pumpAndSettle();

    expect(apiClient.lastPath, ApiConstants.pricingRepricePath);
    final payload = apiClient.lastPayload;
    expect(payload['correctionSource'], 'portfolio_manual_correction');
    final identity = payload['identity'] as Map<String, dynamic>;
    expect(identity['title'], '1999 Pokemon Charizard Holo');
    expect(identity['category'], 'Pokemon Card');
    expect(identity['setName'], 'Base Set');
    expect(identity['cardNumber'], '4/102');

    final updated = repository.items.single;
    expect(updated.title, '1999 Pokemon Charizard Holo');
    expect(updated.category, 'Pokemon Card');
    expect(updated.estimatedValue, 310);
    expect(updated.valuationStatus, ValuationStatus.marketEstimated);
    expect(updated.valuationSource, 'PriceCharting');
    expect(updated.pricing?.pricingSource, 'PriceCharting');
    expect(updated.pricing?.reasonCode, isNull);
    expect(updated.valueAtScan, item.valueAtScan);
    expect(find.text('Details saved and pricing refreshed'), findsOneWidget);
  });

  testWidgets('catalog saved item shows valuation snapshot evidence', (
    tester,
  ) async {
    await _pumpDetail(tester, _catalogSnapshotItem());

    await _revealText(tester, 'Saved valuation snapshot');

    expect(
      find.byKey(const ValueKey('collectible-detail-catalog-snapshot-card')),
      findsOneWidget,
    );
    expect(find.text('Saved valuation snapshot'), findsOneWidget);
    expect(
      find.textContaining('Opening Portfolio does not call pricing APIs'),
      findsOneWidget,
    );
    expect(find.text('Snapshot value'), findsOneWidget);
    expect(find.text('USD \$161'), findsWidgets);
    expect(find.text('Gain/Loss'), findsNothing);
    expect(
      find.text('Refresh value to save the first trusted history point.'),
      findsOneWidget,
    );
    expect(find.text('+Value unavailable'), findsNothing);
    expect(find.text('Source'), findsWidgets);
    expect(find.text('PriceCharting'), findsWidgets);
    expect(find.text('Catalog ID'), findsOneWidget);
    expect(find.text('3666974'), findsOneWidget);
    expect(find.text('Attribution'), findsOneWidget);
    expect(find.text('Pricing data by PriceCharting'), findsWidgets);
    expect(find.text('Strategy'), findsOneWidget);
    expect(find.text('Catalog Lookup'), findsOneWidget);
  });

  testWidgets('QA capture exposes Portfolio Detail visual states', (
    tester,
  ) async {
    for (final screen in [
      'portfolio_detail_valued',
      'portfolio_detail_pending',
      'portfolio_detail_missing_image',
    ]) {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: PackLoxQaCaptureScreen(screen: screen, scroll: ''),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Portfolio Detail'), findsNothing);
      expect(
        find.byKey(const ValueKey('collectible-detail-authority-overview')),
        findsOneWidget,
      );
    }
  });

  testWidgets(
    'inline detail page exposes metadata, AI evidence, notes, and actions',
    (tester) async {
      var deleted = false;
      await _pumpDetail(
        tester,
        _authorityItem(),
        onDelete: (_) async {
          deleted = true;
          return true;
        },
      );

      await _revealText(tester, 'Details & Info');
      expect(find.text('Details & Info'), findsOneWidget);
      expect(find.text('Brand'), findsOneWidget);
      expect(find.text('PackLox Motors'), findsOneWidget);

      await _revealText(tester, 'Item insights');
      expect(find.text('Item insights'), findsOneWidget);
      expect(
        find.textContaining('Stored scan reasoning only.'),
        findsOneWidget,
      );

      await _revealText(tester, 'Stored owner note.');
      expect(
        find.byKey(const ValueKey('collectible-detail-notes-edit-button')),
        findsOneWidget,
      );
      expect(find.text('Stored owner note.'), findsOneWidget);
      expect(find.text('Local only'), findsOneWidget);

      await _revealText(tester, 'Actions Menu');
      expect(find.text('Actions Menu'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('collectible-detail-primary-edit-action')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('collectible-detail-delete-action')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Remove collectible?'), findsOneWidget);
      expect(find.text('PackLox Authority Coupe'), findsWidgets);
      await tester.tap(
        find.byKey(const ValueKey('collectible-delete-confirm-action')),
      );
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    },
  );

  testWidgets('delete confirmation cancel keeps item', (tester) async {
    var deleted = false;
    await _pumpDetail(
      tester,
      _authorityItem(),
      onDelete: (_) async {
        deleted = true;
        return true;
      },
    );

    await _revealText(tester, 'Actions Menu');
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-delete-action')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('collectible-delete-confirmation-sheet')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('collectible-delete-cancel-action')),
    );
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(
      find.byKey(const ValueKey('collectible-delete-confirmation-sheet')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('collectible-detail-delete-action')),
      findsOneWidget,
    );
  });

  testWidgets('delete confirmation dismiss keeps item', (tester) async {
    var deleted = false;
    await _pumpDetail(
      tester,
      _authorityItem(),
      onDelete: (_) async {
        deleted = true;
        return true;
      },
    );

    await _revealText(tester, 'Actions Menu');
    await tester.tap(
      find.byKey(const ValueKey('collectible-detail-delete-action')),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(deleted, isFalse);
    expect(
      find.byKey(const ValueKey('collectible-delete-confirmation-sheet')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('collectible-detail-delete-action')),
      findsOneWidget,
    );
  });

  testWidgets('opening edit flow from Detail shows supported fields', (
    tester,
  ) async {
    await _pumpDetail(tester, _authorityItem());

    await _openEditSheet(tester);

    expect(find.text('Edit item details'), findsOneWidget);
    expect(find.text('PackLox Authority Coupe'), findsWidgets);
    expect(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-collectible-category-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-collectible-low-value-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('edit-collectible-high-value-field')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('edit-collectible-save-button')),
      findsOneWidget,
    );
  });

  testWidgets('edit cancel keeps existing item', (tester) async {
    await _pumpDetail(tester, _authorityItem());
    await _openEditSheet(tester);

    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      'Cancelled Coupe',
    );
    await tester.tap(
      find.byKey(const ValueKey('edit-collectible-cancel-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cancelled Coupe'), findsNothing);
    expect(find.byKey(const ValueKey('edit-collectible-sheet')), findsNothing);
  });

  testWidgets('edit dismiss keeps existing item', (tester) async {
    await _pumpDetail(tester, _authorityItem());
    await _openEditSheet(tester);

    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      'Dismissed Coupe',
    );
    await tester.tapAt(const Offset(12, 12));
    await tester.pumpAndSettle();

    expect(find.text('Dismissed Coupe'), findsNothing);
    expect(find.byKey(const ValueKey('edit-collectible-sheet')), findsNothing);
  });

  testWidgets('edit validation requires supported required fields', (
    tester,
  ) async {
    await _pumpDetail(tester, _authorityItem());
    await _openEditSheet(tester);

    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      '',
    );
    await tester.tap(
      find.byKey(const ValueKey('edit-collectible-save-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Required'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('edit-collectible-sheet')),
      findsOneWidget,
    );
  });

  testWidgets('edit save updates Detail supported fields', (tester) async {
    await _pumpDetail(tester, _authorityItem());
    await _openEditSheet(tester);

    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-title-field')),
      'Edited Authority Coupe',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-category-field')),
      'Trading Card',
    );
    await tester.enterText(
      find.byKey(const ValueKey('edit-collectible-set-field')),
      'Edited Set',
    );
    await tester.tap(
      find.byKey(const ValueKey('edit-collectible-save-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('edit-collectible-sheet')), findsNothing);
    expect(find.text('Collectible updated'), findsOneWidget);
  });

  testWidgets('detail intelligence review opens correction sheet', (
    tester,
  ) async {
    final item =
        _authorityItem(
          estimatedValue: 0,
          valuationStatus: ValuationStatus.noMarketMatch,
          imagePath: '',
          galleryImages: const [],
        ).copyWith(
          category: 'Pokemon Card',
          setName: '',
          cardNumber: '',
          rarity: '',
          pricing: const PricingInfo(
            estimatedMarketValue: 0,
            lowEstimate: 0,
            highEstimate: 0,
            currency: 'USD',
            pricingSource: 'PriceCharting',
            pricingConfidence: 0.42,
            lastUpdated: null,
            valuationStatus: ValuationStatus.noMarketMatch,
            valuationSource: 'pricecharting',
            reasonCode: 'NO_MARKET_MATCH',
            valuationStrategy: 'catalog_lookup',
          ),
        );

    await _pumpDetail(tester, item);

    expect(
      find.byKey(const ValueKey('collectible-detail-intelligence-panel')),
      findsOneWidget,
    );
    expect(find.text('Trusted value needs review'), findsOneWidget);
    expect(find.textContaining('Review the identity fields'), findsOneWidget);
    await tester.tap(
      find.byKey(
        const ValueKey('collectible-detail-intelligence-review-details-action'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('edit-collectible-sheet')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('edit-collectible-card-number-field')),
      findsOneWidget,
    );
    expect(find.text('Save & reprice'), findsOneWidget);
  });
}

Future<void> _pumpDetail(
  WidgetTester tester,
  CollectibleItem item, {
  Future<bool> Function(String itemId)? onDelete,
  WishlistRepository? wishlistRepository,
  PortfolioRepository? portfolioRepository,
  GalleryService? galleryService,
  SyncQueueRepository? syncQueueRepository,
  ApiClient? apiClient,
  PlanLimits? planLimits,
  SharedPreferencesValuationSnapshotRepository? valuationSnapshotRepository,
}) async {
  tester.view.physicalSize = const Size(900, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        if (wishlistRepository != null)
          wishlistRepositoryProvider.overrideWithValue(wishlistRepository),
        if (portfolioRepository != null)
          portfolioRepositoryProvider.overrideWithValue(portfolioRepository),
        if (galleryService != null)
          galleryServiceProvider.overrideWithValue(galleryService),
        if (syncQueueRepository != null) ...[
          supabaseConfigProvider.overrideWithValue(
            const SupabaseConfig(
              url: 'https://packlox.test',
              anonKey: 'test-anon-key',
              isEnabled: true,
            ),
          ),
          syncQueueRepositoryProvider.overrideWithValue(syncQueueRepository),
        ],
        if (apiClient != null) apiClientProvider.overrideWithValue(apiClient),
        if (planLimits != null)
          activePlanLimitsProvider.overrideWithValue(planLimits),
        if (valuationSnapshotRepository != null)
          valuationSnapshotRepositoryProvider.overrideWithValue(
            valuationSnapshotRepository,
          ),
        // Fixed, no-network rates so currency-display tests are
        // deterministic. Parity (1.0 for every tracked currency) keeps
        // every pre-existing dollar-amount assertion in this file valid --
        // converting at parity only changes which currency label is shown,
        // never the number.
        fxRatesRepositoryProvider.overrideWithValue(
          const _FixedRateFxRatesRepository({
            'USD': 1.0,
            'AUD': 1.0,
            'CAD': 1.0,
            'GBP': 1.0,
          }),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.dark,
        home: CollectibleDetailPage(item: item, onDelete: onDelete),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _FixedRateFxRatesRepository implements FxRatesRepository {
  const _FixedRateFxRatesRepository(this.rates);

  final Map<String, double> rates;

  @override
  Future<FxRateSnapshot> fetchRates({DateTime? fromDate, DateTime? toDate}) async {
    return FxRateSnapshot(currentRates: rates, history: const []);
  }
}

class _RecordingValuationSnapshotRepository
    extends SharedPreferencesValuationSnapshotRepository {
  final List<CollectibleItem> recordedItems = [];
  final List<PortfolioValuationSnapshot> snapshots = [];

  @override
  Future<List<PortfolioValuationSnapshot>> getSnapshots(String itemId) async {
    return snapshots
        .where((snapshot) => snapshot.portfolioItemId == itemId)
        .toList();
  }

  @override
  Future<void> recordSnapshot(CollectibleItem item) async {
    recordedItems.add(item);
    final pricing = item.pricing;
    final value = pricing?.estimatedMarketValue;
    snapshots.add(
      PortfolioValuationSnapshot(
        id: '${item.id}-${snapshots.length + 1}',
        portfolioItemId: item.id,
        valueAud: value,
        lowEstimateAud: pricing?.lowEstimate,
        highEstimateAud: pricing?.highEstimate,
        displayString: pricing?.displayString,
        valuationStatus: item.valuationStatus,
        pricingProvider: pricing?.pricingSource,
        confidenceScore: pricing?.pricingConfidence,
        pricedAt: item.lastValueRefreshedAt ?? DateTime(2026, 7, 27),
      ),
    );
  }
}

const _premiumPlanLimits = PlanLimits(
  plan: SubscriptionPlan.premium,
  scanLimit: UsageLimit.unlimited,
  maxPortfolioItems: 10000,
  maxPhotosPerItem: 12,
  maxActivePriceAlerts: 100,
  monthlyPriceRefreshes: 1000,
  canUseFullValueHistory: true,
  canExportPortfolio: true,
  canUseAdvancedFilters: true,
  canBulkRefreshValues: true,
  canUsePortfolioIntelligence: true,
);

class _MemoryPortfolioRepository implements PortfolioRepository {
  _MemoryPortfolioRepository(this.items);

  final List<CollectibleItem> items;

  @override
  Future<CollectibleItem> addItem(CollectibleItem item) async {
    items.add(item);
    return item;
  }

  @override
  Future<void> clearPortfolio() async {
    items.clear();
  }

  @override
  Future<List<CollectibleItem>> getItems() async {
    return items;
  }

  @override
  Future<void> removeItem(String id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> updateItem(CollectibleItem item) async {
    final index = items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      items[index] = item;
    }
  }

  @override
  Future<void> updateItemImageSync({
    required String itemId,
    required String imageStoragePath,
    required String cloudImageUrl,
  }) async {}

  @override
  Future<void> upsertSyncedItem(CollectibleItem item) async {
    await updateItem(item);
  }
}

class _RecordingSyncQueueRepository implements SyncQueueRepository {
  final List<ImageUploadTask> tasks = [];
  DateTime? lastSyncAt;

  @override
  Future<ImageUploadTask> enqueueImageUpload({
    required String collectibleId,
    required String localPath,
  }) async {
    final now = DateTime(2026, 7, 26, 12);
    final task = ImageUploadTask(
      id: 'queued-${tasks.length + 1}',
      collectibleId: collectibleId,
      localPath: localPath,
      status: ImageUploadTaskStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    tasks.add(task);
    return task;
  }

  @override
  Future<List<ImageUploadTask>> getTasks() async => List.unmodifiable(tasks);

  @override
  Future<List<ImageUploadTask>> getUploadableTasks() async => const [];

  @override
  Future<void> markLastSync(DateTime syncedAt) async {
    lastSyncAt = syncedAt;
  }

  @override
  Future<void> saveTask(ImageUploadTask task) async {
    final index = tasks.indexWhere((existing) => existing.id == task.id);
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
  }

  @override
  Future<SyncQueueSnapshot> snapshot() async {
    return SyncQueueSnapshot(
      tasks: List.unmodifiable(tasks),
      lastSyncAt: lastSyncAt,
    );
  }
}

class _FakeGalleryService extends GalleryService {
  _FakeGalleryService({
    required this.pickedImage,
    required this.persistedImage,
  });

  final XFile pickedImage;
  final XFile persistedImage;

  @override
  Future<XFile?> pickImage() async => pickedImage;

  @override
  Future<bool> validateImage(XFile image) async => true;

  @override
  Future<XFile> persistSelectedImage(XFile image) async => persistedImage;
}

class _UnavailablePricingApiClient extends ApiClient {
  _UnavailablePricingApiClient()
    : super(
        config: const EnvironmentConfig(
          environment: AppEnvironment.development,
        ),
      );

  @override
  Future<dio.Response<dynamic>> post(
    String path, {
    Object? data,
    dio.Options? options,
  }) async {
    return dio.Response<dynamic>(
      requestOptions: dio.RequestOptions(path: path),
      data: {
        'success': true,
        'pricing': {
          'status': 'unavailable',
          'reasonCode': 'NO_MARKET_MATCH',
          'displayMessage': 'No trusted market match found for this identity.',
          'estimatedMarketValue': 0,
          'lowEstimate': 0,
          'highEstimate': 0,
          'currency': 'USD',
          'confidenceScore': 0,
          'valuationStrategy': 'catalog_lookup',
          'pricingSource': {
            'name': 'PriceCharting',
            'attributionText': 'Pricing data powered by PriceCharting',
            'lastChecked': '2026-07-27T00:00:00Z',
          },
          'matchMetadata': {'reason': 'No trusted match found.'},
        },
      },
    );
  }
}

class _SuccessfulRepriceApiClient extends ApiClient {
  _SuccessfulRepriceApiClient({this.value = 310})
    : super(
        config: const EnvironmentConfig(
          environment: AppEnvironment.development,
        ),
      );

  final double value;
  String? lastPath;
  Map<String, dynamic> lastPayload = const {};

  @override
  Future<dio.Response<dynamic>> post(
    String path, {
    Object? data,
    dio.Options? options,
  }) async {
    lastPath = path;
    lastPayload = Map<String, dynamic>.from(data! as Map);
    return dio.Response<dynamic>(
      requestOptions: dio.RequestOptions(path: path),
      data: {
        'success': true,
        'pricing': {
          'status': 'available',
          'estimatedMarketValue': value,
          'lowEstimate': value - 20,
          'highEstimate': value + 30,
          'currency': 'USD',
          'displayString': 'USD \$${value.toStringAsFixed(2)}',
          'confidenceScore': 0.88,
          'pricingConfidence': 88,
          'valuationStrategy': 'catalog_lookup',
          'pricingSource': {
            'name': 'PriceCharting',
            'attributionText': 'Pricing data powered by PriceCharting',
            'lastChecked': '2026-07-27T00:00:00Z',
          },
          'originalMarketPayload': {'price': value, 'currency': 'USD'},
          'matchMetadata': {
            'reason': 'Matched by corrected title, set, and card number.',
          },
          'comparableSales': const [],
          'diagnostics': const {},
        },
      },
    );
  }
}

class _MemoryWishlistRepository implements WishlistRepository {
  final Map<String, WishlistStatusEntry> _entries = {};

  @override
  Future<void> clear() async {
    _entries.clear();
  }

  @override
  Future<void> deleteStatus(String itemId) async {
    _entries.remove(itemId);
  }

  @override
  Future<List<WishlistStatusEntry>> getEntries() async {
    return _entries.values.toList();
  }

  @override
  Future<WishlistStatus> getStatusForItem(String itemId) async {
    return _entries[itemId]?.status ?? WishlistStatus.owned;
  }

  @override
  Future<void> saveStatus({
    required CollectibleItem item,
    required WishlistStatus status,
  }) async {
    _entries[item.id] = WishlistStatusEntry(
      itemId: item.id,
      title: item.title,
      category: item.category,
      status: status,
      updatedAt: DateTime(2026, 7, 26),
    );
  }
}

Future<void> _revealText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      finder,
      240,
      scrollable: find.byType(Scrollable).first,
    );
  } else {
    await tester.ensureVisible(finder.first);
  }
  await tester.pumpAndSettle();
}

Future<void> _openEditSheet(WidgetTester tester) async {
  await _revealText(tester, 'Actions Menu');
  await tester.tap(
    find.byKey(const ValueKey('collectible-detail-primary-edit-action')),
  );
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('edit-collectible-sheet')), findsOneWidget);
}

CollectibleItem _authorityItem({
  double estimatedValue = 245,
  ValuationStatus valuationStatus = ValuationStatus.marketEstimated,
  String imagePath = 'sample://front',
  List<CollectibleImage> galleryImages = const [
    CollectibleImage(
      path: 'sample://front',
      role: 'front',
      source: 'sample',
      isPrimary: true,
    ),
    CollectibleImage(path: 'sample://detail', role: 'detail', source: 'sample'),
  ],
}) {
  return CollectibleItem(
    id: 'detail-authority-item',
    title: 'PackLox Authority Coupe',
    category: 'Toy Car',
    estimatedValue: estimatedValue,
    confidence: 0.91,
    condition: 'Near mint',
    recommendation: 'Keep the complete saved capture set.',
    imagePath: imagePath,
    createdAt: DateTime(2026, 7, 14),
    valuationStatus: valuationStatus,
    brand: 'PackLox Motors',
    series: 'Authority Series',
    year: '2026',
    rarity: 'Limited',
    notes: 'Stored owner note.',
    aiReasoning: 'Stored scan reasoning only.',
    confidenceExplanation:
        'Saved evidence matched the front and detail photos.',
    detectionQuality: 'Clear packaging and model markings.',
    galleryImages: galleryImages,
    pricing: const PricingInfo(
      estimatedMarketValue: 245,
      lowEstimate: 220,
      highEstimate: 270,
      currency: 'USD',
      pricingSource: 'Saved provider',
      pricingConfidence: 0.82,
      lastUpdated: null,
    ),
    valueAtScan: 200,
    lastValueRefreshedAt: DateTime(2026, 7, 26),
  );
}

CollectibleItem _catalogSnapshotItem() {
  return _authorityItem(
    estimatedValue: 161,
    imagePath:
        'assets/packlox/icons/categories/3d/packlox_category_placeholder_card_v1.png',
    galleryImages: const [],
  ).copyWith(
    title: 'Charizard #10',
    category: 'Pokemon Card',
    setName: 'Pokemon Go',
    cardNumber: '10',
    notes:
        'Catalog ID: 3666974\nSource: PriceCharting\nPricing data by PriceCharting',
    pricing: PricingInfo(
      estimatedMarketValue: 161,
      lowEstimate: 3.89,
      highEstimate: 25,
      currency: 'USD',
      pricingSource: 'PriceCharting',
      pricingConfidence: 0.96,
      lastUpdated: DateTime(2026, 7, 26),
      valuationStatus: ValuationStatus.marketEstimated,
      valuationSource: 'pricecharting',
      pricingExplanation:
          'Saved from PackLox catalog search as a dated portfolio snapshot.',
      reasonCode: 'CATALOG_SEARCH_MATCH',
      valuationStrategy: 'catalog_lookup',
      attributionText: 'Pricing data by PriceCharting',
      displayString: 'USD \$161',
    ),
    valueAtScan: 161,
    lastValueRefreshedAt: null,
  );
}
