import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_button.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_entry_tile.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_header.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthSignInScreen extends ConsumerStatefulWidget {
  const AuthSignInScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AuthSignInScreen());
  }

  @override
  ConsumerState<AuthSignInScreen> createState() => _AuthSignInScreenState();
}

class _AuthSignInScreenState extends ConsumerState<AuthSignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitted = false;
  bool _completed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.clear();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final before = ref.read(authControllerProvider);
    if (before.isLoading || _emailError != null || _passwordError != null) {
      return;
    }
    await ref.read(authControllerProvider.notifier).signInWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
    final after = ref.read(authControllerProvider);
    if (!mounted || _completed || !after.isSignedIn) {
      return;
    }
    _completed = true;
    _passwordController.clear();
    Navigator.of(context).maybePop();
  }

  String? get _emailError {
    if (!_submitted) return null;
    return _validateEmail(_emailController.text);
  }

  String? get _passwordError {
    if (!_submitted) return null;
    return _validatePassword(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.status == AuthFlowStatus.signingIn &&
          next.status == AuthFlowStatus.signedIn &&
          mounted &&
          !_completed) {
        _completed = true;
        _passwordController.clear();
        Navigator.of(context).maybePop();
      }
    });

    return AuthFlowScaffold(
      key: const ValueKey('auth-sign-in-screen'),
      title: 'Sign In',
      subtitle: 'Access cloud sync when you need it. Local collection access stays available.',
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthIdentityMark(
              icon: Icons.lock_open_rounded,
              title: 'PackLox account',
              subtitle: 'Email and password sign-in',
            ),
            const SizedBox(height: AppSpacing.xl),
            AuthTextField(
              key: const ValueKey('auth-sign-in-email-field'),
              controller: _emailController,
              enabled: !authState.isLoading,
              label: 'Email',
              hint: 'collector@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              errorText: _emailError,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthTextField(
              key: const ValueKey('auth-sign-in-password-field'),
              controller: _passwordController,
              enabled: !authState.isLoading,
              label: 'Password',
              hint: 'Minimum 6 characters',
              obscureText: _obscurePassword,
              autofillHints: const [AutofillHints.password],
              errorText: _passwordError,
              suffixIcon: IconButton(
                key: const ValueKey('auth-sign-in-password-visibility'),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: authState.isLoading
                    ? null
                    : () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const ValueKey('auth-forgot-password-link'),
                onPressed: authState.isLoading
                    ? null
                    : () => Navigator.of(context).push(
                          AuthForgotPasswordScreen.route(
                            initialEmail: _emailController.text.trim(),
                          ),
                        ),
                child: const Text('Forgot Password'),
              ),
            ),
            AuthMessage(
              errorMessage: authState.errorMessage,
              infoMessage: authState.infoMessage,
            ),
            const SizedBox(height: AppSpacing.lg),
            PackLoxButton(
              key: const ValueKey('auth-sign-in-submit'),
              label: authState.isLoading ? 'Signing In' : 'Sign In',
              onPressed: authState.isLoading ? null : _submit,
              loading: authState.isLoading,
              leadingIcon: Icons.login_rounded,
              size: PackLoxButtonSize.fullWidth,
            ),
            const SizedBox(height: AppSpacing.md),
            PackLoxButton(
              key: const ValueKey('auth-open-sign-up'),
              label: 'Create Account',
              onPressed: authState.isLoading
                  ? null
                  : () => Navigator.of(context).push(AuthSignUpScreen.route()),
              leadingIcon: Icons.person_add_alt_1_rounded,
              variant: PackLoxButtonVariant.secondary,
              size: PackLoxButtonSize.fullWidth,
            ),
            const SizedBox(height: AppSpacing.md),
            PackLoxButton(
              key: const ValueKey('auth-continue-guest'),
              label: 'Continue as Guest',
              onPressed: authState.isLoading
                  ? null
                  : () => Navigator.of(context).maybePop(),
              leadingIcon: Icons.arrow_back_rounded,
              variant: PackLoxButtonVariant.quiet,
              size: PackLoxButtonSize.fullWidth,
            ),
            const SizedBox(height: AppSpacing.lg),
            const GuestAccessNote(),
          ],
        ),
      ),
    );
  }
}

