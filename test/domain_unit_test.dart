import 'dart:io';
import 'dart:typed_data';

import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_schema.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:collectiq_ai/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/cloud_sync/data/repositories/mock_cloud_portfolio_repository.dart';
import 'package:collectiq_ai/features/cloud_sync/data/services/local_first_sync_service.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:collectiq_ai/features/cloud_sync/presentation/controllers/sync_controller.dart';
import 'package:collectiq_ai/features/ai/domain/entities/recognition_result.dart';
import 'package:collectiq_ai/features/image_storage/data/repositories/supabase_image_storage_repository.dart';
import 'package:collectiq_ai/features/portfolio/data/repositories/shared_preferences_portfolio_repository.dart';
import 'package:collectiq_ai/features/scanner/services/gallery_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  group('Supabase foundation', () {
    test('config remains disabled when environment is not provided', () {
      final config = SupabaseConfig.fromEnvironment();

      expect(config.isConfigured, isFalse);
      expect(config.url, isEmpty);
      expect(config.anonKey, isEmpty);
    });

    test('schema defines planned cloud tables', () {
      expect(
        SupabaseSchemaDefinition.tables.keys,
        containsAll([
          SupabaseTables.users,
          SupabaseTables.collections,
          SupabaseTables.collectibles,
          SupabaseTables.scanHistory,
          SupabaseTables.pricingSnapshots,
          SupabaseTables.favorites,
          SupabaseTables.wishlist,
        ]),
      );
      expect(
        SupabaseSchemaDefinition.tables[SupabaseTables.collectibles],
        contains('id uuid primary key'),
      );
    });

    test('migration enables RLS and owner-scoped policies', () {
      final migration = File(
        'supabase/migrations/202606290001_collectiq_cloud_schema.sql',
      ).readAsStringSync();

      for (final table in [
        'users',
        'collections',
        'collectibles',
        'scan_history',
        'pricing_snapshots',
        'favorites',
        'wishlist',
      ]) {
        expect(migration, contains('create table if not exists public.$table'));
        expect(
          migration,
          contains('alter table public.$table enable row level security'),
        );
      }

      expect(migration, contains('references auth.users(id)'));
      expect(migration, contains('function public.handle_new_auth_user()'));
      expect(migration, contains('on_auth_user_created'));
      expect(migration, contains('auth.uid() = user_id'));
      expect(migration, contains('auth.uid() = id'));
      expect(migration, contains('with check (auth.uid() = user_id)'));
    });

    test(
      'auth repository falls back to guest mode when not configured',
      () async {
        final service = SupabaseService.instance(
          config: const SupabaseConfig(url: '', anonKey: '', isEnabled: false),
        );
        final repository = SupabaseAuthRepository(supabaseService: service);

        expect(await repository.currentUser(), isNull);
        final user = await repository.signInAnonymously();

        expect(user.displayName, 'Local Collector');
        expect(user.isAnonymous, isTrue);
      },
    );

    test('image storage stays local when Supabase is not configured', () async {
      const repository = SupabaseImageStorageRepository(
        config: SupabaseConfig(url: '', anonKey: '', isEnabled: false),
      );

      final reference = await repository.uploadImage(
        localPath: 'test/fixtures/card.jpg',
        collectibleId: 'item-1',
      );

      expect(reference.isRemote, isFalse);
      expect(reference.path, 'test/fixtures/card.jpg');
      expect(reference.publicUrl, isNull);
    });
  });

  group('AuthController', () {
    test('starts in guest mode and supports optional mock sign in', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(container.read(authControllerProvider).isSignedIn, isFalse);
      expect(container.read(authControllerProvider).statusLabel, 'Guest mode');

      await container.read(authControllerProvider.notifier).signIn();

      final signedInState = container.read(authControllerProvider);
      expect(signedInState.isSignedIn, isTrue);
      expect(signedInState.user!.displayName, 'Local Collector');
      expect(signedInState.statusLabel, 'Signed in');

      await container.read(authControllerProvider.notifier).signOut();

      expect(container.read(authControllerProvider).isSignedIn, isFalse);
      expect(container.read(authControllerProvider).statusLabel, 'Guest mode');
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

    test(
      'uploadLocalItems keeps items pending while cloud backup is disabled',
      () async {
        const repository = MockCloudPortfolioRepository();

        final status = await repository.uploadLocalItems([_testItem()]);

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
  });

  group('SyncService', () {
    test('can mark local items as pending without cloud backup', () async {
      const repository = MockCloudPortfolioRepository();
      const service = LocalFirstSyncService(repository: repository);

      final status = await service.markPending([_testItem()]);

      expect(status.state, SyncState.pending);
      expect(status.pendingItemCount, 1);
      expect(status.isCloudBackupEnabled, isFalse);
    });
  });

  group('Local-first portfolio mode', () {
    test('saves portfolio items while no auth user is signed in', () async {
      SharedPreferences.setMockInitialValues({});
      const authRepository = MockAuthRepository();
      final portfolioRepository = SharedPreferencesPortfolioRepository();

      expect(await authRepository.currentUser(), isNull);

      await portfolioRepository.addItem(_testItem());
      final items = await portfolioRepository.getItems();

      expect(items, hasLength(1));
      expect(items.single.title, contains('Charizard'));
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
