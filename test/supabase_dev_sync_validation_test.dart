import 'package:collectiq_ai/core/cloud/cloud_app_startup.dart';
import 'package:collectiq_ai/core/cloud/cloud_portfolio_sync_coordinator.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/cloud_storage_paths.dart';
import 'package:collectiq_ai/core/cloud/services/analytics_service.dart';
import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:collectiq_ai/core/cloud/services/noop_cloud_services.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_bootstrap.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/config/feature_flags.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Supabase DEV sync validation contract', () {
    test('required DEV flags select Supabase registry services', () {
      final flags = FeatureFlags.fromRawMap(const {
        'USE_CLOUD_AUTH': 'true',
        'USE_CLOUD_PORTFOLIO_SYNC': 'true',
        'USE_CLOUD_IMAGE_STORAGE': 'true',
      });
      final config = EnvironmentConfig.fromValues(
        appEnvironment: 'dev',
        featureFlags: flags,
      );

      final registry = CloudServiceRegistry.fromConfig(config);

      expect(config.environment, AppEnvironment.dev);
      expect(config.featureFlags.useCloudAuth, isTrue);
      expect(config.featureFlags.useCloudPortfolioSync, isTrue);
      expect(config.featureFlags.useCloudImageStorage, isTrue);
      expect(registry.authService.providerName, 'Supabase Auth');
      expect(registry.cloudStorageService.providerName, 'Supabase Storage');
      expect(
        registry.cloudPortfolioSyncService.providerName,
        'Supabase Portfolio Sync',
      );
    });

    test('missing Supabase URL or anon key disables safely in DEV', () async {
      final bootstrap = SupabaseBootstrap(
        config: const EnvironmentConfig(
          environment: AppEnvironment.dev,
          featureFlags: FeatureFlags(
            useCloudAuth: true,
            useCloudPortfolioSync: true,
            useCloudImageStorage: true,
          ),
        ),
        url: '',
        anonKey: '',
      );

      final result = await bootstrap.ensureInitialized();

      expect(result.status, SupabaseBootstrapStatus.missingConfig);
      expect(result.isInitialized, isFalse);
    });

    test(
      'production with Supabase flags falls back safely when config is missing',
      () async {
        final bootstrap = SupabaseBootstrap(
          config: const EnvironmentConfig(
            environment: AppEnvironment.prod,
            featureFlags: FeatureFlags(
              useCloudAuth: true,
              useCloudPortfolioSync: true,
              useCloudImageStorage: true,
            ),
          ),
          url: '',
          anonKey: '',
        );

        final result = await bootstrap.ensureInitialized();
        final registry = CloudServiceRegistry.fromConfig(bootstrap.config);

        expect(result.status, SupabaseBootstrapStatus.missingConfig);
        expect(registry.authService.providerName, 'Supabase Auth');
        expect(registry.cloudStorageService.providerName, 'Supabase Storage');
        expect(
          registry.cloudPortfolioSyncService.providerName,
          'Supabase Portfolio Sync',
        );
      },
    );

    test('storage path matches DEV bucket object convention', () {
      final path = CloudStoragePaths.portfolioImage(
        userId: 'Dev_User_123',
        itemId: 'Item One',
      );

      expect(path, 'users/dev_user_123/portfolio_images/item-one.jpg');
    });

    test('portfolio_items row contains expected insert and update fields', () {
      final row = supabaseRowForItem(
        _item().copyWithCloudSync(
          imageStoragePath: 'users/dev-user/portfolio_images/item-1.jpg',
          cloudImageUrl:
              'https://dev-project.supabase.co/storage/v1/object/sign/collectiq-portfolio-images/users/dev-user/portfolio_images/item-1.jpg',
          syncStatus: CloudItemSyncStatus.pendingUpload,
        ),
        'dev-user',
      );

      expect(row['id'], 'item-1');
      expect(row['user_id'], 'dev-user');
      expect(row['category'], 'Trading Card');
      expect(row['title'], 'Camera Card');
      expect(row['manufacturer'], 'Pokemon');
      expect(row['series'], 'Base Set');
      expect(row['year'], 1999);
      expect(row['country'], 'United States');
      expect(row['estimated_value_low'], 40);
      expect(row['estimated_value_high'], 60);
      expect(row['cloud_image_url'], contains('portfolio_images/item-1.jpg'));
      expect(row['sync_status'], 'pendingUpload');
      expect(row['raw_json'], isA<Map<String, dynamic>>());
      expect(row.keys, containsAll(['created_at', 'updated_at']));
    });

    test('anonymous auth startup succeeds before sync status check', () async {
      final auth = _RecordingAuthService();
      final sync = _RecordingPortfolioSyncService(auth: auth);
      final analytics = _RecordingAnalyticsService();

      await CloudAppStartup(
        registry: _registry(
          authService: auth,
          syncService: sync,
          analyticsService: analytics,
        ),
      ).run();

      expect(auth.signInCount, 1);
      expect(await auth.currentUserId(), 'dev-user');
      expect(sync.statusChecks, 1);
      expect(analytics.events, contains('anonymous_auth_success'));
    });

    test('auth failure falls back safely without throwing', () async {
      final auth = _RecordingAuthService(shouldFail: true);
      final analytics = _RecordingAnalyticsService();

      await CloudAppStartup(
        registry: _registry(authService: auth, analyticsService: analytics),
      ).run();

      expect(auth.signInCount, 1);
      expect(await auth.currentUserId(), isNull);
      expect(analytics.events, contains('anonymous_auth_failed'));
    });

    test(
      'DEV coordinator uploads image then syncs portfolio metadata',
      () async {
        final repository = _MemoryPortfolioRepository([_item()]);
        final storage = _RecordingStorageService();
        final sync = _RecordingPortfolioSyncService();

        await CloudPortfolioSyncCoordinator(
          registry: _registry(storageService: storage, syncService: sync),
          portfolioRepository: repository,
        ).syncPendingItems();

        final item = repository.items.single;
        expect(storage.uploadCount, 1);
        expect(
          storage.lastDestinationPath,
          'users/dev-user/portfolio_images/item-1.jpg',
        );
        expect(sync.syncedItems, hasLength(1));
        expect(sync.syncedItems.single.cloudImageUrl, storage.publicUrl);
        expect(item.syncStatus, CloudItemSyncStatus.synced);
        expect(item.imagePath, 'test/fixtures/persistent-camera-card.jpg');
        expect(item.cloudImageUrl, storage.publicUrl);
        expect(item.lastSyncedAt, isNotNull);
      },
    );

    test('sync failure keeps item local and records retryable state', () async {
      final repository = _MemoryPortfolioRepository([_item()]);
      final storage = _RecordingStorageService(shouldFail: true);
      final sync = _RecordingPortfolioSyncService();

      await CloudPortfolioSyncCoordinator(
        registry: _registry(storageService: storage, syncService: sync),
        portfolioRepository: repository,
      ).syncPendingItems();

      final item = repository.items.single;
      expect(storage.uploadCount, 1);
      expect(sync.syncedItems, isEmpty);
      expect(item.imagePath, 'test/fixtures/persistent-camera-card.jpg');
      expect(item.syncStatus, CloudItemSyncStatus.failed);
      expect(item.syncError, contains('Supabase Storage upload failed'));
    });
  });
}

