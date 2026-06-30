import 'package:collectiq_ai/features/onboarding/data/repositories/shared_preferences_onboarding_repository.dart';
import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return const SharedPreferencesOnboardingRepository();
});

final onboardingControllerProvider =
    AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);

class OnboardingController extends AsyncNotifier<bool> {
  OnboardingRepository get _repository =>
      ref.read(onboardingRepositoryProvider);

  @override
  Future<bool> build() {
    return _repository.hasCompletedOnboarding();
  }

  Future<void> complete() async {
    state = const AsyncValue.data(true);
    await _repository.setOnboardingCompleted(true);
  }

  Future<void> reset() async {
    state = const AsyncValue.data(false);
    await _repository.setOnboardingCompleted(false);
  }
}
