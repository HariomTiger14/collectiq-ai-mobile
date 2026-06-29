/// Domain model for a future authenticated CollectIQ user.
class AppUser {
  /// Creates an immutable app user.
  const AppUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.isAnonymous = false,
  });

  /// Stable user identifier from the auth provider.
  final String id;

  /// Display name shown in account surfaces.
  final String displayName;

  /// User email address, when available.
  final String? email;

  /// Whether this is an anonymous/local placeholder account.
  final bool isAnonymous;
}
