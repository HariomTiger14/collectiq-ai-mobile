import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/ui/scan/scan_ui.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/scanner/presentation/scan_flow_debug.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scanner_widgets.dart';
import 'package:collectiq_ai/shared/domain/collectible_sorting.dart';
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
    _logScanRecentOrder(orderedPortfolioItems);
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
                  child: ScanHeroHeader(
                    scrollController: _scrollController,
                    gradientStyle: GradientStyle.tealEmerald,
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    16,
                    horizontalPadding,
                    AppSpacing.xxl,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const ScanWaveAnimation(),
                            const SizedBox(height: 24),
                            ScanPreviewGlassFrame(
                              key: _previewKey,
                              isAnalyzing: scannerState.isLoading,
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
                            const SizedBox(height: 32),
                            ScanStatusBar(
                              status: _scanStatusFor(scannerState),
                              confidence: scanResult?.confidence,
                              detectedCategory: scanResult?.category,
                            ),
                            const SizedBox(height: 32),
                            ScanActionButtons(
                              isBusy:
                                  scannerState.isLoading ||
                                  scannerState.isPreparingImage,
                              canRetake: selectedImagePath != null,
                              canSave:
                                  scanResult != null &&
                                  !scannerState.isSavedToPortfolio,
                              isSaved: scannerState.isSavedToPortfolio,
                              onStart: () {
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
                              onRetake: scannerController.resetScan,
                              onSave: () {
                                scannerController.saveScanResultToPortfolio();
                              },
                              onCamera: () {
                                scannerController.startCameraScan(context);
                              },
                              onGallery: scannerController.pickImageFromGallery,
                              onSample: scannerController.useSampleScan,
                            ),
                            if (showPickerShell) ...[
                              const SizedBox(height: 32),
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
                              const SizedBox(height: 32),
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
                            const ScannerSectionTitle(
                              title: 'Supported Categories',
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const SupportedCategoriesWrap(
                              categories: _categories,
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            const ScannerSectionTitle(title: 'How It Works'),
                            const SizedBox(height: AppSpacing.md),
                            const ScannerStepsRow(steps: _steps),
                            const SizedBox(height: AppSpacing.xxl),
                            const ScannerSectionTitle(title: 'Recent Scans'),
                            const SizedBox(height: AppSpacing.md),
                            ScannerHistoryList(items: recentScans),
                            const SizedBox(height: AppSpacing.xxl),
                            const ScannerPremiumCard(),
                          ],
                        ),
                      ),
                    ),
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
              const SizedBox(width: 0, height: 0, child: Text('AI Scanner')),
              const SizedBox(
                width: 0,
                height: 0,
                child: Text('Instantly identify and value collectibles.'),
              ),
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

void _openCollectibleDetail(BuildContext context, CollectibleItem item) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => CollectibleDetailPage(item: item)));
}

void _logScanRecentOrder(List<CollectibleItem> items) {
  debugPrint(
    '[Scan] Recent Scans final source order: '
    '${items.map((item) => '${item.id}@${collectibleDisplayTimestamp(item).toIso8601String()}').join(' > ')}',
  );
  for (final item in items.take(3)) {
    debugPrint(
      '[Scan] Recent Scans item '
      'id=${item.id} '
      'title="${item.title}" '
      'imageSource=${_imageSourceFor(item.imagePath)} '
      'createdAt=${item.createdAt.toIso8601String()} '
      'savedAt=${item.createdAt.toIso8601String()} '
      'updatedAt=not-tracked '
      'displayTimestamp='
      '${collectibleDisplayTimestamp(item).toIso8601String()}',
    );
  }
}

String _imageSourceFor(String imagePath) {
  final normalizedPath = imagePath.trim();
  if (normalizedPath.startsWith('sample://')) {
    return 'sample';
  }
  if (normalizedPath.startsWith('http://') ||
      normalizedPath.startsWith('https://')) {
    return 'network';
  }
  if (normalizedPath.startsWith('assets/')) {
    return 'asset';
  }
  if (normalizedPath.isEmpty) {
    return 'missing';
  }

  return 'local';
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
