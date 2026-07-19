import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/widgets/glass_card.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/core/widgets/modern_settings_row.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter/material.dart';

/// Account access panel used by Settings.
class AuthAccessPanel extends StatefulWidget {
  /// Creates the account access panel.
  const AuthAccessPanel({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.authState,
    required this.onSignIn,
    required this.onSignUp,
    required this.onResendConfirmation,
    required this.onForgotPassword,
    required this.onSignOut,
    required this.syncStatusLabel,
  });

  /// Email input controller owned by Settings.
  final TextEditingController emailController;

  /// Password input controller owned by Settings.
  final TextEditingController passwordController;

  /// Current auth presentation state.
  final AuthState authState;

  /// Sign-in callback.
  final VoidCallback onSignIn;

  /// Sign-up callback.
  final VoidCallback onSignUp;

  /// Confirmation resend callback.
  final VoidCallback onResendConfirmation;

  /// Password reset callback.
  final VoidCallback onForgotPassword;

  /// Sign-out callback when signed in.
  final VoidCallback? onSignOut;

  /// Current sync status label for the signed-in account panel.
  final String syncStatusLabel;

  @override
  State<AuthAccessPanel> createState() => _AuthAccessPanelState();
}

class _AuthAccessPanelState extends State<AuthAccessPanel> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  bool _obscurePassword = true;
  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _showStrength = false;

  String? get _emailError {
    if (!_emailTouched) {
      return null;
    }
    final email = widget.emailController.text.trim();
    if (email.isEmpty) {
      return 'Enter an email address.';
    }
    if (!_emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String? get _passwordError {
    if (!_passwordTouched) {
      return null;
    }
    final password = widget.passwordController.text;
    return validateAuthPassword(password);
  }

  bool get _hasLocalErrors => _emailError != null || _passwordError != null;

  void _touchFields() {
    setState(() {
      _emailTouched = true;
      _passwordTouched = true;
    });
  }

  void _handleSignIn() {
    _touchFields();
    if (_hasLocalErrors) {
      return;
    }
    widget.onSignIn();
  }

  void _handleSignUp() {
    _touchFields();
    setState(() => _showStrength = true);
    if (_hasLocalErrors) {
      return;
    }
    widget.onSignUp();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GradientHeader(
          title: 'Account Access',
          subtitle: 'Sign in to sync your collection',
          gradientStyle: GradientStyle.purpleDeepBlue,
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: widget.authState.isSignedIn
                ? _SignedInAuthPanel(
                    key: const ValueKey('settings-auth-account-panel'),
                    authState: widget.authState,
                    syncStatusLabel: widget.syncStatusLabel,
                    onSignOut: widget.onSignOut,
                  )
                : _buildSignedOut(context),
          ),
        ),
      ],
    );
  }

  Widget _buildSignedOut(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLoading = widget.authState.isLoading;
    final resendCountdownLabel = widget.authState.resendCountdownLabel(
      DateTime.now(),
    );
    final passwordResetCountdownLabel = widget.authState
        .passwordResetCountdownLabel(DateTime.now());
    final loadingLabel = switch (widget.authState.status) {
      AuthFlowStatus.signingIn => 'Signing in...',
      AuthFlowStatus.signingUp => 'Creating account...',
      AuthFlowStatus.signingOut => 'Signing out...',
      AuthFlowStatus.sessionRestoring => 'Checking session...',
      _ => 'Working...',
    };
    final statusText = isLoading
        ? loadingLabel
        : widget.authState.isAnonymousCloudSession
        ? 'Anonymous'
        : 'Ready';
    final helperText = widget.authState.isAnonymousCloudSession
        ? 'Anonymous/dev session. Use email/password for real SIT auth.'
        : 'Optional Supabase account. Local mode remains available.';

    return Column(
      key: const ValueKey('settings-auth-signed-out-panel'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthHeader(
          icon: Icons.email_outlined,
          title: 'Email / Password',
          subtitle: helperText,
          trailing: statusText,
        ),
        const SizedBox(height: AppSpacing.lg),
        _AuthHeroBanner(
          hasError: widget.authState.errorMessage != null || _hasLocalErrors,
          isSuccess:
              widget.authState.infoMessage != null &&
              widget.authState.errorMessage == null,
        ),
        const SizedBox(height: AppSpacing.xl),
        if (isLoading) ...[
          const LinearProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(
            loadingLabel,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _AuthFieldShell(
          child: TextField(
            key: const ValueKey('settings-auth-email-field'),
            controller: widget.emailController,
            enabled: !isLoading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            onChanged: (_) => setState(() => _emailTouched = true),
            decoration: _authInputDecoration(
              context: context,
              labelText: 'Email',
              hintText: 'collector@example.com',
              errorText: _emailError,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _AuthFieldShell(
          child: TextField(
            key: const ValueKey('settings-auth-password-field'),
            controller: widget.passwordController,
            enabled: !isLoading,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            onChanged: (_) => setState(() {
              _passwordTouched = true;
              _showStrength = true;
            }),
            decoration: _authInputDecoration(
              context: context,
              labelText: 'Password',
              hintText: AuthMessages.passwordPolicyHelp,
              errorText: _passwordError,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: isLoading
                    ? null
                    : () => setState(() {
                        _obscurePassword = !_obscurePassword;
                      }),
              ),
            ),
          ),
        ),
        if (_showStrength) ...[
          const SizedBox(height: AppSpacing.md),
          PasswordStrengthIndicator(password: widget.passwordController.text),
        ],
        _AuthMessageBlock(
          errorMessage: widget.authState.errorMessage,
          infoMessage: widget.authState.infoMessage,
        ),
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          child: _AuthButtonMotion(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary,
                    colorScheme.tertiary.withValues(alpha: 0.82),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: FilledButton.icon(
                key: const ValueKey('settings-auth-sign-in-button'),
                onPressed: isLoading ? null : _handleSignIn,
                icon: const Icon(Icons.login_outlined),
                label: Text(isLoading ? loadingLabel : 'Sign In'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: colorScheme.onSurface.withValues(
                    alpha: 0.12,
                  ),
                  shadowColor: Colors.transparent,
                  foregroundColor: colorScheme.onPrimary,
                  textStyle: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: _AuthButtonMotion(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withValues(alpha: 0.42),
                    colorScheme.secondaryContainer.withValues(alpha: 0.36),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: OutlinedButton.icon(
                key: const ValueKey('settings-auth-sign-up-button'),
                onPressed: isLoading ? null : _handleSignUp,
                icon: const Icon(Icons.person_add_alt_outlined),
                label: const Text('Sign Up'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: Colors.transparent,
                  foregroundColor: colorScheme.primary,
                  textStyle: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (widget.authState.status == AuthFlowStatus.confirmationRequired &&
            widget.authState.pendingConfirmationEmail != null &&
            !widget.authState.isSignedIn) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const ValueKey('settings-auth-resend-confirmation-button'),
              onPressed: isLoading || resendCountdownLabel != null
                  ? null
                  : widget.onResendConfirmation,
              icon: const Icon(Icons.mark_email_unread_outlined),
              label: Text(resendCountdownLabel ?? 'Resend Confirmation'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            key: const ValueKey('settings-auth-forgot-password-button'),
            onPressed: isLoading || passwordResetCountdownLabel != null
                ? null
                : widget.onForgotPassword,
            icon: const Icon(Icons.help_outline),
            label: Text(passwordResetCountdownLabel ?? 'Forgot Password'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SignedInAuthPanel extends StatelessWidget {
  const _SignedInAuthPanel({
    super.key,
    required this.authState,
    required this.syncStatusLabel,
    required this.onSignOut,
  });

  final AuthState authState;
  final String syncStatusLabel;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final displayName = authState.user?.email ?? authState.user!.displayName;
    final isLoading = authState.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthHeader(
          icon: Icons.account_circle_outlined,
          title: displayName,
          subtitle: 'Auth status connected',
          trailing: 'Connected',
        ),
        const SizedBox(height: AppSpacing.xl),
        _CompactStatusRow(
          icon: Icons.verified_user_outlined,
          title: 'Auth status',
          subtitle: 'Signed in with email/password.',
          trailing: 'Connected',
        ),
        const SizedBox(height: AppSpacing.lg),
        _CompactStatusRow(
          icon: Icons.sync_outlined,
          title: 'Sync status',
          subtitle: 'Cloud sync is available when Supabase is configured.',
          trailing: syncStatusLabel,
        ),
        _AuthMessageBlock(
          errorMessage: authState.errorMessage,
          infoMessage: authState.infoMessage,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            key: const ValueKey('settings-auth-sign-out-button'),
            onPressed: isLoading ? null : onSignOut,
            icon: const Icon(Icons.logout_outlined),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Password strength meter shown while entering an email auth password.
class PasswordStrengthIndicator extends StatelessWidget {
  /// Creates the password strength indicator.
  const PasswordStrengthIndicator({super.key, required this.password});

  /// Current password input.
  final String password;

  int get _score {
    return authPasswordPolicyScore(password);
  }

  double get _progress {
    if (password.isEmpty) return 0;
    if (_score <= 1) return 0.33;
    if (_score <= 3) return 0.66;
    return 1;
  }

  Color get _color {
    if (_score <= 1) return AppColors.danger;
    if (_score <= 3) return const Color(0xFFF97316);
    return AppColors.success;
  }

  String get _label {
    if (password.isEmpty) return 'Password strength: empty';
    if (_score <= 1) return 'Password strength: weak';
    if (_score <= 3) return 'Password strength: medium';
    return 'Password strength: strong';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: LinearProgressIndicator(
            key: const ValueKey('settings-auth-password-strength-meter'),
            value: _progress,
            minHeight: 8,
            color: _color,
            backgroundColor: colorScheme.outlineVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _label,
          key: const ValueKey('settings-auth-password-strength-label'),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.22),
            ),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          trailing,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AuthHeroBanner extends StatelessWidget {
  const _AuthHeroBanner({required this.hasError, required this.isSuccess});

  final bool hasError;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final colors = hasError
        ? [
            colorScheme.error.withValues(alpha: 0.18),
            colorScheme.errorContainer.withValues(alpha: 0.22),
          ]
        : isSuccess
        ? [
            Colors.green.withValues(alpha: 0.18),
            colorScheme.tertiaryContainer.withValues(alpha: 0.24),
          ]
        : [
            colorScheme.primaryContainer.withValues(alpha: 0.32),
            colorScheme.secondaryContainer.withValues(alpha: 0.24),
          ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              (hasError
                      ? colorScheme.error
                      : isSuccess
                      ? Colors.green
                      : colorScheme.primary)
                  .withValues(alpha: 0.22),
        ),
        boxShadow: [
          BoxShadow(
            color:
                (hasError
                        ? colorScheme.error
                        : isSuccess
                        ? Colors.green
                        : colorScheme.primary)
                    .withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.surface.withValues(alpha: 0.38),
            ),
            child: Icon(
              hasError
                  ? Icons.error_outline
                  : isSuccess
                  ? Icons.check_circle_outline
                  : Icons.cloud_sync_outlined,
              color: hasError
                  ? colorScheme.error
                  : isSuccess
                  ? Colors.green.shade700
                  : colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasError
                      ? 'Check your details'
                      : isSuccess
                      ? 'Account update sent'
                      : 'Cloud sync ready',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasError
                      ? 'Small fixes here, then try again.'
                      : isSuccess
                      ? 'Follow the next prompt to continue.'
                      : 'Sign in only when you want collection sync.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

class _AuthMessageBlock extends StatelessWidget {
  const _AuthMessageBlock({
    required this.errorMessage,
    required this.infoMessage,
  });

  final String? errorMessage;
  final String? infoMessage;

  @override
  Widget build(BuildContext context) {
    final message = errorMessage ?? infoMessage;
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: message == null ? 0 : 1,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 0.18),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: message == null
            ? const SizedBox.shrink()
            : TweenAnimationBuilder<double>(
                key: ValueKey(message),
                tween: Tween(begin: errorMessage != null ? 1 : 0, end: 0),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (context, shake, child) {
                  return Transform.translate(
                    offset: Offset(shake * 6, 0),
                    child: child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          (errorMessage != null
                                  ? colorScheme.error
                                  : Colors.green)
                              .withValues(alpha: 0.12),
                          (errorMessage != null
                                  ? colorScheme.errorContainer
                                  : colorScheme.tertiaryContainer)
                              .withValues(alpha: 0.18),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            (errorMessage != null
                                    ? colorScheme.error
                                    : Colors.green)
                                .withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          errorMessage != null
                              ? Icons.error_outline
                              : Icons.check_circle_outline,
                          color: errorMessage != null
                              ? colorScheme.error
                              : Colors.green.shade700,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            message,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: errorMessage != null
                                      ? colorScheme.error
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _AuthButtonMotion extends StatefulWidget {
  const _AuthButtonMotion({required this.child});

  final Widget child;

  @override
  State<_AuthButtonMotion> createState() => _AuthButtonMotionState();
}

class _AuthButtonMotionState extends State<_AuthButtonMotion> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        scale: _pressed ? 0.985 : 1,
        child: widget.child,
      ),
    );
  }
}

class _CompactStatusRow extends StatelessWidget {
  const _CompactStatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String trailing;

  @override
  Widget build(BuildContext context) {
    return ModernSettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailingText: trailing,
    );
  }
}

class _AuthFieldShell extends StatelessWidget {
  const _AuthFieldShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.06),
            blurRadius: 16,
            spreadRadius: -8,
          ),
        ],
      ),
      child: child,
    );
  }
}

InputDecoration _authInputDecoration({
  required BuildContext context,
  required String labelText,
  required String hintText,
  required String? errorText,
  Widget? suffixIcon,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final radius = BorderRadius.circular(18);
  final border = OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(
      color: colorScheme.outlineVariant.withValues(alpha: 0.25),
    ),
  );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    errorText: errorText,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: colorScheme.surface.withValues(alpha: 0.55),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: border,
    enabledBorder: border,
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: colorScheme.primary.withValues(alpha: 0.58),
        width: 1.4,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: colorScheme.error.withValues(alpha: 0.7),
        width: 1.4,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: colorScheme.error.withValues(alpha: 0.45)),
    ),
  );
}
