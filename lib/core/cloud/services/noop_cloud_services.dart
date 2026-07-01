import 'analytics_service.dart';
import 'auth_service.dart';
import 'cloud_portfolio_sync_service.dart';
import 'cloud_storage_service.dart';
import 'crash_reporting_service.dart';
import 'remote_config_service.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';

class NoOpAuthService implements AuthService {
  const NoOpAuthService();

  @override
  String get providerName => 'No-op Auth';

  @override
  Future<String?> currentUserId() async {
    return 'local-user';
  }

  @override
  Future<bool> isSignedIn() async {
    return false;
  }

  @override
  Future<CloudAuthUser?> currentUser() async {
    return const CloudAuthUser(id: 'local-user', isAnonymous: true);
  }

  @override
  Future<CloudAuthUser> signInAnonymously() async {
    return const CloudAuthUser(id: 'local-user', isAnonymous: true);
  }

  @override
  Future<void> signOut() async {}
}

class NoOpCloudStorageService implements CloudStorageService {
  const NoOpCloudStorageService();

  @override
  String get providerName => 'No-op Cloud Storage';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    return null;
  }

  @override
  Future<void> deleteImage(String path) async {}

  @override
  Future<String?> getImageUrl(String path) async {
    return null;
  }
}

class NoOpCloudPortfolioSyncService implements CloudPortfolioSyncService {
  const NoOpCloudPortfolioSyncService();

  @override
  String get providerName => 'No-op Portfolio Sync';

  @override
  Future<void> syncItem(CollectibleItem item) async {}

  @override
  Future<void> deleteItem(String itemId) async {}

  @override
  Future<List<CollectibleItem>> fetchItems() async {
    return const [];
  }

  @override
  Future<CollectibleItem> markSynced(CollectibleItem item) async {
    return item;
  }

  @override
  Future<CloudPortfolioSyncStatus> getSyncStatus() async {
    return const CloudPortfolioSyncStatus(
      enabled: false,
      message: 'Cloud portfolio sync is not configured.',
    );
  }
}

class NoOpAnalyticsService implements AnalyticsService {
  const NoOpAnalyticsService();

  @override
  String get providerName => 'No-op Analytics';

  @override
  Future<void> trackEvent(
    String name, {
    Map<String, Object?> properties = const {},
  }) async {}
}

class NoOpCrashReportingService implements CrashReportingService {
  const NoOpCrashReportingService();

  @override
  String get providerName => 'No-op Crash Reporting';

  @override
  Future<void> recordNonFatalError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    Map<String, Object?> properties = const {},
  }) async {}
}

class NoOpRemoteConfigService implements RemoteConfigService {
  const NoOpRemoteConfigService({this.values = const {}});

  final Map<String, Object> values;

  @override
  String get providerName => 'No-op Remote Config';

  @override
  Future<void> refresh() async {}

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    final value = values[key];
    return value is bool ? value : defaultValue;
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    final value = values[key];
    return value is String ? value : defaultValue;
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    final value = values[key];
    return value is int ? value : defaultValue;
  }

  @override
  double getDouble(String key, {double defaultValue = 0}) {
    final value = values[key];
    return value is double ? value : defaultValue;
  }
}
