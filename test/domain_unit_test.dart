import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:collectiq_ai/features/ai/data/clients/http_ai_backend_client.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/cloud_storage_paths.dart';
import 'package:collectiq_ai/core/cloud/services/analytics_service.dart';
import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:collectiq_ai/core/cloud/services/crash_reporting_service.dart';
import 'package:collectiq_ai/core/cloud/services/noop_cloud_services.dart';
import 'package:collectiq_ai/core/cloud/services/remote_config_service.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_bootstrap.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_cloud_storage_service.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/config/feature_flags.dart';
import 'package:collectiq_ai/core/network/api_constants.dart' as network_config;
import 'package:collectiq_ai/core/supabase/supabase_auth_response_normalizer.dart';
import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:collectiq_ai/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_callback_result.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_exception.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/auth/services/auth_deep_link_service.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_conflict.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/services/sync_service.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/diagnostics/domain/services/provider_diagnostics_service.dart';
import 'package:collectiq_ai/features/home/domain/entities/collector_dashboard_analytics.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/home/data/repositories/shared_preferences_portfolio_history_repository.dart';
import 'package:collectiq_ai/features/home/domain/services/collector_dashboard_analytics_service.dart';
import 'package:collectiq_ai/features/home/domain/services/portfolio_history_service.dart';
import 'package:collectiq_ai/features/home/domain/services/smart_collector_insights_service.dart';
import 'package:collectiq_ai/features/home/presentation/controllers/portfolio_history_controller.dart';
import 'package:collectiq_ai/features/ai/data/clients/noop_ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_backend_contract_validation.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_backend_analysis_models.dart';
import 'package:collectiq_ai/features/ai/data/models/ai_image_upload_payload.dart';
import 'package:collectiq_ai/features/ai/data/providers/mock_ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/data/providers/mock_collectible_result_pool.dart';
import 'package:collectiq_ai/features/ai/data/providers/open_ai_vision_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/data/services/dio_ai_backend_api_service.dart';
import 'package:collectiq_ai/features/ai/data/services/noop_ai_backend_api_service.dart';
import 'package:collectiq_ai/features/ai/domain/clients/ai_backend_client.dart';
import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/ai/domain/providers/ai_analysis_provider.dart';
import 'package:collectiq_ai/features/ai/domain/repositories/recognition_repository.dart';
import 'package:collectiq_ai/features/image_sync/data/repositories/shared_preferences_sync_queue_repository.dart';
import 'package:collectiq_ai/features/image_sync/domain/entities/image_upload_task.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:collectiq_ai/features/image_sync/domain/services/retry_policy.dart';
import 'package:collectiq_ai/features/image_sync/domain/services/upload_worker.dart';
import 'package:collectiq_ai/features/market/data/providers/market_provider_factory.dart';
import 'package:collectiq_ai/features/market/data/providers/market_pricing_provider_factory.dart';
import 'package:collectiq_ai/features/market/data/providers/mock_market_provider.dart';
import 'package:collectiq_ai/features/market/data/providers/mock_market_pricing_provider.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_pricing_request.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_pricing_result.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/market/domain/repositories/market_pricing_provider.dart';
import 'package:collectiq_ai/features/onboarding/data/repositories/shared_preferences_onboarding_repository.dart';
import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/features/portfolio/domain/services/demo_collectible_seed_service.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/price_alerts/data/repositories/shared_preferences_price_alert_repository.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/services/price_alert_evaluator.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/capture_event.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/confidence_model.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_session.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scanner_constants.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_quality_gate_service.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_result_enrichment_service.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_exception.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_plan.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/usage_tracker.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/user_entitlements.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/billing_exception.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/billing_product.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/purchase_result.dart';
import 'package:collectiq_ai/features/subscription/data/repositories/google_play_billing_repository.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/billing_repository.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/entitlement_repository.dart';
import 'package:collectiq_ai/features/subscription/domain/repositories/usage_repository.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/features/wishlist/data/repositories/shared_preferences_wishlist_repository.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/features/wishlist/domain/services/wishlist_service.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SharedPreferencesOnboardingRepository', () {
    test('persists onboarding completion flag', () async {
      SharedPreferences.setMockInitialValues({});
      const repository = SharedPreferencesOnboardingRepository();

      expect(await repository.hasCompletedOnboarding(), isFalse);

      await repository.setOnboardingCompleted(true);
      expect(await repository.hasCompletedOnboarding(), isTrue);

      await repository.setOnboardingCompleted(false);
      expect(await repository.hasCompletedOnboarding(), isFalse);
    });
  });

  group('CollectibleItem', () {
    test('toJson serializes all fields', () {
      final item = _testItem();

      final json = item.toJson();

      expect(json['id'], 'item-1');
      expect(json['title'], '1999 Pokémon Charizard');
      expect(json['category'], 'Trading Card');
      expect(json['estimatedValue'], 1850);
      expect(json['confidence'], 0.94);
      expect(json['condition'], 'Near Mint');
      expect(json['recommendation'], 'Consider grading before selling.');
      expect(json['imagePath'], 'sample://sports-card');
      expect(json['imageStoragePath'], isNull);
      expect(json['cloudImageUrl'], isNull);
      expect(json['savedAt'], '2026-06-27T00:00:00.000');
      expect(json['createdAt'], '2026-06-27T00:00:00.000');
      expect(json['year'], '1999');
      expect(json['brand'], 'Pokemon');
      expect(json['setName'], 'Base Set');
      expect(json['cardNumber'], '4/102');
      expect(json['playerOrCharacter'], 'Charizard');
      expect(json['rarity'], 'Holo Rare');
      expect(json['notes'], 'Verify holo surface.');
      expect(json['pricing']['estimatedMarketValue'], 1850);
      expect(json['pricing']['lowEstimate'], 1443);
      expect(json['pricing']['highEstimate'], 2257);
      expect(json['pricing']['currency'], 'AUD');
      expect(json['marketSummary']['salesCount'], 5);
      expect(json['marketSummary']['comps'], hasLength(1));
    });

    test('fromJson restores all fields', () {
      final item = CollectibleItem.fromJson({
        'id': 'item-1',
        'title': '1999 Pokémon Charizard',
        'category': 'Trading Card',
        'estimatedValue': 1850,
        'confidence': 0.94,
        'condition': 'Near Mint',
        'recommendation': 'Consider grading before selling.',
        'imagePath': 'sample://sports-card',
        'imageStoragePath': 'users/user-1/portfolio_images/item-1.jpg',
        'cloudImageUrl':
            'https://example.supabase.co/storage/v1/object/sign/collectiq-portfolio-images/users/user-1/portfolio_images/item-1.jpg',
        'createdAt': '2026-06-27T00:00:00.000',
        'year': '1999',
        'brand': 'Pokemon',
        'setName': 'Base Set',
        'cardNumber': '4/102',
        'playerOrCharacter': 'Charizard',
        'rarity': 'Holo Rare',
        'notes': 'Verify holo surface.',
        'pricing': {
          'estimatedMarketValue': 1850,
          'lowEstimate': 1443,
          'highEstimate': 2257,
          'currency': 'AUD',
          'pricingSource': 'Mock market blend',
          'pricingConfidence': 85,
          'lastUpdated': '2026-06-29T00:00:00Z',
        },
      });

      expect(item.id, 'item-1');
      expect(item.title, '1999 Pokémon Charizard');
      expect(item.category, 'Trading Card');
      expect(item.estimatedValue, 1850);
      expect(item.confidence, 0.94);
      expect(item.condition, 'Near Mint');
      expect(item.recommendation, 'Consider grading before selling.');
      expect(item.imagePath, 'sample://sports-card');
      expect(item.imageStoragePath, 'users/user-1/portfolio_images/item-1.jpg');
      expect(
        item.cloudImageUrl,
        'https://example.supabase.co/storage/v1/object/sign/collectiq-portfolio-images/users/user-1/portfolio_images/item-1.jpg',
      );
      expect(item.createdAt, DateTime.parse('2026-06-27T00:00:00.000'));
      expect(item.year, '1999');
      expect(item.brand, 'Pokemon');
      expect(item.setName, 'Base Set');
      expect(item.cardNumber, '4/102');
      expect(item.playerOrCharacter, 'Charizard');
      expect(item.rarity, 'Holo Rare');
      expect(item.notes, 'Verify holo surface.');
      expect(item.pricing?.estimatedMarketValue, 1850);
      expect(item.pricing?.pricingConfidence, 0.85);
      expect(item.marketSummary, isNull);
    });

    test('fromJson prefers savedAt and safely falls back for old items', () {
      final savedAtItem = CollectibleItem.fromJson({
        'id': 'item-1',
        'title': 'Saved Later',
        'category': 'Trading Card',
        'estimatedValue': 10,
        'confidence': 0.8,
        'condition': 'Good',
        'recommendation': 'Hold.',
        'imagePath': 'sample://card',
        'savedAt': '2026-06-29T10:30:00.000',
        'createdAt': '2026-06-01T00:00:00.000',
      });
      final missingTimestampItem = CollectibleItem.fromJson({
        'id': 'item-2',
        'title': 'Old Import',
        'category': 'Coin',
        'estimatedValue': 20,
        'confidence': 0.7,
        'condition': 'Good',
        'recommendation': 'Store safely.',
        'imagePath': 'sample://coin',
      });

      expect(savedAtItem.createdAt, DateTime.parse('2026-06-29T10:30:00.000'));
      expect(
        missingTimestampItem.createdAt,
        DateTime.fromMillisecondsSinceEpoch(0),
      );
    });
  });

  group('MarketProvider', () {
    test('mock provider generates realistic market comps', () async {
      final summary = await const MockMarketProvider().summarizeMarket(
        _testRecognitionResult(),
      );

      expect(summary.salesCount, 5);
      expect(summary.averagePrice, greaterThan(0));
      expect(summary.sources, contains('TCGplayer'));
      expect(summary.comps, hasLength(5));
      expect(summary.comps.first.title, contains('Charizard'));
    });

    test('factory defaults to mock and reserves future providers', () {
      const factory = MarketProviderFactory();

      expect(factory.create(), isA<MockMarketProvider>());
      expect(
        () => factory.create(provider: MarketProviderType.ebay),
        throwsUnsupportedError,
      );
      expect(
        () => factory.create(provider: MarketProviderType.tcgplayer),
        throwsUnsupportedError,
      );
    });

    test('market summary parses nullable cloud JSON safely', () {
      final summary = MarketSummary.fromJson({
        'averagePrice': null,
        'medianPrice': null,
        'lowPrice': null,
        'highPrice': null,
        'salesCount': null,
        'trendLabel': null,
        'confidence': null,
        'lastUpdated': null,
        'sources': ['eBay Sold'],
        'comps': [
          {
            'source': 'eBay Sold',
            'title': 'Comparable',
            'soldPrice': null,
            'currency': null,
            'soldDate': null,
            'condition': null,
          },
        ],
      });

      expect(summary.averagePrice, 0);
      expect(summary.salesCount, 0);
      expect(summary.comps.single.soldPrice, 0);
      expect(summary.comps.single.currency, 'AUD');
    });
  });

  group('MarketPricingProvider', () {
    test('mock pricing result returns expected fields', () async {
      final result = await const MockMarketPricingProvider().price(
        const MarketPricingRequest(
          title: '1999 Pokemon Charizard',
          category: 'Trading Card',
          condition: 'Near Mint',
          year: '1999',
          brand: 'Pokemon',
          setName: 'Base Set',
          cardNumber: '4/102',
          playerOrCharacter: 'Charizard',
          asOfDate: null,
        ),
      );

      expect(result.estimatedValue, greaterThan(0));
      expect(result.lowEstimate, lessThanOrEqualTo(result.estimatedValue));
      expect(result.highEstimate, greaterThanOrEqualTo(result.estimatedValue));
      expect(result.currency, 'AUD');
      expect(result.marketTrend, isNotEmpty);
      expect(result.comparableSales, hasLength(5));
      expect(result.confidence, greaterThan(0));
      expect(result.sourceLabel, contains('Mock pricing blend'));
      expect(result.toPricingInfo().pricingSource, result.sourceLabel);
      expect(result.toMarketSummary().comps, hasLength(5));
    });

    test('factory defaults to mock pricing provider', () {
      const factory = MarketPricingProviderFactory();

      expect(factory.create(), isA<MockMarketPricingProvider>());
    });

    test('unsupported pricing provider returns friendly error', () async {
      final provider = const MarketPricingProviderFactory().create(
        provider: MarketPricingProviderType.ebayCompletedSales,
      );

      await expectLater(
        provider.price(
          const MarketPricingRequest(
            title: '1999 Pokemon Charizard',
            category: 'Trading Card',
          ),
        ),
        throwsA(
          isA<MarketPricingException>().having(
            (error) => error.message,
            'message',
            contains('not enabled yet'),
          ),
        ),
      );
    });

    test('partial pricing data uses safe defaults', () {
      final result = MarketPricingResult.fromJson({
        'estimatedValue': null,
        'lowEstimate': null,
        'highEstimate': null,
        'currency': null,
        'marketTrend': null,
        'confidence': null,
        'sourceLabel': null,
        'lastUpdated': null,
        'comparableSales': [
          {
            'source': null,
            'title': null,
            'soldPrice': null,
            'currency': null,
            'soldDate': null,
            'condition': null,
          },
        ],
      });

      expect(result.estimatedValue, 0);
      expect(result.lowEstimate, 0);
      expect(result.highEstimate, 0);
      expect(result.currency, 'AUD');
      expect(result.marketTrend, 'Stable');
      expect(result.confidence, 0);
      expect(result.sourceLabel, 'Unknown');
      expect(result.comparableSales.single.soldPrice, 0);
      expect(result.toPricingInfo().estimatedMarketValue, 0);
      expect(result.toMarketSummary().salesCount, 1);
    });
  });

  group('ProviderDiagnosticsService', () {
    test('diagnostics show mock AI and pricing active by default', () {
      final diagnostics = const ProviderDiagnosticsService().build(
        aiConfig: const AiAnalysisProviderConfig(),
        pricingProviderType: MarketPricingProviderType.mock,
        lastScanPipelineStatus: 'Ready',
      );

      expect(diagnostics.aiProvider, 'Mock AI');
      expect(diagnostics.aiProviderStatus, 'Mock');
      expect(diagnostics.pricingProvider, 'Mock Pricing');
      expect(diagnostics.pricingProviderStatus, 'Mock');
      expect(diagnostics.backendEndpointConfigured, 'Not configured');
      expect(diagnostics.backendEndpointValid, 'Invalid');
      expect(diagnostics.backendEndpointReleaseSafe, 'No');
      expect(diagnostics.httpBackendClientStatus, 'Disabled (mock)');
      expect(diagnostics.mockModeActive, 'Active');
      expect(diagnostics.appMode, 'development/mock');
    });

    test('missing backend endpoint shows not configured', () {
      final diagnostics = const ProviderDiagnosticsService().build(
        aiConfig: const AiAnalysisProviderConfig(
          type: AiAnalysisProviderType.openAiVision,
        ),
        pricingProviderType: MarketPricingProviderType.mock,
        lastScanPipelineStatus: 'Ready',
      );

      expect(diagnostics.aiProvider, 'OpenAI Vision');
      expect(diagnostics.aiProviderStatus, 'Coming soon');
      expect(diagnostics.backendEndpointConfigured, 'Not configured');
      expect(diagnostics.aiBackendClientStatus, 'Not configured');
      expect(diagnostics.httpBackendClientStatus, 'Not configured');
    });

    test('valid backend endpoint reports ready diagnostics', () {
      final diagnostics = const ProviderDiagnosticsService().build(
        aiConfig: const AiAnalysisProviderConfig(
          type: AiAnalysisProviderType.openAiVision,
          backendAnalysisEndpointUrl: 'https://api.collectiq.test/api/analyze',
        ),
        pricingProviderType: MarketPricingProviderType.mock,
        lastScanPipelineStatus: 'Ready',
        isReleaseMode: true,
      );

      expect(diagnostics.backendEndpointConfigured, 'Ready');
      expect(diagnostics.backendEndpointValid, 'Valid');
      expect(diagnostics.backendEndpointReleaseSafe, 'Yes');
      expect(diagnostics.aiBackendClientStatus, 'Ready');
      expect(diagnostics.httpBackendClientStatus, 'HTTP ready');
    });
  });

  group('AiBackendEndpointReadiness', () {
    test('missing endpoint reports not configured', () {
      final readiness = const AiBackendEndpointReadinessChecker().check(
        endpointUrl: '',
      );

      expect(readiness.isConfigured, isFalse);
      expect(readiness.isValid, isFalse);
      expect(readiness.configuredLabel, 'Not configured');
    });

    test('invalid URL reports invalid', () {
      final readiness = const AiBackendEndpointReadinessChecker().check(
        endpointUrl: 'not a url',
      );

      expect(readiness.isConfigured, isTrue);
      expect(readiness.isValid, isFalse);
      expect(readiness.validityLabel, 'Invalid');
    });

    test('valid HTTPS endpoint passes release safety', () {
      final readiness = const AiBackendEndpointReadinessChecker().check(
        endpointUrl: 'https://api.collectiq.test/api/analyze',
        isReleaseMode: true,
      );

      expect(readiness.isConfigured, isTrue);
      expect(readiness.isValid, isTrue);
      expect(readiness.isReleaseSafe, isTrue);
      expect(readiness.releaseSafeLabel, 'Yes');
    });

    test('HTTP endpoint is allowed only in debug local mode', () {
      final debugReadiness = const AiBackendEndpointReadinessChecker().check(
        endpointUrl: 'http://192.168.0.81:8000/api/analyze',
      );
      final releaseReadiness = const AiBackendEndpointReadinessChecker().check(
        endpointUrl: 'http://192.168.0.81:8000/api/analyze',
        isReleaseMode: true,
      );

      expect(debugReadiness.isValid, isTrue);
      expect(debugReadiness.isReleaseSafe, isTrue);
      expect(releaseReadiness.isValid, isTrue);
      expect(releaseReadiness.isReleaseSafe, isFalse);
      expect(releaseReadiness.releaseSafeLabel, 'No');
    });
  });

  group('ScanResultEnrichmentService', () {
    test('combines AI result with pricing data', () async {
      final service = ScanResultEnrichmentService(
        marketPricingProvider: const MockMarketPricingProvider(),
      );
      final analysis = AiAnalysisResult(
        recommendation: 'Provider recommendation.',
        scanResult: _testScanResult(),
      );

      final enriched = await service.enrich(
        analysis: analysis,
        metadata: const ScanResultEnrichmentMetadata(
          imagePath: 'sample://sports-card',
          imageSource: 'sample',
        ),
      );

      expect(enriched.recommendation, 'Provider recommendation.');
      expect(enriched.scanResult.title, analysis.scanResult.title);
      expect(
        enriched.scanResult.pricing.pricingSource,
        contains('Mock pricing blend'),
      );
      expect(enriched.scanResult.pricing.pricingConfidence, greaterThan(0));
      expect(enriched.scanResult.marketSummary, isNotNull);
      expect(enriched.scanResult.marketSummary?.comps, hasLength(5));
    });

    test('pricing failure still returns usable scan result', () async {
      const service = ScanResultEnrichmentService(
        marketPricingProvider: _FailingMarketPricingProvider(),
      );
      final analysis = AiAnalysisResult(
        recommendation: 'Fallback recommendation.',
        scanResult: _testScanResult(),
      );

      final enriched = await service.enrich(
        analysis: analysis,
        metadata: const ScanResultEnrichmentMetadata(
          imagePath: 'sample://sports-card',
          imageSource: 'sample',
        ),
      );

      expect(enriched.scanResult.title, analysis.scanResult.title);
      expect(
        enriched.scanResult.estimatedValue,
        analysis.scanResult.estimatedValue,
      );
      expect(
        enriched.scanResult.pricing.pricingSource,
        'Mock pricing unavailable',
      );
      expect(enriched.scanResult.pricing.pricingConfidence, 0);
      expect(enriched.recommendation, 'Fallback recommendation.');
    });
  });

  group('DemoCollectibleSeedService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('generator returns 500 demo/mock items', () {
      final items = const DemoCollectibleSeedService().generateItems(
        anchorDate: DateTime.utc(2026, 7),
      );

      expect(items, hasLength(packLoxDemoSeedItemCount));
      expect(
        items.every((item) => item.id.startsWith(packLoxDemoItemIdPrefix)),
        isTrue,
      );
      expect(
        items.every((item) => item.notes?.contains('DEMO MOCK DATA') ?? false),
        isTrue,
      );
      expect(
        items.every(
          (item) => item.pricing?.pricingSource == 'PackLox demo seed (mock)',
        ),
        isTrue,
      );
    });

    test('categories are diverse and cover the demo catalog', () {
      final items = const DemoCollectibleSeedService().generateItems(
        anchorDate: DateTime.utc(2026, 7),
      );
      final categories = items.map((item) => item.category).toSet();

      expect(categories, containsAll(DemoCollectibleSeedService.categories));
      expect(categories, hasLength(20));
    });

    test('normal mode does not seed automatically', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(demoSeedEnabledProvider), isFalse);
      const repository = SharedPreferencesPortfolioRepository();

      expect(await repository.getItems(), isEmpty);
    });

    test('demo mode can seed and clear local demo data', () async {
      const repository = SharedPreferencesPortfolioRepository();

      final seededCount = await const DemoCollectibleSeedService()
          .seedPortfolio(repository);
      final seededItems = await repository.getItems();

      expect(seededCount, packLoxDemoSeedItemCount);
      expect(seededItems, hasLength(packLoxDemoSeedItemCount));
      expect(seededItems.every(DemoCollectibleSeedService.isDemoItem), isTrue);

      final removedCount = await const DemoCollectibleSeedService()
          .clearDemoItems(repository);
      final remainingItems = await repository.getItems();

      expect(removedCount, packLoxDemoSeedItemCount);
      expect(remainingItems, isEmpty);
    });
  });

  group('SharedPreferencesPortfolioRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('adds and loads portfolio items', () async {
      const repository = SharedPreferencesPortfolioRepository();
      final item = _testItem();

      await repository.addItem(item);
      final items = await repository.getItems();

      expect(items, hasLength(1));
      expect(items.single.id, item.id);
      expect(items.single.title, item.title);
    });

    test('removeItem removes saved item', () async {
      const repository = SharedPreferencesPortfolioRepository();
      final item = _testItem();

      await repository.addItem(item);
      await repository.removeItem(item.id);
      final items = await repository.getItems();

      expect(items, isEmpty);
    });

    test('loads existing saved items from local storage', () async {
      SharedPreferences.setMockInitialValues({
        'portfolio_items':
            '[{"id":"persisted-1","title":"Persisted Charizard","category":"Trading Card","estimatedValue":1850,"confidence":0.94,"condition":"Near Mint","recommendation":"Consider grading before selling.","imagePath":"sample://sports-card","createdAt":"2026-06-27T00:00:00.000"}]',
      });
      const repository = SharedPreferencesPortfolioRepository();

      final items = await repository.getItems();

      expect(items, hasLength(1));
      expect(items.single.id, 'persisted-1');
      expect(items.single.title, 'Persisted Charizard');
    });

    test('returns newest camera save first after persistence reload', () async {
      SharedPreferences.setMockInitialValues({
        'portfolio_items':
            '[{"id":"gallery-old","title":"Older Gallery Save","category":"Card","estimatedValue":100,"confidence":0.7,"condition":"Good","recommendation":"Hold.","imagePath":"sample://gallery","savedAt":"2026-06-29T08:00:00.000"},{"id":"camera-new","title":"Newer Camera Save","category":"Card","estimatedValue":200,"confidence":0.8,"condition":"Good","recommendation":"Hold.","imagePath":"sample://camera","savedAt":"2026-06-29T09:00:00.000"}]',
      });
      const repository = SharedPreferencesPortfolioRepository();

      final items = await repository.getItems();

      expect(items.map((item) => item.id), ['camera-new', 'gallery-old']);
    });

    test('returns newest gallery save first after persistence reload', () async {
      SharedPreferences.setMockInitialValues({
        'portfolio_items':
            '[{"id":"camera-old","title":"Older Camera Save","category":"Card","estimatedValue":100,"confidence":0.7,"condition":"Good","recommendation":"Hold.","imagePath":"sample://camera","savedAt":"2026-06-29T08:00:00.000"},{"id":"gallery-new","title":"Newer Gallery Save","category":"Card","estimatedValue":200,"confidence":0.8,"condition":"Good","recommendation":"Hold.","imagePath":"sample://gallery","savedAt":"2026-06-29T09:00:00.000"}]',
      });
      const repository = SharedPreferencesPortfolioRepository();

      final items = await repository.getItems();

      expect(items.map((item) => item.id), ['gallery-new', 'camera-old']);
    });

    test(
      'addItem overrides stale mock timestamp with local save time',
      () async {
        const repository = SharedPreferencesPortfolioRepository();
        final staleMockItem = _testItemWith(
          id: 'stale-mock',
          title: 'Stale Mock Result',
          imagePath: 'sample://stale',
          createdAt: DateTime.parse('2020-01-01T00:00:00.000'),
        );
        final beforeSave = DateTime.now();

        final savedItem = await repository.addItem(staleMockItem);
        final items = await repository.getItems();

        expect(items, hasLength(1));
        expect(items.single.id, 'stale-mock');
        expect(savedItem.id, 'stale-mock');
        expect(savedItem.createdAt, items.single.createdAt);
        expect(items.single.createdAt.isBefore(beforeSave), isFalse);
      },
    );

    test(
      'PortfolioController uses repository returned saved item timestamp',
      () async {
        final staleInput = _testItemWith(
          id: 'scan-result',
          title: 'Stale Controller Input',
          createdAt: DateTime.parse('2020-01-01T00:00:00.000'),
        );
        final returnedSavedItem = staleInput.copyWithSavedAt(
          DateTime.parse('2026-06-29T12:00:00.000'),
        );
        final repository = _ReturningPortfolioRepository(returnedSavedItem);
        final container = ProviderContainer(
          overrides: [
            portfolioRepositoryProvider.overrideWithValue(repository),
          ],
        );
        addTearDown(container.dispose);

        await Future<void>.delayed(Duration.zero);
        await container
            .read(portfolioControllerProvider.notifier)
            .saveItem(staleInput);

        final orderedItems = container
            .read(portfolioControllerProvider)
            .orderedItems;
        expect(orderedItems, hasLength(1));
        expect(orderedItems.single.id, 'scan-result');
        expect(
          collectibleDisplayTimestamp(orderedItems.single),
          DateTime.parse('2026-06-29T12:00:00.000'),
        );
        expect(
          collectibleDisplayTimestamp(orderedItems.single),
          isNot(staleInput.createdAt),
        );
      },
    );

    test('gallery then camera saves order by actual save timestamp', () async {
      const repository = SharedPreferencesPortfolioRepository();

      await repository.addItem(
        _testItemWith(
          id: 'gallery-first',
          title: 'Gallery First',
          imagePath: 'sample://gallery',
          createdAt: DateTime.parse('2020-01-01T00:00:00.000'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.addItem(
        _testItemWith(
          id: 'camera-second',
          title: 'Camera Second',
          imagePath: 'sample://camera',
          createdAt: DateTime.parse('2020-01-01T00:00:00.000'),
        ),
      );

      final items = await repository.getItems();

      expect(items.map((item) => item.id), ['camera-second', 'gallery-first']);
    });

    test('camera then gallery saves order by actual save timestamp', () async {
      const repository = SharedPreferencesPortfolioRepository();

      await repository.addItem(
        _testItemWith(
          id: 'camera-first',
          title: 'Camera First',
          imagePath: 'sample://camera',
          createdAt: DateTime.parse('2020-01-01T00:00:00.000'),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.addItem(
        _testItemWith(
          id: 'gallery-second',
          title: 'Gallery Second',
          imagePath: 'sample://gallery',
          createdAt: DateTime.parse('2020-01-01T00:00:00.000'),
        ),
      );

      final items = await repository.getItems();

      expect(items.map((item) => item.id), ['gallery-second', 'camera-first']);
    });

    test('persistence reload keeps local save order', () async {
      const repository = SharedPreferencesPortfolioRepository();
      await repository.addItem(_testItemWith(id: 'old-save'));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.addItem(_testItemWith(id: 'new-save'));

      const reloadedRepository = SharedPreferencesPortfolioRepository();
      final items = await reloadedRepository.getItems();

      expect(items.map((item) => item.id), ['new-save', 'old-save']);
    });

    test(
      'camera and gallery saved image paths survive repository reload',
      () async {
        const repository = SharedPreferencesPortfolioRepository();
        const cameraPath = 'test/fixtures/persistent-camera-card.jpg';
        const galleryPath = 'test/fixtures/persistent-gallery-card.jpg';

        await repository.addItem(
          _testItemWith(id: 'camera-item', imagePath: cameraPath),
        );
        await repository.addItem(
          _testItemWith(id: 'gallery-item', imagePath: galleryPath),
        );

        const reloadedRepository = SharedPreferencesPortfolioRepository();
        final items = await reloadedRepository.getItems();

        expect(items, hasLength(2));
        expect(
          items.firstWhere((item) => item.id == 'camera-item').imagePath,
          cameraPath,
        );
        expect(
          items.firstWhere((item) => item.id == 'gallery-item').imagePath,
          galleryPath,
        );
      },
    );

    test('updateItem edits local fields without losing image path', () async {
      const repository = SharedPreferencesPortfolioRepository();
      const imagePath = 'test/fixtures/persistent-camera-card.jpg';
      final original = await repository.addItem(
        _testItemWith(id: 'editable-item', imagePath: imagePath),
      );

      await repository.updateItem(
        original.copyWith(
          title: 'Edited Charizard',
          category: 'Coin',
          estimatedValue: 300,
          pricing: const PricingInfo(
            estimatedMarketValue: 300,
            lowEstimate: 250,
            highEstimate: 350,
            currency: 'AUD',
            pricingSource: 'Local edit',
            pricingConfidence: 0,
            lastUpdated: null,
          ),
          brand: 'Perth Mint',
          series: 'Lunar',
          year: '2000',
          country: 'Australia',
          notes: 'Edited locally.',
        ),
      );
      final items = await repository.getItems();

      expect(items, hasLength(1));
      expect(items.single.title, 'Edited Charizard');
      expect(items.single.category, 'Coin');
      expect(items.single.estimatedValue, 300);
      expect(items.single.pricing?.lowEstimate, 250);
      expect(items.single.pricing?.highEstimate, 350);
      expect(items.single.imagePath, imagePath);
      expect(items.single.createdAt, original.createdAt);
    });

    test(
      'new save is ordered first when existing timestamp is ahead of now',
      () async {
        SharedPreferences.setMockInitialValues({
          'portfolio_items':
              '[{"id":"future-existing","title":"Future Existing","category":"Card","estimatedValue":100,"confidence":0.7,"condition":"Good","recommendation":"Hold.","imagePath":"sample://old","savedAt":"2999-01-01T00:00:00.000Z"}]',
        });
        const repository = SharedPreferencesPortfolioRepository();

        final savedItem = await repository.addItem(
          _testItemWith(
            id: 'new-local-save',
            title: 'New Local Save',
            imagePath: 'sample://new',
            createdAt: DateTime.parse('2020-01-01T00:00:00.000'),
          ),
        );
        final items = await repository.getItems();

        expect(items.map((item) => item.id), [
          'new-local-save',
          'future-existing',
        ]);
        expect(
          collectibleDisplayTimestamp(
            savedItem,
          ).isAfter(DateTime.parse('2999-01-01T00:00:00.000Z')),
          isTrue,
        );
      },
    );

    test('equal timestamps use deterministic id fallback', () {
      final timestamp = DateTime.parse('2026-06-29T10:00:00.000');
      final items = collectiblesNewestFirst([
        _testItemWith(id: 'item-a', createdAt: timestamp),
        _testItemWith(id: 'item-c', createdAt: timestamp),
        _testItemWith(id: 'item-b', createdAt: timestamp),
      ]);

      expect(items.map((item) => item.id), ['item-c', 'item-b', 'item-a']);
    });

    test('image sync update does not move old item above newer item', () async {
      const repository = SharedPreferencesPortfolioRepository();
      await repository.addItem(_testItemWith(id: 'old-image'));
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.addItem(_testItemWith(id: 'newer-item'));

      await repository.updateItemImageSync(
        itemId: 'old-image',
        imageStoragePath: 'users/item/image.jpg',
        cloudImageUrl: 'https://cdn.example.com/users/item/image.jpg',
      );
      final items = await repository.getItems();

      expect(items.map((item) => item.id), ['newer-item', 'old-image']);
    });
  });

  group('RecognitionResult', () {
    test('fromJson parses backend response', () {
      final result = RecognitionResult.fromJson({
        'success': true,
        'filename': 'scan.png',
        'imageUrl': 'http://192.168.0.81:8000/uploads/scan.png',
        'title': '1999 Pokémon Charizard',
        'category': 'Trading Card',
        'confidence': 94,
        'estimatedValue': 1850,
        'condition': 'Near Mint',
        'recommendation': 'Consider grading before selling.',
        'description': 'Likely a Pokemon card.',
        'primaryMatch': '1999 Pokemon Charizard Holo',
        'alternativeMatches': [
          {
            'title': '2016 Pokemon Evolutions Charizard',
            'category': 'Trading Card',
            'confidence': 68,
            'reason': 'Similar artwork.',
          },
          {
            'title': 'Pokemon Charizard Promo',
            'category': 'Trading Card',
            'confidence': 61,
            'reason': 'Character match.',
          },
          {
            'title': 'Pokemon Expedition Charizard',
            'category': 'Trading Card',
            'confidence': 58,
            'reason': 'Fire-type cues.',
          },
        ],
        'confidenceExplanation': 'Strong visual match.',
        'detectionQuality': 'Good',
        'aiReasoning': 'Card frame and character cues match.',
        'year': '1999',
        'brand': 'Pokemon',
        'setName': 'Base Set',
        'series': 'Pokemon TCG',
        'cardNumber': '4/102',
        'playerOrCharacter': 'Charizard',
        'rarity': 'Holo Rare',
        'estimatedGrade': 'PSA 8',
        'language': 'English',
        'edition': 'Unlimited',
        'country': 'United States',
        'mint': '',
        'material': 'Cardstock',
        'notes': 'Verify holo surface.',
        'pricing': {
          'estimatedMarketValue': 1850,
          'lowEstimate': 1443,
          'highEstimate': 2257,
          'currency': 'AUD',
          'pricingSource': 'Mock market blend',
          'pricingConfidence': 85,
          'lastUpdated': '2026-06-29T00:00:00Z',
        },
      });

      expect(result.title, '1999 Pokémon Charizard');
      expect(result.success, isTrue);
      expect(result.filename, 'scan.png');
      expect(result.imageUrl, 'http://192.168.0.81:8000/uploads/scan.png');
      expect(result.category, 'Trading Card');
      expect(result.confidence, 0.94);
      expect(result.description, 'Likely a Pokemon card.');
      expect(result.estimatedValue, 1850);
      expect(result.condition, 'Near Mint');
      expect(result.recommendation, 'Consider grading before selling.');
      expect(result.primaryMatch, '1999 Pokemon Charizard Holo');
      expect(result.alternativeMatches, hasLength(3));
      expect(result.alternativeMatches.first.confidence, 0.68);
      expect(result.confidenceExplanation, 'Strong visual match.');
      expect(result.detectionQuality, 'Good');
      expect(result.aiReasoning, 'Card frame and character cues match.');
      expect(result.year, '1999');
      expect(result.brand, 'Pokemon');
      expect(result.setName, 'Base Set');
      expect(result.series, 'Pokemon TCG');
      expect(result.cardNumber, '4/102');
      expect(result.playerOrCharacter, 'Charizard');
      expect(result.rarity, 'Holo Rare');
      expect(result.estimatedGrade, 'PSA 8');
      expect(result.language, 'English');
      expect(result.edition, 'Unlimited');
      expect(result.country, 'United States');
      expect(result.mint, isNull);
      expect(result.material, 'Cardstock');
      expect(result.notes, 'Verify holo surface.');
      expect(result.pricing.estimatedMarketValue, 1850);
      expect(result.pricing.lowEstimate, 1443);
      expect(result.pricing.highEstimate, 2257);
      expect(result.pricing.currency, 'AUD');
      expect(result.pricing.pricingSource, 'Mock market blend');
      expect(result.pricing.pricingConfidence, 0.85);
    });

    test('fromJson keeps compatibility with older backend response', () {
      final result = RecognitionResult.fromJson({
        'success': true,
        'title': 'Vintage Coin',
        'category': 'Coin',
        'confidence': 82,
        'estimatedValue': 120,
        'condition': 'Very Fine',
        'recommendation': 'Store safely.',
      });

      expect(result.primaryMatch, 'Vintage Coin');
      expect(result.alternativeMatches, isEmpty);
      expect(result.confidenceExplanation, isNotEmpty);
      expect(result.detectionQuality, isNotEmpty);
      expect(result.aiReasoning, isEmpty);
      expect(result.pricing.estimatedMarketValue, 120);
      expect(result.pricing.pricingSource, 'Legacy AI estimate');
    });
  });

  group('AiBackendAnalysisContract', () {
    test('request serializes future backend metadata safely', () {
      final request = AiBackendAnalysisRequest(
        imagePath: '/local/path/card.jpg',
        imageSource: 'camera',
        requestedCategory: 'Trading Card',
        appVersion: '0.1.0',
        deviceMetadata: const {'platform': 'android'},
        timestamp: DateTime.parse('2026-06-30T09:00:00Z'),
      );

      expect(request.toJson(), {
        'imagePath': '/local/path/card.jpg',
        'imageSource': 'camera',
        'requestedCategory': 'Trading Card',
        'appVersion': '0.1.0',
        'deviceMetadata': {'platform': 'android'},
        'timestamp': '2026-06-30T09:00:00.000Z',
      });
    });

    test('valid request payload passes validation', () {
      final request = AiBackendAnalysisRequest(
        imagePath: '/local/path/card.jpg',
        imageSource: 'gallery',
        timestamp: DateTime.parse('2026-06-30T09:00:00Z'),
      );

      final result = const AiBackendContractValidator().validateRequest(
        request,
      );

      expect(result.isValid, isTrue);
      expect(result.statusLabel, 'Valid');
    });

    test('invalid request payload reports required field issues', () {
      final request = AiBackendAnalysisRequest(
        imagePath: '',
        imageSource: '',
        timestamp: DateTime.parse('1970-01-01T00:00:00Z'),
      );

      final result = const AiBackendContractValidator().validateRequest(
        request,
      );

      expect(result.isValid, isFalse);
      expect(result.issues, contains('imagePath is required.'));
      expect(result.issues, contains('imageSource is required.'));
      expect(result.statusLabel, 'Invalid');
    });

    test('response parses backend analysis fields safely', () {
      final response = AiBackendAnalysisResponse.fromJson(
        _backendAnalysisJson(),
      );

      expect(response.itemName, '1999 Pokemon Charizard Holo');
      expect(response.category, 'Trading Card');
      expect(response.estimatedValue, 1850);
      expect(response.lowEstimate, 1443);
      expect(response.highEstimate, 2257);
      expect(response.confidence, 0.94);
      expect(response.condition, 'Near Mint');
      expect(response.marketTrend, 'Rising');
      expect(response.keyAttributes['setName'], 'Base Set');
      expect(response.aiReview.primaryMatch, '1999 Pokemon Charizard Holo');
      expect(response.alternatives, hasLength(1));
      expect(response.marketSummary, isNotNull);
      expect(response.comparableSales, hasLength(1));
    });

    test('valid response payload passes contract validation', () {
      final result = const AiBackendContractValidator().validateResponsePayload(
        _backendAnalysisJson(),
      );

      expect(result.isValid, isTrue);
    });

    test('response payload validation reports missing required fields', () {
      final result = const AiBackendContractValidator().validateResponsePayload(
        {'confidence': 'not-a-number'},
      );

      expect(result.isValid, isFalse);
      expect(result.issues, contains('itemName is required.'));
      expect(result.issues, contains('category is required.'));
      expect(result.issues, contains('estimatedValue is required.'));
      expect(result.issues, contains('condition is required.'));
      expect(result.issues, contains('recommendation is required.'));
    });

    test('mapper converts backend response to scan result', () {
      final response = AiBackendAnalysisResponse.fromJson(
        _backendAnalysisJson(),
      );
      final result = response.toScanResult(
        thumbnail: '/local/path/card.jpg',
        scanDate: DateTime.parse('2026-06-30T09:30:00Z'),
      );

      expect(result.id, 'backend-card-1');
      expect(result.title, '1999 Pokemon Charizard Holo');
      expect(result.category, 'Trading Card');
      expect(result.estimatedValue, 1850);
      expect(result.confidence, 0.94);
      expect(result.condition, 'Near Mint');
      expect(result.thumbnail, '/local/path/card.jpg');
      expect(result.primaryMatch, '1999 Pokemon Charizard Holo');
      expect(result.alternativeMatches.single.title, 'Charizard Promo');
      expect(result.confidenceExplanation, contains('holographic'));
      expect(result.detectionQuality, 'Good');
      expect(result.aiReasoning, contains('Charizard'));
      expect(result.pricing.lowEstimate, 1443);
      expect(result.pricing.highEstimate, 2257);
      expect(result.marketSummary?.trendLabel, 'Rising');
      expect(result.marketSummary?.comps, hasLength(1));
      expect(result.year, '1999');
      expect(result.brand, 'Pokemon');
      expect(result.setName, 'Base Set');
      expect(result.cardNumber, '4/102');
      expect(result.playerOrCharacter, 'Charizard');
      expect(result.rarity, 'Holo Rare');
    });

    test('malformed response uses safe defaults', () {
      final response = AiBackendAnalysisResponse.fromJson({
        'confidence': 'not-a-number',
        'valueRange': {'low': null},
        'alternatives': [
          {'confidence': 73},
        ],
      });
      final result = response.toScanResult(thumbnail: 'sample://fallback');

      expect(response.itemName, 'Unknown collectible');
      expect(response.category, 'Collectible');
      expect(response.estimatedValue, 0);
      expect(response.confidence, 0);
      expect(response.condition, 'Unknown');
      expect(response.recommendation, 'Review the result before saving.');
      expect(result.thumbnail, 'sample://fallback');
      expect(result.pricing.estimatedMarketValue, 0);
      expect(result.alternativeMatches.single.title, 'Unknown alternative');
      expect(result.alternativeMatches.single.confidence, 0.73);

      final validation = const AiBackendContractValidator().validateResponse(
        response,
      );
      expect(validation.isValid, isFalse);
      expect(validation.issues, contains('itemName is missing or defaulted.'));
    });

    test('backend error parses safe defaults', () {
      final error = AiBackendAnalysisError.fromJson({
        'message': 'Backend unavailable.',
        'retryable': true,
        'details': {'status': 503},
      });

      expect(error.code, 'backend_ai_error');
      expect(error.message, 'Backend unavailable.');
      expect(error.retryable, isTrue);
      expect(error.details['status'], 503);
      expect(error.toJson()['retryable'], isTrue);
    });
  });

  group('Scanner UX v1 foundation', () {
    test('scan goals expose stable metadata', () {
      expect(ScanGoal.identifyValue.id, 'identifyValue');
      expect(ScanGoal.identifyValue.title, 'Identify & Value');
      expect(ScanGoal.identifyValue.confidenceTarget, 0.90);
      expect(ScanGoal.detailedAnalysis.confidenceTarget, 0.98);
      expect(ScanGoal.prepareForSale.confidenceTarget, 0.95);
      expect(ScanGoal.fromId('prepareForSale'), ScanGoal.prepareForSale);
    });

    test('confidence model reports target status and delta', () {
      const below = ConfidenceModel(
        confidenceTarget: 0.95,
        confidenceAchieved: 0.90,
      );
      const unavailable = ConfidenceModel(confidenceTarget: 0.95);

      expect(below.isTargetMet, isFalse);
      expect(below.deltaFromTarget, closeTo(-0.05, 0.0001));
      expect(unavailable.isTargetMet, isFalse);
      expect(unavailable.deltaFromTarget, isNull);
    });

    test('scan session records events and scanner UX version', () {
      final plan = const ScanCapturePlanService().buildPlan(
        ScanGoal.identifyValue,
        null,
        const [],
      );
      final session =
          ScanSession.start(
            sessionId: 'session-1',
            scanGoal: ScanGoal.identifyValue,
            capturePlan: plan,
            startTime: DateTime.parse('2026-07-06T10:00:00Z'),
          ).addEvent(
            CaptureEvent(
              type: CaptureEventType.goalSelected,
              timestamp: DateTime.parse('2026-07-06T10:01:00Z'),
            ),
          );

      expect(session.scannerUxVersion, scannerUxVersion);
      expect(session.confidenceTarget, 0.90);
      expect(session.events.first.type, CaptureEventType.sessionStarted);
      expect(session.events.last.type, CaptureEventType.goalSelected);
    });

    test('capture plan completion and next role are goal aware', () {
      const service = ScanCapturePlanService();

      final initial = service.buildPlan(
        ScanGoal.detailedAnalysis,
        null,
        const [],
      );
      final partial = service.buildPlan(ScanGoal.detailedAnalysis, null, const [
        CapturedScanImage(
          path: 'front.jpg',
          role: ScanCaptureRole.front,
          source: 'camera',
        ),
      ]);

      expect(initial.nextRecommendedRole, ScanCaptureRole.front);
      expect(initial.isMinimumReadyForAnalyze, isFalse);
      expect(partial.completionPercentage, closeTo(1 / 3, 0.001));
      expect(partial.nextRecommendedRole, ScanCaptureRole.back);
    });

    test('goal capture plans expose v1 analyze readiness rules', () {
      const service = ScanCapturePlanService();

      final identifyReady = service
          .buildPlan(ScanGoal.identifyValue, null, const [
            CapturedScanImage(
              path: 'front.jpg',
              role: ScanCaptureRole.front,
              source: 'camera',
            ),
          ]);
      final detailedReady = service
          .buildPlan(ScanGoal.detailedAnalysis, null, const [
            CapturedScanImage(
              path: 'front.jpg',
              role: ScanCaptureRole.front,
              source: 'camera',
            ),
            CapturedScanImage(
              path: 'back.jpg',
              role: ScanCaptureRole.back,
              source: 'camera',
            ),
            CapturedScanImage(
              path: 'close.jpg',
              role: ScanCaptureRole.closeUp,
              source: 'camera',
            ),
          ]);
      final saleReady = service.buildPlan(ScanGoal.prepareForSale, null, const [
        CapturedScanImage(
          path: 'front.jpg',
          role: ScanCaptureRole.front,
          source: 'camera',
        ),
        CapturedScanImage(
          path: 'back.jpg',
          role: ScanCaptureRole.back,
          source: 'camera',
        ),
        CapturedScanImage(
          path: 'close.jpg',
          role: ScanCaptureRole.closeUp,
          source: 'camera',
        ),
        CapturedScanImage(
          path: 'damage.jpg',
          role: ScanCaptureRole.damageDetail,
          source: 'camera',
        ),
      ]);

      expect(identifyReady.isMinimumReadyForAnalyze, isTrue);
      expect(identifyReady.nextRecommendedRole, ScanCaptureRole.back);
      expect(detailedReady.isMinimumReadyForAnalyze, isTrue);
      expect(detailedReady.nextRecommendedRole, ScanCaptureRole.damageDetail);
      expect(saleReady.isMinimumReadyForAnalyze, isTrue);
      expect(saleReady.requiredRoles, [
        ScanCaptureRole.front,
        ScanCaptureRole.back,
        ScanCaptureRole.closeUp,
        ScanCaptureRole.damageDetail,
      ]);
      expect(saleReady.optionalRoles, [
        ScanCaptureRole.serialOrMark,
        ScanCaptureRole.angledReflective,
      ]);
    });

    test('capture plan updates next role after delete-like removal', () {
      const service = ScanCapturePlanService();

      final withFrontBack = service
          .buildPlan(ScanGoal.prepareForSale, null, const [
            CapturedScanImage(
              path: 'front.jpg',
              role: ScanCaptureRole.front,
              source: 'camera',
            ),
            CapturedScanImage(
              path: 'back.jpg',
              role: ScanCaptureRole.back,
              source: 'camera',
            ),
            CapturedScanImage(
              path: 'close.jpg',
              role: ScanCaptureRole.closeUp,
              source: 'camera',
            ),
            CapturedScanImage(
              path: 'damage.jpg',
              role: ScanCaptureRole.damageDetail,
              source: 'camera',
            ),
          ]);
      final afterBackDelete = service
          .buildPlan(ScanGoal.prepareForSale, null, const [
            CapturedScanImage(
              path: 'front.jpg',
              role: ScanCaptureRole.front,
              source: 'camera',
            ),
            CapturedScanImage(
              path: 'close.jpg',
              role: ScanCaptureRole.closeUp,
              source: 'camera',
            ),
            CapturedScanImage(
              path: 'damage.jpg',
              role: ScanCaptureRole.damageDetail,
              source: 'camera',
            ),
          ]);

      expect(withFrontBack.isMinimumReadyForAnalyze, isTrue);
      expect(afterBackDelete.isMinimumReadyForAnalyze, isFalse);
      expect(afterBackDelete.nextRecommendedRole, ScanCaptureRole.back);
    });

    test('quality gates pass valid image and block undecodable bytes', () {
      const service = ScanQualityGateService(
        minimumDimension: 1,
        minimumFileSizeBytes: 1,
      );
      final validBytes = Uint8List.fromList(
        img.encodeJpg(img.Image(width: 4, height: 4)),
      );

      final valid = service.evaluateBytes(
        validBytes,
        fileSizeBytes: validBytes.length,
      );
      final invalid = service.evaluateBytes(
        Uint8List.fromList([1, 2, 3]),
        fileSizeBytes: 3,
      );

      expect(valid.passed, isTrue);
      expect(valid.technicalMetrics['width'], isNotNull);
      expect(invalid.passed, isFalse);
      expect(invalid.severity, QualityGateSeverity.blocker);
    });

    test('analyze payload includes scanner metadata', () {
      final request = AiBackendAnalysisRequest(
        imagePath: 'test/fixtures/image.jpg',
        imageSource: 'gallery',
        timestamp: DateTime.parse('2026-07-06T10:00:00Z'),
        scanGoal: ScanGoal.prepareForSale.id,
        confidenceTarget: ScanGoal.prepareForSale.confidenceTarget,
        scannerUxVersion: scannerUxVersion,
        qualityMetadata: const {
          'front': {'passed': true},
        },
        images: const [
          AiBackendAnalysisImage(
            imagePath: 'test/fixtures/image.jpg',
            imageSource: 'gallery',
            imageRole: 'front',
          ),
        ],
      );

      final json = request.toJson();

      expect(json['scanGoal'], 'prepareForSale');
      expect(json['confidenceTarget'], 0.95);
      expect(json['scannerUxVersion'], scannerUxVersion);
      expect(json['qualityMetadata'], isNotEmpty);
      expect((json['images'] as List).single['imageRole'], 'front');
    });
  });

  group('AiImageUploadPayload', () {
    test('builds metadata from valid file', () async {
      const preparer = AiImagePayloadPreparer();

      final payload = await preparer.fromLocalFile(
        localFilePath: 'test/fixtures/image.jpg',
        imageSource: 'gallery',
      );

      expect(payload.fileName, 'image.jpg');
      expect(payload.mimeType, 'image/jpeg');
      expect(payload.sizeBytes, greaterThan(0));
      expect(payload.imageSource, 'gallery');
      expect(payload.localFilePath, 'test/fixtures/image.jpg');
      expect(payload.base64Image, isNotEmpty);
      expect(payload.base64Preview, isNull);
      expect(payload.toMetadataJson()['mimeType'], 'image/jpeg');
      expect(payload.toMetadataJson()['base64Image'], payload.base64Image);
    });

    test('missing file returns friendly validation error', () async {
      const preparer = AiImagePayloadPreparer();

      await expectLater(
        preparer.fromLocalFile(
          localFilePath: 'test/fixtures/missing-card.jpg',
          imageSource: 'camera',
        ),
        throwsA(
          isA<AiImagePayloadException>().having(
            (error) => error.message,
            'message',
            contains('not found'),
          ),
        ),
      );
    });

    test('unsupported extension returns friendly validation error', () async {
      const preparer = AiImagePayloadPreparer();

      await expectLater(
        preparer.fromLocalFile(
          localFilePath: 'test/fixtures/image.gif',
          imageSource: 'gallery',
        ),
        throwsA(
          isA<AiImagePayloadException>().having(
            (error) => error.message,
            'message',
            contains('Unsupported image type'),
          ),
        ),
      );
    });

    test('oversized image returns friendly validation error', () async {
      const preparer = AiImagePayloadPreparer(maxFileSizeBytes: 4);

      await expectLater(
        preparer.fromLocalFile(
          localFilePath: 'test/fixtures/image.jpg',
          imageSource: 'gallery',
        ),
        throwsA(
          isA<AiImagePayloadException>().having(
            (error) => error.message,
            'message',
            contains('too large'),
          ),
        ),
      );
    });
  });

  group('AiBackendClient', () {
    test('missing endpoint returns safe not-configured error', () async {
      const client = NoopAiBackendClient(endpointUrl: '');

      await expectLater(
        client.analyze(_backendRequest()),
        throwsA(
          isA<AiBackendClientException>()
              .having(
                (error) => error.type,
                'type',
                AiBackendClientErrorType.endpointMissing,
              )
              .having(
                (error) => error.message,
                'message',
                contains('Backend AI endpoint not configured'),
              ),
        ),
      );
    });

    test('timeout maps to friendly error', () async {
      const client = NoopAiBackendClient(
        endpointUrl: 'https://backend.example/analyze',
        simulatedError: AiBackendClientErrorType.timeout,
      );

      await expectLater(
        client.analyze(_backendRequest()),
        throwsA(
          isA<AiBackendClientException>()
              .having(
                (error) => error.type,
                'type',
                AiBackendClientErrorType.timeout,
              )
              .having(
                (error) => error.message,
                'message',
                contains('timed out'),
              ),
        ),
      );
    });

    test('backend error maps to safe structured exception', () async {
      const client = NoopAiBackendClient(
        endpointUrl: 'https://backend.example/analyze',
        simulatedError: AiBackendClientErrorType.backendError,
        simulatedBackendError: AiBackendAnalysisError(
          code: 'provider_unavailable',
          message: 'AI provider is temporarily unavailable.',
          retryable: true,
          details: {'provider': 'openai'},
        ),
      );

      await expectLater(
        client.analyze(_backendRequest()),
        throwsA(
          isA<AiBackendClientException>()
              .having(
                (error) => error.type,
                'type',
                AiBackendClientErrorType.backendError,
              )
              .having((error) => error.statusCode, 'statusCode', 502)
              .having(
                (error) => error.message,
                'message',
                'AI provider is temporarily unavailable.',
              ),
        ),
      );
    });

    test(
      'malformed response maps to friendly error without crashing',
      () async {
        const client = NoopAiBackendClient(
          endpointUrl: 'https://backend.example/analyze',
          simulatedError: AiBackendClientErrorType.malformedJson,
        );

        await expectLater(
          client.analyze(_backendRequest()),
          throwsA(
            isA<AiBackendClientException>()
                .having(
                  (error) => error.type,
                  'type',
                  AiBackendClientErrorType.malformedJson,
                )
                .having(
                  (error) => error.message,
                  'message',
                  contains('could not be read'),
                ),
          ),
        );
      },
    );

    test(
      'API service skeleton returns injected response without network',
      () async {
        final service = NoopAiBackendApiService(
          injectedResponse: AiBackendAnalysisResponse.fromJson(
            _backendAnalysisJson(),
          ),
        );
        const payload = AiImageUploadPayload(
          fileName: 'image.jpg',
          mimeType: 'image/jpeg',
          sizeBytes: 8,
          imageSource: 'camera',
          localFilePath: 'test/fixtures/image.jpg',
        );

        final response = await service.analyzeImage(
          request: _backendRequest(),
          imagePayload: payload,
        );

        expect(response.itemName, '1999 Pokemon Charizard Holo');
        expect(response.category, 'Trading Card');
      },
    );

    test(
      'backend client maps image payload validation errors safely',
      () async {
        const client = NoopAiBackendClient(
          endpointUrl: 'https://backend.example/analyze',
        );

        await expectLater(
          client.analyze(
            AiBackendAnalysisRequest(
              imagePath: 'test/fixtures/missing-card.jpg',
              imageSource: 'gallery',
              timestamp: DateTime.parse('2026-06-30T09:00:00Z'),
            ),
          ),
          throwsA(
            isA<AiBackendClientException>()
                .having(
                  (error) => error.type,
                  'type',
                  AiBackendClientErrorType.invalidImagePayload,
                )
                .having(
                  (error) => error.message,
                  'message',
                  contains('not found'),
                ),
          ),
        );
      },
    );

    test('backend client delegates valid payload to API service', () async {
      final client = NoopAiBackendClient(
        endpointUrl: 'https://backend.example/analyze',
        apiService: NoopAiBackendApiService(
          injectedResponse: AiBackendAnalysisResponse.fromJson(
            _backendAnalysisJson(),
          ),
        ),
      );

      final response = await client.analyze(
        AiBackendAnalysisRequest(
          imagePath: 'test/fixtures/image.jpg',
          imageSource: 'gallery',
          timestamp: DateTime.parse('2026-06-30T09:00:00Z'),
        ),
      );

      expect(response.itemName, '1999 Pokemon Charizard Holo');
    });
  });

  group('DioAiBackendApiService', () {
    test('successful backend response maps through OpenAI provider', () async {
      final adapter = _FakeDioAdapter(
        responseData: {'result': _backendAnalysisJson()},
      );
      final service = DioAiBackendApiService(
        endpointUrl: 'https://api.collectiq.test/api/analyze',
        dio: Dio()..httpClientAdapter = adapter,
      );
      final provider = OpenAiVisionAnalysisProvider(
        backendClient: HttpAiBackendClient(
          endpointUrl: 'https://api.collectiq.test/api/analyze',
          apiService: service,
        ),
      );

      final result = await provider.analyze(
        AiAnalysisRequest(
          imagePath: _fixturePath('image.jpg'),
          metadata: const {'imageSource': 'gallery'},
        ),
      );

      expect(result.scanResult.title, '1999 Pokemon Charizard Holo');
      expect(result.scanResult.category, 'Trading Card');
      expect(result.scanResult.estimatedValue, 1850);
      expect(result.scanResult.confidence, 0.94);
      expect(adapter.calls, 1);
      expect(adapter.lastPath, 'https://api.collectiq.test/api/analyze');
      expect(adapter.lastPayload?['request'], isA<Map>());
      expect(adapter.lastPayload?['image'], isA<Map>());
      final imagePayload =
          adapter.lastPayload?['image'] as Map<String, dynamic>;
      expect(imagePayload['base64Image'], isNotEmpty);
      expect(base64Decode(imagePayload['base64Image'] as String), isNotEmpty);
    });

    test('timeout maps to friendly error', () async {
      final service = DioAiBackendApiService(
        endpointUrl: 'https://api.collectiq.test/api/analyze',
        dio: Dio()
          ..httpClientAdapter = _FakeDioAdapter(
            dioExceptionType: DioExceptionType.receiveTimeout,
          ),
      );
      final client = HttpAiBackendClient(
        endpointUrl: 'https://api.collectiq.test/api/analyze',
        apiService: service,
      );

      await expectLater(
        client.analyze(_backendFileRequest()),
        throwsA(
          isA<AiBackendClientException>().having(
            (error) => error.type,
            'type',
            AiBackendClientErrorType.timeout,
          ),
        ),
      );
    });

    test('500 response maps to backend error', () async {
      final service = DioAiBackendApiService(
        endpointUrl: 'https://api.collectiq.test/api/analyze',
        dio: Dio()
          ..httpClientAdapter = _FakeDioAdapter(
            statusCode: 500,
            responseData: {
              'error': {
                'code': 'provider_down',
                'message': 'Backend provider unavailable.',
                'retryable': true,
              },
            },
          ),
      );
      final client = HttpAiBackendClient(
        endpointUrl: 'https://api.collectiq.test/api/analyze',
        apiService: service,
      );

      await expectLater(
        client.analyze(_backendFileRequest()),
        throwsA(
          isA<AiBackendClientException>()
              .having(
                (error) => error.type,
                'type',
                AiBackendClientErrorType.backendError,
              )
              .having((error) => error.statusCode, 'statusCode', 500)
              .having(
                (error) => error.message,
                'message',
                'Backend provider unavailable.',
              ),
        ),
      );
    });

    test('FastAPI detail error preserves analyzer error code', () async {
      final service = DioAiBackendApiService(
        endpointUrl: 'https://api.collectiq.test/analyze',
        dio: Dio()
          ..httpClientAdapter = _FakeDioAdapter(
            statusCode: 422,
            responseData: {
              'detail': {
                'code': 'INVALID_IMAGE_PAYLOAD',
                'message': 'Real AI analysis requires uploaded image bytes.',
                'retryable': false,
                'details': {
                  'missingImageBytes': [
                    {'fileName': 'hot-wheels.jpg'},
                  ],
                },
              },
            },
          ),
      );
      final client = HttpAiBackendClient(
        endpointUrl: 'https://api.collectiq.test/analyze',
        apiService: service,
      );

      await expectLater(
        client.analyze(_backendFileRequest()),
        throwsA(
          isA<AiBackendClientException>()
              .having(
                (error) => error.type,
                'type',
                AiBackendClientErrorType.backendError,
              )
              .having((error) => error.statusCode, 'statusCode', 422)
              .having(
                (error) => error.message,
                'message',
                'Real AI analysis requires uploaded image bytes.',
              )
              .having(
                (error) => error.details['details']?['missingImageBytes'],
                'missing image bytes',
                isA<List>(),
              ),
        ),
      );
    });

    test('malformed JSON is handled safely', () async {
      final service = DioAiBackendApiService(
        endpointUrl: 'https://api.collectiq.test/api/analyze',
        dio: Dio()
          ..httpClientAdapter = _FakeDioAdapter(rawResponseBody: 'not json'),
      );
      final client = HttpAiBackendClient(
        endpointUrl: 'https://api.collectiq.test/api/analyze',
        apiService: service,
      );

      await expectLater(
        client.analyze(_backendFileRequest()),
        throwsA(
          isA<AiBackendClientException>().having(
            (error) => error.type,
            'type',
            AiBackendClientErrorType.malformedJson,
          ),
        ),
      );
    });

    test('invalid endpoint blocks request before transport', () async {
      final adapter = _FakeDioAdapter(
        responseData: {'result': _backendAnalysisJson()},
      );
      final service = DioAiBackendApiService(
        endpointUrl: 'not a url',
        dio: Dio()..httpClientAdapter = adapter,
      );
      final client = HttpAiBackendClient(
        endpointUrl: 'not a url',
        apiService: service,
      );

      await expectLater(
        client.analyze(_backendFileRequest()),
        throwsA(
          isA<AiBackendClientException>().having(
            (error) => error.type,
            'type',
            AiBackendClientErrorType.invalidEndpoint,
          ),
        ),
      );
      expect(adapter.calls, 0);
    });

    test('mock provider still makes no network call', () async {
      final adapter = _FakeDioAdapter(
        responseData: {'result': _backendAnalysisJson()},
      );
      final provider = MockAiAnalysisProvider(
        recognitionRepository: _StaticRecognitionRepository(
          _testRecognitionResult(),
        ),
        marketProvider: const MockMarketProvider(),
      );

      final result = await provider.analyze(
        AiAnalysisRequest(imagePath: _fixturePath('image.jpg')),
      );

      expect(
        MockCollectibleResultPool.templates.map((item) => item.title),
        contains(result.scanResult.title),
      );
      expect(adapter.calls, 0);
    });
  });

  group('AiAnalysisProvider', () {
    test('config parses known providers and defaults to mock', () {
      expect(
        const AiAnalysisProviderConfig().type,
        AiAnalysisProviderType.mock,
      );
      expect(
        AiAnalysisProviderType.fromConfig('mock'),
        AiAnalysisProviderType.mock,
      );
      expect(
        AiAnalysisProviderType.fromConfig('openai_vision'),
        AiAnalysisProviderType.openAiVision,
      );
      expect(
        AiAnalysisProviderType.fromConfig('gemini'),
        AiAnalysisProviderType.geminiVision,
      );
      expect(
        AiAnalysisProviderType.fromConfig('unknown'),
        AiAnalysisProviderType.mock,
      );
    });

    test('config exposes provider labels and safe backend endpoint status', () {
      const config = AiAnalysisProviderConfig(
        type: AiAnalysisProviderType.openAiVision,
        backendAnalysisEndpointUrl: 'https://api.collectiq.example/analyze',
      );

      expect(config.type.displayName, 'OpenAI Vision');
      expect(config.type.configValue, 'openai_vision');
      expect(config.hasBackendAnalysisEndpoint, isTrue);
      expect(config.isSelectedProviderAvailable, isFalse);
      expect(config.selectedProviderMessage, contains('backend endpoint'));
      expect(AiAnalysisProviderType.mock.isAvailable, isTrue);
      expect(AiAnalysisProviderType.geminiVision.statusLabel, 'Coming soon');
    });

    test('mock provider config requires no backend endpoint or API key', () {
      const config = AiAnalysisProviderConfig();

      expect(config.type, AiAnalysisProviderType.mock);
      expect(config.hasBackendAnalysisEndpoint, isFalse);
      expect(config.isSelectedProviderAvailable, isTrue);
      expect(config.selectedProviderMessage, contains('Mock mode is active'));
    });

    test('SIT resolves live backend analyze endpoint by default', () {
      final endpoint = resolveBackendAnalysisEndpointUrl(
        environment: network_config.AppEnvironment.sit,
        backendAnalysisEndpointUrl: '',
        apiBaseUrl: '',
      );

      expect(endpoint, 'https://api-sit.packlox.com/analyze');
    });

    test('explicit analyzer endpoint takes precedence over SIT default', () {
      final endpoint = resolveBackendAnalysisEndpointUrl(
        environment: network_config.AppEnvironment.sit,
        backendAnalysisEndpointUrl: 'https://override.example/analyze',
        apiBaseUrl: 'https://api-sit.packlox.com',
      );

      expect(endpoint, 'https://override.example/analyze');
    });

    test('API base URL override appends analyze path', () {
      final endpoint = resolveBackendAnalysisEndpointUrl(
        environment: network_config.AppEnvironment.sit,
        backendAnalysisEndpointUrl: '',
        apiBaseUrl: 'https://api-sit.packlox.com/',
      );

      expect(endpoint, 'https://api-sit.packlox.com/analyze');
    });

    test('development keeps backend analyzer disabled unless configured', () {
      final endpoint = resolveBackendAnalysisEndpointUrl(
        environment: network_config.AppEnvironment.development,
        backendAnalysisEndpointUrl: '',
        apiBaseUrl: '',
      );

      expect(endpoint, isEmpty);
    });

    test('SIT API base URL uses live backend', () {
      expect(
        network_config.ApiConstants.baseUrlFor(
          network_config.AppEnvironment.sit,
        ),
        'https://api-sit.packlox.com',
      );
    });

    test('OpenAI Vision skeleton returns safe backend error', () async {
      const provider = OpenAiVisionAnalysisProvider(
        backendClient: NoopAiBackendClient(endpointUrl: ''),
      );

      await expectLater(
        provider.analyze(
          const AiAnalysisRequest(imagePath: 'sample://sports-card'),
        ),
        throwsA(
          isA<AiAnalysisException>().having(
            (error) => error.message,
            'message',
            contains('Backend AI endpoint not configured'),
          ),
        ),
      );
    });

    test(
      'OpenAI Vision provider maps backend response to scan result',
      () async {
        final backendClient = _SuccessfulAiBackendClient(
          AiBackendAnalysisResponse.fromJson(_backendAnalysisJson()),
        );
        final provider = OpenAiVisionAnalysisProvider(
          backendClient: backendClient,
        );

        final result = await provider.analyze(
          const AiAnalysisRequest(
            imagePath: '/local/path/card.jpg',
            metadata: {'imageSource': 'gallery'},
          ),
        );

        expect(backendClient.calls, 1);
        expect(backendClient.lastRequest?.imageSource, 'gallery');
        expect(result.scanResult.title, '1999 Pokemon Charizard Holo');
        expect(result.scanResult.thumbnail, '/local/path/card.jpg');
        expect(result.scanResult.marketSummary?.trendLabel, 'Rising');
        expect(result.recommendation, 'Consider grading before selling.');
      },
    );

    test('mock provider returns scan analysis result', () async {
      final provider = MockAiAnalysisProvider(
        recognitionRepository: _StaticRecognitionRepository(
          _testRecognitionResult(),
        ),
        marketProvider: const MockMarketProvider(),
      );

      final result = await provider.analyze(
        const AiAnalysisRequest(imagePath: 'sample://sports-card'),
      );

      expect(result.scanResult.title, contains('Charizard'));
      expect(result.scanResult.category, 'Pokemon Card');
      expect(result.scanResult.thumbnail, 'sample://sports-card');
      expect(result.scanResult.alternativeMatches, hasLength(3));
      expect(result.scanResult.marketSummary, isNotNull);
      expect(result.scanResult.year, '1999');
      expect(result.scanResult.brand, 'Pokemon');
      expect(result.scanResult.pricing.lowEstimate, greaterThan(0));
      expect(result.scanResult.notes, contains('SIT MOCK DATA'));
      expect(result.recommendation, contains('Sleeve it'));
    });

    test('SIT mock analyzer can return more than one unique result', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'packlox-mock-pool-',
      );
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });
      final firstImage = File('${tempDir.path}/first.jpg')
        ..writeAsBytesSync(List<int>.generate(128, (index) => index));
      final secondImage = File('${tempDir.path}/second.jpg')
        ..writeAsBytesSync(List<int>.generate(128, (index) => 255 - index));
      final repository = _StaticRecognitionRepository(_testRecognitionResult());
      final provider = MockAiAnalysisProvider(
        recognitionRepository: repository,
        marketProvider: const MockMarketProvider(),
      );

      final first = await provider.analyze(
        AiAnalysisRequest(
          imagePath: firstImage.path,
          image: XFile(firstImage.path),
        ),
      );
      final second = await provider.analyze(
        AiAnalysisRequest(
          imagePath: secondImage.path,
          image: XFile(secondImage.path),
        ),
      );

      expect({first.scanResult.title, second.scanResult.title}, hasLength(2));
      expect(repository.calls, 0);
      expect(first.scanResult.thumbnail, firstImage.path);
      expect(second.scanResult.thumbnail, secondImage.path);
    });

    test('mock result pool covers required SIT demo categories', () {
      final categories = {
        for (final template in MockCollectibleResultPool.templates)
          template.category,
      };

      expect(
        MockCollectibleResultPool.templates,
        hasLength(greaterThanOrEqualTo(30)),
      );
      expect(categories, contains('Pokemon Card'));
      expect(categories, contains('Sports Card'));
      expect(categories, contains('Coin'));
      expect(categories, contains('Action Figure'));
      expect(categories, contains('Comic Book'));
      expect(categories, contains('Stamp'));
      expect(categories, contains('Retro Game'));
      expect(categories, contains('Trading Card'));
      expect(categories, contains('Vintage Toy'));
      expect(
        MockCollectibleResultPool.templates.map((item) => item.title),
        contains('1999 Pokemon Charizard Holo'),
      );
    });

    test('mock result shape matches scan result schema', () async {
      const pool = MockCollectibleResultPool();

      final recognition = await pool.resultFor(
        const AiAnalysisRequest(imagePath: 'sample://sports-card'),
      );

      expect(recognition.success, isTrue);
      expect(recognition.title, isNotEmpty);
      expect(recognition.category, isNotEmpty);
      expect(recognition.year, isNotEmpty);
      expect(recognition.brand, isNotEmpty);
      expect(recognition.confidence, inInclusiveRange(0, 1));
      expect(recognition.estimatedValue, greaterThan(0));
      expect(recognition.condition, isNotEmpty);
      expect(recognition.description, isNotEmpty);
      expect(recognition.notes, contains('SIT MOCK DATA'));
      expect(recognition.pricing.lowEstimate, greaterThan(0));
      expect(
        recognition.pricing.highEstimate,
        greaterThanOrEqualTo(recognition.estimatedValue),
      );
      expect(recognition.alternativeMatches, hasLength(3));
    });
  });

  group('GalleryService', () {
    test('validates supported image extensions case-insensitively', () async {
      final service = GalleryService();

      for (final name in [
        'test/fixtures/image.PNG',
        'test/fixtures/image.Png',
        'test/fixtures/image.jpg',
        'test/fixtures/image.JPEG',
      ]) {
        final image = XFile(name);

        await expectLater(service.validateImage(image), completion(isTrue));
      }
    });

    test('rejects unsupported image extension with clear message', () async {
      final service = GalleryService();
      final image = XFile('test/fixtures/image.gif');

      await expectLater(
        service.validateImage(image),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('Please select a PNG, JPG, or JPEG image.'),
          ),
        ),
      );
    });
  });

  group('MockAuthRepository', () {
    test('defaults to local anonymous user for local-first mode', () async {
      const repository = MockAuthRepository();

      final user = await repository.currentUser();

      expect(user, isNotNull);
      expect(user!.id, 'local-anonymous-user');
      expect(user.displayName, 'Local Collector');
      expect(user.isAnonymous, isTrue);
      expect(user.isLocalOnly, isTrue);
      expect(user.provider, AuthProviderType.localAnonymous);
    });

    test('signIn returns mock anonymous user placeholder', () async {
      const repository = MockAuthRepository();

      final user = await repository.signIn();

      expect(user.id, 'local-anonymous-user');
      expect(user.displayName, 'Local Collector');
      expect(user.isAnonymous, isTrue);
    });

    test('future sign-in providers return safe placeholder errors', () async {
      const repository = MockAuthRepository();

      await expectLater(
        repository.signInWithEmailPassword(
          email: 'harry@example.com',
          password: 'password',
        ),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        repository.signUpWithEmailPassword(
          email: 'harry@example.com',
          password: 'password',
        ),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        repository.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
      await expectLater(
        repository.signInWithApple(),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('Supabase foundation', () {
    test('config remains disabled when environment is not provided', () {
      final config = SupabaseConfig.fromEnvironment();

      expect(config.isConfigured, isFalse);
      expect(config.url, isEmpty);
      expect(config.anonKey, isEmpty);
    });

    test('SIT config with anon key reports configured safely', () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: 'public-anon-key',
        isEnabled: true,
      );

      expect(config.isConfigured, isTrue);
      expect(config.hasUrl, isTrue);
      expect(config.hasAnonKey, isTrue);
      expect(config.anonKeyLength, 'public-anon-key'.length);
      expect(config.maskedAnonKeyLengthLabel, '15 characters');
      expect(config.maskedAnonKeyLengthLabel, isNot(contains('public')));
    });

    test('missing anon key reports setup required state', () {
      const config = SupabaseConfig(
        url: 'https://example.supabase.co',
        anonKey: '',
        isEnabled: true,
      );

      expect(config.isConfigured, isFalse);
      expect(config.hasUrl, isTrue);
      expect(config.hasAnonKey, isFalse);
      expect(config.anonKeyLength, 0);
      expect(config.maskedAnonKeyLengthLabel, '0');
    });

    test(
      'SIT scripts pass required dart defines without hardcoded secrets',
      () {
        for (final path in ['run_sit.bat', 'build_sit_apk.bat']) {
          final script = File(path).readAsStringSync();

          expect(script, contains('--dart-define=SUPABASE_URL=%SUPABASE_URL%'));
          expect(
            script,
            contains('--dart-define=SUPABASE_ANON_KEY=%SUPABASE_ANON_KEY%'),
          );
          expect(script, contains('--dart-define=API_BASE_URL=%API_BASE_URL%'));
          expect(script, contains('--dart-define=APP_ENV=sit'));
          expect(
            script,
            contains(
              '--dart-define=AI_ANALYSIS_PROVIDER=%AI_ANALYSIS_PROVIDER%',
            ),
          );
          expect(script, contains('--dart-define=USE_CLOUD_AUTH=true'));
          expect(
            script,
            contains('--dart-define=USE_CLOUD_PORTFOLIO_SYNC=true'),
          );
          expect(
            script,
            contains('--dart-define=USE_CLOUD_IMAGE_STORAGE=true'),
          );
          expect(script, contains('scripts\\load_env.bat'));
          expect(
            script,
            isNot(contains('--dart-define=AI_ANALYSIS_PROVIDER=mock')),
          );
          expect(script, isNot(contains('ljrkhamgbgtsicqdisos')));
        }
      },
    );

    test('SIT release build docs include Supabase auth dart defines', () {
      final buildSetup = File('docs/SIT_BUILD_SETUP.md').readAsStringSync();
      final realDeviceCommands = File(
        'docs/PACKLOX_REAL_DEVICE_SIT_COMMANDS.md',
      ).readAsStringSync();

      for (final docs in [buildSetup, realDeviceCommands]) {
        expect(docs, contains('build apk'));
        expect(docs, contains('--release'));
        expect(docs, contains('--flavor sit'));
        expect(docs, contains('--dart-define=APP_ENV=sit'));
        expect(docs, contains('--dart-define=USE_CLOUD_AUTH=true'));
        expect(docs, contains('--dart-define=SUPABASE_ENABLED=true'));
        expect(
          docs,
          contains(
            '--dart-define=SUPABASE_URL=https://ljrkhamgbgtsicqdisos.supabase.co',
          ),
        );
        expect(
          docs,
          contains('--dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY'),
        );
        expect(docs, isNot(contains('eyJ')));
      }
    });

    test('auth error mapper handles common Supabase auth failures', () {
      final missingKey = SupabaseService.authFailureMessageForTesting(
        DioException(
          requestOptions: RequestOptions(path: '/auth/v1/signup'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/v1/signup'),
            statusCode: 401,
            data: const {'message': 'No API key found in request'},
          ),
        ),
      );
      final network = SupabaseService.authFailureMessageForTesting(
        DioException(
          requestOptions: RequestOptions(path: '/auth/v1/signup'),
          type: DioExceptionType.connectionError,
        ),
      );
      final confirmationRequired = SupabaseService.authFailureMessageForTesting(
        DioException(
          requestOptions: RequestOptions(path: '/auth/v1/token'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/v1/token'),
            statusCode: 400,
            data: const {'message': 'Email not confirmed'},
          ),
        ),
      );
      final alreadyRegistered = SupabaseService.authFailureMessageForTesting(
        DioException(
          requestOptions: RequestOptions(path: '/auth/v1/signup'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/v1/signup'),
            statusCode: 422,
            data: const {'message': 'User already registered'},
          ),
        ),
      );
      final invalidCredentials = SupabaseService.authFailureMessageForTesting(
        DioException(
          requestOptions: RequestOptions(path: '/auth/v1/token'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/v1/token'),
            statusCode: 400,
            data: const {'error_description': 'Invalid login credentials'},
          ),
        ),
      );
      final weakPassword = SupabaseService.authFailureMessageForTesting(
        DioException(
          requestOptions: RequestOptions(path: '/auth/v1/signup'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/v1/signup'),
            statusCode: 422,
            data: const {'message': 'Weak password'},
          ),
        ),
      );
      final rateLimited = SupabaseService.authFailureMessageForTesting(
        DioException(
          requestOptions: RequestOptions(path: '/auth/v1/signup'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/v1/signup'),
            statusCode: 429,
            data: const {'code': 'over_email_send_rate_limit'},
          ),
        ),
      );
      final unmappedHttpError = SupabaseService.authFailureMessageForTesting(
        DioException(
          requestOptions: RequestOptions(path: '/auth/v1/signup'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/v1/signup'),
            statusCode: 500,
            data: const {},
          ),
        ),
      );

      expect(missingKey, 'Supabase anon key is missing from SIT config.');
      expect(
        network,
        'Unable to reach Supabase. Check your internet connection.',
      );
      expect(
        confirmationRequired,
        'Please confirm your email before signing in.',
      );
      expect(alreadyRegistered, 'An account already exists. Please sign in.');
      expect(invalidCredentials, 'Invalid email or password.');
      expect(weakPassword, 'Password is too weak. Use a stronger password.');
      expect(
        rateLimited,
        'Too many auth requests. Wait a moment and try again.',
      );
      expect(
        unmappedHttpError,
        'Supabase is temporarily unavailable. Please try again soon.',
      );
      expect(unmappedHttpError, isNot(contains('Unable to connect')));
    });

    test(
      'auth error mapper handles unknown account separately when proven',
      () {
        final message = SupabaseService.authFailureMessageForTesting(
          DioException(
            requestOptions: RequestOptions(path: '/auth/v1/token'),
            response: Response<Map<String, dynamic>>(
              requestOptions: RequestOptions(path: '/auth/v1/token'),
              statusCode: 400,
              data: const {'message': 'User not found'},
            ),
          ),
        );

        expect(message, 'Please sign up first.');
      },
    );

    test(
      'confirmation resend error mapper handles expected Supabase responses',
      () {
        final rateLimited =
            SupabaseService.confirmationFailureMessageForTesting(
              DioException(
                requestOptions: RequestOptions(path: '/auth/v1/resend'),
                response: Response<Map<String, dynamic>>(
                  requestOptions: RequestOptions(path: '/auth/v1/resend'),
                  statusCode: 429,
                  data: const {'code': 'over_email_send_rate_limit'},
                ),
              ),
            );
        final alreadyConfirmed =
            SupabaseService.confirmationFailureMessageForTesting(
              DioException(
                requestOptions: RequestOptions(path: '/auth/v1/resend'),
                response: Response<Map<String, dynamic>>(
                  requestOptions: RequestOptions(path: '/auth/v1/resend'),
                  statusCode: 400,
                  data: const {'message': 'User already confirmed'},
                ),
              ),
            );
        final invalidEmail =
            SupabaseService.confirmationFailureMessageForTesting(
              DioException(
                requestOptions: RequestOptions(path: '/auth/v1/resend'),
                response: Response<Map<String, dynamic>>(
                  requestOptions: RequestOptions(path: '/auth/v1/resend'),
                  statusCode: 400,
                  data: const {'message': 'Invalid email'},
                ),
              ),
            );
        final network = SupabaseService.confirmationFailureMessageForTesting(
          DioException(
            requestOptions: RequestOptions(path: '/auth/v1/resend'),
            type: DioExceptionType.connectionError,
          ),
        );
        final retryAfter = SupabaseService.retryAfterDurationForTesting(
          Headers.fromMap({
            'retry-after': ['123'],
          }),
        );

        expect(rateLimited, AuthMessages.confirmationRateLimited);
        expect(retryAfter, const Duration(seconds: 123));
        expect(
          alreadyConfirmed,
          'Your email is already confirmed. Please sign in.',
        );
        expect(invalidEmail, 'Please enter a valid email address.');
        expect(
          network,
          'Unable to reach Supabase. Check your internet connection.',
        );
      },
    );

    group('SupabaseAuthResponseNormalizer contract', () {
      SupabaseAuthNormalizedResult normalize({
        required SupabaseAuthAction action,
        required int? statusCode,
        required Object? body,
        Headers? headers,
      }) {
        return SupabaseAuthResponseNormalizer.normalizeResponse(
          action: action,
          statusCode: statusCode,
          body: body,
          headers: headers,
        );
      }

      test('normalizes wrapped signup user with null session', () {
        final result = normalize(
          action: SupabaseAuthAction.signUp,
          statusCode: 200,
          body: const {
            'user': {'id': 'user-1', 'email': 'new@example.com'},
            'session': null,
          },
        );

        expect(
          result.status,
          SupabaseAuthNormalizedStatus.confirmationRequired,
        );
        expect(result.metadata.hasUser, isTrue);
        expect(result.metadata.hasSession, isFalse);
      });

      test('normalizes direct signup user object with confirmation fields', () {
        final result = normalize(
          action: SupabaseAuthAction.signUp,
          statusCode: 200,
          body: const {
            'id': 'user-1',
            'email': 'new@example.com',
            'aud': 'authenticated',
            'role': 'authenticated',
            'confirmation_sent_at': '2026-07-02T00:00:00Z',
          },
        );

        expect(
          result.status,
          SupabaseAuthNormalizedStatus.confirmationRequired,
        );
        expect(result.metadata.hasDirectId, isTrue);
        expect(result.metadata.hasDirectEmail, isTrue);
        expect(result.metadata.hasConfirmationSentAt, isTrue);
      });

      test('normalizes direct signup user object with identities', () {
        final result = normalize(
          action: SupabaseAuthAction.signUp,
          statusCode: 200,
          body: const {
            'id': 'user-1',
            'email': 'new@example.com',
            'identities': [],
          },
        );

        expect(
          result.status,
          SupabaseAuthNormalizedStatus.confirmationRequired,
        );
        expect(result.metadata.hasIdentities, isTrue);
      });

      test('normalizes empty and string 2xx signup bodies as confirmation', () {
        for (final response in [
          (statusCode: 200, body: null),
          (statusCode: 200, body: const <String, dynamic>{}),
          (statusCode: 201, body: null),
          (statusCode: 200, body: 'OK'),
        ]) {
          final result = normalize(
            action: SupabaseAuthAction.signUp,
            statusCode: response.statusCode,
            body: response.body,
          );

          expect(
            result.status,
            SupabaseAuthNormalizedStatus.confirmationRequired,
          );
        }
      });

      test('normalizes already registered response', () {
        final result = normalize(
          action: SupabaseAuthAction.signUp,
          statusCode: 400,
          body: const {'msg': 'User already registered'},
        );

        expect(result.status, SupabaseAuthNormalizedStatus.alreadyRegistered);
        expect(result.metadata.hasErrorMessage, isTrue);
      });

      test('normalizes email not confirmed response', () {
        final result = normalize(
          action: SupabaseAuthAction.signIn,
          statusCode: 400,
          body: const {'message': 'Email not confirmed'},
        );

        expect(result.status, SupabaseAuthNormalizedStatus.emailNotConfirmed);
      });

      test('normalizes invalid login response', () {
        final result = normalize(
          action: SupabaseAuthAction.signIn,
          statusCode: 400,
          body: const {
            'error': 'invalid_grant',
            'error_description': 'Invalid login credentials',
          },
        );

        expect(result.status, SupabaseAuthNormalizedStatus.invalidCredentials);
        expect(result.metadata.hasErrorCode, isTrue);
      });

      test('normalizes missing API key response', () {
        final result = normalize(
          action: SupabaseAuthAction.signUp,
          statusCode: 401,
          body: const {'message': 'No API key found in request'},
        );

        expect(result.status, SupabaseAuthNormalizedStatus.configMissing);
      });

      test('normalizes rate limit response with retry-after', () {
        final result = normalize(
          action: SupabaseAuthAction.resendConfirmation,
          statusCode: 429,
          body: const {'code': 'over_email_send_rate_limit'},
          headers: Headers.fromMap({
            'retry-after': ['90'],
          }),
        );

        expect(result.status, SupabaseAuthNormalizedStatus.rateLimited);
        expect(result.retryAfter, const Duration(seconds: 90));
        expect(result.cooldownSource, 'retry-after');
      });

      test('normalizes network timeout separately from HTTP errors', () {
        final result = SupabaseAuthResponseNormalizer.normalizeException(
          action: SupabaseAuthAction.signUp,
          error: DioException(
            requestOptions: RequestOptions(path: '/auth/v1/signup'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        expect(result.status, SupabaseAuthNormalizedStatus.networkFailure);
        expect(result.metadata.httpStatus, isNull);
      });
    });

    test(
      'signup success responses without session require email confirmation',
      () {
        const baseUser = {
          'id': 'new-user',
          'email': 'collector@example.com',
          'user_metadata': {'display_name': 'collector@example.com'},
        };
        final responses = [
          (statusCode: 200, data: const {'user': baseUser, 'session': null}),
          (statusCode: 201, data: const {'user': baseUser, 'session': null}),
          (
            statusCode: 200,
            data: const {
              'user': {...baseUser, 'identities': []},
            },
          ),
          (
            statusCode: 200,
            data: const {
              'id': 'new-user',
              'email': 'collector@example.com',
              'aud': 'authenticated',
              'role': 'authenticated',
              'confirmation_sent_at': '2026-07-02T00:00:00Z',
            },
          ),
          (
            statusCode: 201,
            data: const {
              'id': 'new-user',
              'email': 'collector@example.com',
              'identities': [],
            },
          ),
        ];

        for (final response in responses) {
          expect(
            SupabaseService.isEmailConfirmationSignUpResponseForTesting(
              statusCode: response.statusCode,
              data: response.data,
            ),
            isTrue,
          );
        }
      },
    );

    test('empty successful signup response is confirmation email sent', () {
      expect(
        SupabaseService.isEmptySuccessfulSignUpResponseForTesting(
          statusCode: 200,
          data: null,
        ),
        isTrue,
      );
      expect(
        SupabaseService.isEmptySuccessfulSignUpResponseForTesting(
          statusCode: 201,
          data: const {},
        ),
        isTrue,
      );
      expect(
        SupabaseService.isEmptySuccessfulSignUpResponseForTesting(
          statusCode: 400,
          data: const {},
        ),
        isFalse,
      );
    });

    test(
      'unexpected non-success signup response is not confirmation success',
      () {
        expect(
          SupabaseService.isEmailConfirmationSignUpResponseForTesting(
            statusCode: 400,
            data: const {'message': 'Unknown shape'},
          ),
          isFalse,
        );
        expect(
          SupabaseService.isEmptySuccessfulSignUpResponseForTesting(
            statusCode: 400,
            data: const {'message': 'Unknown shape'},
          ),
          isFalse,
        );
      },
    );

    test(
      'signup response without session is treated as email confirmation',
      () {
        final session = SupabaseAuthSession.fromJson(const {
          'user': {
            'id': 'new-user',
            'email': 'collector@example.com',
            'user_metadata': {'display_name': 'collector@example.com'},
          },
        }, projectUrl: 'https://example.supabase.co');

        expect(session.userId, 'new-user');
        expect(session.accessToken, isEmpty);
        expect(session.isEmailConfirmationPending, isTrue);
        expect(session.hasAuthenticatedSession, isFalse);
      },
    );

    test('migration creates the portfolio_items schema used by sync', () {
      final migration = File(
        'supabase/migrations/202607010001_collectiq_portfolio_items_schema.sql',
      ).readAsStringSync();

      expect(
        migration,
        contains('create table if not exists public.user_profiles'),
      );
      expect(
        migration,
        contains('create table if not exists public.portfolio_items'),
      );
      expect(migration, contains('manufacturer text'));
      expect(migration, contains('series text'));
      expect(migration, contains('estimated_value_low numeric(12, 2)'));
      expect(migration, contains('estimated_value_high numeric(12, 2)'));
      expect(migration, contains('image_storage_path text'));
      expect(migration, contains('cloud_image_url text'));
      expect(migration, contains('raw_json jsonb'));
      expect(migration, contains('references auth.users(id)'));
      expect(migration, contains('function public.handle_new_auth_user()'));
      expect(migration, contains('on_auth_user_created'));
      expect(
        migration,
        contains('alter table public.user_profiles enable row level security'),
      );
      expect(
        migration,
        contains(
          'alter table public.portfolio_items enable row level security',
        ),
      );
      expect(migration, contains('auth.uid() = user_id'));
      expect(migration, contains('auth.uid() = id'));
      expect(migration, contains('with check (auth.uid() = user_id)'));
      expect(migration, contains("'pendingUpload'"));
      expect(migration, contains("'deleted'"));
    });

    test(
      'migration creates the selected image bucket and user folder policies',
      () {
        final migration = File(
          'supabase/migrations/202607010001_collectiq_portfolio_items_schema.sql',
        ).readAsStringSync();

        expect(migration, contains("values ('collectiq-portfolio-images'"));
        expect(migration, contains("bucket_id = 'collectiq-portfolio-images'"));
        expect(migration, contains("(storage.foldername(name))[1] = 'users'"));
        expect(migration, contains('(storage.foldername(name))[1]'));
        expect(migration, contains('(storage.foldername(name))[2]'));
        expect(migration, contains('auth.uid()::text'));
        expect(migration, contains('for insert'));
        expect(migration, contains('for select'));
        expect(migration, contains('for update'));
        expect(migration, contains('for delete'));
      },
    );

    test('production readiness files document policies and validation', () {
      final checks = File(
        'supabase/setup/production_readiness_checks.sql',
      ).readAsStringSync();
      final validator = File(
        'scripts/validate_supabase_setup.py',
      ).readAsStringSync();
      final guide = File(
        'docs/SUPABASE_PRODUCTION_SETUP.md',
      ).readAsStringSync();

      expect(checks, contains('table_exists'));
      expect(checks, contains('rls_enabled'));
      expect(checks, contains('storage_bucket_exists'));
      expect(checks, contains('storage_policy_exists'));
      expect(checks, contains('portfolio_items'));
      expect(checks, contains('collectiq-portfolio-images'));
      expect(validator, contains('EXPECTED_TABLES'));
      expect(validator, contains('EXPECTED_STORAGE_POLICIES'));
      expect(validator, contains('SUPABASE_DB_URL'));
      expect(guide, contains('SUPABASE_ENABLED'));
      expect(guide, contains('users/{userId}/portfolio_images/{itemId}.jpg'));
      expect(guide, contains('auth.uid() = user_id'));
    });

    test(
      'auth repository falls back to guest mode when not configured',
      () async {
        final service = SupabaseService.instance(
          config: const SupabaseConfig(url: '', anonKey: '', isEnabled: false),
        );
        final repository = SupabaseAuthRepository(supabaseService: service);

        final currentUser = await repository.currentUser();
        expect(currentUser, isNotNull);
        expect(currentUser!.isLocalOnly, isTrue);
        final user = await repository.signInAnonymously();

        expect(user.displayName, 'Local Collector');
        expect(user.isAnonymous, isTrue);
      },
    );

    test('email auth reports missing config instead of mock sign-in', () async {
      final service = SupabaseService.instance(
        config: const SupabaseConfig(url: '', anonKey: '', isEnabled: false),
      );
      final repository = SupabaseAuthRepository(supabaseService: service);

      await expectLater(
        repository.signInWithEmailPassword(
          email: 'collector@example.com',
          password: 'password123',
        ),
        throwsA(isA<SupabaseNotConfiguredException>()),
      );
      await expectLater(
        repository.signUpWithEmailPassword(
          email: 'collector@example.com',
          password: 'password123',
        ),
        throwsA(isA<SupabaseNotConfiguredException>()),
      );
      await expectLater(
        repository.sendPasswordResetEmail(email: 'collector@example.com'),
        throwsA(isA<SupabaseNotConfiguredException>()),
      );
    });

    test('email sign-in success maps Supabase session to app user', () async {
      final gateway = _FakeSupabaseAuthGateway(
        passwordSession: const SupabaseAuthSession(
          userId: 'user-email',
          email: 'harry@example.com',
          accessToken: 'access-token',
          displayName: 'harry@example.com',
          isAnonymous: false,
          projectUrl: 'https://example.supabase.co',
        ),
      );
      final repository = SupabaseAuthRepository(supabaseService: gateway);

      final user = await repository.signInWithEmailPassword(
        email: 'harry@example.com',
        password: 'password123',
      );

      expect(user.id, 'user-email');
      expect(user.email, 'harry@example.com');
      expect(user.provider, AuthProviderType.emailPassword);
      expect(user.isCloudBacked, isTrue);
      expect(gateway.signInCalls, 1);
    });

    test('email sign-up success maps Supabase session to app user', () async {
      final gateway = _FakeSupabaseAuthGateway(
        signUpSession: const SupabaseAuthSession(
          userId: 'new-user',
          email: 'new@example.com',
          accessToken: 'new-token',
          displayName: 'new@example.com',
          isAnonymous: false,
          projectUrl: 'https://example.supabase.co',
        ),
      );
      final repository = SupabaseAuthRepository(supabaseService: gateway);

      final user = await repository.signUpWithEmailPassword(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(user.id, 'new-user');
      expect(user.email, 'new@example.com');
      expect(user.provider, AuthProviderType.emailPassword);
      expect(gateway.signUpCalls, 1);
    });

    test('email sign-up confirmation exception stays signed out', () async {
      final repository = SupabaseAuthRepository(
        supabaseService: _FakeSupabaseAuthGateway(
          signUpError: const SupabaseEmailConfirmationRequiredException(),
        ),
      );

      await expectLater(
        repository.signUpWithEmailPassword(
          email: 'new@example.com',
          password: 'password123',
        ),
        throwsA(isA<SupabaseEmailConfirmationRequiredException>()),
      );
    });

    test(
      'resend confirmation calls Supabase resend endpoint gateway',
      () async {
        final gateway = _FakeSupabaseAuthGateway();
        final repository = SupabaseAuthRepository(supabaseService: gateway);

        await repository.resendEmailConfirmation(email: 'new@example.com');

        expect(gateway.resendCalls, 1);
        expect(gateway.lastResendEmail, 'new@example.com');
        expect(gateway.signUpCalls, 0);
      },
    );

    test('password reset calls Supabase recovery gateway', () async {
      final gateway = _FakeSupabaseAuthGateway();
      final repository = SupabaseAuthRepository(supabaseService: gateway);

      await repository.sendPasswordResetEmail(email: 'reset@example.com');

      expect(gateway.passwordResetCalls, 1);
      expect(gateway.lastPasswordResetEmail, 'reset@example.com');
    });

    test('email sign-in failure surfaces auth exception', () async {
      final repository = SupabaseAuthRepository(
        supabaseService: _FakeSupabaseAuthGateway(
          signInError: const SupabaseAuthException('Invalid login credentials'),
        ),
      );

      await expectLater(
        repository.signInWithEmailPassword(
          email: 'harry@example.com',
          password: 'bad-password',
        ),
        throwsA(
          isA<SupabaseAuthException>().having(
            (error) => error.message,
            'message',
            'Invalid login credentials',
          ),
        ),
      );
    });

    test('email sign-in before confirmation uses confirmation message', () {
      final message = SupabaseService.authFailureMessageForTesting(
        DioException(
          requestOptions: RequestOptions(path: '/auth/v1/token'),
          response: Response<Map<String, dynamic>>(
            requestOptions: RequestOptions(path: '/auth/v1/token'),
            statusCode: 400,
            data: const {'message': 'Email not confirmed'},
          ),
        ),
      );

      expect(message, 'Please confirm your email before signing in.');
    });

    test('sign-out clears Supabase session', () async {
      final gateway = _FakeSupabaseAuthGateway(
        currentSessionValue: const SupabaseAuthSession(
          userId: 'user-email',
          email: 'harry@example.com',
          accessToken: 'access-token',
          displayName: 'Harry',
          isAnonymous: false,
          projectUrl: 'https://example.supabase.co',
        ),
      );
      final repository = SupabaseAuthRepository(supabaseService: gateway);

      await repository.signOut();

      expect(gateway.signOutCalls, 1);
      expect(gateway.lastSignOutToken, 'access-token');
    });

    test('currentUser maps persisted email session after restart', () async {
      final gateway = _FakeSupabaseAuthGateway(
        currentSessionValue: const SupabaseAuthSession(
          userId: 'persisted-user',
          email: 'collector@example.com',
          accessToken: 'persisted-token',
          displayName: 'collector@example.com',
          isAnonymous: false,
          projectUrl: 'https://example.supabase.co',
        ),
      );
      final repository = SupabaseAuthRepository(supabaseService: gateway);

      final user = await repository.currentUser();

      expect(user, isNotNull);
      expect(user!.id, 'persisted-user');
      expect(user.email, 'collector@example.com');
      expect(user.provider, AuthProviderType.emailPassword);
      expect(user.isCloudBacked, isTrue);
    });

    test('same device can switch signed-in Supabase users', () async {
      final repository = _ScriptedAuthRepository(
        initialUser: const AppUser(
          id: 'user-a',
          displayName: 'user-a@example.com',
          email: 'user-a@example.com',
          provider: AuthProviderType.emailPassword,
        ),
        emailUser: const AppUser(
          id: 'user-b',
          displayName: 'user-b@example.com',
          email: 'user-b@example.com',
          provider: AuthProviderType.emailPassword,
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(authControllerProvider).user!.id, 'user-a');

      await container.read(authControllerProvider.notifier).signOut();
      expect(container.read(authControllerProvider).isSignedIn, isFalse);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'user-b@example.com',
            password: 'password123',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isTrue);
      expect(state.user!.id, 'user-b');
      expect(state.user!.email, 'user-b@example.com');
      expect(repository.signOutCalls, 1);
    });

    test('auth session cache is scoped to the Supabase project URL', () async {
      SharedPreferences.setMockInitialValues({
        'supabase_auth_session': const SupabaseAuthSession(
          userId: 'old-user',
          email: null,
          accessToken: 'old-token',
          displayName: 'Old User',
          isAnonymous: true,
          projectUrl: 'https://old-project.supabase.co',
        ).toJsonString(),
      });
      final service = SupabaseService.instance(
        config: const SupabaseConfig(
          url: 'https://new-project.supabase.co',
          anonKey: 'anon-key',
          isEnabled: true,
        ),
      );

      final session = await service.currentSession();
      final preferences = await SharedPreferences.getInstance();

      expect(session, isNull);
      expect(preferences.getString('supabase_auth_session'), isNull);
    });

    test(
      'storage upload path uses selected user portfolio image convention',
      () {
        final path = CloudStoragePaths.portfolioImage(
          userId: '2DD0B46B-336B-463E-9F43-9D9F8D68A767',
          itemId: 'Scan 1780000000000',
        );

        expect(
          path,
          'users/2dd0b46b-336b-463e-9f43-9d9f8d68a767/'
          'portfolio_images/scan-1780000000000.jpg',
        );
      },
    );

    test(
      'portfolio_items row parser tolerates null pricing and profile fields',
      () {
        final item = itemFromSupabaseRow({
          'id': 'scan-1780000000000',
          'user_id': 'user-1',
          'title': 'Cloud Card',
          'category': 'Trading Card',
          'manufacturer': null,
          'series': null,
          'year': null,
          'country': null,
          'estimated_value_low': null,
          'estimated_value_high': null,
          'image_local_path': null,
          'image_storage_path': null,
          'cloud_image_url': null,
          'sync_status': 'synced',
          'last_synced_at': null,
          'raw_json': null,
          'created_at': null,
          'updated_at': null,
        });

        expect(item, isNotNull);
        final parsedItem = item!;
        expect(parsedItem.id, 'scan-1780000000000');
        expect(parsedItem.estimatedValue, 0);
        expect(parsedItem.pricing, isNull);
        expect(parsedItem.syncStatus, CloudItemSyncStatus.synced);
      },
    );

    test(
      'Supabase storage service is disabled when config is missing',
      () async {
        final service = SupabaseCloudStorageService(
          bootstrap: SupabaseBootstrap(
            config: const EnvironmentConfig(
              environment: AppEnvironment.dev,
              featureFlags: FeatureFlags(useCloudImageStorage: true),
            ),
            url: '',
            anonKey: '',
          ),
          authService: const NoOpAuthService(),
        );

        final reference = await service.uploadImage(
          localPath: 'test/fixtures/card.jpg',
          destinationPath: 'users/user-1/portfolio_images/item-1.jpg',
        );

        expect(reference, isNull);
      },
    );
  });

  group('AuthController', () {
    test('starts in local mode and keeps sign in optional', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(container.read(authControllerProvider).isSignedIn, isFalse);
      expect(container.read(authControllerProvider).isLocalMode, isTrue);
      expect(container.read(authControllerProvider).statusLabel, 'Local mode');
      expect(
        container.read(authControllerProvider).accountModeLabel,
        'Local Anonymous',
      );

      await container.read(authControllerProvider.notifier).signIn();

      final signedInState = container.read(authControllerProvider);
      expect(signedInState.isSignedIn, isFalse);
      expect(signedInState.isLocalMode, isTrue);
      expect(signedInState.user!.displayName, 'Local Collector');
      expect(signedInState.statusLabel, 'Local mode');

      await container.read(authControllerProvider.notifier).signOut();

      expect(container.read(authControllerProvider).isSignedIn, isFalse);
      expect(container.read(authControllerProvider).isLocalMode, isTrue);
      expect(container.read(authControllerProvider).statusLabel, 'Local mode');
    });

    test('email sign-in success updates auth state', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _ScriptedAuthRepository(
              emailUser: const AppUser(
                id: 'email-user',
                displayName: 'harry@example.com',
                email: 'harry@example.com',
                provider: AuthProviderType.emailPassword,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'harry@example.com',
            password: 'password123',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isTrue);
      expect(state.status, AuthFlowStatus.signedIn);
      expect(state.user!.email, 'harry@example.com');
      expect(state.accountModeLabel, 'Email / Password');
      expect(state.errorMessage, isNull);
      expect(state.infoMessage, AuthMessages.signedIn);
    });

    test('email sign-in exposes loading state and visible result', () async {
      final completer = Completer<AppUser>();
      final repository = _ScriptedAuthRepository(signInCompleter: completer);
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final signIn = container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'harry@example.com',
            password: 'password123',
          );
      await Future<void>.delayed(Duration.zero);

      var state = container.read(authControllerProvider);
      expect(state.isLoading, isTrue);
      expect(state.status, AuthFlowStatus.signingIn);
      expect(state.errorMessage, isNull);

      completer.complete(
        const AppUser(
          id: 'email-user',
          displayName: 'harry@example.com',
          email: 'harry@example.com',
          provider: AuthProviderType.emailPassword,
        ),
      );
      await signIn;

      state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.status, AuthFlowStatus.signedIn);
      expect(state.infoMessage, AuthMessages.signedIn);
      expect(state.errorMessage, isNull);
    });

    test('email sign-in timeout shows visible auth timeout result', () async {
      final repository = _ScriptedAuthRepository(
        signInError: TimeoutException(AuthMessages.authTimedOut),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'harry@example.com',
            password: 'password123',
          );

      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.isSignedIn, isFalse);
      expect(state.errorMessage, AuthMessages.authTimedOut);
    });

    test('email sign-in validation stops repository call', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(email: '', password: '');

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.signedOut);
      expect(state.errorMessage, 'Enter an email address.');
      expect(repository.signInCalls, 0);
    });

    test('email sign-in invalid email stops repository call', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(email: 'not-an-email', password: 'secret');

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.signedOut);
      expect(state.errorMessage, 'Please enter a valid email address.');
      expect(repository.signInCalls, 0);
    });

    test('email sign-up validation stops repository call', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(authControllerProvider.notifier)
          .signUpWithEmailPassword(
            email: 'collector@example.com',
            password: '12345',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.signedOut);
      expect(state.errorMessage, 'Password must be at least 6 characters.');
      expect(repository.signUpCalls, 0);
    });

    test('password reset sends email and shows success message', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(email: 'reset@example.com');

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.infoMessage, AuthMessages.passwordResetSentWithCooldown);
      expect(
        state.lastPasswordResetRedirectUrl,
        SupabaseService.passwordResetRedirectUri,
      );
      expect(state.lastPasswordResetStatus, 'sent');
      expect(state.passwordResetCooldownSource, 'success');
      expect(state.passwordResetCooldownUntil, isNotNull);
      expect(repository.passwordResetCalls, 1);
      expect(repository.lastPasswordResetEmail, 'reset@example.com');
    });

    test('password reset is blocked during success cooldown', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(email: 'reset@example.com');
      await container
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(email: 'reset@example.com');

      final state = container.read(authControllerProvider);
      expect(repository.passwordResetCalls, 1);
      expect(state.infoMessage, startsWith('Reset available in '));
      expect(state.lastPasswordResetStatus, 'blocked');
    });

    test(
      'password reset rate limit shows clear message and cooldown',
      () async {
        final repository = _ScriptedAuthRepository(
          passwordResetError: const SupabasePasswordResetRateLimitedException(
            cooldown: Duration(minutes: 5),
            cooldownSource: 'fallback',
          ),
        );
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        await container
            .read(authControllerProvider.notifier)
            .sendPasswordResetEmail(email: 'reset@example.com');

        final state = container.read(authControllerProvider);
        expect(state.infoMessage, isNull);
        expect(state.errorMessage, AuthMessages.passwordResetRateLimited);
        expect(state.lastPasswordResetStatus, 'rate-limited');
        expect(state.passwordResetCooldownSource, 'fallback');
        expect(state.passwordResetRateLimitedUntil, isNotNull);
        expect(repository.passwordResetCalls, 1);
      },
    );

    test('password reset validates email before repository call', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.notifier).loadCurrentUser();

      await container
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(email: 'not-an-email');

      final state = container.read(authControllerProvider);
      expect(state.errorMessage, 'Please enter a valid email address.');
      expect(repository.passwordResetCalls, 0);
    });

    test('password reset failure shows user-safe error', () async {
      final repository = _ScriptedAuthRepository(
        passwordResetError: const SupabaseAuthException(
          'Unable to reach Supabase. Check your internet connection.',
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .sendPasswordResetEmail(email: 'reset@example.com');

      final state = container.read(authControllerProvider);
      expect(state.infoMessage, isNull);
      expect(
        state.errorMessage,
        'Unable to reach Supabase. Check your internet connection.',
      );
      expect(repository.passwordResetCalls, 1);
    });

    test('anonymous cloud session is not treated as email signed in', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _ScriptedAuthRepository(
              initialUser: const AppUser(
                id: 'anonymous-user',
                displayName: 'Anonymous Collector',
                email: null,
                isAnonymous: true,
                provider: AuthProviderType.supabaseAnonymous,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.isAnonymousCloudSession, isTrue);
      expect(state.statusLabel, 'Anonymous dev session');
    });

    test('email sign-up success updates auth state', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _ScriptedAuthRepository(
              signUpUser: const AppUser(
                id: 'new-email-user',
                displayName: 'new@example.com',
                email: 'new@example.com',
                provider: AuthProviderType.emailPassword,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signUpWithEmailPassword(
            email: 'new@example.com',
            password: 'password123',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isTrue);
      expect(state.status, AuthFlowStatus.signedIn);
      expect(state.user!.email, 'new@example.com');
      expect(state.accountModeLabel, 'Email / Password');
      expect(state.infoMessage, AuthMessages.signedIn);
    });

    test(
      'email sign-up confirmation keeps signed-out state with message',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _ScriptedAuthRepository(
                signUpError: const SupabaseEmailConfirmationRequiredException(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(authControllerProvider.notifier)
            .signUpWithEmailPassword(
              email: 'new@example.com',
              password: 'password123',
            );

        final state = container.read(authControllerProvider);
        expect(state.isSignedIn, isFalse);
        expect(state.status, AuthFlowStatus.confirmationRequired);
        expect(state.isLocalMode, isTrue);
        expect(state.errorMessage, isNull);
        expect(
          state.infoMessage,
          SupabaseEmailConfirmationRequiredException.message,
        );
      },
    );

    test(
      'empty successful sign-up keeps signed-out state with sent message',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _ScriptedAuthRepository(
                signUpError: const SupabaseEmailConfirmationSentException(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(authControllerProvider.notifier)
            .signUpWithEmailPassword(
              email: 'new@example.com',
              password: 'password123',
            );

        final state = container.read(authControllerProvider);
        expect(state.isSignedIn, isFalse);
        expect(state.status, AuthFlowStatus.confirmationRequired);
        expect(state.errorMessage, isNull);
        expect(state.infoMessage, AuthMessages.confirmationEmailSentSignIn);
        expect(state.pendingConfirmationEmail, 'new@example.com');
      },
    );

    test('email sign-up network failure remains an auth error', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _ScriptedAuthRepository(
              signUpError: const SupabaseAuthException(
                'Unable to reach Supabase. Check your internet connection.',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signUpWithEmailPassword(
            email: 'new@example.com',
            password: 'password123',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.networkError);
      expect(state.infoMessage, isNull);
      expect(
        state.errorMessage,
        'Unable to reach Supabase. Check your internet connection.',
      );
    });

    test('resend confirmation keeps signed out with sent message', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
      final start = DateTime(2026, 7, 2, 10);

      await container
          .read(authControllerProvider.notifier)
          .resendConfirmationEmail(email: 'new@example.com', now: start);

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.confirmationRequired);
      expect(state.pendingConfirmationEmail, 'new@example.com');
      expect(state.infoMessage, AuthMessages.confirmationEmailSent);
      expect(state.resendCooldownUntil, start.add(const Duration(seconds: 60)));
      expect(state.lastResendStatus, 'sent');
      expect(state.resendCooldownSource, 'success');
      expect(repository.resendCalls, 1);
      expect(repository.lastResendEmail, 'new@example.com');
      expect(repository.signUpCalls, 0);
    });

    test('resend confirmation is blocked during success cooldown', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
      final start = DateTime(2026, 7, 2, 10);

      await container
          .read(authControllerProvider.notifier)
          .resendConfirmationEmail(email: 'new@example.com', now: start);
      await container
          .read(authControllerProvider.notifier)
          .resendConfirmationEmail(
            email: 'new@example.com',
            now: start.add(const Duration(seconds: 1)),
          );

      final state = container.read(authControllerProvider);
      expect(repository.resendCalls, 1);
      expect(state.status, AuthFlowStatus.confirmationRequired);
      expect(state.infoMessage, 'Resend available in 59s');
    });

    test('sign-in unconfirmed email stores pending resend email', () async {
      final repository = _ScriptedAuthRepository(
        signInError: const SupabaseAuthException(
          'Please confirm your email before signing in.',
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'new@example.com',
            password: 'password123',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.confirmationRequired);
      expect(state.pendingConfirmationEmail, 'new@example.com');
      expect(
        state.errorMessage,
        'Please confirm your email before signing in.',
      );
    });

    test('rate-limit resend with Retry-After uses header value', () async {
      final repository = _ScriptedAuthRepository(
        resendError: const SupabaseConfirmationRateLimitedException(
          cooldown: Duration(seconds: 123),
          cooldownSource: 'retry-after',
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final start = DateTime(2026, 7, 2, 10);

      await container
          .read(authControllerProvider.notifier)
          .resendConfirmationEmail(email: 'new@example.com', now: start);

      final state = container.read(authControllerProvider);
      expect(state.status, AuthFlowStatus.confirmationRequired);
      expect(state.errorMessage, AuthMessages.confirmationRateLimited);
      expect(state.infoMessage, isNull);
      expect(
        state.resendRateLimitedUntil,
        start.add(const Duration(seconds: 123)),
      );
      expect(state.lastResendStatus, 'rate-limited');
      expect(state.resendCooldownSource, 'retry-after');
      expect(repository.resendCalls, 1);
    });

    test(
      'rate-limit resend without Retry-After uses fallback five minutes',
      () async {
        final repository = _ScriptedAuthRepository(
          resendError: const SupabaseConfirmationRateLimitedException(
            cooldown: Duration(minutes: 5),
            cooldownSource: 'fallback',
          ),
        );
        final container = ProviderContainer(
          overrides: [authRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);
        container.read(authControllerProvider);
        await Future<void>.delayed(Duration.zero);
        final start = DateTime(2026, 7, 2, 10);

        await container
            .read(authControllerProvider.notifier)
            .resendConfirmationEmail(email: 'new@example.com', now: start);
        await container
            .read(authControllerProvider.notifier)
            .resendConfirmationEmail(
              email: 'new@example.com',
              now: start.add(const Duration(seconds: 10)),
            );

        final state = container.read(authControllerProvider);
        expect(repository.resendCalls, 1);
        expect(state.status, AuthFlowStatus.confirmationRequired);
        expect(state.infoMessage, 'Resend available in 290s');
        expect(state.errorMessage, isNull);
        expect(state.lastResendStatus, 'rate-limited');
        expect(state.resendCooldownSource, 'fallback');
        expect(
          state.resendRateLimitedUntil,
          start.add(const Duration(minutes: 5)),
        );
      },
    );

    test('failed resend does not show email sent message', () async {
      final repository = _ScriptedAuthRepository(
        resendError: const SupabaseAuthException('Supabase Auth failed.'),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .resendConfirmationEmail(email: 'new@example.com');

      final state = container.read(authControllerProvider);
      expect(state.infoMessage, isNull);
      expect(state.errorMessage, 'Supabase Auth failed.');
      expect(state.lastResendStatus, 'failed');
      expect(state.resendCooldownSource, 'none');
      expect(state.resendCooldownUntil, isNull);
      expect(state.resendRateLimitedUntil, isNull);
    });

    test('resend confirmation requires email address', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);

      await container
          .read(authControllerProvider.notifier)
          .resendConfirmationEmail(email: '');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthFlowStatus.confirmationRequired);
      expect(state.errorMessage, 'Enter an email address.');
      expect(repository.resendCalls, 0);
    });

    test('resend confirmation max attempts blocks fourth resend', () async {
      final repository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final start = DateTime(2026, 7, 2, 10);
      final notifier = container.read(authControllerProvider.notifier);

      await notifier.resendConfirmationEmail(
        email: 'new@example.com',
        now: start,
      );
      await notifier.resendConfirmationEmail(
        email: 'new@example.com',
        now: start.add(const Duration(seconds: 61)),
      );
      await notifier.resendConfirmationEmail(
        email: 'new@example.com',
        now: start.add(const Duration(seconds: 122)),
      );
      await notifier.resendConfirmationEmail(
        email: 'new@example.com',
        now: start.add(const Duration(seconds: 183)),
      );

      final state = container.read(authControllerProvider);
      expect(repository.resendCalls, 3);
      expect(state.status, AuthFlowStatus.confirmationRequired);
      expect(state.errorMessage, AuthMessages.confirmationMaxAttempts);
    });

    test('deep link parser handles callback with access and refresh token', () {
      final result = AuthCallbackParser.parse(
        'collectiq-sit://auth/callback#access_token=access-secret&refresh_token=refresh-secret&type=signup',
        environment: AppEnvironment.sit,
      );

      expect(result.status, AuthCallbackStatus.signedIn);
      expect(result.accessToken, 'access-secret');
      expect(result.refreshToken, 'refresh-secret');
      expect(result.type, 'signup');
    });

    test('deep link parser handles confirmation without session', () {
      final result = AuthCallbackParser.parse(
        'collectiq-sit://auth/callback?type=signup&token_hash=hash-value',
        environment: AppEnvironment.sit,
      );

      expect(result.status, AuthCallbackStatus.confirmedNoSession);
      expect(result.tokenHash, 'hash-value');
    });

    test('deep link parser ignores password recovery callbacks', () {
      final withTokens = AuthCallbackParser.parse(
        'collectiq-sit://auth/callback#access_token=access-secret&refresh_token=refresh-secret&type=recovery',
        environment: AppEnvironment.sit,
      );
      final withTokenHash = AuthCallbackParser.parse(
        'collectiq-sit://auth/callback?type=recovery&token_hash=hash-value',
        environment: AppEnvironment.sit,
      );

      expect(withTokens.status, AuthCallbackStatus.ignored);
      expect(withTokenHash.status, AuthCallbackStatus.ignored);
    });

    test('https Packlox reset password links are ignored by mobile parser', () {
      final result = AuthCallbackParser.parse(
        'https://packlox.com/auth/reset-password#access_token=access-secret&refresh_token=refresh-secret&type=recovery',
        environment: AppEnvironment.sit,
      );

      expect(result.status, AuthCallbackStatus.ignored);
    });

    test('deep link parser maps expired callback error', () {
      final result = AuthCallbackParser.parse(
        'collectiq-sit://auth/callback?error=access_denied&error_description=Email%20link%20is%20invalid%20or%20expired',
        environment: AppEnvironment.sit,
      );

      expect(result.status, AuthCallbackStatus.invalidOrExpired);
      expect(result.error, 'access_denied');
    });

    test('deep link parser reports malformed SIT callback safely', () {
      final result = AuthCallbackParser.parse(
        'collectiq-sit://auth/not-callback?access_token=access-secret',
        environment: AppEnvironment.sit,
      );

      expect(result.status, AuthCallbackStatus.error);
    });

    test('local mode ignores SIT auth callback safely', () {
      final result = AuthCallbackParser.parse(
        'collectiq-sit://auth/callback#access_token=access-secret&refresh_token=refresh-secret&type=signup',
        environment: AppEnvironment.local,
      );

      expect(result.status, AuthCallbackStatus.ignored);
    });

    test('auth callback with session signs in without logging tokens', () async {
      final gateway = _FakeSupabaseAuthGateway();
      final platform = _FakeAuthDeepLinkPlatform(
        initialLink:
            'collectiq-sit://auth/callback#access_token=access-secret&refresh_token=refresh-secret&type=signup',
      );
      final logs = <String>[];
      final previousDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) {
          logs.add(message);
        }
      };
      addTearDown(() => debugPrint = previousDebugPrint);
      final container = ProviderContainer(
        overrides: [
          environmentConfigProvider.overrideWithValue(
            const EnvironmentConfig(environment: AppEnvironment.sit),
          ),
          authRepositoryProvider.overrideWithValue(_ScriptedAuthRepository()),
          authCallbackGatewayProvider.overrideWithValue(gateway),
          authDeepLinkPlatformProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await container.read(authDeepLinkCoordinatorProvider).start();

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isTrue);
      expect(state.user?.email, 'callback@example.com');
      expect(state.infoMessage, AuthMessages.emailConfirmed);
      expect(gateway.callbackCalls, 1);
      expect(gateway.lastCallbackAccessToken, 'access-secret');
      expect(logs.join('\n'), isNot(contains('access-secret')));
      expect(logs.join('\n'), isNot(contains('refresh-secret')));
    });

    test('auth callback without session asks user to sign in', () async {
      final platform = _FakeAuthDeepLinkPlatform(
        initialLink:
            'collectiq-sit://auth/callback?type=signup&token_hash=hash-value',
      );
      final container = ProviderContainer(
        overrides: [
          environmentConfigProvider.overrideWithValue(
            const EnvironmentConfig(environment: AppEnvironment.sit),
          ),
          authRepositoryProvider.overrideWithValue(_ScriptedAuthRepository()),
          authDeepLinkPlatformProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await container.read(authDeepLinkCoordinatorProvider).start();

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.infoMessage, AuthMessages.emailConfirmedSignIn);
    });

    test(
      'auth callback diagnostics store keys only without token values',
      () async {
        final platform = _FakeAuthDeepLinkPlatform(
          initialLink:
              'collectiq-sit://auth/not-callback?access_token=access-secret&refresh_token=refresh-secret',
        );
        final container = ProviderContainer(
          overrides: [
            environmentConfigProvider.overrideWithValue(
              const EnvironmentConfig(environment: AppEnvironment.sit),
            ),
            authRepositoryProvider.overrideWithValue(_ScriptedAuthRepository()),
            authDeepLinkPlatformProvider.overrideWithValue(platform),
          ],
        );
        addTearDown(container.dispose);

        container.read(authControllerProvider);
        await Future<void>.delayed(Duration.zero);
        await container.read(authDeepLinkCoordinatorProvider).start();

        final state = container.read(authControllerProvider);
        final metadata = container.read(authDeepLinkMetadataProvider);
        expect(state.errorMessage, AuthMessages.confirmationCallbackFailed);
        expect(metadata, isNotNull);
        expect(metadata!.received, isTrue);
        expect(metadata.result, AuthCallbackStatus.error);
        expect(metadata.scheme, 'collectiq-sit');
        expect(metadata.host, 'auth');
        expect(metadata.path, '/not-callback');
        expect(
          metadata.queryKeys,
          containsAll(['access_token', 'refresh_token']),
        );
        expect(metadata.queryKeysLabel, isNot(contains('access-secret')));
        expect(metadata.queryKeysLabel, isNot(contains('refresh-secret')));
      },
    );

    test('auth callback expired link shows invalid message', () async {
      final platform = _FakeAuthDeepLinkPlatform(
        initialLink:
            'collectiq-sit://auth/callback?error=access_denied&error_description=invalid%20or%20expired',
      );
      final container = ProviderContainer(
        overrides: [
          environmentConfigProvider.overrideWithValue(
            const EnvironmentConfig(environment: AppEnvironment.sit),
          ),
          authRepositoryProvider.overrideWithValue(_ScriptedAuthRepository()),
          authDeepLinkPlatformProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(container.dispose);

      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await container.read(authDeepLinkCoordinatorProvider).start();

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.errorMessage, AuthMessages.confirmationLinkInvalid);
    });

    test('repeated sign-up before confirmation shows resent message', () async {
      final repository = _ScriptedAuthRepository(
        signUpError: const SupabaseEmailConfirmationRequiredException(),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signUpWithEmailPassword(
            email: 'new@example.com',
            password: 'password123',
          );
      await container
          .read(authControllerProvider.notifier)
          .signUpWithEmailPassword(
            email: 'new@example.com',
            password: 'password123',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.confirmationRequired);
      expect(state.infoMessage, AuthMessages.confirmationResent);
      expect(repository.signUpCalls, 2);
    });

    test('missing Supabase config shows configuration message', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _ScriptedAuthRepository(
              signInError: const SupabaseNotConfiguredException(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'harry@example.com',
            password: 'password123',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.configurationError);
      expect(
        state.errorMessage,
        'Supabase configuration is missing or invalid.',
      );
    });

    test('email sign-in before confirmation stays signed out', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _ScriptedAuthRepository(
              signInError: const SupabaseAuthException(
                'Please confirm your email before signing in.',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'harry@example.com',
            password: 'password123',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.confirmationRequired);
      expect(
        state.errorMessage,
        'Please confirm your email before signing in.',
      );
    });

    test('email sign-in failure leaves local mode with error', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _ScriptedAuthRepository(
              signInError: const AuthException('Invalid email or password.'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'harry@example.com',
            password: 'bad-password',
          );

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.signedOut);
      expect(state.errorMessage, 'Invalid email or password.');
    });

    test('sign-out returns Settings state to local mode', () async {
      final repository = _ScriptedAuthRepository(
        emailUser: const AppUser(
          id: 'email-user',
          displayName: 'harry@example.com',
          email: 'harry@example.com',
          provider: AuthProviderType.emailPassword,
        ),
      );
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container
          .read(authControllerProvider.notifier)
          .signInWithEmailPassword(
            email: 'harry@example.com',
            password: 'password123',
          );
      await container.read(authControllerProvider.notifier).signOut();

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.signedOut);
      expect(state.isLocalMode, isTrue);
      expect(repository.signOutCalls, 1);
    });

    test('expired restored session is cleared and reported', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _ScriptedAuthRepository(
              currentUserError: const SupabaseSessionExpiredException(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(authControllerProvider);
      expect(state.isSignedIn, isFalse);
      expect(state.status, AuthFlowStatus.sessionExpired);
      expect(state.errorMessage, SupabaseSessionExpiredException.message);
    });
  });

  group('Subscription foundation', () {
    test('default plan is free and development safe', () {
      const config = UsageLimitConfig();
      final usage = UsageTracker.fromLimit(
        limit: config.usageLimit,
        scansUsedToday: 999,
      );

      expect(UserEntitlements.developmentFree.plan, SubscriptionPlan.free);
      expect(config.developmentUnlimited, isTrue);
      expect(usage.canAnalyze, isTrue);
      expect(usage.isUnlimited, isTrue);
      expect(usage.remainingScans, config.dailyFreeScanLimit);
    });

    test('usage controller increments successful analyses', () async {
      final repository = _MemoryUsageRepository();
      final container = ProviderContainer(
        overrides: [
          usageRepositoryProvider.overrideWithValue(repository),
          usageLimitConfigProvider.overrideWithValue(
            const UsageLimitConfig(
              developmentUnlimited: false,
              dailyFreeScanLimit: 2,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(subscriptionControllerProvider.notifier).loadUsage();
      await container
          .read(subscriptionControllerProvider.notifier)
          .ensureCanAnalyze();
      await container
          .read(subscriptionControllerProvider.notifier)
          .recordSuccessfulAnalysis();

      final state = container.read(subscriptionControllerProvider);
      expect(repository.count, 1);
      expect(state.usage.scansUsedToday, 1);
      expect(state.usage.remainingScans, 1);
    });

    test('usage controller blocks when limit is reached', () async {
      final repository = _MemoryUsageRepository(initialCount: 1);
      final container = ProviderContainer(
        overrides: [
          usageRepositoryProvider.overrideWithValue(repository),
          usageLimitConfigProvider.overrideWithValue(
            const UsageLimitConfig(
              developmentUnlimited: false,
              dailyFreeScanLimit: 1,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container
            .read(subscriptionControllerProvider.notifier)
            .ensureCanAnalyze(),
        throwsA(isA<SubscriptionException>()),
      );
      expect(repository.count, 1);
    });

    test('billing unavailable keeps payments unconfigured', () async {
      final container = ProviderContainer(
        overrides: [
          usageRepositoryProvider.overrideWithValue(_MemoryUsageRepository()),
          entitlementRepositoryProvider.overrideWithValue(
            _MemoryEntitlementRepository(),
          ),
          billingRepositoryProvider.overrideWithValue(
            _FakeBillingRepository(available: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(subscriptionControllerProvider.notifier).loadUsage();

      final state = container.read(subscriptionControllerProvider);
      expect(state.isBillingAvailable, isFalse);
      expect(state.paymentStatusLabel, 'Not configured');
      expect(state.entitlements.plan, SubscriptionPlan.free);
    });

    test('product load success exposes billing products', () async {
      final container = ProviderContainer(
        overrides: [
          googlePlayBillingConfigProvider.overrideWithValue(
            const GooglePlayBillingConfig(enabled: true),
          ),
          usageRepositoryProvider.overrideWithValue(_MemoryUsageRepository()),
          entitlementRepositoryProvider.overrideWithValue(
            _MemoryEntitlementRepository(),
          ),
          billingRepositoryProvider.overrideWithValue(
            _FakeBillingRepository(
              products: const [
                BillingProduct(
                  id: 'collectiq_pro_monthly_test',
                  plan: SubscriptionPlan.pro,
                  title: 'CollectIQ Pro',
                  description: 'Higher scan limits',
                  price: r'$4.99',
                ),
              ],
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(subscriptionControllerProvider.notifier).loadUsage();

      final state = container.read(subscriptionControllerProvider);
      expect(state.isBillingAvailable, isTrue);
      expect(state.products.single.plan, SubscriptionPlan.pro);
      expect(state.paymentStatusLabel, 'Configured');
    });

    test('product load failure reports friendly error', () async {
      final container = ProviderContainer(
        overrides: [
          googlePlayBillingConfigProvider.overrideWithValue(
            const GooglePlayBillingConfig(enabled: true),
          ),
          usageRepositoryProvider.overrideWithValue(_MemoryUsageRepository()),
          entitlementRepositoryProvider.overrideWithValue(
            _MemoryEntitlementRepository(),
          ),
          billingRepositoryProvider.overrideWithValue(
            _FakeBillingRepository(
              loadError: const BillingException('Products unavailable.'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(subscriptionControllerProvider.notifier).loadUsage();

      final state = container.read(subscriptionControllerProvider);
      expect(state.errorMessage, 'Products unavailable.');
      expect(state.entitlements.plan, SubscriptionPlan.free);
    });

    test('purchase success updates entitlement', () async {
      final entitlements = _MemoryEntitlementRepository();
      final container = ProviderContainer(
        overrides: [
          googlePlayBillingConfigProvider.overrideWithValue(
            const GooglePlayBillingConfig(enabled: true),
          ),
          usageRepositoryProvider.overrideWithValue(_MemoryUsageRepository()),
          entitlementRepositoryProvider.overrideWithValue(entitlements),
          billingRepositoryProvider.overrideWithValue(
            _FakeBillingRepository(
              purchaseResult: const PurchaseResult(
                status: PurchaseResultStatus.success,
                plan: SubscriptionPlan.pro,
                message: 'Pro is active.',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(subscriptionControllerProvider.notifier)
          .purchasePlan(SubscriptionPlan.pro);

      final state = container.read(subscriptionControllerProvider);
      expect(state.entitlements.plan, SubscriptionPlan.pro);
      expect(state.purchaseMessage, 'Pro is active.');
      expect(await entitlements.loadPlan(), SubscriptionPlan.pro);
    });

    test('restore purchase updates entitlement', () async {
      final container = ProviderContainer(
        overrides: [
          googlePlayBillingConfigProvider.overrideWithValue(
            const GooglePlayBillingConfig(enabled: true),
          ),
          usageRepositoryProvider.overrideWithValue(_MemoryUsageRepository()),
          entitlementRepositoryProvider.overrideWithValue(
            _MemoryEntitlementRepository(),
          ),
          billingRepositoryProvider.overrideWithValue(
            _FakeBillingRepository(
              restoreResult: const PurchaseResult(
                status: PurchaseResultStatus.restored,
                plan: SubscriptionPlan.premium,
                message: 'Premium restored.',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(subscriptionControllerProvider.notifier)
          .restorePurchases();

      final state = container.read(subscriptionControllerProvider);
      expect(state.entitlements.plan, SubscriptionPlan.premium);
      expect(state.usage.isUnlimited, isTrue);
      expect(state.purchaseMessage, 'Premium restored.');
    });

    test('cancelled purchase does not upgrade entitlement', () async {
      final container = ProviderContainer(
        overrides: [
          googlePlayBillingConfigProvider.overrideWithValue(
            const GooglePlayBillingConfig(enabled: true),
          ),
          usageRepositoryProvider.overrideWithValue(_MemoryUsageRepository()),
          entitlementRepositoryProvider.overrideWithValue(
            _MemoryEntitlementRepository(),
          ),
          billingRepositoryProvider.overrideWithValue(
            _FakeBillingRepository(
              purchaseResult: const PurchaseResult(
                status: PurchaseResultStatus.cancelled,
                message: 'Purchase was cancelled.',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(subscriptionControllerProvider.notifier)
          .purchasePlan(SubscriptionPlan.pro);

      final state = container.read(subscriptionControllerProvider);
      expect(state.entitlements.plan, SubscriptionPlan.free);
      expect(state.purchaseMessage, 'Purchase was cancelled.');
    });
  });

  group('RegistrySyncService', () {
    test('reports local-only sync status by default', () async {
      final service = RegistrySyncService(
        registry: CloudServiceRegistry.local(
          config: const EnvironmentConfig(environment: AppEnvironment.local),
        ),
      );

      final status = await service.currentStatus();

      expect(status.state, SyncState.localOnly);
      expect(status.statusLabel, 'Local only');
      expect(status.isCloudBackupEnabled, isFalse);
    });

    test(
      'syncLocalItems keeps items pending while cloud backup is disabled',
      () async {
        final service = RegistrySyncService(
          registry: CloudServiceRegistry.local(
            config: const EnvironmentConfig(environment: AppEnvironment.local),
          ),
        );

        final status = await service.syncLocalItems([_testItem()]);

        expect(status.state, SyncState.localOnly);
        expect(status.pendingItemCount, 1);
        expect(status.isCloudBackupEnabled, isFalse);
      },
    );
  });

  group('SyncController', () {
    test('keeps cloud backup local-only for placeholder uploads', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(syncControllerProvider).status.state,
        SyncState.localOnly,
      );

      await container.read(syncControllerProvider.notifier).uploadLocalItems([
        _testItem(),
      ]);

      final syncState = container.read(syncControllerProvider);
      expect(syncState.status.state, SyncState.localOnly);
      expect(syncState.status.pendingItemCount, 1);
      expect(syncState.status.isCloudBackupEnabled, isFalse);
    });

    test('cloud connected requires authenticated user id', () {
      const status = SyncStatus(
        state: SyncState.synced,
        message: 'Cloud configured.',
        isCloudBackupEnabled: true,
      );

      expect(status.isCloudConnected, isFalse);
      expect(status.statusLabel, 'Auth required');
    });

    test('configured Supabase without user shows auth required', () async {
      final container = ProviderContainer(
        overrides: [
          syncServiceProvider.overrideWithValue(
            const _StaticSyncService(
              status: SyncStatus(
                state: SyncState.synced,
                message: 'Cloud configured, auth required.',
                isCloudBackupEnabled: true,
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(syncControllerProvider.notifier).loadStatus();
      final syncState = container.read(syncControllerProvider);

      expect(syncState.status.isCloudBackupEnabled, isTrue);
      expect(syncState.status.isCloudConnected, isFalse);
      expect(syncState.status.statusLabel, 'Auth required');
    });

    test('anonymous sign-in success changes status to connected', () async {
      final container = ProviderContainer(
        overrides: [
          syncServiceProvider.overrideWithValue(
            const _StaticSyncService(
              status: SyncStatus(
                state: SyncState.synced,
                message: 'Cloud connected as anonymous user user-123.',
                isCloudBackupEnabled: true,
                authenticatedUserId: 'user-123',
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(syncControllerProvider.notifier).loadStatus();
      final syncState = container.read(syncControllerProvider);

      expect(syncState.status.isCloudBackupEnabled, isTrue);
      expect(syncState.status.isCloudConnected, isTrue);
      expect(syncState.status.statusLabel, 'Synced');
    });

    test(
      'manual upload errors are caught and reported as sync state',
      () async {
        final container = ProviderContainer(
          overrides: [
            syncServiceProvider.overrideWithValue(const _FailingSyncService()),
          ],
        );
        addTearDown(container.dispose);

        await container.read(syncControllerProvider.notifier).uploadLocalItems([
          _testItem(),
        ]);

        final syncState = container.read(syncControllerProvider);
        expect(syncState.status.state, SyncState.failed);
        expect(syncState.status.pendingItemCount, 1);
        expect(syncState.status.retryableItemCount, 1);
        expect(syncState.status.statusLabel, 'Retryable');
        expect(syncState.errorMessage, contains('network unavailable'));
      },
    );
  });

  group('Supabase authenticated cloud sync', () {
    test('signed-out configured sync stays local-only', () async {
      final service = RegistrySyncService(
        registry: _cloudRegistry(
          syncService: SupabaseCloudPortfolioSyncService(
            bootstrap: _configuredSupabaseBootstrap(),
            authService: const _SignedOutCloudAuthService(),
            supabaseDataGateway: _FakeSupabaseDataGateway(session: null),
          ),
        ),
      );

      final status = await service.currentStatus();

      expect(status.state, SyncState.localOnly);
      expect(status.isCloudBackupEnabled, isFalse);
      expect(status.message, contains('Sign in'));
    });

    test('signed-in sync uses authenticated user id', () async {
      final gateway = _FakeSupabaseDataGateway(
        session: const SupabaseAuthSession(
          userId: 'email-user-123',
          email: 'collector@example.com',
          accessToken: 'email-token',
          displayName: 'Collector',
          isAnonymous: false,
          projectUrl: 'https://example.supabase.co',
        ),
      );
      final service = RegistrySyncService(
        registry: _cloudRegistry(
          syncService: SupabaseCloudPortfolioSyncService(
            bootstrap: _configuredSupabaseBootstrap(),
            authService: const _SignedInCloudAuthService(
              userId: 'email-user-123',
              email: 'collector@example.com',
            ),
            supabaseDataGateway: gateway,
          ),
        ),
      );

      final status = await service.syncLocalItems([_testItem()]);

      expect(status.state, SyncState.synced);
      expect(status.authenticatedUserId, 'email-user-123');
      expect(gateway.lastPostPath, '/rest/v1/portfolio_items');
      expect(gateway.lastPostedRows.single['user_id'], 'email-user-123');
    });

    test(
      'anonymous Supabase session is not treated as production sync',
      () async {
        final service = RegistrySyncService(
          registry: _cloudRegistry(
            syncService: SupabaseCloudPortfolioSyncService(
              bootstrap: _configuredSupabaseBootstrap(),
              authService: const _SignedInCloudAuthService(
                userId: 'anonymous-user',
                isAnonymous: true,
              ),
              supabaseDataGateway: _FakeSupabaseDataGateway(
                session: const SupabaseAuthSession(
                  userId: 'anonymous-user',
                  email: null,
                  accessToken: 'anonymous-token',
                  displayName: 'Guest',
                  isAnonymous: true,
                  projectUrl: 'https://example.supabase.co',
                ),
              ),
            ),
          ),
        );

        final status = await service.currentStatus();

        expect(status.state, SyncState.localOnly);
        expect(status.isCloudConnected, isFalse);
      },
    );

    test('sync failure becomes retryable and local items remain', () async {
      SharedPreferences.setMockInitialValues({});
      const portfolioRepository = SharedPreferencesPortfolioRepository();
      await portfolioRepository.addItem(_testItem());
      final service = RegistrySyncService(
        registry: _cloudRegistry(
          syncService: SupabaseCloudPortfolioSyncService(
            bootstrap: _configuredSupabaseBootstrap(),
            authService: const _SignedInCloudAuthService(
              userId: 'email-user-123',
              email: 'collector@example.com',
            ),
            supabaseDataGateway: _FakeSupabaseDataGateway(
              session: const SupabaseAuthSession(
                userId: 'email-user-123',
                email: 'collector@example.com',
                accessToken: 'email-token',
                displayName: 'Collector',
                isAnonymous: false,
                projectUrl: 'https://example.supabase.co',
              ),
              postError: DioException(
                requestOptions: RequestOptions(
                  path: '/rest/v1/portfolio_items',
                ),
                type: DioExceptionType.connectionError,
              ),
            ),
          ),
        ),
      );

      final status = await service.syncLocalItems(
        await portfolioRepository.getItems(),
      );
      final localItems = await portfolioRepository.getItems();

      expect(status.state, SyncState.failed);
      expect(status.retryableItemCount, 1);
      expect(localItems.single.id, _testItem().id);
    });

    test('sign-out does not delete local portfolio', () async {
      SharedPreferences.setMockInitialValues({});
      const portfolioRepository = SharedPreferencesPortfolioRepository();
      final authRepository = _ScriptedAuthRepository();
      final container = ProviderContainer(
        overrides: [authRepositoryProvider.overrideWithValue(authRepository)],
      );
      addTearDown(container.dispose);

      await portfolioRepository.addItem(_testItem());
      await container.read(authControllerProvider.notifier).signOut();
      final items = await portfolioRepository.getItems();

      expect(items, hasLength(1));
      expect(items.single.title, contains('Charizard'));
    });
  });

  group('SyncService', () {
    test('can mark local items as pending without cloud backup', () async {
      final service = RegistrySyncService(
        registry: CloudServiceRegistry.local(
          config: const EnvironmentConfig(environment: AppEnvironment.local),
        ),
      );

      final status = await service.markPending([_testItem()]);

      expect(status.state, SyncState.pending);
      expect(status.pendingItemCount, 1);
      expect(status.isCloudBackupEnabled, isFalse);
    });
  });

  group('SyncConflict', () {
    test('resolves using newest update wins', () {
      final localItem = _testItem();
      final cloudItem = CollectibleItem(
        id: localItem.id,
        title: 'Cloud Charizard',
        category: localItem.category,
        estimatedValue: localItem.estimatedValue,
        confidence: localItem.confidence,
        condition: localItem.condition,
        recommendation: localItem.recommendation,
        imagePath: localItem.imagePath,
        createdAt: localItem.createdAt.add(const Duration(days: 1)),
      );

      final resolved = SyncConflict(
        localItem: localItem,
        cloudItem: cloudItem,
      ).resolve();

      expect(resolved.title, 'Cloud Charizard');
    });
  });

  group('ImageSyncQueue', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists pending image upload tasks', () async {
      const repository = SharedPreferencesSyncQueueRepository();

      final task = await repository.enqueueImageUpload(
        collectibleId: 'item-1',
        localPath: 'test/fixtures/persistent-camera-card.jpg',
      );
      final snapshot = await repository.snapshot();

      expect(task.status, ImageUploadTaskStatus.pending);
      expect(snapshot.pendingCount, 1);
      expect(snapshot.tasks.single.collectibleId, 'item-1');
    });

    test('worker uploads image and stores cloud metadata locally', () async {
      const portfolioRepository = SharedPreferencesPortfolioRepository();
      const queueRepository = SharedPreferencesSyncQueueRepository();
      await portfolioRepository.addItem(
        CollectibleItem(
          id: 'item-1',
          title: 'Camera Card',
          category: 'Trading Card',
          estimatedValue: 50,
          confidence: 0.8,
          condition: 'Good',
          recommendation: 'Keep protected.',
          imagePath: 'test/fixtures/persistent-camera-card.jpg',
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
      );
      await queueRepository.enqueueImageUpload(
        collectibleId: 'item-1',
        localPath: 'test/fixtures/persistent-camera-card.jpg',
      );
      final worker = UploadWorker(
        queueRepository: queueRepository,
        portfolioRepository: portfolioRepository,
        registry: _cloudRegistry(
          storageService: const _SuccessfulCloudStorageService(),
        ),
      );

      await worker.processQueue();

      final snapshot = await queueRepository.snapshot();
      final items = await portfolioRepository.getItems();
      expect(snapshot.uploadedCount, 1);
      expect(snapshot.lastSyncAt, isNotNull);
      expect(
        items.single.imagePath,
        'test/fixtures/persistent-camera-card.jpg',
      );
      expect(items.single.imageStoragePath, 'remote/item-1.jpg');
      expect(items.single.cloudImageUrl, 'https://cdn.example.com/item-1.jpg');
    });

    test('failed image sync is queued as retryable with backoff', () async {
      const portfolioRepository = SharedPreferencesPortfolioRepository();
      const queueRepository = SharedPreferencesSyncQueueRepository();
      await portfolioRepository.addItem(
        CollectibleItem(
          id: 'item-1',
          title: 'Camera Card',
          category: 'Trading Card',
          estimatedValue: 50,
          confidence: 0.8,
          condition: 'Good',
          recommendation: 'Keep protected.',
          imagePath: 'test/fixtures/persistent-camera-card.jpg',
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
      );
      await queueRepository.enqueueImageUpload(
        collectibleId: 'item-1',
        localPath: 'test/fixtures/persistent-camera-card.jpg',
      );
      final worker = UploadWorker(
        queueRepository: queueRepository,
        portfolioRepository: portfolioRepository,
        registry: _cloudRegistry(
          storageService: const _FailingCloudStorageService(),
        ),
      );

      await worker.processQueue();

      final snapshot = await queueRepository.snapshot();
      expect(snapshot.retryableCount, 1);
      expect(snapshot.failedCount, 0);
      expect(snapshot.tasks.single.status, ImageUploadTaskStatus.retryable);
      expect(snapshot.tasks.single.lastError, contains('storage unavailable'));
      expect(snapshot.tasks.single.nextRetryAt, isNotNull);
    });

    test('retryable image sync uploads successfully on retry', () async {
      const portfolioRepository = SharedPreferencesPortfolioRepository();
      const queueRepository = SharedPreferencesSyncQueueRepository();
      final storageService = _FlakyCloudStorageService();
      await portfolioRepository.addItem(
        CollectibleItem(
          id: 'item-1',
          title: 'Camera Card',
          category: 'Trading Card',
          estimatedValue: 50,
          confidence: 0.8,
          condition: 'Good',
          recommendation: 'Keep protected.',
          imagePath: 'test/fixtures/persistent-camera-card.jpg',
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
      );
      await queueRepository.enqueueImageUpload(
        collectibleId: 'item-1',
        localPath: 'test/fixtures/persistent-camera-card.jpg',
      );
      final worker = UploadWorker(
        queueRepository: queueRepository,
        portfolioRepository: portfolioRepository,
        registry: _cloudRegistry(storageService: storageService),
        retryPolicy: const RetryPolicy(baseDelay: Duration.zero),
      );

      await worker.processQueue();
      var snapshot = await queueRepository.snapshot();
      expect(snapshot.retryableCount, 1);

      await worker.processQueue();

      snapshot = await queueRepository.snapshot();
      final items = await portfolioRepository.getItems();
      expect(snapshot.syncedCount, 1);
      expect(snapshot.retryableCount, 0);
      expect(items.single.cloudImageUrl, 'https://cdn.example.com/item-1.jpg');
    });

    test('local mode does not queue cloud image sync failures', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseConfigProvider.overrideWithValue(
            const SupabaseConfig(url: '', anonKey: '', isEnabled: false),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(imageSyncControllerProvider.notifier)
          .enqueueImage(
            collectibleId: 'item-1',
            localPath: 'test/fixtures/persistent-camera-card.jpg',
          );

      final snapshot = await container
          .read(syncQueueRepositoryProvider)
          .snapshot();
      final state = container.read(imageSyncControllerProvider);
      expect(snapshot.tasks, isEmpty);
      expect(state.cloudStatus, 'Local only');
      expect(state.errorMessage, isNull);
    });
  });

  group('Local-first portfolio mode', () {
    test('saves portfolio items while no cloud user is signed in', () async {
      SharedPreferences.setMockInitialValues({});
      const authRepository = MockAuthRepository();
      final portfolioRepository = SharedPreferencesPortfolioRepository();

      final user = await authRepository.currentUser();
      expect(user, isNotNull);
      expect(user!.isLocalOnly, isTrue);
      expect(user.isCloudBacked, isFalse);

      await portfolioRepository.addItem(_testItem());
      final items = await portfolioRepository.getItems();

      expect(items, hasLength(1));
      expect(items.single.title, contains('Charizard'));
    });
  });

  group('CollectorDashboardAnalyticsService', () {
    const service = CollectorDashboardAnalyticsService();

    test('calculates portfolio intelligence metrics', () {
      final items = [
        _analyticsItem(
          id: 'new-card',
          title: 'Charizard Holo',
          category: 'Trading Card',
          value: 1850,
          confidence: 0.94,
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
        _analyticsItem(
          id: 'coin',
          title: 'Silver Eagle',
          category: 'Coin',
          value: 300,
          confidence: 0.80,
          createdAt: DateTime.parse('2026-06-28T00:00:00Z'),
        ),
        _analyticsItem(
          id: 'comic',
          title: 'Amazing Spider-Man',
          category: 'Comic',
          value: 650,
          confidence: 0.72,
          createdAt: DateTime.parse('2026-06-25T00:00:00Z'),
        ),
      ];

      final analytics = service.build(items);

      expect(analytics.totalValue, 2800);
      expect(analytics.itemCount, 3);
      expect(analytics.averageItemValue, closeTo(933.33, 0.01));
      expect(analytics.averageConfidence, closeTo(0.82, 0.01));
      expect(analytics.highestValueItem?.id, 'new-card');
      expect(analytics.lowestValueItem?.id, 'coin');
      expect(analytics.mostRecentItem?.id, 'new-card');
      expect(analytics.strongestConfidenceItem?.id, 'new-card');
      expect(analytics.categoryDistribution[CollectorCategory.cards], 1);
      expect(analytics.categoryDistribution[CollectorCategory.coins], 1);
      expect(analytics.categoryDistribution[CollectorCategory.comics], 1);
      expect(analytics.topHighestValue.map((item) => item.id), [
        'new-card',
        'comic',
        'coin',
      ]);
      expect(analytics.topLowestConfidence.first.id, 'comic');
      expect(analytics.newestAdditions.map((item) => item.id), [
        'new-card',
        'coin',
        'comic',
      ]);
    });

    test(
      'scores collection health from confidence, metadata, pricing, duplicates and quality',
      () {
        final analytics = service.build([
          _analyticsItem(
            id: 'healthy',
            title: 'Charizard Holo',
            category: 'Trading Card',
            value: 1850,
            confidence: 0.94,
            createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          ),
          _analyticsItem(
            id: 'duplicate',
            title: 'Charizard Holo',
            category: 'Trading Card',
            value: 1700,
            confidence: 0.62,
            createdAt: DateTime.parse('2026-06-28T00:00:00Z'),
            pricingLastUpdated: DateTime.parse('2026-04-01T00:00:00Z'),
            detectionQuality: 'Dark image with glare and cropped edges.',
            includeMetadata: false,
          ),
        ]);

        expect(analytics.collectionHealth.score, inInclusiveRange(0, 100));
        expect(analytics.collectionHealth.duplicateCount, 1);
        expect(analytics.collectionHealth.missingDataCount, 1);
        expect(analytics.collectionHealth.stalePricingCount, 1);
        expect(analytics.collectionHealth.lowQualityCount, 1);
        expect(analytics.collectionHealth.label, isNotEmpty);
      },
    );

    test('generates insights and recommendations for review actions', () {
      final analytics = service.build([
        _analyticsItem(
          id: 'low-confidence',
          title: 'Blurry Mewtwo',
          category: 'Trading Card',
          value: 250,
          confidence: 0.61,
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          detectionQuality: 'Blurry image with low resolution.',
          includeMetadata: false,
        ),
      ]);

      expect(
        analytics.insights.map((insight) => insight.title),
        containsAll([
          'Low confidence scans',
          'Cards needing review',
          'Highest value item',
          'Most scanned category',
        ]),
      );
      expect(
        analytics.recommendations.map((recommendation) => recommendation.type),
        containsAll([
          CollectionRecommendationType.reviewLowConfidence,
          CollectionRecommendationType.scanAgain,
          CollectionRecommendationType.improvePhoto,
          CollectionRecommendationType.addMoreCollectibles,
        ]),
      );
    });

    test('builds daily, weekly and monthly trend snapshots', () {
      final analytics = service.build([
        _analyticsItem(
          id: 'june-card',
          title: 'June Card',
          category: 'Trading Card',
          value: 100,
          confidence: 0.9,
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
        _analyticsItem(
          id: 'july-coin',
          title: 'July Coin',
          category: 'Coin',
          value: 200,
          confidence: 0.8,
          createdAt: DateTime.parse('2026-07-03T00:00:00Z'),
        ),
      ]);

      expect(analytics.dailySnapshots, hasLength(2));
      expect(analytics.weeklySnapshots, hasLength(1));
      expect(analytics.weeklySnapshots.single.totalValue, 300);
      expect(analytics.monthlySnapshots, hasLength(2));
      expect(analytics.monthlySnapshots.map((snapshot) => snapshot.itemCount), [
        1,
        1,
      ]);
    });

    test('dashboard analytics update when portfolio data changes', () {
      final initial = service.build([
        _analyticsItem(
          id: 'first',
          title: 'First Card',
          category: 'Trading Card',
          value: 100,
          confidence: 0.9,
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
      ]);
      final updated = service.build([
        _analyticsItem(
          id: 'newer',
          title: 'Newer Coin',
          category: 'Coin',
          value: 500,
          confidence: 0.95,
          createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
        ),
        _analyticsItem(
          id: 'first',
          title: 'First Card',
          category: 'Trading Card',
          value: 100,
          confidence: 0.9,
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
      ]);

      expect(initial.totalValue, 100);
      expect(updated.totalValue, 600);
      expect(updated.itemCount, 2);
      expect(updated.mostRecentItem?.id, 'newer');
      expect(updated.categoryDistribution[CollectorCategory.coins], 1);
    });
  });

  group('SmartCollectorInsightsService', () {
    const dashboardService = CollectorDashboardAnalyticsService();
    const smartService = SmartCollectorInsightsService();

    test('calculates a 0 to 1000 collection score with factor breakdowns', () {
      final analytics = dashboardService.build([
        _analyticsItem(
          id: 'rare-card',
          title: 'Charizard Holo',
          category: 'Trading Card',
          value: 1850,
          confidence: 0.94,
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          rarity: 'Rare Holo',
        ),
        _analyticsItem(
          id: 'coin',
          title: 'Silver Eagle',
          category: 'Coin',
          value: 300,
          confidence: 0.88,
          createdAt: DateTime.parse('2026-06-28T00:00:00Z'),
          brand: 'US Mint',
          setName: 'Bullion',
        ),
      ]);

      final intelligence = smartService.build(analytics);

      expect(intelligence.collectionScore.score, inInclusiveRange(0, 1000));
      expect(intelligence.collectionScore.label, isNotEmpty);
      expect(
        intelligence.collectionScore.factorScores.keys,
        containsAll(CollectionScoreFactor.values),
      );
      expect(
        intelligence.collectionScore.factorScores[CollectionScoreFactor.rarity],
        greaterThan(0),
      );
      expect(
        intelligence.collectionScore.factorScores[CollectionScoreFactor
            .diversity],
        greaterThan(0),
      );
    });

    test(
      'generates smart insights for duplicates, rescans and category mix',
      () {
        final analytics = dashboardService.build([
          _analyticsItem(
            id: 'duplicate-a',
            title: 'Charizard Holo',
            category: 'Trading Card',
            value: 1850,
            confidence: 0.94,
            createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
            rarity: 'Rare Holo',
          ),
          _analyticsItem(
            id: 'duplicate-b',
            title: 'Charizard Holo',
            category: 'Trading Card',
            value: 1700,
            confidence: 0.62,
            createdAt: DateTime.parse('2026-06-28T00:00:00Z'),
            detectionQuality: 'Blurry image with glare.',
            includeMetadata: false,
          ),
          _analyticsItem(
            id: 'coin',
            title: 'Silver Eagle',
            category: 'Coin',
            value: 300,
            confidence: 0.88,
            createdAt: DateTime.parse('2026-06-27T00:00:00Z'),
          ),
          _analyticsItem(
            id: 'comic',
            title: 'Amazing Spider-Man',
            category: 'Comic',
            value: 650,
            confidence: 0.86,
            createdAt: DateTime.parse('2026-06-26T00:00:00Z'),
            trendLabel: 'Rising',
          ),
        ]);

        final intelligence = smartService.build(analytics);
        final insightTitles = intelligence.insights.map(
          (insight) => insight.title,
        );

        expect(insightTitles, contains('Duplicate collectibles'));
        expect(insightTitles, contains('Three collectibles need rescanning'));
        expect(insightTitles, contains('Highest value category'));
        expect(insightTitles, contains('Coins are underrepresented'));
        expect(insightTitles, contains('Comic watchlist signal'));
        expect(
          intelligence.insights.map((insight) => insight.message).join(' '),
          contains('Your highest value category is Cards.'),
        );
      },
    );

    test('generates AI collector recommendations from collection signals', () {
      final analytics = dashboardService.build([
        _analyticsItem(
          id: 'rare-card',
          title: 'Charizard Holo',
          category: 'Trading Card',
          value: 1850,
          confidence: 0.63,
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          pricingLastUpdated: DateTime.parse('2026-04-01T00:00:00Z'),
          detectionQuality: 'Dark and blurry image.',
          rarity: 'Rare Holo',
        ),
        _analyticsItem(
          id: 'comic',
          title: 'Amazing Spider-Man',
          category: 'Comic',
          value: 650,
          confidence: 0.86,
          createdAt: DateTime.parse('2026-06-28T00:00:00Z'),
          trendLabel: 'Rising',
        ),
      ]);

      final intelligence = smartService.build(analytics);
      final recommendationTypes = intelligence.recommendations.map(
        (recommendation) => recommendation.type,
      );

      expect(
        recommendationTypes,
        containsAll([
          AiCollectorRecommendationType.scanBetterPhotos,
          AiCollectorRecommendationType.upgradeGrading,
          AiCollectorRecommendationType.sellNow,
          AiCollectorRecommendationType.hold,
          AiCollectorRecommendationType.watchPrice,
          AiCollectorRecommendationType.addMissingCards,
        ]),
      );
    });

    test('builds wishlist foundation and collection goals', () {
      final analytics = dashboardService.build([
        _analyticsItem(
          id: 'base-set-card',
          title: 'Base Set Pikachu',
          category: 'Trading Card',
          value: 80,
          confidence: 0.90,
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          setName: 'Base Set',
        ),
      ]);

      final intelligence = smartService.build(analytics);

      expect(intelligence.wishlistStatusCounts[WishlistStatus.owned], 1);
      expect(intelligence.wishlistStatusCounts[WishlistStatus.wanted], 1);
      expect(intelligence.wishlistStatusCounts[WishlistStatus.missing], 99);
      expect(intelligence.goals.map((goal) => goal.title), [
        'Complete Base Set',
        'Collect 100 Pokemon',
        'Own 50 graded cards',
      ]);
      expect(intelligence.goals.first.progressLabel, '1 / 102');
    });

    test('unlocks achievements from collector milestones', () {
      final coinItems = [
        for (var index = 0; index < 10; index++)
          _analyticsItem(
            id: 'coin-$index',
            title: 'Silver Eagle $index',
            category: 'Coin',
            value: 50,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
            brand: 'US Mint',
            setName: 'Bullion',
          ),
      ];
      final analytics = dashboardService.build([
        _analyticsItem(
          id: 'rare-card',
          title: 'Charizard Holo',
          category: 'Trading Card',
          value: 1850,
          confidence: 0.94,
          createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
          rarity: 'Rare Holo',
        ),
        ...coinItems,
      ]);

      final intelligence = smartService.build(analytics);
      final unlocked = intelligence.unlockedAchievements.map(
        (achievement) => achievement.type,
      );

      expect(
        unlocked,
        containsAll([
          AchievementType.firstScan,
          AchievementType.rareCollector,
          AchievementType.coinExpert,
        ]),
      );
      expect(
        intelligence.achievements
            .firstWhere(
              (achievement) => achievement.type == AchievementType.hundredScans,
            )
            .progress,
        closeTo(0.11, 0.01),
      );
    });
  });

  group('WishlistService', () {
    const service = WishlistService();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('persists wishlist status updates locally', () async {
      const repository = SharedPreferencesWishlistRepository();
      final item = _testItemWith(id: 'wishlist-card');

      await repository.saveStatus(item: item, status: WishlistStatus.wanted);

      expect(
        await repository.getStatusForItem('wishlist-card'),
        WishlistStatus.wanted,
      );
      expect(await repository.getEntries(), hasLength(1));

      await repository.saveStatus(item: item, status: WishlistStatus.missing);
      final entries = await repository.getEntries();

      expect(
        await repository.getStatusForItem('wishlist-card'),
        WishlistStatus.missing,
      );
      expect(entries, hasLength(1));
      expect(entries.single.title, '1999 Pokemon Charizard');
    });

    test('builds wishlist summary from portfolio items and status entries', () {
      final items = [
        _testItemWith(id: 'owned-card'),
        _testItemWith(id: 'wanted-card', title: 'Wanted Pikachu'),
      ];
      final summary = service.buildSummary(
        items: items,
        entries: [
          WishlistStatusEntry(
            itemId: 'wanted-card',
            title: 'Wanted Pikachu',
            category: 'Trading Card',
            status: WishlistStatus.wanted,
            updatedAt: DateTime.parse('2026-06-30T00:00:00Z'),
          ),
          WishlistStatusEntry(
            itemId: 'missing-card',
            title: 'Missing Blastoise',
            category: 'Trading Card',
            status: WishlistStatus.missing,
            updatedAt: DateTime.parse('2026-06-29T00:00:00Z'),
          ),
        ],
      );

      expect(summary.countFor(WishlistStatus.owned), 1);
      expect(summary.countFor(WishlistStatus.wanted), 1);
      expect(summary.countFor(WishlistStatus.missing), 1);
      expect(summary.recommendations, contains('Review missing collectibles'));
      expect(
        summary.recommendations,
        contains('Add missing items to wishlist'),
      );
    });

    test('collection goal progress exposes percentage completion', () {
      const goal = CollectionGoal(
        type: CollectionGoalType.collectPokemon,
        title: 'Collect 100 Pokemon',
        description: 'Build a dedicated Pokemon collection.',
        current: 80,
        target: 100,
      );

      expect(goal.progress, 0.8);
      expect(goal.progressLabel, '80 / 100');
    });
  });

  group('PortfolioHistoryService', () {
    const service = PortfolioHistoryService();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('creates daily weekly and monthly portfolio snapshots', () {
      final items = [
        _analyticsItem(
          id: 'card',
          title: 'Charizard Holo',
          category: 'Trading Card',
          value: 1800,
          confidence: 0.94,
          createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
        ),
        _analyticsItem(
          id: 'coin',
          title: 'Silver Eagle',
          category: 'Coin',
          value: 200,
          confidence: 0.86,
          createdAt: DateTime.parse('2026-06-28T00:00:00Z'),
        ),
      ];

      final snapshots = service.createCurrentSnapshots(
        items,
        capturedAt: DateTime.parse('2026-06-30T12:00:00Z'),
      );

      expect(snapshots, hasLength(3));
      expect(
        snapshots.map((snapshot) => snapshot.period),
        containsAll(TrendSnapshotPeriod.values),
      );
      expect(snapshots.first.totalPortfolioValue, 2000);
      expect(snapshots.first.totalItems, 2);
      expect(snapshots.first.averageValue, 1000);
      expect(snapshots.first.categoryTotals[CollectorCategory.cards], 1800);
      expect(snapshots.first.categoryTotals[CollectorCategory.coins], 200);
      expect(snapshots.first.collectionScore, inInclusiveRange(0, 1000));
      expect(snapshots.first.itemValues['card'], 1800);
    });

    test('persists and upserts history snapshots', () async {
      const repository = SharedPreferencesPortfolioHistoryRepository();
      final first = service.createSnapshot(
        [
          _analyticsItem(
            id: 'card',
            title: 'Charizard Holo',
            category: 'Trading Card',
            value: 1000,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          ),
        ],
        period: TrendSnapshotPeriod.daily,
        capturedAt: DateTime.parse('2026-06-30T08:00:00Z'),
      );
      final updated = service.createSnapshot(
        [
          _analyticsItem(
            id: 'card',
            title: 'Charizard Holo',
            category: 'Trading Card',
            value: 1200,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          ),
        ],
        period: TrendSnapshotPeriod.daily,
        capturedAt: DateTime.parse('2026-06-30T18:00:00Z'),
      );

      await repository.upsertSnapshot(first);
      await repository.upsertSnapshot(updated);
      final snapshots = await repository.getSnapshots(
        TrendSnapshotPeriod.daily,
      );

      expect(snapshots, hasLength(1));
      expect(snapshots.single.totalPortfolioValue, 1200);
      expect(snapshots.single.capturedAt.hour, 18);
    });

    test('calculates value changes against historical snapshots', () {
      final yesterday = service.createSnapshot(
        [
          _analyticsItem(
            id: 'card',
            title: 'Charizard Holo',
            category: 'Trading Card',
            value: 1000,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          ),
        ],
        period: TrendSnapshotPeriod.daily,
        capturedAt: DateTime.parse('2026-06-29T12:00:00Z'),
      );
      final lastWeek = service.createSnapshot(
        [
          _analyticsItem(
            id: 'card',
            title: 'Charizard Holo',
            category: 'Trading Card',
            value: 800,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-20T00:00:00Z'),
          ),
        ],
        period: TrendSnapshotPeriod.weekly,
        capturedAt: DateTime.parse('2026-06-22T12:00:00Z'),
      );

      final performance = service.buildPerformance(
        currentItems: [
          _analyticsItem(
            id: 'card',
            title: 'Charizard Holo',
            category: 'Trading Card',
            value: 1200,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
          ),
        ],
        history: [yesterday, lastWeek],
        capturedAt: DateTime.parse('2026-06-30T12:00:00Z'),
      );

      expect(performance.todayChange.absoluteChange, 200);
      expect(performance.todayChange.percentageChange, closeTo(0.2, 0.001));
      expect(performance.weeklyChange.absoluteChange, 400);
      expect(performance.overallChange.currentValue, 1200);
    });

    test('calculates top gainers and top losers', () {
      final previous = service.createSnapshot(
        [
          _analyticsItem(
            id: 'gainer',
            title: 'Rising Card',
            category: 'Trading Card',
            value: 100,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          ),
          _analyticsItem(
            id: 'loser',
            title: 'Falling Coin',
            category: 'Coin',
            value: 300,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
          ),
        ],
        period: TrendSnapshotPeriod.daily,
        capturedAt: DateTime.parse('2026-06-29T12:00:00Z'),
      );

      final performance = service.buildPerformance(
        currentItems: [
          _analyticsItem(
            id: 'gainer',
            title: 'Rising Card',
            category: 'Trading Card',
            value: 250,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
          ),
          _analyticsItem(
            id: 'loser',
            title: 'Falling Coin',
            category: 'Coin',
            value: 180,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
          ),
        ],
        history: [previous],
        capturedAt: DateTime.parse('2026-06-30T12:00:00Z'),
      );

      expect(performance.topGainer?.itemId, 'gainer');
      expect(performance.topGainer?.absoluteChange, 150);
      expect(performance.topLoser?.itemId, 'loser');
      expect(performance.topLoser?.absoluteChange, -120);
      expect(performance.recentlyAppreciated.single.itemId, 'gainer');
      expect(performance.recentlyDropped.single.itemId, 'loser');
    });

    test('generates trend recommendations', () {
      final previous = service.createSnapshot(
        [
          _analyticsItem(
            id: 'card',
            title: 'Watch Card',
            category: 'Trading Card',
            value: 1000,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-22T00:00:00Z'),
          ),
        ],
        period: TrendSnapshotPeriod.weekly,
        capturedAt: DateTime.parse('2026-06-22T12:00:00Z'),
      );

      final performance = service.buildPerformance(
        currentItems: [
          _analyticsItem(
            id: 'card',
            title: 'Watch Card',
            category: 'Trading Card',
            value: 1080,
            confidence: 0.9,
            createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
          ),
        ],
        history: [previous],
        capturedAt: DateTime.parse('2026-06-30T12:00:00Z'),
      );

      expect(
        performance.recommendations,
        contains('Collection gained 8% this week.'),
      );
      expect(
        performance.recommendations.any(
          (recommendation) => recommendation.contains('Cards outperform'),
        ),
        isTrue,
      );
    });

    test('provider records history from supplied portfolio items', () async {
      final items = [
        _analyticsItem(
          id: 'history-card',
          title: 'History Charizard',
          category: 'Trading Card',
          value: 1200,
          confidence: 0.9,
          createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
        ),
      ];
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final performance = await container.read(
        portfolioPerformanceProvider(items).future,
      );
      const repository = SharedPreferencesPortfolioHistoryRepository();
      final snapshots = await repository.getAllSnapshots();

      expect(performance.dailySnapshots, isNotEmpty);
      expect(performance.dailySnapshots.last.totalPortfolioValue, 1200);
      expect(snapshots, hasLength(3));
    });
  });

  group('PriceAlertEvaluator', () {
    const evaluator = PriceAlertEvaluator();

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('triggers when price rises above threshold', () {
      final item = _analyticsItem(
        id: 'charizard',
        title: 'Charizard Holo',
        category: 'Trading Card',
        value: 1850,
        confidence: 0.94,
        createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
      );
      final alert = _priceAlert(
        itemId: item.id,
        itemTitle: item.title,
        rule: const PriceAlertRule(
          type: PriceAlertRuleType.priceRisesAboveAmount,
          amount: 1800,
        ),
      );

      final evaluation = evaluator.evaluateAlert(
        alert: alert,
        item: item,
        now: DateTime.parse('2026-06-30T12:00:00Z'),
      );

      expect(evaluation.triggered, isTrue);
      expect(evaluation.alert.status, PriceAlertStatus.triggered);
      expect(evaluation.message, contains('rose above AUD 1,800'));
    });

    test('triggers when price drops below threshold', () {
      final item = _analyticsItem(
        id: 'coin',
        title: 'Silver Eagle',
        category: 'Coin',
        value: 120,
        confidence: 0.88,
        createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
      );
      final alert = _priceAlert(
        itemId: item.id,
        itemTitle: item.title,
        rule: const PriceAlertRule(
          type: PriceAlertRuleType.priceDropsBelowAmount,
          amount: 150,
        ),
      );

      final evaluation = evaluator.evaluateAlert(
        alert: alert,
        item: item,
        now: DateTime.parse('2026-06-30T12:00:00Z'),
      );

      expect(evaluation.triggered, isTrue);
      expect(evaluation.message, contains('dropped below AUD 150'));
    });

    test('triggers percentage increase and decrease alerts', () {
      final risingItem = _analyticsItem(
        id: 'riser',
        title: 'Rising Card',
        category: 'Trading Card',
        value: 125,
        confidence: 0.9,
        createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
      );
      final fallingItem = _analyticsItem(
        id: 'faller',
        title: 'Falling Comic',
        category: 'Comic',
        value: 80,
        confidence: 0.9,
        createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
      );

      final increase = evaluator.evaluateAlert(
        alert: _priceAlert(
          itemId: risingItem.id,
          itemTitle: risingItem.title,
          rule: const PriceAlertRule(
            type: PriceAlertRuleType.percentageIncrease,
            percentage: 0.1,
            baselineValue: 100,
          ),
        ),
        item: risingItem,
      );
      final decrease = evaluator.evaluateAlert(
        alert: _priceAlert(
          itemId: fallingItem.id,
          itemTitle: fallingItem.title,
          rule: const PriceAlertRule(
            type: PriceAlertRuleType.percentageDecrease,
            percentage: 0.1,
            baselineValue: 100,
          ),
        ),
        item: fallingItem,
      );

      expect(increase.triggered, isTrue);
      expect(increase.message, contains('gained 25%'));
      expect(decrease.triggered, isTrue);
      expect(decrease.message, contains('lost 20%'));
    });

    test('triggers stale pricing reminder', () {
      final item = _analyticsItem(
        id: 'stale',
        title: 'Stale Price Card',
        category: 'Trading Card',
        value: 500,
        confidence: 0.9,
        pricingLastUpdated: DateTime.parse('2026-05-01T00:00:00Z'),
        createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
      );
      final alert = _priceAlert(
        itemId: item.id,
        itemTitle: item.title,
        rule: const PriceAlertRule(
          type: PriceAlertRuleType.stalePricingReminder,
          staleAfterDays: 30,
        ),
      );

      final evaluation = evaluator.evaluateAlert(
        alert: alert,
        item: item,
        now: DateTime.parse('2026-06-30T12:00:00Z'),
      );

      expect(evaluation.triggered, isTrue);
      expect(evaluation.message, contains('pricing is stale'));
    });

    test('persists alerts locally', () async {
      const repository = SharedPreferencesPriceAlertRepository();
      final first = _priceAlert(
        id: 'alert-old',
        createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
      );
      final latest = _priceAlert(
        id: 'alert-new',
        itemId: 'item-2',
        createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
      );

      await repository.saveAlert(first);
      await repository.saveAlert(latest);

      final alerts = await repository.getAlerts();
      expect(alerts.map((alert) => alert.id), ['alert-new', 'alert-old']);
      expect(await repository.getAlertsForItem('item-2'), hasLength(1));

      await repository.deleteAlert('alert-new');
      expect(await repository.getAlerts(), hasLength(1));
    });
  });
}

CollectibleItem _testItem() {
  return CollectibleItem(
    id: 'item-1',
    title: '1999 Pokémon Charizard',
    category: 'Trading Card',
    estimatedValue: 1850,
    confidence: 0.94,
    condition: 'Near Mint',
    recommendation: 'Consider grading before selling.',
    imagePath: 'sample://sports-card',
    createdAt: DateTime.parse('2026-06-27T00:00:00.000'),
    year: '1999',
    brand: 'Pokemon',
    setName: 'Base Set',
    cardNumber: '4/102',
    playerOrCharacter: 'Charizard',
    rarity: 'Holo Rare',
    notes: 'Verify holo surface.',
    pricing: PricingInfo(
      estimatedMarketValue: 1850,
      lowEstimate: 1443,
      highEstimate: 2257,
      currency: 'AUD',
      pricingSource: 'Mock market blend',
      pricingConfidence: 0.85,
      lastUpdated: DateTime.parse('2026-06-29T00:00:00Z'),
    ),
    marketSummary: MarketSummary.fromJson({
      'averagePrice': 1810,
      'medianPrice': 1850,
      'lowPrice': 1443,
      'highPrice': 2257,
      'salesCount': 5,
      'trendLabel': 'Stable',
      'confidence': 0.86,
      'lastUpdated': '2026-06-29T00:00:00Z',
      'sources': ['eBay Sold', 'TCGplayer'],
      'comps': [
        {
          'source': 'eBay Sold',
          'title': '1999 Pokemon Charizard sold listing',
          'soldPrice': 1850,
          'currency': 'AUD',
          'soldDate': '2026-06-20T00:00:00Z',
          'condition': 'Near Mint',
        },
      ],
    }),
  );
}

CollectibleItem _testItemWith({
  String id = 'item-1',
  String title = '1999 Pokemon Charizard',
  String imagePath = 'sample://sports-card',
  DateTime? createdAt,
}) {
  return CollectibleItem(
    id: id,
    title: title,
    category: 'Trading Card',
    estimatedValue: 1850,
    confidence: 0.94,
    condition: 'Near Mint',
    recommendation: 'Consider grading before selling.',
    imagePath: imagePath,
    createdAt: createdAt ?? DateTime.parse('2026-06-27T00:00:00.000'),
  );
}

CollectibleItem _analyticsItem({
  required String id,
  required String title,
  required String category,
  required double value,
  required double confidence,
  required DateTime createdAt,
  DateTime? pricingLastUpdated,
  String? detectionQuality,
  String? rarity,
  String? trendLabel,
  String? estimatedGrade,
  String? brand,
  String? setName,
  bool includeMetadata = true,
}) {
  return CollectibleItem(
    id: id,
    title: title,
    category: category,
    estimatedValue: value,
    confidence: confidence,
    condition: 'Near Mint',
    recommendation: 'Review before selling.',
    imagePath: 'sample://$id',
    createdAt: createdAt,
    year: includeMetadata ? '1999' : null,
    brand: includeMetadata ? (brand ?? 'Pokemon') : null,
    setName: includeMetadata ? (setName ?? 'Base Set') : null,
    cardNumber: includeMetadata ? '4/102' : null,
    playerOrCharacter: includeMetadata ? title : null,
    rarity: includeMetadata ? (rarity ?? 'Rare') : null,
    estimatedGrade: estimatedGrade,
    notes: includeMetadata ? 'Collector-ready record.' : null,
    detectionQuality: detectionQuality,
    pricing: PricingInfo(
      estimatedMarketValue: value,
      lowEstimate: value * 0.8,
      highEstimate: value * 1.2,
      currency: 'AUD',
      pricingSource: 'Mock market blend',
      pricingConfidence: 0.85,
      lastUpdated: pricingLastUpdated ?? createdAt,
    ),
    marketSummary: MarketSummary.fromJson({
      'averagePrice': value,
      'medianPrice': value,
      'lowPrice': value * 0.8,
      'highPrice': value * 1.2,
      'salesCount': 3,
      'trendLabel': trendLabel ?? 'Stable',
      'confidence': confidence,
      'lastUpdated': (pricingLastUpdated ?? createdAt).toIso8601String(),
      'sources': ['Mock market'],
      'comps': const [],
    }),
  );
}

PriceAlert _priceAlert({
  String id = 'alert-1',
  String itemId = 'item-1',
  String itemTitle = '1999 Pokemon Charizard',
  PriceAlertRule rule = const PriceAlertRule(
    type: PriceAlertRuleType.priceRisesAboveAmount,
    amount: 2000,
  ),
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime.parse('2026-06-30T00:00:00Z');
  return PriceAlert(
    id: id,
    itemId: itemId,
    itemTitle: itemTitle,
    rule: rule,
    status: PriceAlertStatus.active,
    createdAt: created,
    updatedAt: created,
  );
}

Map<String, dynamic> _backendAnalysisJson() {
  return {
    'id': 'backend-card-1',
    'itemName': '1999 Pokemon Charizard Holo',
    'type': 'Trading Card',
    'estimatedValue': '1850',
    'valueRange': {'low': 1443, 'high': 2257},
    'confidence': 94,
    'condition': 'Near Mint',
    'marketTrend': 'Rising',
    'keyAttributes': {
      'year': '1999',
      'brand': 'Pokemon',
      'setName': 'Base Set',
      'cardNumber': '4/102',
      'playerOrCharacter': 'Charizard',
      'rarity': 'Holo Rare',
    },
    'aiReview': {
      'primaryMatch': '1999 Pokemon Charizard Holo',
      'confidenceExplanation':
          'High confidence from holographic cues and character artwork.',
      'detectionQuality': 'Good',
      'reasoning': 'The image contains a Charizard card layout.',
    },
    'alternatives': [
      {
        'title': 'Charizard Promo',
        'category': 'Trading Card',
        'confidence': 61,
        'reason': 'Same character with similar collector cues.',
      },
    ],
    'recommendation': 'Consider grading before selling.',
    'marketSummary': {
      'averagePrice': 1810,
      'medianPrice': 1850,
      'lowPrice': 1443,
      'highPrice': 2257,
      'salesCount': 1,
      'trendLabel': 'Rising',
      'confidence': 86,
      'lastUpdated': '2026-06-29T00:00:00Z',
      'sources': ['eBay Sold'],
    },
    'comparableSales': [
      {
        'source': 'eBay Sold',
        'title': '1999 Pokemon Charizard sold listing',
        'soldPrice': 1850,
        'currency': 'AUD',
        'soldDate': '2026-06-20T00:00:00Z',
        'condition': 'Near Mint',
      },
    ],
    'timestamp': '2026-06-30T09:00:00Z',
  };
}

AiBackendAnalysisRequest _backendRequest() {
  return AiBackendAnalysisRequest(
    imagePath: '/local/path/card.jpg',
    imageSource: 'camera',
    timestamp: DateTime.parse('2026-06-30T09:00:00Z'),
  );
}

AiBackendAnalysisRequest _backendFileRequest() {
  return AiBackendAnalysisRequest(
    imagePath: _fixturePath('image.jpg'),
    imageSource: 'camera',
    timestamp: DateTime.parse('2026-06-30T09:00:00Z'),
  );
}

RecognitionResult _testRecognitionResult() {
  return RecognitionResult(
    success: true,
    filename: null,
    imageUrl: 'sample://sports-card',
    title: '1999 Pokemon Charizard',
    category: 'Trading Card',
    confidence: 0.94,
    description: 'Sample scanner result.',
    estimatedValue: 1850,
    condition: 'Near Mint',
    recommendation: 'Consider grading before selling.',
    primaryMatch: '1999 Pokemon Charizard',
    alternativeMatches: const [],
    confidenceExplanation: 'Strong visual match.',
    detectionQuality: 'Good',
    aiReasoning: 'Visible card and character details match.',
    pricing: PricingInfo(
      estimatedMarketValue: 1850,
      lowEstimate: 1443,
      highEstimate: 2257,
      currency: 'AUD',
      pricingSource: 'Mock market blend',
      pricingConfidence: 0.85,
      lastUpdated: DateTime.parse('2026-06-29T00:00:00Z'),
    ),
  );
}

ScanResult _testScanResult() {
  final now = DateTime.parse('2026-06-30T09:00:00Z');
  return ScanResult(
    id: 'scan-test',
    title: '1999 Pokemon Charizard',
    category: 'Trading Card',
    estimatedValue: 1850,
    confidence: 0.94,
    condition: 'Near Mint',
    thumbnail: 'sample://sports-card',
    scanDate: now,
    primaryMatch: '1999 Pokemon Charizard',
    alternativeMatches: const [],
    confidenceExplanation: 'Strong visual match.',
    detectionQuality: 'Good',
    aiReasoning: 'Visible card and character details match.',
    pricing: PricingInfo(
      estimatedMarketValue: 1850,
      lowEstimate: 1443,
      highEstimate: 2257,
      currency: 'AUD',
      pricingSource: 'Provider fixture',
      pricingConfidence: 0.85,
      lastUpdated: now,
    ),
    year: '1999',
    brand: 'Pokemon',
    setName: 'Base Set',
    cardNumber: '4/102',
    playerOrCharacter: 'Charizard',
  );
}

class _FailingMarketPricingProvider implements MarketPricingProvider {
  const _FailingMarketPricingProvider();

  @override
  Future<MarketPricingResult> price(MarketPricingRequest request) async {
    throw const MarketPricingException('Pricing unavailable.');
  }
}

class _SuccessfulAiBackendClient implements AiBackendClient {
  _SuccessfulAiBackendClient(this.response);

  final AiBackendAnalysisResponse response;
  int calls = 0;
  AiBackendAnalysisRequest? lastRequest;

  @override
  Future<AiBackendAnalysisResponse> analyze(
    AiBackendAnalysisRequest request,
  ) async {
    calls += 1;
    lastRequest = request;
    return response;
  }
}

class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter({
    this.statusCode = 200,
    this.responseData,
    this.rawResponseBody,
    this.dioExceptionType,
  });

  final int statusCode;
  final Object? responseData;
  final String? rawResponseBody;
  final DioExceptionType? dioExceptionType;

  int calls = 0;
  String? lastPath;
  Map<String, dynamic>? lastPayload;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls += 1;
    lastPath = options.path;
    final data = options.data;
    if (data is Map<String, dynamic>) {
      lastPayload = data;
    }

    final exceptionType = dioExceptionType;
    if (exceptionType != null) {
      throw DioException(
        requestOptions: options,
        type: exceptionType,
        message: 'Simulated Dio failure',
      );
    }

    return ResponseBody.fromString(
      rawResponseBody ?? jsonEncode(responseData ?? _backendAnalysisJson()),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _StaticRecognitionRepository implements RecognitionRepository {
  _StaticRecognitionRepository(this.result);

  final RecognitionResult result;
  int calls = 0;

  @override
  Future<RecognitionResult> recognizeCollectible(XFile image) async {
    calls += 1;
    return result;
  }
}

String _fixturePath(String name) {
  return File('test/fixtures/$name').absolute.path;
}

class _SuccessfulCloudStorageService implements CloudStorageService {
  const _SuccessfulCloudStorageService();

  @override
  String get providerName => 'Supabase Storage';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    return const CloudStorageUploadResult(
      path: 'remote/item-1.jpg',
      publicUrl: 'https://cdn.example.com/item-1.jpg',
    );
  }

  @override
  Future<void> deleteImage(String path) async {}

  @override
  Future<String?> getImageUrl(String path) async {
    return 'https://cdn.example.com/item-1.jpg';
  }
}

class _FailingCloudStorageService implements CloudStorageService {
  const _FailingCloudStorageService();

  @override
  String get providerName => 'Supabase Storage';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    throw StateError('storage unavailable');
  }

  @override
  Future<void> deleteImage(String path) async {}

  @override
  Future<String?> getImageUrl(String path) async {
    return null;
  }
}

class _FlakyCloudStorageService implements CloudStorageService {
  var _uploadAttempts = 0;

  @override
  String get providerName => 'Supabase Storage';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    _uploadAttempts += 1;
    if (_uploadAttempts == 1) {
      throw StateError('storage unavailable');
    }

    return const CloudStorageUploadResult(
      path: 'remote/item-1.jpg',
      publicUrl: 'https://cdn.example.com/item-1.jpg',
    );
  }

  @override
  Future<void> deleteImage(String path) async {}

  @override
  Future<String?> getImageUrl(String path) async {
    return 'https://cdn.example.com/item-1.jpg';
  }
}

class _MemoryUsageRepository implements UsageRepository {
  _MemoryUsageRepository({int initialCount = 0}) : count = initialCount;

  int count;

  @override
  Future<int> scansUsedToday() async {
    return count;
  }

  @override
  Future<int> incrementScansUsedToday() async {
    count += 1;
    return count;
  }

  @override
  Future<void> resetUsage() async {
    count = 0;
  }
}

class _MemoryEntitlementRepository implements EntitlementRepository {
  _MemoryEntitlementRepository();

  SubscriptionPlan plan = SubscriptionPlan.free;

  @override
  Future<SubscriptionPlan> loadPlan() async {
    return plan;
  }

  @override
  Future<void> savePlan(SubscriptionPlan plan) async {
    this.plan = plan;
  }
}

class _FakeBillingRepository implements BillingRepository {
  const _FakeBillingRepository({
    this.available = true,
    this.products = const [],
    this.loadError,
    this.purchaseResult = const PurchaseResult(
      status: PurchaseResultStatus.failed,
      message: 'Purchase failed.',
    ),
    this.restoreResult = const PurchaseResult(
      status: PurchaseResultStatus.failed,
      message: 'Restore failed.',
    ),
  });

  final bool available;
  final List<BillingProduct> products;
  final Object? loadError;
  final PurchaseResult purchaseResult;
  final PurchaseResult restoreResult;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<List<BillingProduct>> loadProducts() async {
    final error = loadError;
    if (error != null) {
      throw error;
    }
    return products;
  }

  @override
  Future<PurchaseResult> purchase(SubscriptionPlan plan) async {
    return purchaseResult;
  }

  @override
  Future<PurchaseResult> restorePurchases() async {
    return restoreResult;
  }
}

class _ReturningPortfolioRepository implements PortfolioRepository {
  _ReturningPortfolioRepository(this.savedItem);

  final CollectibleItem savedItem;
  List<CollectibleItem> _items = const [];

  @override
  Future<CollectibleItem> addItem(CollectibleItem item) async {
    _items = [savedItem];
    return savedItem;
  }

  @override
  Future<void> upsertSyncedItem(CollectibleItem item) async {
    _items = [
      item,
      ..._items.where((existingItem) => existingItem.id != item.id),
    ];
  }

  @override
  Future<void> updateItem(CollectibleItem item) async {
    _items = [
      item,
      ..._items.where((existingItem) => existingItem.id != item.id),
    ];
  }

  @override
  Future<void> clearPortfolio() async {
    _items = const [];
  }

  @override
  Future<List<CollectibleItem>> getItems() async {
    return _items;
  }

  @override
  Future<void> removeItem(String id) async {
    _items = _items.where((item) => item.id != id).toList();
  }

  @override
  Future<void> updateItemImageSync({
    required String itemId,
    String? imageStoragePath,
    String? cloudImageUrl,
  }) async {}
}

class _StaticSyncService implements SyncService {
  const _StaticSyncService({required this.status});

  final SyncStatus status;

  @override
  Future<SyncStatus> currentStatus() async {
    return status;
  }

  @override
  Future<SyncStatus> syncLocalItems(List<CollectibleItem> items) async {
    return status;
  }

  @override
  Future<List<CollectibleItem>> downloadCloudItems() async {
    return const [];
  }

  @override
  Future<SyncStatus> markPending(List<CollectibleItem> items) async {
    return SyncStatus(
      state: SyncState.pending,
      message: status.message,
      isCloudBackupEnabled: status.isCloudBackupEnabled,
      authenticatedUserId: status.authenticatedUserId,
      lastSyncedAt: status.lastSyncedAt,
      pendingItemCount: items.length,
      failedItemCount: status.failedItemCount,
      retryableItemCount: status.retryableItemCount,
    );
  }
}

class _FailingSyncService implements SyncService {
  const _FailingSyncService();

  @override
  Future<SyncStatus> currentStatus() async {
    throw StateError('network unavailable');
  }

  @override
  Future<SyncStatus> syncLocalItems(List<CollectibleItem> items) async {
    throw StateError('network unavailable');
  }

  @override
  Future<List<CollectibleItem>> downloadCloudItems() async {
    throw StateError('network unavailable');
  }

  @override
  Future<SyncStatus> markPending(List<CollectibleItem> items) async {
    throw StateError('network unavailable');
  }
}

SupabaseBootstrap _configuredSupabaseBootstrap() {
  return SupabaseBootstrap(
    config: const EnvironmentConfig(
      environment: AppEnvironment.sit,
      featureFlags: FeatureFlags(
        useCloudAuth: true,
        useCloudPortfolioSync: true,
        useCloudImageStorage: true,
      ),
    ),
    url: 'https://example.supabase.co',
    anonKey: 'anon-key',
  );
}

CloudServiceRegistry _cloudRegistry({
  AuthService authService = const _SignedInCloudAuthService(),
  CloudStorageService storageService = const NoOpCloudStorageService(),
  CloudPortfolioSyncService syncService = const NoOpCloudPortfolioSyncService(),
  AnalyticsService analyticsService = const NoOpAnalyticsService(),
  CrashReportingService crashReportingService =
      const NoOpCrashReportingService(),
  RemoteConfigService remoteConfigService = const NoOpRemoteConfigService(),
}) {
  return CloudServiceRegistry(
    config: const EnvironmentConfig(
      environment: AppEnvironment.sit,
      featureFlags: FeatureFlags(
        useCloudAuth: true,
        useCloudPortfolioSync: true,
        useCloudImageStorage: true,
      ),
    ),
    authService: authService,
    cloudStorageService: storageService,
    cloudPortfolioSyncService: syncService,
    analyticsService: analyticsService,
    crashReportingService: crashReportingService,
    remoteConfigService: remoteConfigService,
  );
}

class _SignedOutCloudAuthService implements AuthService {
  const _SignedOutCloudAuthService();

  @override
  String get providerName => 'Supabase Auth';

  @override
  Future<CloudAuthUser?> currentUser() async => null;

  @override
  Future<String?> currentUserId() async => null;

  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<CloudAuthUser> signInAnonymously() async {
    throw StateError('auth unavailable');
  }

  @override
  Future<void> signOut() async {}
}

class _SignedInCloudAuthService implements AuthService {
  const _SignedInCloudAuthService({
    this.userId = 'user-1',
    this.email,
    this.isAnonymous = false,
  });

  final String userId;
  final String? email;
  final bool isAnonymous;

  @override
  String get providerName => 'Supabase Auth';

  @override
  Future<CloudAuthUser?> currentUser() async {
    return CloudAuthUser(id: userId, email: email, isAnonymous: isAnonymous);
  }

  @override
  Future<String?> currentUserId() async {
    return userId;
  }

  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<CloudAuthUser> signInAnonymously() async {
    return CloudAuthUser(id: userId, email: email, isAnonymous: true);
  }

  @override
  Future<void> signOut() async {}
}

class _FakeSupabaseAuthGateway implements SupabaseAuthGateway {
  _FakeSupabaseAuthGateway({
    this.currentSessionValue,
    this.passwordSession,
    this.signUpSession,
    this.signInError,
    this.signUpError,
  });

  final SupabaseAuthSession? currentSessionValue;
  final SupabaseAuthSession? passwordSession;
  final SupabaseAuthSession? signUpSession;
  final Object? signInError;
  final Object? signUpError;
  var signInCalls = 0;
  var signUpCalls = 0;
  var callbackCalls = 0;
  String? lastCallbackAccessToken;
  String? lastCallbackRefreshToken;
  var resendCalls = 0;
  String? lastResendEmail;
  var passwordResetCalls = 0;
  String? lastPasswordResetEmail;
  var signOutCalls = 0;
  String? lastSignOutToken;

  @override
  bool get isConfigured => true;

  @override
  Future<SupabaseAuthSession?> currentSession() async => currentSessionValue;

  @override
  Future<SupabaseAuthSession> ensureAnonymousSession() async {
    return currentSessionValue ??
        const SupabaseAuthSession(
          userId: 'anonymous-user',
          email: null,
          accessToken: 'anonymous-token',
          displayName: 'Anonymous Collector',
          isAnonymous: true,
          projectUrl: 'https://example.supabase.co',
        );
  }

  @override
  Future<SupabaseAuthSession> signInAnonymously() async {
    return ensureAnonymousSession();
  }

  @override
  Future<SupabaseAuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    final error = signInError;
    if (error != null) {
      throw error;
    }
    return passwordSession ??
        SupabaseAuthSession(
          userId: 'email-user',
          email: email,
          accessToken: 'email-token',
          displayName: email,
          isAnonymous: false,
          projectUrl: 'https://example.supabase.co',
        );
  }

  @override
  Future<SupabaseAuthSession> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    final error = signUpError;
    if (error != null) {
      throw error;
    }
    return signUpSession ??
        SupabaseAuthSession(
          userId: 'new-email-user',
          email: email,
          accessToken: 'new-email-token',
          displayName: email,
          isAnonymous: false,
          projectUrl: 'https://example.supabase.co',
        );
  }

  @override
  Future<void> signOut(String accessToken) async {
    signOutCalls += 1;
    lastSignOutToken = accessToken;
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {
    resendCalls += 1;
    lastResendEmail = email;
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    passwordResetCalls += 1;
    lastPasswordResetEmail = email;
  }

  @override
  Future<SupabaseAuthSession> completeAuthCallback({
    required String accessToken,
    required String refreshToken,
  }) async {
    callbackCalls += 1;
    lastCallbackAccessToken = accessToken;
    lastCallbackRefreshToken = refreshToken;
    return SupabaseAuthSession(
      userId: 'callback-user',
      email: 'callback@example.com',
      accessToken: accessToken,
      displayName: 'callback@example.com',
      isAnonymous: false,
      projectUrl: 'https://example.supabase.co',
    );
  }
}

class _FakeSupabaseDataGateway implements SupabaseDataGateway {
  _FakeSupabaseDataGateway({required this.session, this.postError});

  final SupabaseAuthSession? session;
  final Object? postError;
  String? lastPostPath;
  List<Map<String, dynamic>> lastPostedRows = const [];

  @override
  SupabaseConfig get config => const SupabaseConfig(
    url: 'https://example.supabase.co',
    anonKey: 'anon-key',
    isEnabled: true,
  );

  @override
  bool get isConfigured => true;

  @override
  Future<SupabaseAuthSession?> currentSession() async => session;

  @override
  Future<SupabaseAuthSession> ensureAnonymousSession() async {
    return session ??
        const SupabaseAuthSession(
          userId: 'anonymous-user',
          email: null,
          accessToken: 'anonymous-token',
          displayName: 'Anonymous Collector',
          isAnonymous: true,
          projectUrl: 'https://example.supabase.co',
        );
  }

  @override
  Future<SupabaseAuthSession> signInAnonymously() async {
    return ensureAnonymousSession();
  }

  @override
  Future<SupabaseAuthSession> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return SupabaseAuthSession(
      userId: 'email-user',
      email: email,
      accessToken: 'email-token',
      displayName: email,
      isAnonymous: false,
      projectUrl: 'https://example.supabase.co',
    );
  }

  @override
  Future<SupabaseAuthSession> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    return SupabaseAuthSession(
      userId: 'new-email-user',
      email: email,
      accessToken: 'new-email-token',
      displayName: email,
      isAnonymous: false,
      projectUrl: 'https://example.supabase.co',
    );
  }

  @override
  Future<void> signOut(String accessToken) async {}

  @override
  Future<void> resendEmailConfirmation({required String email}) async {}

  @override
  Future<void> resetPasswordForEmail({required String email}) async {}

  @override
  Future<SupabaseAuthSession> completeAuthCallback({
    required String accessToken,
    required String refreshToken,
  }) async {
    return SupabaseAuthSession(
      userId: 'callback-user',
      email: 'callback@example.com',
      accessToken: accessToken,
      displayName: 'callback@example.com',
      isAnonymous: false,
      projectUrl: 'https://example.supabase.co',
    );
  }

  @override
  Future<Response<T>> authenticatedGetWithSession<T>(
    String path, {
    required SupabaseAuthSession session,
    Map<String, dynamic>? queryParameters,
  }) async {
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: <dynamic>[] as T,
      statusCode: 200,
    );
  }

  @override
  Future<Response<T>> authenticatedPostWithSession<T>(
    String path, {
    required SupabaseAuthSession session,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final error = postError;
    if (error != null) {
      throw error;
    }

    lastPostPath = path;
    lastPostedRows = (data as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: <dynamic>[] as T,
      statusCode: 200,
    );
  }
}

class _FakeAuthDeepLinkPlatform implements AuthDeepLinkPlatform {
  _FakeAuthDeepLinkPlatform({this.initialLink});

  final String? initialLink;
  Future<void> Function(String link)? handler;

  @override
  Future<String?> getInitialLink() async => initialLink;

  @override
  void setLinkHandler(Future<void> Function(String link) handler) {
    this.handler = handler;
  }
}

class _ScriptedAuthRepository implements AuthRepository {
  _ScriptedAuthRepository({
    this.initialUser,
    this.emailUser,
    this.signUpUser,
    this.signInCompleter,
    this.signInError,
    this.signUpError,
    this.resendError,
    this.passwordResetError,
    this.currentUserError,
  });

  final AppUser? initialUser;
  final AppUser? emailUser;
  final AppUser? signUpUser;
  final Completer<AppUser>? signInCompleter;
  final Object? signInError;
  final Object? signUpError;
  final Object? resendError;
  final Object? passwordResetError;
  final Object? currentUserError;
  var signInCalls = 0;
  var signUpCalls = 0;
  var resendCalls = 0;
  var passwordResetCalls = 0;
  String? lastResendEmail;
  String? lastPasswordResetEmail;
  var signOutCalls = 0;

  static const _localUser = AppUser(
    id: 'local-anonymous-user',
    displayName: 'Local Collector',
    email: null,
    isAnonymous: true,
    isLocalOnly: true,
    provider: AuthProviderType.localAnonymous,
  );

  @override
  Future<AppUser?> currentUser() async {
    final error = currentUserError;
    if (error != null) {
      throw error;
    }
    return initialUser ?? _localUser;
  }

  @override
  Future<AppUser> signIn() async => _localUser;

  @override
  Future<AppUser> signInAnonymously() async => _localUser;

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    signInCalls += 1;
    final error = signInError;
    if (error != null) {
      throw error;
    }
    final completer = signInCompleter;
    if (completer != null) {
      return completer.future;
    }
    return emailUser ??
        AppUser(
          id: 'email-user',
          displayName: email,
          email: email,
          provider: AuthProviderType.emailPassword,
        );
  }

  @override
  Future<AppUser> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    signUpCalls += 1;
    final error = signUpError;
    if (error != null) {
      throw error;
    }
    return signUpUser ??
        AppUser(
          id: 'new-email-user',
          displayName: email,
          email: email,
          provider: AuthProviderType.emailPassword,
        );
  }

  @override
  Future<void> resendEmailConfirmation({required String email}) async {
    resendCalls += 1;
    lastResendEmail = email;
    final error = resendError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    passwordResetCalls += 1;
    lastPasswordResetEmail = email;
    final error = passwordResetError;
    if (error != null) {
      throw error;
    }
  }

  @override
  Future<AppUser> signInWithGoogle() {
    throw const AuthException('Google sign-in is coming soon.');
  }

  @override
  Future<AppUser> signInWithApple() {
    throw const AuthException('Apple sign-in is coming soon.');
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }
}
