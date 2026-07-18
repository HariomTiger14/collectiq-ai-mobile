abstract interface class GuestModeRepository {
  const GuestModeRepository();

  Future<bool> hasChosenGuestMode();

  Future<void> setGuestModeChosen(bool chosen);
}
