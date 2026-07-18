import 'package:dio/dio.dart';

enum SupabaseAuthAction {
  signUp,
  otpSignupStart,
  otpVerify,
  passwordUpdate,
  signIn,
  resendConfirmation,
  passwordReset,
  signOut,
  sessionRestore,
}

enum SupabaseAuthNormalizedStatus {
  signedIn,
  signedOut,
  otpSent,
  otpVerified,
  passwordUpdated,
  confirmationRequired,
  confirmationEmailSent,
  passwordResetSent,
  emailNotConfirmed,
  emailNotRegistered,
  invalidCredentials,
  alreadyRegistered,
  weakPassword,
  rateLimited,
  configMissing,
  networkFailure,
  expiredSession,
  temporaryFailure,
  unknownFailure,
}

class SupabaseAuthNormalizedResult {
  const SupabaseAuthNormalizedResult({
    required this.status,
    required this.metadata,
    this.retryAfter,
    this.cooldownSource = 'none',
  });

  final SupabaseAuthNormalizedStatus status;
  final SupabaseAuthAttemptMetadata metadata;
  final Duration? retryAfter;
  final String cooldownSource;
}

class SupabaseAuthAttemptMetadata {
  const SupabaseAuthAttemptMetadata({
    required this.action,
    required this.normalizedStatus,
    required this.timestamp,
    this.httpStatus,
    this.contentType = 'none',
    this.bodyType = 'empty',
    this.keys = const <String>[],
    this.hasUser = false,
    this.hasSession = false,
    this.hasDirectId = false,
    this.hasDirectEmail = false,
    this.hasConfirmationSentAt = false,
    this.hasIdentities = false,
    this.hasAud = false,
    this.hasRole = false,
    this.hasErrorCode = false,
    this.hasErrorMessage = false,
  });

  final SupabaseAuthAction action;
  final SupabaseAuthNormalizedStatus normalizedStatus;
  final DateTime timestamp;
  final int? httpStatus;
  final String contentType;
  final String bodyType;
  final List<String> keys;
  final bool hasUser;
  final bool hasSession;
  final bool hasDirectId;
  final bool hasDirectEmail;
  final bool hasConfirmationSentAt;
  final bool hasIdentities;
  final bool hasAud;
  final bool hasRole;
  final bool hasErrorCode;
  final bool hasErrorMessage;

  String get actionLabel => action.name;

  String get statusLabel => normalizedStatus.name;

  String get keysLabel => keys.isEmpty ? 'none' : keys.join(', ');
}

class SupabaseAuthResponseNormalizer {
  const SupabaseAuthResponseNormalizer._();

  static SupabaseAuthNormalizedResult normalizeResponse({
    required SupabaseAuthAction action,
    required int? statusCode,
    required Object? body,
    Headers? headers,
    DateTime? timestamp,
  }) {
    final metadataBase = _metadata(
      action: action,
      statusCode: statusCode,
      headers: headers,
      body: body,
      timestamp: timestamp,
      status: SupabaseAuthNormalizedStatus.unknownFailure,
    );
    final isSuccess =
        statusCode != null && statusCode >= 200 && statusCode < 300;
    final status = isSuccess
        ? _successStatus(action: action, body: body)
        : _failureStatus(statusCode: statusCode, body: body);
    final retryAfter = retryAfterDuration(headers);
    return SupabaseAuthNormalizedResult(
      status: status,
      metadata: metadataBase.copyWith(normalizedStatus: status),
      retryAfter: retryAfter,
      cooldownSource: retryAfter == null ? 'fallback' : 'retry-after',
    );
  }

  static SupabaseAuthNormalizedResult normalizeException({
    required SupabaseAuthAction action,
    required DioException error,
    DateTime? timestamp,
  }) {
    final response = error.response;
    if (response != null) {
      return normalizeResponse(
        action: action,
        statusCode: response.statusCode,
        body: response.data,
        headers: response.headers,
        timestamp: timestamp,
      );
    }

    final isNetworkFailure =
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.connectionError;
    final status = isNetworkFailure
        ? SupabaseAuthNormalizedStatus.networkFailure
        : SupabaseAuthNormalizedStatus.unknownFailure;
    return SupabaseAuthNormalizedResult(
      status: status,
      metadata: _metadata(
        action: action,
        statusCode: null,
        headers: null,
        body: null,
        timestamp: timestamp,
        status: status,
      ),
    );
  }

