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
  static const _stageCount = 4;

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
                    _ScanStage(),
                    _ReviewStage(),
                    _PortfolioStage(),
                    _ControlStage(),
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

class _ScanStage extends StatelessWidget {
  const _ScanStage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingStageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PackLoxHero(
            variant: PackLoxHeroVariant.scanner,
            eyebrow: 'PackLox',
            title: 'Scan any collectible',
            subtitle:
                'Use camera or gallery photos to identify cards, figures, sneakers, comics, watches, and the pieces you care about.',
            icon: Icons.document_scanner_outlined,
            semanticLabel:
                'PackLox scans collectibles from camera or gallery photos.',
          ),
          SizedBox(height: AppSpacing.xl),
          _OnboardingSignalCard(
            icon: Icons.photo_camera_outlined,
            iconColor: _iconCyan,
            title: 'Camera and gallery ready',
            body:
                'Take a new photo or choose one from your phone when the item is already pictured.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingSignalCard(
            icon: Icons.filter_center_focus_outlined,
            iconColor: _iconPurple,
            title: 'Multiple angles help',
            body:
                'Add front, back, label, serial, or condition photos when a collectible needs more context.',
          ),
        ],
      ),
    );
  }
}

class _ReviewStage extends StatelessWidget {
  const _ReviewStage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingStageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PackLoxHero(
            variant: PackLoxHeroVariant.analysis,
            eyebrow: 'Review',
            title: 'Check the AI result before saving',
            subtitle:
                'PackLox shows what it detected, how confident it is, and what details are available from analysis.',
            icon: Icons.fact_check_outlined,
            semanticLabel:
                'Review the AI result and decide what to keep before saving.',
          ),
          SizedBox(height: AppSpacing.xl),
          _OnboardingStepCard(
            icon: Icons.badge_outlined,
            iconColor: _iconCyan,
            title: 'Identity',
            body:
                'Review title, category, brand, year, set, edition, and match confidence.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingStepCard(
            icon: Icons.rate_review_outlined,
            iconColor: _iconPurple,
            title: 'Condition and notes',
            body:
                'Use condition, identifiers, and AI reasoning to decide what to keep.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingStepCard(
            icon: Icons.payments_outlined,
            iconColor: _iconGold,
            title: 'Market value when available',
            body:
                'Estimated value appears only when PackLox has enough reliable market evidence.',
          ),
        ],
      ),
    );
  }
}

class _PortfolioStage extends StatelessWidget {
  const _PortfolioStage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingStageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PackLoxHero(
            variant: PackLoxHeroVariant.portfolio,
            eyebrow: 'Portfolio',
            title: 'Build a collection you can manage',
            subtitle:
                'Saved items become portfolio records with photos, valuation context, ownership details, and notes.',
            icon: Icons.inventory_2_outlined,
            semanticLabel:
                'Saved collectibles become portfolio records you can track over time.',
          ),
          SizedBox(height: AppSpacing.xl),
          _OnboardingStepCard(
            icon: Icons.bookmark_added_outlined,
            iconColor: _iconGreen,
            title: 'Save the final result',
            body:
                'Keep the item after review, then open it later with all captured details.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingStepCard(
            icon: Icons.query_stats_outlined,
            iconColor: _iconGold,
            title: 'Track value and status',
            body:
                'Use portfolio detail, wishlist status, and alerts as your collection grows.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingStepCard(
            icon: Icons.dashboard_customize_outlined,
            iconColor: _iconCyan,
            title: 'See the bigger picture',
            body:
                'The dashboard gives a quick view of collection activity and next actions.',
          ),
        ],
      ),
    );
  }
}

class _ControlStage extends StatelessWidget {
  const _ControlStage();

  @override
  Widget build(BuildContext context) {
    return const _OnboardingStageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PackLoxHero(
            variant: PackLoxHeroVariant.standard,
            eyebrow: 'Your account',
            title: 'Every item belongs to your PackLox account',
            subtitle:
                'Scan, pricing evidence, photos, alerts, and valuation history stay connected to your signed-in collection.',
            icon: Icons.account_circle_outlined,
            semanticLabel:
                'Your PackLox account keeps your collection connected across devices.',
          ),
          SizedBox(height: AppSpacing.xl),
          _OnboardingSignalCard(
            icon: Icons.cloud_done_outlined,
            iconColor: _iconCyan,
            title: 'Cloud-backed portfolio',
            body:
                'Your saved collectibles are tied to your account, so your collection travels with you — not just this device.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingSignalCard(
            icon: Icons.verified_user_outlined,
            iconColor: _iconPurple,
            title: 'Evidence stays attached',
            body:
                'Photos, notes, identifiers, and pricing snapshots remain part of the same portfolio record.',
          ),
          SizedBox(height: AppSpacing.md),
          _OnboardingSignalCard(
            icon: Icons.lock_outline_rounded,
            iconColor: _iconGreen,
            title: 'Private account space',
            body:
                'Your collection is yours. PackLox keeps account access required before portfolio actions begin.',
          ),
        ],
      ),
    );
  }
}

class _OnboardingStageFrame extends StatelessWidget {
  const _OnboardingStageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
          child: child,
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

// Mirrors category_visual.dart's 4-color palette (which itself mirrors
// HomeTokens.categoryCards/Coins/Figures/More) so onboarding's icon badges
// read as the same "PackLox" coloring convention as Home's category tiles,
// instead of the flat single-cyan badges every card used before.
const _iconCyan = Color(0xFF22D3EE);
const _iconGold = Color(0xFFF4B740);
const _iconPurple = Color(0xFF9B7CFF);
const _iconGreen = Color(0xFF00D88A);

class _OnboardingStepCard extends StatelessWidget {
  const _OnboardingStepCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      icon: icon,
      iconColor: iconColor,
      title: title,
      body: body,
      borderColor: PackLoxTokens.blue.withValues(alpha: .52),
    );
  }
}

class _OnboardingSignalCard extends StatelessWidget {
  const _OnboardingSignalCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _OnboardingCard(
      icon: icon,
      iconColor: iconColor,
      title: title,
      body: body,
      borderColor: PackLoxTokens.border,
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.borderColor,
  });

  final IconData icon;
  final Color iconColor;
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
                shape: BoxShape.circle,
                color: iconColor.withValues(alpha: .14),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withValues(alpha: .18),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ExcludeSemantics(
                child: Icon(icon, color: iconColor, size: 22),
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
