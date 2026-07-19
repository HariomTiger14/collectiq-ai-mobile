import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';

const authSignupStartBlockedMessage =
    "We couldn't start account creation for this email. Try signing in or resetting your password.";

const authResetRequestRetryableMessage =
    'We could not send reset instructions. Check your connection and try again.';

const authOtpVerificationRetryableMessage =
    'We could not verify that code. Check your connection and try again.';

/// UI-safe backend failure categories for the reset auth flow.
enum AuthBackendFailureCode {
  invalidCredentialsNeutral,
  accountExistenceNotDisclosed,
  emailNotVerified,
  providerUnavailable,
  networkOffline,
  cooldownRateLimited,
  otpInvalid,
  otpExpired,
  otpAttemptLimitReached,
  passwordPolicyMismatch,
  capabilityUnavailable,
  unknown,
}

extension AuthBackendFailureCodeCopy on AuthBackendFailureCode {
  String get safeMessage {
    return switch (this) {
      AuthBackendFailureCode.invalidCredentialsNeutral =>
        'Email or password is not correct.',
      AuthBackendFailureCode.accountExistenceNotDisclosed =>
        'If an account exists for this email, reset instructions have been sent.',
      AuthBackendFailureCode.emailNotVerified =>
        'Verify your email to continue.',
      AuthBackendFailureCode.providerUnavailable =>
        'This sign-in option is not available on this device.',
      AuthBackendFailureCode.networkOffline =>
        'You appear to be offline. Check your connection and try again.',
      AuthBackendFailureCode.cooldownRateLimited =>
        'Please wait before trying again.',
      AuthBackendFailureCode.otpInvalid => 'Code is not correct. Try again.',
      AuthBackendFailureCode.otpExpired => 'Code expired. Request a new code.',
      AuthBackendFailureCode.otpAttemptLimitReached =>
        'Too many attempts. Request a new code.',
      AuthBackendFailureCode.passwordPolicyMismatch =>
        'Use a password that meets the PackLox requirements.',
      AuthBackendFailureCode.capabilityUnavailable =>
        'This authentication step is not available yet.',
      AuthBackendFailureCode.unknown => 'Something went wrong. Try again.',
    };
  }
}

/// UI-safe backend failure result.
class AuthBackendFailure {
  const AuthBackendFailure(
    this.code, {
    this.message,
    this.cooldownRemaining,
    this.attemptsRemaining,
  });

  final AuthBackendFailureCode code;
  final String? message;
  final Duration? cooldownRemaining;
  final int? attemptsRemaining;

  String get safeMessage => message ?? code.safeMessage;
}

/// Result wrapper for backend-auth contract calls.
class AuthBackendResult<T> {
  const AuthBackendResult._({this.value, this.failure});

  const AuthBackendResult.success(T value)
    : this._(value: value, failure: null);

  const AuthBackendResult.failure(AuthBackendFailure failure)
    : this._(value: null, failure: failure);

  final T? value;
  final AuthBackendFailure? failure;

  bool get isSuccess => failure == null;

  T get requireValue {
    final currentValue = value;
    if (currentValue == null) {
      throw StateError('Auth backend result has no success value.');
    }
    return currentValue;
  }
}

/// How the signup verification step is delivered.
enum EmailVerificationDelivery { otpCode, emailLink }

/// Result for starting an email signup verification step.
class EmailSignupStart {
  const EmailSignupStart({
    required this.email,
    required this.safeForAccountCreation,
    this.delivery = EmailVerificationDelivery.otpCode,
    this.cooldownRemaining = const Duration(seconds: 30),
    this.requestId,
  });

  final String email;
  final bool safeForAccountCreation;
  final EmailVerificationDelivery delivery;
  final Duration cooldownRemaining;
  final String? requestId;
}

/// Result for a verified email OTP step.
class EmailOtpVerification {
  const EmailOtpVerification({
    required this.email,
    required this.verifiedAt,
    this.verificationToken,
  });

  final String email;
  final DateTime verifiedAt;
  final String? verificationToken;
}

/// Generic, account-enumeration-safe password reset result.
class PasswordResetRequestResult {
  const PasswordResetRequestResult({
    required this.email,
    this.confirmationMessage =
        'If an account exists for this email, reset instructions have been sent.',
    this.cooldownRemaining = const Duration(seconds: 30),
  });

  final String email;
  final String confirmationMessage;
  final Duration cooldownRemaining;
}

/// Frozen S04 password policy expressed as an app-side contract.
class AuthPasswordPolicy {
  const AuthPasswordPolicy({
    this.minimumLength = 12,
    this.requiresCharacterMix = false,
    this.allowsSymbols = true,
    this.allowsSpaces = true,
  });

  static const frozenS04 = AuthPasswordPolicy();

  final int minimumLength;
  final bool requiresCharacterMix;
  final bool allowsSymbols;
  final bool allowsSpaces;

  AuthBackendFailure? validate({
    required String password,
    required String confirmPassword,
  }) {
    if (password.length < minimumLength) {
      return AuthBackendFailure(
        AuthBackendFailureCode.passwordPolicyMismatch,
        message: 'Use at least $minimumLength characters.',
      );
    }
    if (!allowsSpaces && password.contains(' ')) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.passwordPolicyMismatch,
        message: 'Spaces are not allowed in this password.',
      );
    }
    if (!allowsSymbols && RegExp(r'[^A-Za-z0-9\s]').hasMatch(password)) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.passwordPolicyMismatch,
        message: 'Symbols are not allowed in this password.',
      );
    }
    if (requiresCharacterMix && !_hasLetterAndNumber(password)) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.passwordPolicyMismatch,
        message: 'Use at least one letter and one number.',
      );
    }
    if (password != confirmPassword) {
      return const AuthBackendFailure(
        AuthBackendFailureCode.passwordPolicyMismatch,
        message: 'Passwords do not match.',
      );
    }
    return null;
  }

  static bool _hasLetterAndNumber(String password) {
    return RegExp('[A-Za-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password);
  }
}

/// Typed contract for password completion after OTP verification.
class PasswordCreationRequest {
  const PasswordCreationRequest({
    required this.verification,
    required this.password,
  });

  final EmailOtpVerification verification;
  final String password;
}

/// Shared helper for cloud-backed email users in test fakes and adapters.
AppUser emailPasswordUser({required String email, String? id}) {
  return AppUser(
    id: id ?? 'email:${email.toLowerCase()}',
    displayName: email,
    email: email,
    provider: AuthProviderType.emailPassword,
  );
}
