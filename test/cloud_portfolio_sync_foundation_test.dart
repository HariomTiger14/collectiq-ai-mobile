import 'package:flutter_test/flutter_test.dart';

import 'package:collectiq_ai/core/cloud/cloud_app_startup.dart';
import 'package:collectiq_ai/core/cloud/cloud_portfolio_sync_coordinator.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/services/analytics_service.dart';
import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:collectiq_ai/core/cloud/services/noop_cloud_services.dart';
import 'package:collectiq_ai/core/cloud/services/remote_config_service.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/config/feature_flags.dart';
import 'package:collectiq_ai/features/portfolio/domain/repositories/portfolio_repository.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

void main() {
  group('CloudAppStartup', () {
    test('local mode tracks app start but does not attempt auth', () async {
      final auth = _RecordingAuthService();
      final analytics = _RecordingAnalyticsService();

      await CloudAppStartup(
        registry: _registry(
          environment: AppEnvironment.local,
          authService: auth,
          analyticsService: analytics,
        ),
      ).run();

      expect(auth.signInCount, 0);
      expect(analytics.events, contains('app_started'));
      expect(analytics.events, isNot(contains('anonymous_auth_success')));
    });

    test('dev auth runs only when cloud auth flag is enabled', () async {
      final disabledAuth = _RecordingAuthService();
      await CloudAppStartup(
        registry: _registry(
          authService: disabledAuth,
          featureFlags: const FeatureFlags(
            useCloudAuth: false,
            useCloudPortfolioSync: true,
            useCloudImageStorage: true,
          ),
        ),
      ).run();
      expect(disabledAuth.signInCount, 0);

      final enabledAuth = _RecordingAuthService();
      final analytics = _RecordingAnalyticsService();
      await CloudAppStartup(
        registry: _registry(
          authService: enabledAuth,
          analyticsService: analytics,
        ),
      ).run();

      expect(enabledAuth.signInCount, 1);
      expect(analytics.events, contains('anonymous_auth_success'));
    });

    test('auth failure is logged and does not throw', () async {
      final auth = _RecordingAuthService(shouldFail: true);
      final analytics = _RecordingAnalyticsService();

      await CloudAppStartup(
        registry: _registry(authService: auth, analyticsService: analytics),
      ).run();

      expect(auth.signInCount, 1);
      expect(analytics.events, contains('anonymous_auth_failed'));
    });

    test(
      'dev cloud flags validate cloud sync availability at startup',
      () async {
        final remoteConfig = _RecordingRemoteConfigService();

        await CloudAppStartup(
          registry: _registry(
            featureFlags: const FeatureFlags(useAnalytics: true),
            remoteConfigService: remoteConfig,
          ),
        ).run();

        expect(remoteConfig.refreshCount, 1);
      },
    );
  });

  group('CloudPortfolioSyncCoordinator', () {
    test('local mode never calls cloud services', () async {
      final repository = _MemoryPortfolioRepository([_item()]);
      final storage = _RecordingStorageService();
      final sync = _RecordingPortfolioSyncService();
      final coordinator = CloudPortfolioSyncCoordinator(
        registry: _registry(
          environment: AppEnvironment.local,
          authService: const _SignedInAuthService(),
          storageService: storage,
          syncService: sync,
        ),
        portfolioRepository: repository,
      );

      await coordinator.syncPendingItems();

      expect(storage.uploadCount, 0);
      expect(sync.syncCount, 0);
      expect(repository.items.single.syncStatus, CloudItemSyncStatus.localOnly);
    });

    test('no user ID skips sync safely', () async {
      final repository = _MemoryPortfolioRepository([_item()]);
      final storage = _RecordingStorageService();
      final sync = _RecordingPortfolioSyncService();
      final coordinator = CloudPortfolioSyncCoordinator(
        registry: _registry(
          authService: const _SignedOutAuthService(),
          storageService: storage,
          syncService: sync,
        ),
        portfolioRepository: repository,
      );

      await coordinator.syncPendingItems();

      expect(storage.uploadCount, 0);
      expect(sync.syncCount, 0);
      expect(repository.items.single.syncStatus, CloudItemSyncStatus.localOnly);
    });

    test(
      'item remains local and metadata sync is skipped if upload fails',
      () async {
        final repository = _MemoryPortfolioRepository([_item()]);
        final storage = _RecordingStorageService(shouldFail: true);
        final sync = _RecordingPortfolioSyncService();
        final coordinator = CloudPortfolioSyncCoordinator(
          registry: _registry(storageService: storage, syncService: sync),
          portfolioRepository: repository,
        );

        await coordinator.syncPendingItems();

        final item = repository.items.single;
        expect(storage.uploadCount, 1);
        expect(sync.syncCount, 0);
        expect(item.imagePath, 'test/fixtures/persistent-camera-card.jpg');
        expect(item.syncStatus, CloudItemSyncStatus.failed);
        expect(item.syncError, contains('upload failed'));
      },
    );

    test('successful upload syncs metadata and marks item synced', () async {
      final repository = _MemoryPortfolioRepository([_item()]);
      final storage = _RecordingStorageService();
      final sync = _RecordingPortfolioSyncService();
      final coordinator = CloudPortfolioSyncCoordinator(
        registry: _registry(storageService: storage, syncService: sync),
        portfolioRepository: repository,
      );

      await coordinator.syncPendingItems();

      final item = repository.items.single;
      expect(storage.uploadCount, 1);
      expect(sync.syncCount, 1);
      expect(
        storage.lastDestinationPath,
        'users/dev-user/portfolio_images/item-1.jpg',
      );
      expect(
        sync.syncedItems.single.cloudImageUrl,
        'https://cdn.example.com/item-1.jpg',
      );
      expect(item.syncStatus, CloudItemSyncStatus.synced);
      expect(item.cloudImageUrl, 'https://cdn.example.com/item-1.jpg');
      expect(item.lastSyncedAt, isNotNull);
    });

    test(
      'manual sync downloads cloud items without deleting local items',
      () async {
        final repository = _MemoryPortfolioRepository([_item()]);
        final cloudItem = _cloudItem();
        final sync = _RecordingPortfolioSyncService(cloudItems: [cloudItem]);
        final coordinator = CloudPortfolioSyncCoordinator(
          registry: _registry(syncService: sync),
          portfolioRepository: repository,
        );

        final mergedCount = await coordinator.syncNow();

        expect(mergedCount, 1);
        expect(repository.items, hasLength(2));
        expect(
          repository.items
              .where((item) => item.id == 'cloud-item-1')
              .single
              .title,
          'Cloud Silver Eagle',
        );
        expect(
          repository.items
              .where((item) => item.id == 'cloud-item-1')
              .single
              .syncStatus,
          CloudItemSyncStatus.synced,
        );
      },
    );

    test('updated item is pushed to portfolio sync service', () async {
      final repository = _MemoryPortfolioRepository([_item()]);
      final sync = _RecordingPortfolioSyncService();
      final coordinator = CloudPortfolioSyncCoordinator(
        registry: _registry(syncService: sync),
        portfolioRepository: repository,
      );

      await coordinator.syncUpdatedItem(_item().copyWith(title: 'Edited Card'));

      expect(sync.syncCount, 1);
      expect(sync.syncedItems.single.title, 'Edited Card');
      expect(repository.items.single.syncStatus, CloudItemSyncStatus.synced);
    });

    test(
      'deleted item is tombstoned in cloud only when sync is available',
      () async {
        final repository = _MemoryPortfolioRepository([_item()]);
        final sync = _RecordingPortfolioSyncService();
        final coordinator = CloudPortfolioSyncCoordinator(
          registry: _registry(syncService: sync),
          portfolioRepository: repository,
        );

        await coordinator.deleteCloudItem('item-1');

        expect(sync.deletedItemIds, ['item-1']);
        expect(repository.items.single.id, 'item-1');
      },
    );
  });
}

