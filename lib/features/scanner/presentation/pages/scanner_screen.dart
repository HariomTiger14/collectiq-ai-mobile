import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scanner_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({this.onViewPortfolio, super.key});

  final VoidCallback? onViewPortfolio;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _scrollController = ScrollController();
  final _previewKey = GlobalKey();
  final _resultKey = GlobalKey();
  late final ProviderSubscription<ScannerState> _scannerSubscription;
  String? _lastScrolledPreviewPath;
  String? _lastScrolledResultId;

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
  void initState() {
    super.initState();
    _scannerSubscription = ref.listenManual<ScannerState>(
      scannerControllerProvider,
      (previous, next) {
        final selectedImagePath = next.selectedImagePath;
        if (selectedImagePath != null &&
            selectedImagePath != _lastScrolledPreviewPath) {
          _lastScrolledPreviewPath = selectedImagePath;
          _scrollTo(_previewKey);
        }
        final scanResultId = next.scanResult?.id;
        if (scanResultId != null && scanResultId != _lastScrolledResultId) {
          _lastScrolledResultId = scanResultId;
          _scrollTo(_resultKey);
        }
        if (previous?.scanResult != null && next.scanResult == null) {
          _lastScrolledPreviewPath = null;
          _lastScrolledResultId = null;
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
            );
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _scannerSubscription.close();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
              controller: _scrollController,
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
                          key: _previewKey,
                          imagePath: selectedImagePath,
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
                        KeyedSubtree(
                          key: _resultKey,
                          child: const ScannerSectionTitle(
                            title: 'Analysis Complete',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AiResultCard(
                          key: ValueKey('scan-result-${scanResult.id}'),
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
                          pricing: scanResult.pricing,
                          year: scanResult.year,
                          brand: scanResult.brand,
                          setName: scanResult.setName,
                          series: scanResult.series,
                          cardNumber: scanResult.cardNumber,
                          playerOrCharacter: scanResult.playerOrCharacter,
                          rarity: scanResult.rarity,
                          estimatedGrade: scanResult.estimatedGrade,
                          language: scanResult.language,
                          edition: scanResult.edition,
                          country: scanResult.country,
                          mint: scanResult.mint,
                          material: scanResult.material,
                          notes: scanResult.notes,
                          recommendation:
                              scannerState.aiRecommendation ??
                              'Consider grading before selling.',
                          isSaved: scannerState.isSavedToPortfolio,
                          onViewPortfolio: widget.onViewPortfolio,
                          onScanAnother: ref
                              .read(scannerControllerProvider.notifier)
                              .resetScan,
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
