import 'package:collectiq_ai/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesOnboardingRepository implements OnboardingRepository {
  const SharedPreferencesOnboardingRepository();

  static const completedKey = 'onboarding_completed_v1';

  @override
  Future<bool> hasCompletedOnboarding() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(completedKey) ?? false;
  }

  @override
  Future<void> setOnboardingCompleted(bool completed) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(completedKey, completed);
  }
}
