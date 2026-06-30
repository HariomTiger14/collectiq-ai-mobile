abstract class OnboardingRepository {
  const OnboardingRepository();

  Future<bool> hasCompletedOnboarding();

  Future<void> setOnboardingCompleted(bool completed);
}
