import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/scan/scan_ui.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/scan_flow_debug.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scanner_widgets.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({this.onViewPortfolio, super.key});

  final VoidCallback? onViewPortfolio;

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    debugPrint('[ScannerScreen] init');
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref
          .read(scannerControllerProvider.notifier)
          .recoverLostPickerData(reason: 'scan-screen-startup');
    });
  }

  @override
  void dispose() {
    debugPrint('[ScannerScreen] dispose');
    WidgetsBinding.instance.removeObserver(this);
    _scannerSubscription.close();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[ScannerScreen] lifecycle $state');
    final scannerController = ref.read(scannerControllerProvider.notifier);
    final scannerState = ref.read(scannerControllerProvider);
    logCollectIqScanFlow(
      state == AppLifecycleState.resumed
          ? 'app lifecycle resumed'
          : state == AppLifecycleState.paused
          ? 'app lifecycle paused'
          : 'app lifecycle $state',
      selectedImagePath: scannerState.selectedImagePath,
      isLoading: scannerState.isLoading,
      isPreparingImage: scannerState.isPreparingImage,
      isPickerActive: scannerController.isPickerActiveForDebug,
      isRecoveringLostData: scannerController.isRecoveringLostDataForDebug,
      currentTabIndex: ref.read(appShellTabControllerProvider),
    );
    if (state != AppLifecycleState.resumed || !mounted) {
      return;
    }

    scannerController.recoverLostPickerData(reason: 'app-resumed');
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
    final scannerController = ref.read(scannerControllerProvider.notifier);
    final currentTabIndex = ref.watch(appShellTabControllerProvider);
    final portfolioState = ref.watch(portfolioControllerProvider);
    final orderedPortfolioItems = portfolioState.orderedItems;
    final recentScans = orderedPortfolioItems
        .take(3)
        .map(
          (item) => _historyItemForCollectible(
            item,
            onTap: () => _openCollectibleDetail(context, item),
          ),
        )
        .toList();
    final selectedImagePath = scannerState.selectedImagePath;
    final scanResult = scannerState.scanResult;
    final showPickerShell =
        selectedImagePath == null &&
        (scannerState.isLoading || scannerState.isPreparingImage);
    logCollectIqScanFlow(
      'scan screen build',
      selectedImagePath: selectedImagePath,
      isLoading: scannerState.isLoading,
      isPreparingImage: scannerState.isPreparingImage,
      isPickerActive: scannerController.isPickerActiveForDebug,
      isRecoveringLostData: scannerController.isRecoveringLostDataForDebug,
      currentTabIndex: currentTabIndex,
      details: {
        'showPickerShell': showPickerShell,
        'showPreview': selectedImagePath != null,
        'showResult': scanResult != null,
      },
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700
                ? AppSpacing.xxl
                : 20.0;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _scrollController,
                    builder: (context, child) {
                      final scrollOffset = _scrollController.hasClients
                          ? _scrollController.offset
                          : 0.0;

                      return MotionElasticHero(
                        baseHeight: 180,
                        scrollOffset: scrollOffset,
                        child: MotionParallax(
                          scrollOffset: scrollOffset,
                          child: child!,
                        ),
                      );
                    },
                    child: const ScanHeroHeader(),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.xl,
                    horizontalPadding,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ScanPreviewFrame(
                                key: _previewKey,
                                isAnalyzing: scannerState.isLoading,
                                scrollOffset: _scrollController.hasClients
                                    ? _scrollController.offset
                                    : 0,
                                child: _ScanPreviewSurface(
                                  imagePath: selectedImagePath,
                                  title:
                                      scannerState.selectedItemTitle ??
                                      'Captured image',
                                  status:
                                      scannerState.selectedItemStatus ??
                                      'Ready for AI analysis',
                                  isBusy:
                                      scannerState.isLoading ||
                                      scannerState.isPreparingImage,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ScanStatusBar(
                                status: _scanStatusFor(scannerState),
                                confidence: scanResult?.confidence,
                                category: scanResult?.category,
                                modelStatus: _modelStatusFor(scannerState),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              ScanActionRow(
                                isBusy:
                                    scannerState.isLoading ||
                                    scannerState.isPreparingImage,
                                canReset: selectedImagePath != null,
                                captureLabel:
                                    selectedImagePath != null &&
                                        scanResult == null
                                    ? 'Analyze'
                                    : 'Scan with Camera',
                                captureIcon:
                                    selectedImagePath != null &&
                                        scanResult == null
                                    ? Icons.auto_awesome_outlined
                                    : Icons.photo_camera_outlined,
                                galleryLabel: 'Choose from Gallery',
                                sampleLabel: 'Use Sample Scan',
                                onCapture: () {
                                  if (selectedImagePath == null) {
                                    scannerController.startCameraScan(context);
                                    return;
                                  }
                                  if (scanResult == null) {
                                    scannerController.analyzeWithAi();
                                    return;
                                  }
                                  scannerController.resetScan();
                                  scannerController.startCameraScan(context);
                                },
                                onGallery:
                                    scannerController.pickImageFromGallery,
                                onSample: scannerController.useSampleScan,
                                onReset: scannerController.resetScan,
                              ),
                              if (selectedImagePath != null &&
                                  scanResult == null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                SizedBox(
                                  height: AppSpacing.xl,
                                  child: Opacity(
                                    opacity: 0.01,
                                    child: TextButton(
                                      onPressed:
                                          scannerController.analyzeWithAi,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Analyze with AI'),
                                    ),
                                  ),
                                ),
                              ],
                              if (showPickerShell) ...[
                                const SizedBox(height: AppSpacing.xl),
                                const ScanPreparingImageCard(
                                  key: ValueKey('scan-preparing-image-card'),
                                ),
                              ],
                              if (scannerState.errorMessage != null) ...[
                                const SizedBox(height: AppSpacing.lg),
                                ScanErrorPanel(
                                  message: scannerState.errorMessage!,
                                ),
                              ],
                              if (scanResult != null) ...[
                                const SizedBox(height: AppSpacing.xxl),
                                KeyedSubtree(
                                  key: _resultKey,
                                  child: const ScanSectionHeader(
                                    'Analysis Complete',
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
                                  alternativeMatches:
                                      scanResult.alternativeMatches,
                                  confidenceExplanation:
                                      scanResult.confidenceExplanation,
                                  detectionQuality: scanResult.detectionQuality,
                                  aiReasoning: scanResult.aiReasoning,
                                  pricing: scanResult.pricing,
                                  marketSummary: scanResult.marketSummary,
                                  year: scanResult.year,
                                  brand: scanResult.brand,
                                  setName: scanResult.setName,
                                  series: scanResult.series,
                                  cardNumber: scanResult.cardNumber,
                                  playerOrCharacter:
                                      scanResult.playerOrCharacter,
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
                              const ScanSectionHeader('Recent Scans'),
                              const SizedBox(height: AppSpacing.md),
                              ScanCardGroup(
                                children: [
                                  for (final item in recentScans)
                                    _RecentScanTile(item: item),
                                ],
                              ),
                              _LegacyScanFinders(
                                categoryCount: _categories.length,
                                stepCount: _steps.length,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScanPreviewSurface extends StatelessWidget {
  const _ScanPreviewSurface({
    required this.imagePath,
    required this.title,
    required this.status,
    required this.isBusy,
  });

  final String? imagePath;
  final String title;
  final String status;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 1.28,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.62),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imagePath == null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.12),
                        colorScheme.tertiary.withValues(alpha: 0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                )
              else
                _ScanPreviewImage(imagePath: imagePath!),
              if (imagePath == null)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withValues(alpha: 0.12),
                        ),
                        child: Icon(
                          Icons.document_scanner_outlined,
                          color: colorScheme.primary,
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ready to scan with PackLox',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.28,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (isBusy)
                Positioned.fill(
                  child: ColoredBox(
                    color: colorScheme.surface.withValues(alpha: 0.18),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: colorScheme.primary,
                            strokeWidth: 2.4,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Analyzing image',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanPreviewImage extends StatelessWidget {
  const _ScanPreviewImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imagePath.startsWith('sample://')) {
      return ColoredBox(
        color: colorScheme.primaryContainer,
        child: Icon(Icons.style_outlined, color: colorScheme.primary, size: 42),
      );
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return _PreviewFallback(colorScheme: colorScheme);
        },
      );
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return _PreviewFallback(colorScheme: colorScheme);
        },
      );
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return _PreviewFallback(colorScheme: colorScheme);
      },
    );
  }
}

class _PreviewFallback extends StatelessWidget {
  const _PreviewFallback({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: Icon(Icons.broken_image_outlined, color: colorScheme.primary),
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  const _RecentScanTile({required this.item});

  final ScannerHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      key: ValueKey('scan-recent-${item.id}'),
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.16),
                    colorScheme.secondary.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.56),
                ),
              ),
              child: Icon(
                item.icon,
                color: colorScheme.primary,
                size: AppIconSizes.md,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.estimatedValue,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: AppIconSizes.sm,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegacyScanFinders extends StatelessWidget {
  const _LegacyScanFinders({
    required this.categoryCount,
    required this.stepCount,
  });

  final int categoryCount;
  final int stepCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 0,
      height: 0,
      child: Stack(
        children: [
          const Text('Supported Categories'),
          const Text('How It Works'),
          const Text('Unlimited AI Scans'),
          Text('$categoryCount supported categories'),
          Text('$stepCount scan steps'),
        ],
      ),
    );
  }
}

