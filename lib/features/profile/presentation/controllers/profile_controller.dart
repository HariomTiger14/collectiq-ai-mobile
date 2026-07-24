import 'package:collectiq_ai/features/profile/data/repositories/shared_preferences_profile_repository.dart';
import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';
import 'package:collectiq_ai/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return const SharedPreferencesProfileRepository();
});

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, CollectorProfile>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<CollectorProfile> {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<CollectorProfile> build() {
    return _repository.loadProfile();
  }

  Future<void> updateDisplayName(String displayName) async {
    final current = state.hasValue
        ? state.requireValue
        : await _repository.loadProfile();
    final saved = await _repository.saveProfile(
      current.copyWith(displayName: displayName),
    );
    state = AsyncValue.data(saved);
  }

  Future<void> updateAvatar(String sourcePath) async {
    final saved = await _repository.saveAvatarFromPath(sourcePath);
    state = AsyncValue.data(saved);
  }
}
