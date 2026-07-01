class CloudAuthUser {
  const CloudAuthUser({required this.id, this.email, this.isAnonymous = true});

  final String id;
  final String? email;
  final bool isAnonymous;
}

abstract interface class AuthService {
  String get providerName;

  Future<String?> currentUserId();

  Future<bool> isSignedIn();

  Future<CloudAuthUser?> currentUser();

  Future<CloudAuthUser> signInAnonymously();

  Future<void> signOut();
}