CloudServiceRegistry _registry({
  AppEnvironment environment = AppEnvironment.dev,
  FeatureFlags featureFlags = const FeatureFlags(
    useCloudAuth: true,
    useCloudPortfolioSync: true,
    useCloudImageStorage: true,
  ),
  AuthService authService = const _SignedInAuthService(),
  CloudStorageService storageService = const NoOpCloudStorageService(),
  CloudPortfolioSyncService syncService = const NoOpCloudPortfolioSyncService(),
  AnalyticsService analyticsService = const NoOpAnalyticsService(),
  RemoteConfigService remoteConfigService = const NoOpRemoteConfigService(),
}) {
  return CloudServiceRegistry(
    config: EnvironmentConfig(
      environment: environment,
      featureFlags: featureFlags,
    ),
    authService: authService,
    cloudStorageService: storageService,
    cloudPortfolioSyncService: syncService,
    analyticsService: analyticsService,
    crashReportingService: const NoOpCrashReportingService(),
    remoteConfigService: remoteConfigService,
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
  );
}

CollectibleItem _cloudItem() {
  return CollectibleItem(
    id: 'cloud-item-1',
    title: 'Cloud Silver Eagle',
    category: 'Coin',
    estimatedValue: 120,
    confidence: 0.7,
    condition: 'Good',
    recommendation: 'Review synced collectible.',
    imagePath: 'https://cdn.example.com/cloud-item-1.jpg',
    createdAt: DateTime.parse('2026-06-30T00:00:00Z'),
    syncStatus: CloudItemSyncStatus.synced,
    lastSyncedAt: DateTime.parse('2026-06-30T01:00:00Z'),
  );
}

class _MemoryPortfolioRepository implements PortfolioRepository {
  _MemoryPortfolioRepository(this.items);

  final List<CollectibleItem> items;

  @override
  Future<CollectibleItem> addItem(CollectibleItem item) async {
    items.add(item);
    return item;
  }

