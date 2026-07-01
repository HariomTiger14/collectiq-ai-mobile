import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import 'package:collectiq_ai/core/cloud/firebase/firebase_bootstrap.dart';
import 'package:collectiq_ai/core/cloud/services/auth_service.dart';

@Deprecated(
  'SupabaseAuthService is the primary DEV/STAGING auth implementation. '
  'Firebase auth is retained only for reference and should not be selected '
  'by CloudServiceRegistry.',
)
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({required this.bootstrap, this.auth});

  final FirebaseBootstrap bootstrap;
  final firebase_auth.FirebaseAuth? auth;

  firebase_auth.FirebaseAuth get _firebaseAuth =>
      auth ?? firebase_auth.FirebaseAuth.instance;

  @override
  String get providerName => 'Firebase Auth';

  @override
  Future<String?> currentUserId() async {
    final user = await currentUser();
    return user?.id;
  }

  @override
  Future<bool> isSignedIn() async {
    final user = await currentUser();
    return user != null;
  }

  @override
  Future<CloudAuthUser?> currentUser() async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return null;
    }
    return _mapUser(_firebaseAuth.currentUser);
  }

  @override
  Future<CloudAuthUser> signInAnonymously() async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      throw StateError(ready.message);
    }
    final credential = await _firebaseAuth.signInAnonymously();
    final user = _mapUser(credential.user);
    if (user == null) {
      throw StateError('Firebase anonymous sign-in returned no user.');
    }
    return user;
  }

  @override
  Future<void> signOut() async {
    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return;
    }
    await _firebaseAuth.signOut();
  }

  CloudAuthUser? _mapUser(firebase_auth.User? user) {
    if (user == null) {
      return null;
    }
    return CloudAuthUser(
      id: user.uid,
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
  }
}
