import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_profile_sync_service.dart';
import 'package:collectiq_ai/core/cloud/services/noop_cloud_services.dart';
import 'package:collectiq_ai/core/config/app_environment.dart';
import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';
import 'package:collectiq_ai/features/profile/domain/repositories/profile_repository.dart';
import 'package:collectiq_ai/features/profile/presentation/controllers/profile_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('build merges the cloud profile over the local cache', () async {
    final repo = _FakeProfileRepository(
      const CollectorProfile(displayName: 'Local Name'),
    );
    final sync = _FakeProfileSync(
      snapshot: const CloudProfileSnapshot(displayName: 'Cloud Name'),
    );
    final container = _container(repo, sync);

    final profile = await container.read(profileControllerProvider.future);

    expect(profile.displayName, 'Cloud Name');
    expect(repo.saved.last.displayName, 'Cloud Name');
  });

  test('build seeds the cloud when there is no cloud record yet', () async {
    final repo = _FakeProfileRepository(
      const CollectorProfile(displayName: 'Local Name'),
    );
    final sync = _FakeProfileSync(snapshot: null);
    final container = _container(repo, sync);

    final profile = await container.read(profileControllerProvider.future);
    // Let the fire-and-forget seed push run.
    await Future<void>.delayed(Duration.zero);

    expect(profile.displayName, 'Local Name');
    expect(sync.pushes, hasLength(1));
    expect(sync.pushes.single.uploadAvatar, isTrue);
  });

  test('updateDisplayName saves locally and pushes to cloud', () async {
    final repo = _FakeProfileRepository(
      const CollectorProfile(displayName: 'Old'),
    );
    final sync = _FakeProfileSync(snapshot: null);
    final container = _container(repo, sync);
    await container.read(profileControllerProvider.future);
    sync.pushes.clear();

    await container
        .read(profileControllerProvider.notifier)
        .updateDisplayName('New');
    await Future<void>.delayed(Duration.zero);

    expect(repo.saved.last.displayName, 'New');
    expect(sync.pushes, hasLength(1));
    expect(sync.pushes.single.profile.displayName, 'New');
    expect(sync.pushes.single.uploadAvatar, isFalse);
  });

  test('updateAvatar pushes with uploadAvatar=true', () async {
    final repo = _FakeProfileRepository(
      const CollectorProfile(displayName: 'Name'),
    );
    final sync = _FakeProfileSync(snapshot: null);
    final container = _container(repo, sync);
    await container.read(profileControllerProvider.future);
    sync.pushes.clear();

    await container
        .read(profileControllerProvider.notifier)
        .updateAvatar('/tmp/new-avatar.jpg');
    await Future<void>.delayed(Duration.zero);

    expect(sync.pushes, hasLength(1));
    expect(sync.pushes.single.uploadAvatar, isTrue);
  });
}

ProviderContainer _container(
  ProfileRepository repo,
  CloudProfileSyncService sync,
) {
  final container = ProviderContainer(
    overrides: [
      profileRepositoryProvider.overrideWithValue(repo),
      cloudServiceRegistryProvider.overrideWithValue(_registry(sync)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

CloudServiceRegistry _registry(CloudProfileSyncService profileSync) {
  return CloudServiceRegistry(
    config: const EnvironmentConfig(environment: AppEnvironment.dev),
    authService: const NoOpAuthService(),
    cloudStorageService: const NoOpCloudStorageService(),
    cloudPortfolioSyncService: const NoOpCloudPortfolioSyncService(),
    cloudProfileSyncService: profileSync,
    analyticsService: const NoOpAnalyticsService(),
    crashReportingService: const NoOpCrashReportingService(),
    remoteConfigService: const NoOpRemoteConfigService(),
  );
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this._profile);

  CollectorProfile _profile;
  final List<CollectorProfile> saved = [];

  @override
  Future<CollectorProfile> loadProfile() async => _profile;

  @override
  Future<CollectorProfile> saveProfile(CollectorProfile profile) async {
    _profile = profile;
    saved.add(profile);
    return profile;
  }

  @override
  Future<CollectorProfile> saveAvatarFromPath(String sourcePath) async {
    _profile = _profile.copyWith(avatarPath: sourcePath);
    saved.add(_profile);
    return _profile;
  }
}

class _FakeProfileSync implements CloudProfileSyncService {
  _FakeProfileSync({this.snapshot});

  CloudProfileSnapshot? snapshot;
  final List<({CollectorProfile profile, bool uploadAvatar})> pushes = [];

  @override
  String get providerName => 'fake';

  @override
  Future<void> pushProfile(
    CollectorProfile profile, {
    bool uploadAvatar = false,
  }) async {
    pushes.add((profile: profile, uploadAvatar: uploadAvatar));
  }

  @override
  Future<CloudProfileSnapshot?> fetchProfile() async => snapshot;
}
