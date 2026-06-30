import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({
    required this.onStartScanning,
    required this.onExploreDashboard,
    super.key,
  });

  final VoidCallback onStartScanning;
  final VoidCallback onExploreDashboard;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.xxl,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      gradient: AppGradients.premium,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppElevation.accentGlow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.document_scanner_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          'Welcome to CollectIQ AI',
                          style: textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Scan collectibles, estimate value, save them to your portfolio, and track what matters over time.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppInfoSection(
                    title: 'How CollectIQ AI works',
                    child: Column(
                      children: const [
                        _OnboardingStep(
                          icon: Icons.photo_camera_outlined,
                          title: 'Scan',
                          body:
                              'Use Camera or Gallery to add a collectible photo.',
                        ),
                        SizedBox(height: AppSpacing.md),
                        _OnboardingStep(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Analyze',
                          body:
                              'Mock AI mode identifies the item and prepares pricing fields for beta testing.',
                        ),
                        SizedBox(height: AppSpacing.md),
                        _OnboardingStep(
                          icon: Icons.inventory_2_outlined,
                          title: 'Save',
                          body:
                              'Add the result to your local-first portfolio when you are happy with it.',
                        ),
                        SizedBox(height: AppSpacing.md),
                        _OnboardingStep(
                          icon: Icons.query_stats_outlined,
                          title: 'Track',
                          body:
                              'Follow insights, alerts, wishlist status, and collection goals from the dashboard.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppInfoSection(
                    title: 'Local-first by default',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'You can use CollectIQ AI without signing in. Camera, gallery, mock analysis, portfolio saves, alerts, wishlist, and goals all work locally on this device.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const _OnboardingCallout(
                          icon: Icons.cloud_done_outlined,
                          title: 'Cloud sync is optional',
                          body:
                              'Sign-in and sync are prepared for production, but they are never required to start collecting.',
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        const _OnboardingCallout(
                          icon: Icons.lock_outline,
                          title: 'Privacy conscious',
                          body:
                              'No API keys or personal image paths are sent through telemetry.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: const ValueKey('onboarding-start-scanning'),
                      onPressed: onStartScanning,
                      icon: const Icon(Icons.document_scanner_outlined),
                      label: const Text('Start Scanning'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      key: const ValueKey('onboarding-explore-dashboard'),
                      onPressed: onExploreDashboard,
                      icon: const Icon(Icons.dashboard_outlined),
                      label: const Text('Explore Dashboard'),
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

class _OnboardingStep extends StatelessWidget {
  const _OnboardingStep({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: colorScheme.primary),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                body,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingCallout extends StatelessWidget {
  const _OnboardingCallout({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
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
