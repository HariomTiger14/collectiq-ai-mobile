import 'package:collectiq_ai/core/cloud/services/auth_service.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/core/cloud/supabase/supabase_bootstrap.dart';

class SupabaseAuthService implements AuthService {
  SupabaseAuthService({required this.bootstrap, this.supabaseAuthGateway});

  final SupabaseBootstrap bootstrap;
  final SupabaseAuthGateway? supabaseAuthGateway;

  @override
  String get providerName => 'Supabase Auth';

  @override
  Future<String?> currentUserId() async {
    final user = await currentUser();
    return user?.id;
  }

  @override
  Future<bool> isSignedIn() async {
    return await currentUserId() != null;
  }

  @override
  Future<CloudAuthUser?> currentUser() async {
    final gatewayUser = await _currentGatewayUser();
    if (gatewayUser != null) {
      return gatewayUser;
    }

    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return null;
    }
    final user = bootstrap.client?.auth.currentUser;
    if (user == null) {
      return null;
    }
    return CloudAuthUser(
      id: user.id,
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
  }

  @override
  Future<CloudAuthUser> signInAnonymously() async {
    final gateway = supabaseAuthGateway;
    if (gateway != null && gateway.isConfigured) {
      final session = await gateway.signInAnonymously();
      return _userFromGatewaySession(session);
    }

    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      throw StateError(ready.message);
    }
    final response = await bootstrap.client!.auth.signInAnonymously();
    final user = response.user ?? bootstrap.client!.auth.currentUser;
    if (user == null) {
      throw StateError('Supabase anonymous sign-in returned no user.');
    }
    return CloudAuthUser(
      id: user.id,
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
  }

  @override
  Future<void> signOut() async {
    final gateway = supabaseAuthGateway;
    if (gateway != null && gateway.isConfigured) {
      final session = await gateway.currentSession();
      if (session != null && session.accessToken.isNotEmpty) {
        await gateway.signOut(session.accessToken);
      }
    }

    final ready = await bootstrap.ensureInitialized();
    if (!ready.isInitialized) {
      return;
    }
    await bootstrap.client!.auth.signOut();
  }

  Future<CloudAuthUser?> _currentGatewayUser() async {
    final gateway = supabaseAuthGateway;
    if (gateway == null || !gateway.isConfigured) {
      return null;
    }
    final session = await gateway.currentSession();
    if (session == null || session.accessToken.isEmpty || session.isAnonymous) {
      return null;
    }
    return _userFromGatewaySession(session);
  }

  CloudAuthUser _userFromGatewaySession(SupabaseAuthSession session) {
    return CloudAuthUser(
      id: session.userId,
      email: session.email,
      isAnonymous: session.isAnonymous,
    );
  }
}
