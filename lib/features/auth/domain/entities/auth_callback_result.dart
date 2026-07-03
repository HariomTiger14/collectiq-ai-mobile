import 'package:collectiq_ai/core/config/app_environment.dart';

enum AuthCallbackStatus {
  ignored,
  signedIn,
  confirmedNoSession,
  invalidOrExpired,
  error,
}

class AuthCallbackResult {
  const AuthCallbackResult({
    required this.status,
    this.accessToken,
    this.refreshToken,
    this.type,
    this.tokenHash,
    this.error,
    this.errorDescription,
  });

  final AuthCallbackStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? type;
  final String? tokenHash;
  final String? error;
  final String? errorDescription;

  bool get hasSessionTokens =>
      accessToken != null &&
      accessToken!.isNotEmpty &&
      refreshToken != null &&
      refreshToken!.isNotEmpty;
}

class AuthCallbackMetadata {
  const AuthCallbackMetadata({
    required this.received,
    required this.result,
    required this.timestamp,
    this.scheme,
    this.host,
    this.path,
    this.queryKeys = const <String>[],
    this.errorMessage,
  });

  final bool received;
  final AuthCallbackStatus result;
  final DateTime timestamp;
  final String? scheme;
  final String? host;
  final String? path;
  final List<String> queryKeys;
  final String? errorMessage;

  String get receivedLabel => received ? 'Yes' : 'No';

  String get resultLabel => result.name;

  String get queryKeysLabel =>
      queryKeys.isEmpty ? 'none' : queryKeys.join(', ');
}

class AuthCallbackParser {
  const AuthCallbackParser._();

  static const sitRedirectUri = 'collectiq-sit://auth/callback';
  static const prodRedirectUri = 'collectiq://auth/callback';

  static AuthCallbackResult parse(
    String rawLink, {
    required AppEnvironment environment,
  }) {
    final uri = Uri.tryParse(rawLink.trim());
    if (uri == null) {
      return const AuthCallbackResult(status: AuthCallbackStatus.error);
    }

    final expectedScheme = switch (environment) {
      AppEnvironment.sit ||
      AppEnvironment.dev ||
      AppEnvironment.staging => 'collectiq-sit',
      AppEnvironment.prod => 'collectiq',
      AppEnvironment.local => 'collectiq-local',
    };
    if (uri.scheme == expectedScheme &&
        (uri.host != 'auth' || uri.path != '/callback') &&
        environment != AppEnvironment.local &&
        !environment.isProduction) {
      return const AuthCallbackResult(status: AuthCallbackStatus.error);
    }
    if (uri.host != 'auth' || uri.path != '/callback') {
      return const AuthCallbackResult(status: AuthCallbackStatus.ignored);
    }
    if (uri.scheme != expectedScheme) {
      return const AuthCallbackResult(status: AuthCallbackStatus.ignored);
    }
    if (environment == AppEnvironment.local || environment.isProduction) {
      return const AuthCallbackResult(status: AuthCallbackStatus.ignored);
    }

    final parameters = _combinedParameters(uri);
    final error = parameters['error'];
    final errorDescription = parameters['error_description'];
    if ((error ?? '').isNotEmpty || (errorDescription ?? '').isNotEmpty) {
      final message = '${error ?? ''} ${errorDescription ?? ''}'.toLowerCase();
      return AuthCallbackResult(
        status:
            message.contains('expired') ||
                message.contains('invalid') ||
                message.contains('token')
            ? AuthCallbackStatus.invalidOrExpired
            : AuthCallbackStatus.error,
        error: error,
        errorDescription: errorDescription,
      );
    }

    final accessToken = parameters['access_token'];
    final refreshToken = parameters['refresh_token'];
    final type = parameters['type'];
    if (type == 'recovery') {
      return const AuthCallbackResult(status: AuthCallbackStatus.ignored);
    }
    if ((accessToken ?? '').isNotEmpty && (refreshToken ?? '').isNotEmpty) {
      return AuthCallbackResult(
        status: AuthCallbackStatus.signedIn,
        accessToken: accessToken,
        refreshToken: refreshToken,
        type: type,
        tokenHash: parameters['token_hash'],
      );
    }

    final tokenHash = parameters['token_hash'];
    if (type == 'signup' ||
        type == 'email' ||
        type == 'magiclink' ||
        (tokenHash ?? '').isNotEmpty) {
      return AuthCallbackResult(
        status: AuthCallbackStatus.confirmedNoSession,
        type: type,
        tokenHash: tokenHash,
      );
    }

    return const AuthCallbackResult(status: AuthCallbackStatus.error);
  }

  static AuthCallbackMetadata metadataFor(
    String rawLink,
    AuthCallbackResult result,
  ) {
    final uri = Uri.tryParse(rawLink.trim());
    final keys = uri == null
        ? const <String>[]
        : _combinedParameters(uri).keys.toList(growable: false);
    return AuthCallbackMetadata(
      received: true,
      result: result.status,
      timestamp: DateTime.now(),
      scheme: uri?.scheme,
      host: uri?.host,
      path: uri?.path,
      queryKeys: keys,
      errorMessage: result.errorDescription ?? result.error,
    );
  }

  static Map<String, String> _combinedParameters(Uri uri) {
    final parameters = <String, String>{...uri.queryParameters};
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      parameters.addAll(Uri.splitQueryString(fragment));
    }
    return parameters;
  }
}