CloudServiceRegistry _registry({
  AuthService? authService,
  CloudStorageService storageService = const NoOpCloudStorageService(),
  CloudPortfolioSyncService? syncService,
  AnalyticsService analyticsService = const NoOpAnalyticsService(),
}) {
  final auth = authService ?? _RecordingAuthService(signedIn: true);
  return CloudServiceRegistry(
    config: const EnvironmentConfig(
      environment: AppEnvironment.dev,
      featureFlags: FeatureFlags(
        useCloudAuth: true,
        useCloudPortfolioSync: true,
        useCloudImageStorage: true,
      ),
    ),
    authService: auth,
    cloudStorageService: storageService,
    cloudPortfolioSyncService:
        syncService ?? _RecordingPortfolioSyncService(auth: auth),
    analyticsService: analyticsService,
    crashReportingService: const NoOpCrashReportingService(),
    remoteConfigService: const NoOpRemoteConfigService(),
  );
}

CollectibleItem _item() {
  return CollectibleItem(
    id: 'item-1',
    title: 'Camera Card',
    category: 'Trading Card',
    estimatedValue: 50,
    confidence: 0.8,
    condition: 'Good',
    recommendation: 'Keep protected.',
    imagePath: 'test/fixtures/persistent-camera-card.jpg',
    createdAt: DateTime.parse('2026-06-29T00:00:00Z'),
    brand: 'Pokemon',
    series: 'Base Set',
    year: '1999',
    country: 'United States',
    pricing: const PricingInfo(
      estimatedMarketValue: 50,
      lowEstimate: 40,
      highEstimate: 60,
      currency: 'AUD',
      pricingSource: 'Mock market blend',
      pricingConfidence: 0.8,
      lastUpdated: null,
    ),
  );
}