class AuthSignUpScreen extends ConsumerStatefulWidget {
  const AuthSignUpScreen({super.key});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const AuthSignUpScreen());
  }

  @override
  ConsumerState<AuthSignUpScreen> createState() => _AuthSignUpScreenState();
}

class _AuthSignUpScreenState extends ConsumerState<AuthSignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.clear();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final state = ref.read(authControllerProvider);
    if (state.isLoading || _emailError != null || _passwordError != null) {
      return;
    }
    await ref.read(authControllerProvider.notifier).signUpWithEmailPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
    if (mounted && ref.read(authControllerProvider).isSignedIn) {
      _passwordController.clear();
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String? get _emailError {
    if (!_submitted) return null;
    return _validateEmail(_emailController.text);
  }

  String? get _passwordError {
    if (!_submitted) return null;
    return _validatePassword(_passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final pendingEmail =
        authState.pendingConfirmationEmail ?? _emailController.text.trim();
    final confirmationRequired =
        authState.status == AuthFlowStatus.confirmationRequired;

    return AuthFlowScaffold(
      key: const ValueKey('auth-sign-up-screen'),
      title: confirmationRequired ? 'Check Your Email' : 'Create Account',
      subtitle: confirmationRequired
          ? 'Confirm your email before signing in.'
          : 'Create a cloud account only when you want sync across devices.',
      child: confirmationRequired
          ? AuthVerificationPanel(
              email: pendingEmail,
              isLoading: authState.isLoading,
              infoMessage: authState.infoMessage,
              errorMessage: authState.errorMessage,
              onResend: () => ref
                  .read(authControllerProvider.notifier)
                  .resendConfirmationEmail(email: pendingEmail),
              onReturnToSignIn: () => Navigator.of(context).maybePop(),
            )
          : AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthIdentityMark(
                    icon: Icons.person_add_alt_1_rounded,
                    title: 'Cloud sync account',
                    subtitle: 'Email and password only',
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AuthTextField(
                    key: const ValueKey('auth-sign-up-email-field'),
                    controller: _emailController,
                    enabled: !authState.isLoading,
                    label: 'Email',
                    hint: 'collector@example.com',
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    errorText: _emailError,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AuthTextField(
                    key: const ValueKey('auth-sign-up-password-field'),
                    controller: _passwordController,
                    enabled: !authState.isLoading,
                    label: 'Password',
                    hint: 'Minimum 6 characters',
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    errorText: _passwordError,
                    suffixIcon: IconButton(
                      key: const ValueKey('auth-sign-up-password-visibility'),
                      tooltip:
                          _obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: authState.isLoading
                          ? null
                          : () => setState(() {
                              _obscurePassword = !_obscurePassword;
                            }),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Use at least 6 characters. Email confirmation may be required before sign-in.',
                    style: TextStyle(
                      color: PackLoxTokens.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                  AuthMessage(
                    errorMessage: authState.errorMessage,
                    infoMessage: authState.infoMessage,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PackLoxButton(
                    key: const ValueKey('auth-sign-up-submit'),
                    label: authState.isLoading ? 'Creating Account' : 'Create Account',
                    onPressed: authState.isLoading ? null : _submit,
                    loading: authState.isLoading,
                    leadingIcon: Icons.person_add_alt_1_rounded,
                    size: PackLoxButtonSize.fullWidth,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PackLoxButton(
                    key: const ValueKey('auth-return-sign-in'),
                    label: 'Back to Sign In',
                    onPressed: authState.isLoading
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    leadingIcon: Icons.login_rounded,
                    variant: PackLoxButtonVariant.secondary,
                    size: PackLoxButtonSize.fullWidth,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const GuestAccessNote(),
                ],
              ),
            ),
    );
  }
}

class AuthForgotPasswordScreen extends ConsumerStatefulWidget {
  const AuthForgotPasswordScreen({super.key, this.initialEmail});

  final String? initialEmail;

  static Route<void> route({String? initialEmail}) {
    return MaterialPageRoute<void>(
      builder: (_) => AuthForgotPasswordScreen(initialEmail: initialEmail),
    );
  }

  @override
  ConsumerState<AuthForgotPasswordScreen> createState() =>
      _AuthForgotPasswordScreenState();
}

class _AuthForgotPasswordScreenState
    extends ConsumerState<AuthForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _submitted = false;
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    final state = ref.read(authControllerProvider);
    if (state.isLoading || _emailError != null) {
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email: _emailController.text);
    if (mounted && ref.read(authControllerProvider).errorMessage == null) {
      setState(() => _requestSent = true);
    }
  }

  String? get _emailError {
    if (!_submitted) return null;
    return _validateEmail(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final sent = _requestSent &&
        authState.errorMessage == null &&
        authState.lastPasswordResetStatus != 'failed';

    return AuthFlowScaffold(
      key: const ValueKey('auth-forgot-password-screen'),
      title: sent ? 'Check Your Email' : 'Forgot Password',
      subtitle: sent
          ? 'The reset continues through the secure web link sent by email.'
          : 'Enter your email and PackLox will send the existing web reset flow.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthIdentityMark(
            icon: sent
                ? Icons.mark_email_read_outlined
                : Icons.mark_email_unread_outlined,
            title: sent ? 'Reset email sent' : 'Password recovery',
            subtitle: sent
                ? 'Open the email link to finish on the approved web flow.'
                : 'No in-app password reset form is used here.',
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!sent)
            AuthTextField(
              key: const ValueKey('auth-forgot-email-field'),
              controller: _emailController,
              enabled: !authState.isLoading,
              label: 'Email',
              hint: 'collector@example.com',
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              errorText: _emailError,
              onSubmitted: (_) => _submit(),
            )
          else
            PackLoxEntryTile(
              key: const ValueKey('auth-recovery-web-handoff'),
              icon: Icons.open_in_browser_rounded,
              title: 'Secure web reset',
              supportingText:
                  'Use the email link to set a new password. Return here when complete.',
              onTap: null,
              state: PackLoxEntryTileState.success,
              showTrailing: false,
            ),
          AuthMessage(
            errorMessage: authState.errorMessage,
            infoMessage: authState.infoMessage,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!sent)
            PackLoxButton(
              key: const ValueKey('auth-forgot-submit'),
              label: authState.isLoading ? 'Sending Email' : 'Send Reset Email',
              onPressed: authState.isLoading ? null : _submit,
              loading: authState.isLoading,
              leadingIcon: Icons.send_rounded,
              size: PackLoxButtonSize.fullWidth,
            ),
          if (!sent) const SizedBox(height: AppSpacing.md),
          PackLoxButton(
            key: const ValueKey('auth-forgot-return-sign-in'),
            label: 'Back to Sign In',
            onPressed: authState.isLoading
                ? null
                : () => Navigator.of(context).maybePop(),
            leadingIcon: Icons.login_rounded,
            variant: sent
                ? PackLoxButtonVariant.primary
                : PackLoxButtonVariant.secondary,
            size: PackLoxButtonSize.fullWidth,
          ),
        ],
      ),
    );
  }
}

class AuthFlowScaffold extends StatelessWidget {
  const AuthFlowScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Scaffold(
      backgroundColor: PackLoxTokens.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              key: const ValueKey('auth-scroll-view'),
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xl + viewInsets.bottom,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight: constraints.maxHeight -
                        AppSpacing.lg -
                        AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PackLoxHeader(
                        key: const ValueKey('auth-packlox-header'),
                        firstName: title,
                        greetingText: 'PackLox',
                        fallbackName: title,
                        onNotifications: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: PackLoxTokens.textSecondary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      child,
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthIdentityMark extends StatelessWidget {
  const AuthIdentityMark({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: PackLoxTokens.surfaceRaised,
        border: Border.all(color: PackLoxTokens.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PackLoxTokens.blue.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: PackLoxTokens.border),
            ),
            child: Icon(icon, color: PackLoxTokens.textPrimary),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: PackLoxTokens.textPrimary,
                    fontSize: 16,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: PackLoxTokens.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.enabled = true,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.errorText,
    this.suffixIcon,
    this.onSubmitted,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final String? errorText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      obscureText: obscureText,
      textInputAction: TextInputAction.next,
      onSubmitted: onSubmitted,
      inputFormatters: keyboardType == TextInputType.emailAddress
          ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class AuthMessage extends StatelessWidget {
  const AuthMessage({this.errorMessage, this.infoMessage, super.key});

  final String? errorMessage;
  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage ?? infoMessage;
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }
    final isError = errorMessage != null;
    return Semantics(
      liveRegion: true,
      child: Container(
        key: ValueKey(isError ? 'auth-error-message' : 'auth-info-message'),
        margin: const EdgeInsets.only(top: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: (isError ? PackLoxTokens.error : PackLoxTokens.success)
              .withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: isError ? PackLoxTokens.error : PackLoxTokens.success,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: PackLoxTokens.textPrimary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: PackLoxTokens.textPrimary,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthVerificationPanel extends StatelessWidget {
  const AuthVerificationPanel({
    required this.email,
    required this.isLoading,
    required this.onResend,
    required this.onReturnToSignIn,
    this.infoMessage,
    this.errorMessage,
    super.key,
  });

  final String email;
  final bool isLoading;
  final VoidCallback onResend;
  final VoidCallback onReturnToSignIn;
  final String? infoMessage;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthIdentityMark(
          icon: Icons.mark_email_read_outlined,
          title: 'Verification email sent',
          subtitle: email.isEmpty ? 'Check your inbox.' : email,
        ),
        AuthMessage(errorMessage: errorMessage, infoMessage: infoMessage),
        const SizedBox(height: AppSpacing.lg),
        PackLoxButton(
          key: const ValueKey('auth-resend-confirmation'),
          label: isLoading ? 'Sending' : 'Resend Confirmation',
          onPressed: isLoading ? null : onResend,
          loading: isLoading,
          leadingIcon: Icons.mark_email_unread_outlined,
          variant: PackLoxButtonVariant.secondary,
          size: PackLoxButtonSize.fullWidth,
        ),
        const SizedBox(height: AppSpacing.md),
        PackLoxButton(
          key: const ValueKey('auth-verification-return-sign-in'),
          label: 'Back to Sign In',
          onPressed: isLoading ? null : onReturnToSignIn,
          leadingIcon: Icons.login_rounded,
          size: PackLoxButtonSize.fullWidth,
        ),
      ],
    );
  }
}

class GuestAccessNote extends StatelessWidget {
  const GuestAccessNote({super.key});

  @override
  Widget build(BuildContext context) {
    return PackLoxEntryTile(
      key: const ValueKey('auth-guest-access-note'),
      icon: Icons.inventory_2_outlined,
      title: 'Guest mode stays available',
      supportingText:
          'Use scanning and Portfolio locally without an account. Sign in only for cloud sync.',
      onTap: null,
      showTrailing: false,
    );
  }
}

String? _validateEmail(String email) {
  final trimmed = email.trim();
  if (trimmed.isEmpty) {
    return 'Enter an email address.';
  }
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
    return 'Please enter a valid email address.';
  }
  return null;
}

String? _validatePassword(String password) {
  if (password.isEmpty) {
    return 'Enter a password.';
  }
  if (password.length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
}
