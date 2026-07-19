import 'package:collectiq_ai/features/auth/data/repositories/auth_repository_backend_adapter.dart';
import 'package:collectiq_ai/features/auth/data/services/signup_start_guard_client.dart';
import 'package:collectiq_ai/features/auth/domain/entities/app_user.dart';
import 'package:collectiq_ai/features/auth/domain/entities/auth_backend_contract.dart';
import 'package:collectiq_ai/features/auth/domain/repositories/auth_backend_repository.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authBackendRepositoryProvider = Provider<AuthBackendRepository>((ref) {
  return AuthRepositoryBackendAdapter(
    repository: ref.watch(authRepositoryProvider),
    signupStartGuard: ref.watch(signupStartGuardClientProvider),
  );
});

final authBackendContractControllerProvider =
    NotifierProvider<AuthBackendContractController, AuthBackendContractState>(
      AuthBackendContractController.new,
    );

enum AuthBackendContractStatus {
  idle,
  restoringSession,
  signedOut,
  signingIn,
  signedIn,
  startingSignup,
  verificationSent,
  verifyingOtp,
  otpVerified,
  creatingPassword,
  requestingPasswordReset,
  passwordResetConfirmation,
  signingOut,
  failure,
}

class AuthBackendContractState {
  const AuthBackendContractState({
    this.status = AuthBackendContractStatus.idle,
    this.user,
    this.email,
    this.verification,
    this.failure,
    this.infoMessage,
    this.cooldownRemaining,
    this.attemptsRemaining,
    this.passwordPolicy = AuthPasswordPolicy.frozenS04,
  });

  final AuthBackendContractStatus status;
  final AppUser? user;
  final String? email;
  final EmailOtpVerification? verification;
  final AuthBackendFailure? failure;
  final String? infoMessage;
  final Duration? cooldownRemaining;
  final int? attemptsRemaining;
  final AuthPasswordPolicy passwordPolicy;

  bool get isSignedIn =>
      user != null && user!.isCloudBacked && !user!.isAnonymous;

  AuthBackendContractState copyWith({
    AuthBackendContractStatus? status,
    AppUser? user,
    String? email,
    EmailOtpVerification? verification,
    AuthBackendFailure? failure,
    String? infoMessage,
    Duration? cooldownRemaining,
    int? attemptsRemaining,
    AuthPasswordPolicy? passwordPolicy,
    bool clearUser = false,
    bool clearEmail = false,
    bool clearVerification = false,
    bool clearFailure = false,
    bool clearInfoMessage = false,
    bool clearCooldownRemaining = false,
    bool clearAttemptsRemaining = false,
  }) {
    return AuthBackendContractState(
      status: status ?? this.status,
      user: clearUser ? null : user ?? this.user,
      email: clearEmail ? null : email ?? this.email,
      verification: clearVerification
          ? null
          : verification ?? this.verification,
      failure: clearFailure ? null : failure ?? this.failure,
      infoMessage: clearInfoMessage ? null : infoMessage ?? this.infoMessage,
      cooldownRemaining: clearCooldownRemaining
          ? null
          : cooldownRemaining ?? this.cooldownRemaining,
      attemptsRemaining: clearAttemptsRemaining
          ? null
          : attemptsRemaining ?? this.attemptsRemaining,
      passwordPolicy: passwordPolicy ?? this.passwordPolicy,
    );
  }
}

class AuthBackendContractController extends Notifier<AuthBackendContractState> {
  AuthBackendRepository get _repository =>
      ref.read(authBackendRepositoryProvider);

  @override
  AuthBackendContractState build() {
    return const AuthBackendContractState();
  }

  Future<void> restoreSession() async {
    state = state.copyWith(
      status: AuthBackendContractStatus.restoringSession,
      clearFailure: true,
      clearInfoMessage: true,
    );
    final result = await _repository.currentUser();
    final failure = result.failure;
    if (failure != null) {
      _applyFailure(
        failure,
        fallbackStatus: AuthBackendContractStatus.signedOut,
      );
      return;
    }
    final user = result.value;
    state = state.copyWith(
      status: user != null && user.isCloudBacked && !user.isAnonymous
          ? AuthBackendContractStatus.signedIn
          : AuthBackendContractStatus.signedOut,
      user: user,
      clearUser: user == null,
      clearFailure: true,
      clearInfoMessage: true,
    );
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(
      status: AuthBackendContractStatus.signingIn,
      email: email.trim(),
      clearFailure: true,
      clearInfoMessage: true,
    );
    final result = await _repository.signInWithEmailPassword(
      email: email.trim(),
      password: password,
    );
    final failure = result.failure;
    if (failure != null) {
      _applyFailure(
        failure,
        fallbackStatus: AuthBackendContractStatus.signedOut,
      );
      return;
    }
    state = state.copyWith(
      status: AuthBackendContractStatus.signedIn,
      user: result.requireValue,
      clearFailure: true,
      infoMessage: 'Signed in successfully.',
    );
  }

  Future<void> startEmailSignup({required String email}) async {
    state = state.copyWith(
      status: AuthBackendContractStatus.startingSignup,
      email: email.trim(),
      clearFailure: true,
      clearInfoMessage: true,
      clearVerification: true,
    );
    final result = await _repository.startEmailSignup(email: email.trim());
    final failure = result.failure;
    if (failure != null) {
      _applyFailure(
        failure,
        fallbackStatus: AuthBackendContractStatus.signedOut,
      );
      return;
    }
    final start = result.requireValue;
    if (!start.safeForAccountCreation) {
      _applyFailure(
        const AuthBackendFailure(
          AuthBackendFailureCode.accountExistenceNotDisclosed,
          message: authSignupStartBlockedMessage,
        ),
        fallbackStatus: AuthBackendContractStatus.signedOut,
      );
      return;
    }
    state = state.copyWith(
      status: AuthBackendContractStatus.verificationSent,
      email: start.email,
      cooldownRemaining: start.cooldownRemaining,
      clearFailure: true,
      infoMessage: 'Enter the code we sent to ${start.email}.',
    );
  }