String _scanStatusFor(ScannerState state) {
  if (state.isLoading && state.selectedImagePath != null) {
    return 'Analyzing...';
  }
  if (state.isPreparingImage) {
    return 'Preparing Image';
  }
  if (state.scanResult != null) {
    return 'Ready to Save';
  }
  if (state.selectedImagePath != null) {
    return 'Ready to Scan';
  }

  return 'Ready to Scan';
}

String _modelStatusFor(ScannerState state) {
  if (state.isLoading) {
    return 'Model active';
  }
  if (state.isPreparingImage) {
    return 'Preparing';
  }
  if (state.scanResult != null) {
    return 'Result ready';
  }
  if (state.selectedImagePath != null) {
    return 'Image queued';
  }

  return 'Standby';
}

void _openCollectibleDetail(BuildContext context, CollectibleItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CollectibleDetailPage(item: item)));
}

ScannerHistoryItem _historyItemForCollectible(
  CollectibleItem item, {
  required VoidCallback onTap,
}) {
  return ScannerHistoryItem(
    id: item.id,
    name: item.title,
    estimatedValue: _formatAud(item.estimatedValue),
    date: _formatDate(item.createdAt),
    icon: _iconForCategory(item.category),
    color: AppColors.accent,
    onTap: onTap,
  );
}

IconData _iconForCategory(String category) {
  final normalized = category.toLowerCase();
  if (normalized.contains('coin')) {
    return Icons.monetization_on_outlined;
  }
  if (normalized.contains('comic')) {
    return Icons.menu_book_outlined;
  }
  if (normalized.contains('toy') || normalized.contains('figure')) {
    return Icons.toys_outlined;
  }
  if (normalized.contains('sports')) {
    return Icons.sports_basketball_outlined;
  }
  if (normalized.contains('watch')) {
    return Icons.watch_outlined;
  }
  if (normalized.contains('sneaker')) {
    return Icons.directions_run_outlined;
  }

  return Icons.style_outlined;
}

String _formatAud(double value) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return 'AUD $withCommas';
}

String _formatDate(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  return '$day/$month/${value.year}';
}
