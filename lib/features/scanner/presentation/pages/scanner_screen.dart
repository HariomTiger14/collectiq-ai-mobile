import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scanner_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScannerScreen extends ConsumerWidget {
  const ScannerScreen({super.key});

  static const _categories = [
    'Sports Cards',
    'Pokemon Cards',
    'Coins',
    'Banknotes',
    'Comics',
    'Vinyl Records',
    'Watches',
    'Sneakers',
    'Luxury Handbags',
    'Action Figures',
  ];

  static const _steps = [
    ScannerStep(
      title: 'Capture',
      description: 'Take a sharp photo or import an image from your gallery.',
      icon: Icons.photo_camera_outlined,
      color: AppColors.accent,
    ),
    ScannerStep(
      title: 'AI Analysis',
      description:
          'CollectIQ checks rarity, condition cues, and visual detail.',
      icon: Icons.psychology_alt_outlined,
      color: AppColors.accent,
    ),
    ScannerStep(
      title: 'Market Value',
      description: 'Review an instant estimate from comparable market signals.',
      icon: Icons.paid_outlined,
      color: AppColors.accent,
    ),
  ];

  static const _recentScans = [
    ScannerHistoryItem(
      name: '1986 Fleer Jordan Rookie',
      estimatedValue: r'$12,300',
      date: 'Today',
      icon: Icons.sports_basketball_outlined,
      color: AppColors.accent,
    ),
    ScannerHistoryItem(
      name: 'Charizard Base Set Holo',
      estimatedValue: r'$4,850',
      date: 'Today',
      icon: Icons.style_outlined,
      color: AppColors.accent,
    ),
    ScannerHistoryItem(
      name: 'Silver Eagle Proof Coin',
      estimatedValue: r'$780',
      date: 'Yesterday',
      icon: Icons.monetization_on_outlined,
      color: AppColors.accent,
    ),
    ScannerHistoryItem(
      name: 'Omega Seamaster Vintage',
      estimatedValue: r'$3,420',
      date: 'Jun 25',
      icon: Icons.watch_outlined,
      color: AppColors.accent,
    ),
    ScannerHistoryItem(
      name: 'Air Jordan 1 Chicago',
      estimatedValue: r'$1,950',
      date: 'Jun 24',
      icon: Icons.directions_run_outlined,
      color: AppColors.accent,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final scannerState = ref.watch(scannerControllerProvider);
    final selectedImagePath = scannerState.selectedImagePath;
    final scanResult = scannerState.scanResult;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700
                ? AppSpacing.xxl
                : AppSpacing.lg;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.xl,
                horizontalPadding,
                AppSpacing.xxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScannerHeader(),
                      const SizedBox(height: AppSpacing.xxl),
                      const ScanHeroCard(),
                      if (selectedImagePath != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        ScanPreviewCard(
                          imagePath: selectedImagePath,
                          image: scannerState.selectedImage,
                          title:
                              scannerState.selectedItemTitle ??
                              'Captured image',
                          status:
                              scannerState.selectedItemStatus ??
                              'Ready for AI analysis',
                        ),
                      ],
                      if (scanResult != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        AiResultCard(
                          item: scanResult.title,
                          category: scanResult.category,
                          estimatedValue:
                              'AUD ${scanResult.estimatedValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}',
                          confidence:
                              '${(scanResult.confidence * 100).toStringAsFixed(0)}%',
                          condition: scanResult.condition,
                          primaryMatch: scanResult.primaryMatch,
                          alternativeMatches: scanResult.alternativeMatches,
                          confidenceExplanation:
                              scanResult.confidenceExplanation,
                          detectionQuality: scanResult.detectionQuality,
                          aiReasoning: scanResult.aiReasoning,
                          recommendation:
                              scannerState.aiRecommendation ??
                              'Consider grading before selling.',
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      const ScannerSectionTitle(title: 'Supported Categories'),
                      const SizedBox(height: AppSpacing.md),
                      const SupportedCategoriesWrap(categories: _categories),
                      const SizedBox(height: AppSpacing.xxl),
                      const ScannerSectionTitle(title: 'How It Works'),
                      const SizedBox(height: AppSpacing.md),
                      const ScannerStepsRow(steps: _steps),
                      const SizedBox(height: AppSpacing.xxl),
                      const ScannerSectionTitle(title: 'Recent Scans'),
                      const SizedBox(height: AppSpacing.md),
                      const ScannerHistoryList(items: _recentScans),
                      const SizedBox(height: AppSpacing.xxl),
                      const ScannerPremiumCard(),
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
