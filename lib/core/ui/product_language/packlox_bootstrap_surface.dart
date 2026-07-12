import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_button.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:flutter/material.dart';

enum PackLoxBootstrapSurfaceState { loading, recoverableError }

class PackLoxBootstrapSurface extends StatelessWidget {
  const PackLoxBootstrapSurface.loading({super.key})
    : state = PackLoxBootstrapSurfaceState.loading,
      onRetry = null;

  const PackLoxBootstrapSurface.recoverableError({
    required this.onRetry,
    super.key,
  }) : state = PackLoxBootstrapSurfaceState.recoverableError;

  final PackLoxBootstrapSurfaceState state;
  final VoidCallback? onRetry;

  static const startupSemanticLabel =
      'PackLox is preparing your collection workspace';
  static const errorSemanticLabel =
      'PackLox could not read the startup preference';

  bool get _isError => state == PackLoxBootstrapSurfaceState.recoverableError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final surfaceColor = isDark ? PackLoxTokens.surface : colorScheme.surface;
    final borderColor = isDark
        ? PackLoxTokens.border
        : colorScheme.outlineVariant;
    final primaryText = isDark
        ? PackLoxTokens.textPrimary
        : colorScheme.onSurface;
    final secondaryText = isDark
        ? PackLoxTokens.textSecondary
        : colorScheme.onSurfaceVariant;

    return Semantics(
      container: true,
      liveRegion: true,
      label: _isError ? errorSemanticLabel : startupSemanticLabel,
      child: ColoredBox(
        key: ValueKey(
          _isError ? 'packlox-bootstrap-error' : 'packlox-bootstrap',
        ),
        color: colorScheme.surface,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: borderColor),
                    boxShadow: isDark ? const [] : AppElevation.level2,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _BootstrapMark(isError: _isError),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'PackLox',
                          style: textTheme.headlineMedium?.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isError
                              ? 'Startup preference unavailable'
                              : 'Preparing your collection workspace',
                          style: textTheme.titleSmall?.copyWith(
                            color: primaryText,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _isError
                              ? 'PackLox could not read your onboarding state. You can retry without changing your account or collection data.'
                              : 'Checking your saved startup preference.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: secondaryText,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        if (_isError)
                          PackLoxButton(
                            key: const ValueKey('packlox-bootstrap-retry'),
                            label: 'Try again',
                            leadingIcon: Icons.refresh_rounded,
                            onPressed: onRetry,
                            size: PackLoxButtonSize.fullWidth,
                          )
                        else
                          const _BootstrapProgress(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PackLoxEntryTransition extends StatelessWidget {
  const PackLoxEntryTransition({
    required this.stateKey,
    required this.child,
    super.key,
  });

  final String stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 180);

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: duration,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeOutCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return currentChild ?? const SizedBox.shrink();
      },
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(key: ValueKey(stateKey), child: child),
    );
  }
}

class _BootstrapMark extends StatelessWidget {
  const _BootstrapMark({required this.isError});

  final bool isError;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: isError ? null : PackLoxTokens.heroGradient,
          color: isError ? PackLoxTokens.error.withValues(alpha: .18) : null,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isError
                ? PackLoxTokens.error.withValues(alpha: .55)
                : PackLoxTokens.cyan.withValues(alpha: .45),
          ),
        ),
        child: Icon(
          isError ? Icons.error_outline_rounded : Icons.inventory_2_outlined,
          color: isError ? PackLoxTokens.error : PackLoxTokens.textPrimary,
          size: AppIconSizes.lg,
        ),
      ),
    );
  }
}

class _BootstrapProgress extends StatelessWidget {
  const _BootstrapProgress();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(
            key: ValueKey('packlox-bootstrap-progress'),
            strokeWidth: 2.5,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Starting',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
