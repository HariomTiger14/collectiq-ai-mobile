import 'package:collectiq_ai/features/auth/data/repositories/shared_preferences_guest_mode_repository.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/guest_mode_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final guestModeRepositoryProvider = Provider<GuestModeRepository>((ref) {
  return const SharedPreferencesGuestModeRepository();
});

final guestModeControllerProvider =
    AsyncNotifierProvider<GuestModeController, bool>(GuestModeController.new);

class GuestModeController extends AsyncNotifier<bool> {
  GuestModeRepository get _repository => ref.read(guestModeRepositoryProvider);

  @override
  Future<bool> build() {
    return _repository.hasChosenGuestMode();
  }

  Future<void> chooseGuestMode() async {
    await _repository.setGuestModeChosen(true);
    state = const AsyncValue.data(true);
  }

  Future<void> reset() async {
    await _repository.setGuestModeChosen(false);
    state = const AsyncValue.data(false);
  }
}
