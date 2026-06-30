/// Domain model for a CollectIQ auth identity.
class AuthUser {
  /// Creates an immutable app user.
  const AuthUser({
    required this.id,
    required this.displayName,
    required this.email,
    this.isAnonymous = false,
    this.isLocalOnly = false,
    this.provider = AuthProviderType.localAnonymous,
  });

  /// Stable user identifier from the auth provider.
  final String id;

  /// Display name shown in account surfaces.
  final String displayName;

  /// User email address, when available.
  final String? email;

  /// Whether this is an anonymous/local placeholder account.
  final bool isAnonymous;

  /// Whether this identity exists only on the device.
  final bool isLocalOnly;

  /// Auth provider that produced this user.
  final AuthProviderType provider;

  /// Whether this is a real cloud-backed account.
  bool get isCloudBacked => !isLocalOnly;
}

/// Backward-compatible app user name used by existing features.
typedef AppUser = AuthUser;

/// Supported auth providers and placeholders.
enum AuthProviderType {
  /// Device-only local account used by default.
  localAnonymous,

  /// Supabase anonymous session.
  supabaseAnonymous,

  /// Future email/password provider.
  emailPassword,

  /// Future Google sign-in provider.
  google,

  /// Future Apple sign-in provider.
  apple;

  /// Human-readable label for settings/debug surfaces.
  String get displayName {
    return switch (this) {
      AuthProviderType.localAnonymous => 'Local Anonymous',
      AuthProviderType.supabaseAnonymous => 'Supabase Anonymous',
      AuthProviderType.emailPassword => 'Email / Password',
      AuthProviderType.google => 'Google',
      AuthProviderType.apple => 'Apple',
    };
  }

  /// Whether this provider is implemented in the mobile app today.
  bool get isAvailable {
    return switch (this) {
      AuthProviderType.localAnonymous ||
      AuthProviderType.supabaseAnonymous ||
      AuthProviderType.emailPassword => true,
      AuthProviderType.google || AuthProviderType.apple => false,
    };
  }

  /// Safe status label for settings.
  String get statusLabel => isAvailable ? 'Ready' : 'Coming soon';
}