  static String messageFor(SupabaseAuthNormalizedStatus status) {
    return switch (status) {
      SupabaseAuthNormalizedStatus.confirmationRequired =>
        'Check your email to confirm your account, then sign in.',
      SupabaseAuthNormalizedStatus.confirmationEmailSent =>
        'Confirmation email sent. Please check Inbox, Spam, Junk, and Promotions.',
      SupabaseAuthNormalizedStatus.passwordResetSent =>
        'Password reset email sent. Please wait before requesting another.',
      SupabaseAuthNormalizedStatus.otpSent =>
        'Verification code sent. Please check your email.',
      SupabaseAuthNormalizedStatus.otpVerified => 'Verification code accepted.',
      SupabaseAuthNormalizedStatus.passwordUpdated => 'Password updated.',
      SupabaseAuthNormalizedStatus.emailNotConfirmed =>
        'Please confirm your email before signing in.',
      SupabaseAuthNormalizedStatus.emailNotRegistered =>
        'Please sign up first.',
      SupabaseAuthNormalizedStatus.invalidCredentials =>
        'Invalid email or password.',
      SupabaseAuthNormalizedStatus.alreadyRegistered =>
        'An account already exists. Please sign in.',
      SupabaseAuthNormalizedStatus.weakPassword =>
        'Password is too weak. Use a stronger password.',
      SupabaseAuthNormalizedStatus.rateLimited =>
        'Too many auth requests. Wait a moment and try again.',
      SupabaseAuthNormalizedStatus.configMissing =>
        'Supabase anon key is missing from SIT config.',
      SupabaseAuthNormalizedStatus.networkFailure =>
        'Unable to reach Supabase. Check your internet connection.',
      SupabaseAuthNormalizedStatus.expiredSession =>
        'Session expired. Please sign in again.',
      SupabaseAuthNormalizedStatus.temporaryFailure =>
        'Supabase is temporarily unavailable. Please try again soon.',
      SupabaseAuthNormalizedStatus.otpSent ||
      SupabaseAuthNormalizedStatus.otpVerified ||
      SupabaseAuthNormalizedStatus.passwordUpdated ||
      SupabaseAuthNormalizedStatus.signedIn ||
      SupabaseAuthNormalizedStatus.signedOut =>
        'Supabase Auth request completed.',
      SupabaseAuthNormalizedStatus.unknownFailure =>
        'Supabase Auth request failed. Try again or check Supabase Auth settings.',
    };
  }

