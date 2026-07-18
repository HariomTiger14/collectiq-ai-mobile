import 'package:collectiq_ai/features/auth/domain/repositories/guest_mode_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesGuestModeRepository implements GuestModeRepository {
  const SharedPreferencesGuestModeRepository();

  static const chosenKey = 'auth_guest_mode_chosen_v1';

  @override
  Future<bool> hasChosenGuestMode() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(chosenKey) ?? false;
  }

  @override
  Future<void> setGuestModeChosen(bool chosen) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(chosenKey, chosen);
  }
}
