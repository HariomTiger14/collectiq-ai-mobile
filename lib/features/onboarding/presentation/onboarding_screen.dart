import 'dart:async';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_button.dart';
import 'package:collectiq_ai/core/ui/product_language/packlox_hero.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:flutter/material.dart';

typedef OnboardingActionCallback = FutureOr<void> Function();

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.onStartScanning,
    required this.onExploreDashboard,
    super.key,
  });

  final OnboardingActionCallback onStartScanning;
  final OnboardingActionCallback onExploreDashboard;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _stageCount = 3;

  late final PageController _pageController;
  var _stageIndex = 0;
  var _completionInFlight = false;

  bool get _isLastStage => _stageIndex == _stageCount - 1;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToStage(int index) async {
    final target = index.clamp(0, _stageCount - 1);
    if (target == _stageIndex || _completionInFlight) {
      return;
    }

    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.disableAnimations || mediaQuery.accessibleNavigation) {
      _pageController.jumpToPage(target);
      if (mounted) {
        setState(() => _stageIndex = target);
      }
      return;
    }

    await _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _goBack() => _goToStage(_stageIndex - 1);

  Future<void> _complete(OnboardingActionCallback callback) async {
    if (_completionInFlight) {
      return;
    }

    setState(() => _completionInFlight = true);
    try {
      await Future<void>.sync(callback);
    } finally {
      if (mounted) {
        setState(() => _completionInFlight = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stageIndex == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || _stageIndex == 0) {
          return;
        }
        await _goBack();
      },
      child: Scaffold(
        key: const ValueKey('onboarding-screen'),
        backgroundColor: PackLoxTokens.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView(
                  key: const ValueKey('onboarding-stage-page-view'),
                  controller: _pageController,
                  physics: _completionInFlight
                      ? const NeverScrollableScrollPhysics()
                      : const PageScrollPhysics(),
                  onPageChanged: (index) {
                    if (mounted) {
                      setState(() => _stageIndex = index);
                    }
                  },
                  children: const [
                    _WelcomeStage(),
                    _FlowStage(),
                    _LocalFirstStage(),
                  ],
                ),
              ),
              _OnboardingControls(
                stageIndex: _stageIndex,
                stageCount: _stageCount,
                isCompleting: _completionInFlight,
                onBack: _stageIndex == 0 ? null : _goBack,
                onNext: _isLastStage ? null : () => _goToStage(_stageIndex + 1),
                onStartScanning: _isLastStage
                    ? () => _complete(widget.onStartScanning)
                    : null,
                onExploreDashboard: _isLastStage
                    ? () => _complete(widget.onExploreDashboard)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeStage extends StatelessWidget {
  const _WelcomeStage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingStageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PackLoxHero(
            variant: PackLoxHeroVariant.standard,
            eyebrow: 'First launch',
            title: 'Welcome to PackLox',
            subtitle:
                'Scan collectibles, estimate value, save them to your portfolio, and track what matters over time.',
            icon: Icons.document_scanner_outlined,
            semanticLabel:
                'Welcome to PackLox. Scan collectibles, estimate value, save them, and track what matters.',
          ),
          SizedBox(height: AppSpacing.xl),
          _OnboardingSignalCard(
            icon: Icons.lock_outline,
            title: 'Guest access stays open',
            body:
                'You can start collecting without signing in, creating an account, or waiting for cloud setup.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingSignalCard(
            icon: Icons.offline_bolt_outlined,
            title: 'Local-first by default',
            body:
                'Your first-launch setup is stored on this device with the existing PackLox onboarding preference.',
          ),
        ],
      ),
    );
  }
}

class _FlowStage extends StatelessWidget {
  const _FlowStage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingStageFrame(
      eyebrow: 'How PackLox works',
      title: 'A simple collecting loop',
      subtitle:
          'Move from photo to saved item without leaving the app or crossing an account gate.',
      child: Column(
        children: [
          _OnboardingStepCard(
            icon: Icons.photo_camera_outlined,
            title: 'Scan',
            body: 'Use Camera or Gallery to add a collectible photo.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingStepCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Analyze',
            body:
                'Review an item match, estimated value, and confidence notes before you save.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingStepCard(
            icon: Icons.inventory_2_outlined,
            title: 'Save',
            body:
                'Add the result to your local-first portfolio when you are happy with it.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingStepCard(
            icon: Icons.query_stats_outlined,
            title: 'Track',
            body:
                'Follow insights, alerts, wishlist status, and collection goals from the dashboard.',
          ),
        ],
      ),
    );
  }
}