  static Duration? retryAfterDuration(Headers? headers) {
    final rawValue = headers?.value('retry-after')?.trim();
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }
    final seconds = int.tryParse(rawValue);
    if (seconds == null) {
      return null;
    }
    return Duration(seconds: seconds < 0 ? 0 : seconds);
  }

  static SupabaseAuthNormalizedStatus _successStatus({
    required SupabaseAuthAction action,
    required Object? body,
  }) {
    return switch (action) {
      SupabaseAuthAction.signUp => _signUpSuccessStatus(body),
      SupabaseAuthAction.otpSignupStart => SupabaseAuthNormalizedStatus.otpSent,
      SupabaseAuthAction.otpVerify =>
        _hasAuthenticatedSession(body)
            ? SupabaseAuthNormalizedStatus.otpVerified
            : SupabaseAuthNormalizedStatus.emailNotConfirmed,
      SupabaseAuthAction.passwordUpdate =>
        _hasUser(body)
            ? SupabaseAuthNormalizedStatus.passwordUpdated
            : SupabaseAuthNormalizedStatus.unknownFailure,
      SupabaseAuthAction.signIn =>
        _hasAuthenticatedSession(body)
            ? SupabaseAuthNormalizedStatus.signedIn
            : SupabaseAuthNormalizedStatus.emailNotConfirmed,
      SupabaseAuthAction.resendConfirmation =>
        SupabaseAuthNormalizedStatus.confirmationEmailSent,
      SupabaseAuthAction.passwordReset =>
        SupabaseAuthNormalizedStatus.passwordResetSent,
      SupabaseAuthAction.signOut => SupabaseAuthNormalizedStatus.signedOut,
      SupabaseAuthAction.sessionRestore =>
        _hasUser(body)
            ? SupabaseAuthNormalizedStatus.signedIn
            : SupabaseAuthNormalizedStatus.expiredSession,
    };
  }

  static SupabaseAuthNormalizedStatus _signUpSuccessStatus(Object? body) {
    if (_hasAuthenticatedSession(body)) {
      return SupabaseAuthNormalizedStatus.signedIn;
    }
    return SupabaseAuthNormalizedStatus.confirmationRequired;
  }

  static SupabaseAuthNormalizedStatus _failureStatus({
    required int? statusCode,
    required Object? body,
  }) {
    final message = _serverErrorMessage(body)?.toLowerCase() ?? '';
    final code = _serverErrorCode(body)?.toLowerCase() ?? '';
    final combined = '$code $message';

    if (combined.contains('no api key') ||
        combined.contains('missing api key')) {
      return SupabaseAuthNormalizedStatus.configMissing;
    }
    if (combined.contains('email not confirmed') ||
        combined.contains('email_not_confirmed') ||
        combined.contains('confirm your email')) {
      return SupabaseAuthNormalizedStatus.emailNotConfirmed;
    }
    if (combined.contains('invalid login') ||
        combined.contains('invalid credentials') ||
        combined.contains('invalid_grant')) {
      return SupabaseAuthNormalizedStatus.invalidCredentials;
    }
    if (combined.contains('user not found') ||
        combined.contains('signup first') ||
        combined.contains('sign up first')) {
      return SupabaseAuthNormalizedStatus.emailNotRegistered;
    }
    if (combined.contains('already registered') ||
        combined.contains('already exists') ||
        combined.contains('user already') ||
        combined.contains('user_already_exists')) {
      return SupabaseAuthNormalizedStatus.alreadyRegistered;
    }
    if (combined.contains('weak password') ||
        combined.contains('weak_password') ||
        combined.contains('password should') ||
        combined.contains('password must')) {
      return SupabaseAuthNormalizedStatus.weakPassword;
    }
    if (statusCode == 429 ||
        combined.contains('rate limit') ||
        combined.contains('too many requests') ||
        combined.contains('over_email_send_rate_limit')) {
      return SupabaseAuthNormalizedStatus.rateLimited;
    }
    if (statusCode == 401 || statusCode == 403) {
      return SupabaseAuthNormalizedStatus.configMissing;
    }
    if (statusCode != null && statusCode >= 500) {
      return SupabaseAuthNormalizedStatus.temporaryFailure;
    }
    return SupabaseAuthNormalizedStatus.unknownFailure;
  }

  static bool _hasAuthenticatedSession(Object? body) {
    final data = body is Map<String, dynamic> ? body : null;
    if (data == null) {
      return false;
    }
    final accessToken = data['access_token'];
    final session = data['session'];
    if (accessToken is String && accessToken.isNotEmpty) {
      return true;
    }
    if (session is Map<String, dynamic>) {
      final sessionToken = session['access_token'];
      return sessionToken is String && sessionToken.isNotEmpty;
    }
    return false;
  }

  static bool _hasUser(Object? body) {
    final data = body is Map<String, dynamic> ? body : null;
    if (data == null) {
      return false;
    }
    return data['user'] is Map<String, dynamic> || data['id'] is String;
  }

  static SupabaseAuthAttemptMetadata _metadata({
    required SupabaseAuthAction action,
    required int? statusCode,
    required Headers? headers,
    required Object? body,
    required DateTime? timestamp,
    required SupabaseAuthNormalizedStatus status,
  }) {
    final data = body is Map<String, dynamic> ? body : null;
    final bodyType = switch (body) {
      null => 'empty',
      Map<String, dynamic>() => 'map',
      List() => 'list',
      String() => body.isEmpty ? 'empty-string' : 'string',
      _ => body.runtimeType.toString(),
    };
    return SupabaseAuthAttemptMetadata(
      action: action,
      normalizedStatus: status,
      timestamp: timestamp ?? DateTime.now(),
      httpStatus: statusCode,
      contentType: headers?.value('content-type') ?? 'none',
      bodyType: bodyType,
      keys: data?.keys.map((key) => key.toString()).toList() ?? const [],
      hasUser: data?['user'] is Map,
      hasSession: data?['session'] is Map,
      hasDirectId: data?['id'] is String,
      hasDirectEmail: data?['email'] is String,
      hasConfirmationSentAt: data?['confirmation_sent_at'] != null,
      hasIdentities: data?['identities'] is List,
      hasAud: data?['aud'] is String,
      hasRole: data?['role'] is String,
      hasErrorCode:
          data?['code'] != null ||
          data?['error_code'] != null ||
          data?['error'] != null,
      hasErrorMessage: _serverErrorMessage(body) != null,
    );
  }

  static String? _serverErrorCode(Object? data) {
    if (data is Map<String, dynamic>) {
      for (final key in ['code', 'error_code', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return null;
  }

  static String? _serverErrorMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      for (final key in ['msg', 'message', 'error_description', 'error']) {
        final value = data[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    if (data is String && data.trim().isNotEmpty) {
      return data.trim();
    }

    return null;
  }
}

extension SupabaseAuthAttemptMetadataCopy on SupabaseAuthAttemptMetadata {
  SupabaseAuthAttemptMetadata copyWith({
    SupabaseAuthNormalizedStatus? normalizedStatus,
  }) {
    return SupabaseAuthAttemptMetadata(
      action: action,
      normalizedStatus: normalizedStatus ?? this.normalizedStatus,
      timestamp: timestamp,
      httpStatus: httpStatus,
      contentType: contentType,
      bodyType: bodyType,
      keys: keys,
      hasUser: hasUser,
      hasSession: hasSession,
      hasDirectId: hasDirectId,
      hasDirectEmail: hasDirectEmail,
      hasConfirmationSentAt: hasConfirmationSentAt,
      hasIdentities: hasIdentities,
      hasAud: hasAud,
      hasRole: hasRole,
      hasErrorCode: hasErrorCode,
      hasErrorMessage: hasErrorMessage,
    );
  }
}