  @override
  Future<void> upsertSyncedItem(CollectibleItem item) async {
    items
      ..removeWhere((existing) => existing.id == item.id)
      ..add(item);
  }

  @override
  Future<void> updateItem(CollectibleItem item) async {
    await upsertSyncedItem(item);
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
    await upsertSyncedItem(
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

class _RecordingStorageService implements CloudStorageService {
  _RecordingStorageService({this.shouldFail = false});

  final bool shouldFail;
  int uploadCount = 0;
  String? lastDestinationPath;

  @override
  String get providerName => 'Recording Storage';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    uploadCount += 1;
    lastDestinationPath = destinationPath;
    if (shouldFail) {
      throw StateError('upload failed');
    }
    return CloudStorageUploadResult(
      path: destinationPath,
      publicUrl: 'https://cdn.example.com/item-1.jpg',
    );
  }

  @override
  Future<void> deleteImage(String path) async {}

  @override
  Future<String?> getImageUrl(String path) async =>
      'https://cdn.example.com/item-1.jpg';
}

class _RecordingPortfolioSyncService implements CloudPortfolioSyncService {
  _RecordingPortfolioSyncService({this.cloudItems = const []});

  int syncCount = 0;
  final syncedItems = <CollectibleItem>[];
  final List<CollectibleItem> cloudItems;
  final deletedItemIds = <String>[];

  @override
  String get providerName => 'Recording Portfolio Sync';

  @override
  Future<void> syncItem(CollectibleItem item) async {
    syncCount += 1;
    syncedItems.add(item);
  }

  @override
  Future<void> deleteItem(String itemId) async {
    deletedItemIds.add(itemId);
  }

  @override
  Future<List<CollectibleItem>> fetchItems() async => cloudItems;

  @override
  Future<CollectibleItem> markSynced(CollectibleItem item) async {
    return item.copyWithCloudSync(
      syncStatus: CloudItemSyncStatus.synced,
      lastSyncedAt: DateTime.parse('2026-06-29T01:00:00Z'),
      clearSyncError: true,
    );
  }

  @override
  Future<CloudPortfolioSyncStatus> getSyncStatus() async {
    return const CloudPortfolioSyncStatus(
      enabled: true,
      message: 'Ready',
      userId: 'dev-user',
    );
  }
}

class _SignedInAuthService implements AuthService {
  const _SignedInAuthService();

  @override
  String get providerName => 'Signed-in Auth';

  @override
  Future<String?> currentUserId() async => 'dev-user';

  @override
  Future<bool> isSignedIn() async => true;

  @override
  Future<CloudAuthUser?> currentUser() async {
    return const CloudAuthUser(id: 'dev-user', isAnonymous: true);
  }

  @override
  Future<CloudAuthUser> signInAnonymously() async {
    return const CloudAuthUser(id: 'dev-user', isAnonymous: true);
  }

  @override
  Future<void> signOut() async {}
}

class _SignedOutAuthService implements AuthService {
  const _SignedOutAuthService();

  @override
  String get providerName => 'Signed-out Auth';

  @override
  Future<String?> currentUserId() async => null;

  @override
  Future<bool> isSignedIn() async => false;

  @override
  Future<CloudAuthUser?> currentUser() async => null;

  @override
  Future<CloudAuthUser> signInAnonymously() async {
    throw StateError('sign-in disabled for test');
  }

  @override
  Future<void> signOut() async {}
}

class _RecordingAuthService implements AuthService {
  _RecordingAuthService({this.shouldFail = false});

  final bool shouldFail;
  int signInCount = 0;
  bool signedIn = false;

  @override
  String get providerName => 'Recording Auth';

  @override
  Future<String?> currentUserId() async => signedIn ? 'dev-user' : null;

  @override
  Future<bool> isSignedIn() async => signedIn;

  @override
  Future<CloudAuthUser?> currentUser() async {
    return signedIn ? const CloudAuthUser(id: 'dev-user') : null;
  }

  @override
  Future<CloudAuthUser> signInAnonymously() async {
    signInCount += 1;
    if (shouldFail) {
      throw StateError('auth failed');
    }
    signedIn = true;
    return const CloudAuthUser(id: 'dev-user', isAnonymous: true);
  }

  @override
  Future<void> signOut() async {
    signedIn = false;
  }
}

class _RecordingAnalyticsService implements AnalyticsService {
  final events = <String>[];

  @override
  String get providerName => 'Recording Analytics';

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {
    events.add(name);
  }
}

class _RecordingRemoteConfigService implements RemoteConfigService {
  int refreshCount = 0;

  @override
  String get providerName => 'Recording Remote Config';

  @override
  Future<void> refresh() async {
    refreshCount += 1;
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) => defaultValue;

  @override
  String getString(String key, {String defaultValue = ''}) => defaultValue;

  @override
  int getInt(String key, {int defaultValue = 0}) => defaultValue;

  @override
  double getDouble(String key, {double defaultValue = 0}) => defaultValue;
}