class _MemoryPortfolioRepository implements PortfolioRepository {
  _MemoryPortfolioRepository(this.items);

  final List<CollectibleItem> items;

  @override
  Future<CollectibleItem> addItem(CollectibleItem item) async {
    items
      ..removeWhere((existing) => existing.id == item.id)
      ..add(item);
    return item;
  }

  @override
  Future<void> upsertSyncedItem(CollectibleItem item) async {
    await updateItem(item);
  }

  @override
  Future<void> updateItem(CollectibleItem item) async {
    items
      ..removeWhere((existing) => existing.id == item.id)
      ..add(item);
  }

  @override
  Future<List<CollectibleItem>> getItems() async => List.of(items);

  @override
  Future<void> removeItem(String id) async {
    items.removeWhere((item) => item.id == id);
  }

  @override
  Future<void> updateItemImageSync({
    required String itemId,
    required String imageStoragePath,
    required String cloudImageUrl,
  }) async {
    final item = items.singleWhere((item) => item.id == itemId);
    await updateItem(
      item.copyWithImageSync(
        imageStoragePath: imageStoragePath,
        cloudImageUrl: cloudImageUrl,
      ),
    );
  }

  @override
  Future<void> clearPortfolio() async {
    items.clear();
  }
}

class _RecordingAuthService implements AuthService {
  _RecordingAuthService({this.shouldFail = false, this.signedIn = false});

  final bool shouldFail;
  bool signedIn;
  int signInCount = 0;

  @override
  String get providerName => 'Supabase Auth';

  @override
  Future<CloudAuthUser?> currentUser() async {
    if (!signedIn) {
      return null;
    }
    return const CloudAuthUser(id: 'dev-user', isAnonymous: true);
  }

  @override
  Future<String?> currentUserId() async {
    return (await currentUser())?.id;
  }

  @override
  Future<bool> isSignedIn() async {
    return signedIn;
  }

  @override
  Future<CloudAuthUser> signInAnonymously() async {
    signInCount += 1;
    if (shouldFail) {
      throw StateError('Supabase Auth failed');
    }
    signedIn = true;
    return const CloudAuthUser(id: 'dev-user', isAnonymous: true);
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
  }
}

class _RecordingStorageService implements CloudStorageService {
  _RecordingStorageService({this.shouldFail = false});

  final bool shouldFail;
  int uploadCount = 0;
  String? lastDestinationPath;
  final publicUrl = 'https://cdn.example.com/item-1.jpg';

  @override
  String get providerName => 'Supabase Storage';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    uploadCount += 1;
    lastDestinationPath = destinationPath;
    if (shouldFail) {
      throw StateError('Supabase Storage upload failed');
    }
    return CloudStorageUploadResult(
      path: destinationPath,
      publicUrl: publicUrl,
    );
  }

  @override
  Future<void> deleteImage(String path) async {}

  @override
  Future<String?> getImageUrl(String path) async => publicUrl;
}

class _RecordingPortfolioSyncService implements CloudPortfolioSyncService {
  _RecordingPortfolioSyncService({AuthService? auth})
    : auth = auth ?? _RecordingAuthService(signedIn: true);

  final AuthService auth;
  final List<CollectibleItem> syncedItems = [];
  int statusChecks = 0;

  @override
  String get providerName => 'Supabase Portfolio Sync';

  @override
  Future<void> syncItem(CollectibleItem item) async {
    syncedItems.add(item);
  }

  @override
  Future<void> deleteItem(String itemId) async {}

  @override
  Future<List<CollectibleItem>> fetchItems() async => syncedItems;

  @override
  Future<CollectibleItem> markSynced(CollectibleItem item) async {
    return item.copyWithCloudSync(
      syncStatus: CloudItemSyncStatus.synced,
      lastSyncedAt: DateTime.parse('2026-07-01T00:00:00Z'),
      clearSyncError: true,
    );
  }

  @override
  Future<CloudPortfolioSyncStatus> getSyncStatus() async {
    statusChecks += 1;
    final userId = await auth.currentUserId();
    return CloudPortfolioSyncStatus(
      enabled: userId != null,
      message: userId == null
          ? 'Cloud sync skipped: no signed-in Supabase user.'
          : 'Supabase portfolio sync ready.',
      userId: userId,
    );
  }
}

class _RecordingAnalyticsService implements AnalyticsService {
  final events = <String>[];

  @override
  String get providerName => 'No-op Analytics';

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    events.add(name);
  }
}
