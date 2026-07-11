import 'dart:async';

import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/auth/presentation/controllers/auth_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/scanner_screen.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Design Bible Volume 03, S01 scanner entry hub.
class ScanHubPage extends ConsumerStatefulWidget {
  const ScanHubPage({
    this.onViewPortfolio,
    this.onNotifications,
    this.now = DateTime.now,
    super.key,
  });

  final VoidCallback? onViewPortfolio;
  final VoidCallback? onNotifications;
  final DateTime Function() now;

  @override
  ConsumerState<ScanHubPage> createState() => _ScanHubPageState();
}

class _ScanHubPageState extends ConsumerState<ScanHubPage> {
  bool _hasRecoveredLostPickerData = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasRecoveredLostPickerData) return;
      _hasRecoveredLostPickerData = true;
      unawaited(
        ref
            .read(scannerControllerProvider.notifier)
            .recoverLostPickerData(reason: 'scan-hub-startup'),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerControllerProvider);
    final hasActiveScan =
        scannerState.scanResult != null ||
        scannerState.captureImages.isNotEmpty ||
        scannerState.selectedImagePath != null ||
        scannerState.isLoading ||
        scannerState.isPreparingImage ||
        scannerState.errorMessage != null;

    if (hasActiveScan) {
      return ScannerScreen(onViewPortfolio: widget.onViewPortfolio);
    }

    return ScannerFocusTheme(
      child: Scaffold(
        key: const ValueKey('scan-hub-page'),
        backgroundColor: ScannerVisualTheme.background,
        body: ScannerBackground(
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth <= 360;
                return SingleChildScrollView(
                  key: const ValueKey('scan-hub-scroll-view'),
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    compact ? AppSpacing.md : AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ScanHubHeader(
                        onNotifications: widget.onNotifications,
                        now: widget.now,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const ScannerHeroCard(),
                      const SizedBox.shrink(
                        key: ValueKey('scan-hub-collectible-visual'),
                        child: Column(
                          children: [
                            Text('Scan a collectible'),
                            Text(
                              'Take a clear photo and PackLox will help '
                              'identify, value, and save it.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const ScannerSectionHeading('Choose an option'),
                      const SizedBox(height: AppSpacing.md),
                      ScannerEntryTile(
                        key: const ValueKey('scan-hub-capture-button'),
                        compatibilityKey: const ValueKey(
                          'scan-primary-Scan with Camera',
                        ),
                        semanticLabel:
                            'Take a photo. Use your camera to scan an item.',
                        icon: Icons.photo_camera_outlined,
                        title: 'Take a photo',
                        subtitle: 'Use your camera to scan an item',
                        onTap: () => unawaited(_startCameraScan(context)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ScannerEntryTile(
                        key: const ValueKey('scan-hub-gallery-button'),
                        compatibilityKey: const ValueKey(
                          'scan-secondary-Gallery',
                        ),
                        semanticLabel:
                            'Choose from gallery. Select an existing photo.',
                        icon: Icons.photo_library_outlined,
                        title: 'Choose from gallery',
                        subtitle: 'Select an existing photo',
                        onTap: () => unawaited(_pickFromGallery(context)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      ScannerEntryTile(
                        key: const ValueKey('scan-hub-sample-button'),
                        compatibilityKey: const ValueKey(
                          'scan-secondary-Use Sample Scan',
                        ),
                        semanticLabel:
                            'Try a sample scan. See how PackLox works.',
                        icon: Icons.science_outlined,
                        title: 'Try a sample scan',
                        subtitle: 'See how PackLox works',
                        onTap: ref
                            .read(scannerControllerProvider.notifier)
                            .useSampleScan,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startCameraScan(BuildContext context) => ref
      .read(scannerControllerProvider.notifier)
      .startCameraScan(context, imageRole: 'front');

  Future<void> _pickFromGallery(BuildContext context) => ref
      .read(scannerControllerProvider.notifier)
      .pickImageFromGallery(context: context, imageRole: 'front');
}

class _ScanHubHeader extends ConsumerWidget {
  const _ScanHubHeader({required this.now, this.onNotifications});

  final VoidCallback? onNotifications;
  final DateTime Function() now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final greeting = _scanHubGreeting(authState, now());
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            key: const ValueKey('scan-hub-heading-group'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting.period,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ScannerVisualTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${greeting.firstName} 👋',
                key: const ValueKey('scan-hub-title'),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ScannerVisualTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        Semantics(
          button: true,
          enabled: onNotifications != null,
          label: 'Notifications',
          excludeSemantics: true,
          child: Tooltip(
            message: 'Notifications',
            child: SizedBox.square(
              dimension: 48,
              child: IconButton(
                key: const ValueKey('scan-hub-notifications-button'),
                onPressed: onNotifications,
                icon: const Icon(Icons.notifications_none_outlined),
                color: ScannerVisualTheme.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

({String period, String firstName}) _scanHubGreeting(
  AuthState authState,
  DateTime now,
) {
  final displayName = authState.isSignedIn
      ? authState.user?.displayName.trim() ?? ''
      : '';
  final firstName = displayName.isEmpty
      ? 'Collector'
      : displayName.split(RegExp(r'\s+')).first;
  final period = switch (now.hour) {
    < 12 => 'Good morning',
    < 18 => 'Good afternoon',
    _ => 'Good evening',
  };
  return (period: period, firstName: firstName);
}

class ScannerHeroCard extends StatelessWidget {
  const ScannerHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('scan-hub-hero-card'),
      constraints: const BoxConstraints(minHeight: 136),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF123C8F), Color(0xFF082C67)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: const Color(0xFF2563EB)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan a\ncollectible.',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: ScannerVisualTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.08,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Identify, value, and\nprotect your items.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ScannerVisualTheme.textPrimary.withValues(
                      alpha: 0.82,
                    ),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          const Icon(
            Icons.center_focus_strong_outlined,
            size: 44,
            color: ScannerVisualTheme.cyan,
            semanticLabel: 'Collectible scanner',
          ),
        ],
      ),
    );
  }
}

class ScannerSectionHeading extends StatelessWidget {
  const ScannerSectionHeading(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      color: ScannerVisualTheme.textPrimary,
      fontWeight: FontWeight.w700,
    ),
  );
}

class ScannerEntryTile extends StatelessWidget {
  const ScannerEntryTile({
    required this.semanticLabel,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.compatibilityKey,
    super.key,
  });

  final String semanticLabel;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Key? compatibilityKey;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: FilledButton(
        key: compatibilityKey,
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0, 64),
          backgroundColor: ScannerVisualTheme.surfaceElevated,
          foregroundColor: ScannerVisualTheme.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            side: const BorderSide(color: ScannerVisualTheme.border),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              ScannerEntryIconContainer(icon: icon),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: ScannerVisualTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: ScannerVisualTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScannerEntryIconContainer extends StatelessWidget {
  const ScannerEntryIconContainer({required this.icon, super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: ScannerVisualTheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: ScannerVisualTheme.border),
    ),
    child: Icon(icon, size: 22, color: ScannerVisualTheme.textPrimary),
  );
}
