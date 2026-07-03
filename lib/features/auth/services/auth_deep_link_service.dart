import 'dart:async';

import 'package:collectiq_ai/core/config/environment_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_callback_result.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authDeepLinkPlatformProvider = Provider<AuthDeepLinkPlatform>((ref) {
  return const MethodChannelAuthDeepLinkPlatform();
});

final authDeepLinkCoordinatorProvider = Provider<AuthDeepLinkCoordinator>((
  ref,
) {
  return AuthDeepLinkCoordinator(ref: ref);
});

final authCallbackGatewayProvider = Provider<SupabaseAuthGateway>((ref) {
  return ref.watch(supabaseServiceProvider);
});

final authDeepLinkMetadataProvider =
    NotifierProvider<AuthDeepLinkMetadataController, AuthCallbackMetadata?>(
      AuthDeepLinkMetadataController.new,
    );

class AuthDeepLinkMetadataController extends Notifier<AuthCallbackMetadata?> {
  @override
  AuthCallbackMetadata? build() => null;

  void record(AuthCallbackMetadata metadata) {
    state = metadata;
  }
}

abstract interface class AuthDeepLinkPlatform {
  Future<String?> getInitialLink();

  void setLinkHandler(Future<void> Function(String link) handler);
}

class MethodChannelAuthDeepLinkPlatform implements AuthDeepLinkPlatform {
  const MethodChannelAuthDeepLinkPlatform();

  static const _channel = MethodChannel('collectiq_ai/auth_links');

  @override
  Future<String?> getInitialLink() async {
    try {
      return await _channel.invokeMethod<String>('getInitialLink');
    } on MissingPluginException {
      return null;
    }
  }

  @override
  void setLinkHandler(Future<void> Function(String link) handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'authLink') {
        return null;
      }
      final link = call.arguments;
      if (link is String && link.trim().isNotEmpty) {
        await handler(link);
      }
      return null;
    });
  }
}

class AuthDeepLinkCoordinator {
  AuthDeepLinkCoordinator({required this.ref});

  final Ref ref;
  bool _started = false;

  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    final platform = ref.read(authDeepLinkPlatformProvider);
    platform.setLinkHandler(handleLink);
    final initialLink = await platform.getInitialLink();
    if (initialLink != null && initialLink.trim().isNotEmpty) {
      await handleLink(initialLink);
    }
  }

  Future<void> handleLink(String rawLink) async {
    final environment = ref.read(environmentConfigProvider).environment;
    final result = AuthCallbackParser.parse(rawLink, environment: environment);
    ref
        .read(authDeepLinkMetadataProvider.notifier)
        .record(AuthCallbackParser.metadataFor(rawLink, result));
    if (result.status == AuthCallbackStatus.ignored) {
      return;
    }

    final authController = ref.read(authControllerProvider.notifier);
    switch (result.status) {
      case AuthCallbackStatus.signedIn:
        await _completeSignedInCallback(result, authController);
      case AuthCallbackStatus.confirmedNoSession:
        authController.applyEmailConfirmationWithoutSession();
      case AuthCallbackStatus.invalidOrExpired:
        authController.applyEmailConfirmationError(
          AuthMessages.confirmationLinkInvalid,
        );
      case AuthCallbackStatus.error:
        authController.applyEmailConfirmationError(
          AuthMessages.confirmationCallbackFailed,
        );
      case AuthCallbackStatus.ignored:
        break;
    }
  }

  Future<void> _completeSignedInCallback(
    AuthCallbackResult result,
    AuthController authController,
  ) async {
    try {
      final session = await ref
          .read(authCallbackGatewayProvider)
          .completeAuthCallback(
            accessToken: result.accessToken!,
            refreshToken: result.refreshToken!,
          );
      authController.applyEmailConfirmationSession(_userFromSession(session));
    } on Object catch (error) {
      debugPrint('[Auth callback] completion failed: ${error.runtimeType}');
      authController.applyEmailConfirmationError(
        AuthMessages.confirmationCallbackFailed,
      );
    }
  }

  AppUser _userFromSession(SupabaseAuthSession session) {
    return AppUser(
      id: session.userId,
      displayName: session.displayName,
      email: session.email,
      isAnonymous: session.isAnonymous,
      isLocalOnly: false,
      provider: session.isAnonymous
          ? AuthProviderType.supabaseAnonymous
          : AuthProviderType.emailPassword,
    );
  }
}