class _LocalFirstStage extends StatelessWidget {
  const _LocalFirstStage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingStageFrame(
      eyebrow: 'Local-first by default',
      title: 'Start privately. Sync later if you want.',
      subtitle:
          'Camera, gallery, estimates, portfolio saves, alerts, wishlist, and goals all work locally on this device.',
      child: Column(
        children: [
          _OnboardingSignalCard(
            icon: Icons.cloud_done_outlined,
            title: 'Cloud sync is optional',
            body:
                'Sign in when you want backup and restore. You can start collecting right away.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingSignalCard(
            icon: Icons.verified_user_outlined,
            title: 'Privacy conscious',
            body: 'Your photos and collection details stay private by default.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingSignalCard(
            icon: Icons.dashboard_customize_outlined,
            title: 'Choose your landing spot',
            body:
                'Finish onboarding by opening the scanner or exploring the dashboard.',
          ),
        ],
      ),
    );
  }
}

class _OnboardingStageFrame extends StatelessWidget {
  const _OnboardingStageFrame({
    required this.child,
    this.eyebrow,
    this.title,
    this.subtitle,
  });

  final String? eyebrow;
  final String? title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: PackLoxTokens.cyan,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (title != null) ...[
                Text(
                  title!,
                  style: textTheme.headlineMedium?.copyWith(
                    color: PackLoxTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (subtitle != null) ...[
                Text(
                  subtitle!,
                  style: textTheme.bodyLarge?.copyWith(
                    color: PackLoxTokens.textSecondary,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({
    required this.stageIndex,
    required this.stageCount,
    required this.isCompleting,
    required this.onBack,
    required this.onNext,
    required this.onStartScanning,
    required this.onExploreDashboard,
  });

  final int stageIndex;
  final int stageCount;
  final bool isCompleting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;
  final VoidCallback? onStartScanning;
  final VoidCallback? onExploreDashboard;

  @override
  Widget build(BuildContext context) {
    final stepText = 'Step ${stageIndex + 1} of $stageCount';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: PackLoxTokens.surface,
        border: Border(top: BorderSide(color: PackLoxTokens.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Semantics(
                  label: 'Onboarding progress',
                  value: stepText,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < stageCount; index++) ...[
                        _ProgressDot(active: index == stageIndex),
                        if (index != stageCount - 1)
                          const SizedBox(width: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  stepText,
                  style: const TextStyle(
                    color: PackLoxTokens.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (stageIndex == stageCount - 1)
                  Column(
                    children: [
                      PackLoxButton(
                        key: const ValueKey('onboarding-start-scanning'),
                        label: 'Start Scanning',
                        onPressed: onStartScanning,
                        leadingIcon: Icons.document_scanner_outlined,
                        loading: isCompleting,
                        size: PackLoxButtonSize.fullWidth,
                        semanticLabel: 'Start Scanning',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      PackLoxButton(
                        key: const ValueKey('onboarding-explore-dashboard'),
                        label: 'Explore Dashboard',
                        onPressed: onExploreDashboard,
                        leadingIcon: Icons.dashboard_outlined,
                        loading: isCompleting,
                        variant: PackLoxButtonVariant.secondary,
                        size: PackLoxButtonSize.fullWidth,
                        semanticLabel: 'Explore Dashboard',
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      if (onBack != null)
                        Expanded(
                          child: PackLoxButton(
                            key: const ValueKey('onboarding-back'),
                            label: 'Back',
                            onPressed: onBack,
                            variant: PackLoxButtonVariant.secondary,
                            size: PackLoxButtonSize.fullWidth,
                          ),
                        ),
                      if (onBack != null) const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: PackLoxButton(
                          key: const ValueKey('onboarding-next'),
                          label: 'Next',
                          onPressed: onNext,
                          trailingIcon: Icons.arrow_forward_rounded,
                          size: PackLoxButtonSize.fullWidth,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  const _ProgressDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: MediaQuery.of(context).disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180),
      width: active ? 28 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? PackLoxTokens.cyan : PackLoxTokens.border,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      icon: icon,
      title: title,
      body: body,
      borderColor: PackLoxTokens.blue.withValues(alpha: .52),
    );
  }
}

class _OnboardingSignalCard extends StatelessWidget {
  const _OnboardingSignalCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      icon: icon,
      title: title,
      body: body,
      borderColor: PackLoxTokens.border,
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.borderColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $body',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: PackLoxTokens.surfaceRaised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: PackLoxTokens.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: PackLoxTokens.border),
              ),
              child: ExcludeSemantics(
                child: Icon(icon, color: PackLoxTokens.cyan),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: PackLoxTokens.textPrimary,
                      fontSize: 15,
                      height: 1.25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body,
                    style: const TextStyle(
                      color: PackLoxTokens.textSecondary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
