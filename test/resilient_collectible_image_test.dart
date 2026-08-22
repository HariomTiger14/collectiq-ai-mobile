import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_storage_service.dart';
import 'package:collectiq_ai/core/cloud/services/noop_cloud_services.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/ui/portfolio/resilient_collectible_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'falls back to a cloud-resolved image when the local file does not '
    'exist (real bug: after any reinstall -- or a fresh scan whose upload '
    'raced ahead of the display -- the recorded local path no longer '
    'resolves to a real file, and the widget used to have nothing else to '
    'try, showing "Preview unavailable" even though the image was safely '
    'in the cloud)',
    (tester) async {
      final storage = _RecordingCloudStorageService(
        urlForPath: {
          'users/u/portfolio_images/item-1.jpg': 'https://example.test/item-1.jpg',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudServiceRegistryProvider.overrideWithValue(
              _registryWithStorage(storage),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ResilientCollectibleImage(
                localPath: '/no/such/file/on/disk.jpg',
                storagePath: 'users/u/portfolio_images/item-1.jpg',
              ),
            ),
          ),
        ),
      );
      // Local-file check happens synchronously in build; the cloud
      // resolution is async, so pump once to let it complete.
      await tester.pump();

      expect(storage.requestedPaths, ['users/u/portfolio_images/item-1.jpg']);
      expect(find.byType(Image), findsOneWidget);
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://example.test/item-1.jpg',
      );
    },
  );

  testWidgets(
    'shows the placeholder, not a broken image, when there is no storage '
    'path to fall back to (a genuinely local-only item, e.g. never '
    'signed in)',
    (tester) async {
      final storage = _RecordingCloudStorageService(urlForPath: const {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cloudServiceRegistryProvider.overrideWithValue(
              _registryWithStorage(storage),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ResilientCollectibleImage(
                localPath: '/no/such/file/on/disk.jpg',
                placeholderBuilder: () =>
                    const Icon(key: ValueKey('custom-placeholder'), Icons.star),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(storage.requestedPaths, isEmpty);
      expect(find.byKey(const ValueKey('custom-placeholder')), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    },
  );
}

CloudServiceRegistry _registryWithStorage(CloudStorageService storage) {
  return CloudServiceRegistry(
    config: const EnvironmentConfig(environment: AppEnvironment.local),
    authService: const NoOpAuthService(),
    cloudStorageService: storage,
    cloudPortfolioSyncService: const NoOpCloudPortfolioSyncService(),
    cloudProfileSyncService: const NoOpCloudProfileSyncService(),
    analyticsService: const NoOpAnalyticsService(),
    crashReportingService: const NoOpCrashReportingService(),
    remoteConfigService: const NoOpRemoteConfigService(),
  );
}

class _RecordingCloudStorageService implements CloudStorageService {
  _RecordingCloudStorageService({required this.urlForPath});

  final Map<String, String> urlForPath;
  final List<String> requestedPaths = [];

  @override
  String get providerName => 'Recording Fake';

  @override
  Future<CloudStorageUploadResult?> uploadImage({
    required String localPath,
    required String destinationPath,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteImage(String path) async {}

  @override
  Future<String?> getImageUrl(String path) async {
    requestedPaths.add(path);
    return urlForPath[path];
  }
}
