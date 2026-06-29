import 'dart:typed_data';

import 'package:collectiq_ai/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:collectiq_ai/features/cloud_sync/data/repositories/mock_cloud_portfolio_repository.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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

  group('GalleryService', () {
    test('validates supported image extensions case-insensitively', () async {
      final service = GalleryService();

      for (final name in [
        'image.PNG',
        'image.Png',
        'image.jpg',
        'image.JPEG',
      ]) {
        final image = XFile.fromData(Uint8List.fromList([1, 2, 3]), path: name);

        await expectLater(service.validateImage(image), completion(isTrue));
      }
    });

    test('rejects unsupported image extension with clear message', () async {
      final service = GalleryService();
      final image = XFile.fromData(
        Uint8List.fromList([1, 2, 3]),
        path: 'image.gif',
      );

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
    test('defaults to no signed-in user for local-first mode', () async {
      const repository = MockAuthRepository();

      final user = await repository.currentUser();

      expect(user, isNull);
    });

    test('signIn returns mock anonymous user placeholder', () async {
      const repository = MockAuthRepository();

      final user = await repository.signIn();

      expect(user.id, 'mock-user');
      expect(user.displayName, 'Local Collector');
      expect(user.isAnonymous, isTrue);
    });
  });

  group('MockCloudPortfolioRepository', () {
    test('reports local-only sync status by default', () async {
      const repository = MockCloudPortfolioRepository();

      final status = await repository.getSyncStatus();

      expect(status.state, SyncState.localOnly);
      expect(status.statusLabel, 'Local only');
      expect(status.isCloudBackupEnabled, isFalse);
    });

    test('uploadLocalItems keeps items pending while cloud backup is disabled', () async {
      const repository = MockCloudPortfolioRepository();

      final status = await repository.uploadLocalItems([_testItem()]);

      expect(status.state, SyncState.localOnly);
      expect(status.pendingItemCount, 1);
      expect(status.isCloudBackupEnabled, isFalse);
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
  );
}