  Future<void> verifyEmailOtp({required String code, String? email}) async {
    final currentEmail = (state.email ?? email)?.trim();
    if (currentEmail == null || currentEmail.isEmpty) {
      _applyFailure(
        const AuthBackendFailure(AuthBackendFailureCode.otpInvalid),
        fallbackStatus: AuthBackendContractStatus.verificationSent,
      );
      return;
    }
    state = state.copyWith(
      status: AuthBackendContractStatus.verifyingOtp,
      email: currentEmail,
      clearFailure: true,
      clearInfoMessage: true,
    );
    final result = await _repository.verifyEmailOtp(
      email: currentEmail,
      code: code,
    );
    final failure = result.failure;
    if (failure != null) {
      _applyFailure(
        failure,
        fallbackStatus: AuthBackendContractStatus.verificationSent,
      );
      return;
    }
    final verification = result.requireValue;
    state = state.copyWith(
      status: AuthBackendContractStatus.otpVerified,
      email: verification.email,
      verification: verification,
      clearFailure: true,
      infoMessage: 'Email verified.',
    );
  }

  Future<void> createPasswordAfterVerification({
    required String password,
    required String confirmPassword,
  }) async {
    final policyFailure = state.passwordPolicy.validate(
      password: password,
      confirmPassword: confirmPassword,
    );
    if (policyFailure != null) {
      _applyFailure(
        policyFailure,
        fallbackStatus: AuthBackendContractStatus.otpVerified,
      );
      return;
    }
    final currentVerification = state.verification;
    if (currentVerification == null) {
      _applyFailure(
        const AuthBackendFailure(AuthBackendFailureCode.otpInvalid),
        fallbackStatus: AuthBackendContractStatus.verificationSent,
      );
      return;
    }
    state = state.copyWith(
      status: AuthBackendContractStatus.creatingPassword,
      clearFailure: true,
      clearInfoMessage: true,
    );
    final result = await _repository.createPasswordAfterVerification(
      verification: currentVerification,
      password: password,
    );
    final failure = result.failure;
    if (failure != null) {
      _applyFailure(
        failure,
        fallbackStatus: AuthBackendContractStatus.otpVerified,
      );
      return;
    }
    state = state.copyWith(
      status: AuthBackendContractStatus.signedIn,
      user: result.requireValue,
      clearFailure: true,
      infoMessage: 'Account ready.',
    );
  }

  Future<void> resendVerificationCode({String? email}) async {
    final currentEmail = (state.email ?? email)?.trim();
    if (currentEmail == null || currentEmail.isEmpty) {
      _applyFailure(
        const AuthBackendFailure(AuthBackendFailureCode.otpInvalid),
        fallbackStatus: AuthBackendContractStatus.verificationSent,
      );
      return;
    }
    final result = await _repository.resendVerificationCode(
      email: currentEmail,
    );
    final failure = result.failure;
    if (failure != null) {
      _applyFailure(
        failure,
        fallbackStatus: AuthBackendContractStatus.verificationSent,
      );
      return;
    }
    final start = result.requireValue;
    state = state.copyWith(
      status: AuthBackendContractStatus.verificationSent,
      email: start.email,
      cooldownRemaining: start.cooldownRemaining,
      attemptsRemaining: 5,
      clearFailure: true,
      infoMessage: 'A new code has been sent.',
    );
  }

  Future<void> requestPasswordReset({required String email}) async {
    state = state.copyWith(
      status: AuthBackendContractStatus.requestingPasswordReset,
      email: email.trim(),
      clearFailure: true,
      clearInfoMessage: true,
    );
    final result = await _repository.requestPasswordReset(email: email.trim());
    final failure = result.failure;
    final shouldPreserveResetAnonymity =
        failure?.code == AuthBackendFailureCode.accountExistenceNotDisclosed ||
        failure?.code == AuthBackendFailureCode.invalidCredentialsNeutral;
    if (failure != null && !shouldPreserveResetAnonymity) {
      _applyFailure(
        failure,
        fallbackStatus: AuthBackendContractStatus.signedOut,
      );
      return;
    }
    final reset =
        result.value ?? PasswordResetRequestResult(email: email.trim());
    state = state.copyWith(
      status: AuthBackendContractStatus.passwordResetConfirmation,
      email: reset.email,
      cooldownRemaining: reset.cooldownRemaining,
      clearFailure: true,
      infoMessage: reset.confirmationMessage,
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(
      status: AuthBackendContractStatus.signingOut,
      clearFailure: true,
      clearInfoMessage: true,
    );
    final result = await _repository.signOut();
    final failure = result.failure;
    if (failure != null) {
      _applyFailure(
        failure,
        fallbackStatus: AuthBackendContractStatus.signedIn,
      );
      return;
    }
    state = state.copyWith(
      status: AuthBackendContractStatus.signedOut,
      clearUser: true,
      clearVerification: true,
      clearFailure: true,
      infoMessage: 'Signed out.',
    );
  }

  void _applyFailure(
    AuthBackendFailure failure, {
    required AuthBackendContractStatus fallbackStatus,
  }) {
    state = state.copyWith(
      status: fallbackStatus,
      failure: failure,
      infoMessage: failure.safeMessage,
      cooldownRemaining: failure.cooldownRemaining,
      attemptsRemaining: failure.attemptsRemaining,
    );
  }
}
