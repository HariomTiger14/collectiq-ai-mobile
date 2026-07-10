import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/navigation/app_shell_controller.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/ui/scan/scan_ui.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/pages/collectible_detail_page.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/captured_scan_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/confidence_model.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_capture_role.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_goal.dart';
import 'package:collectiq_ai/features/scanner/domain/services/scan_capture_plan_service.dart';
import 'package:collectiq_ai/features/scanner/presentation/scan_flow_debug.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/capture_workspace.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scanner_widgets.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
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
          if (!mounted) {
            return;
          }
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
      if (!mounted) {
        return;
      }
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
    final currentTabIndex = ref.read(appShellTabControllerProvider);
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
    final activeGoal =
        scannerState.scanSession?.scanGoal ?? ScanGoal.identifyValue;
    final activePlan =
        scannerState.scanSession?.capturePlan ??
        const ScanCapturePlanService().buildPlan(
          activeGoal,
          null,
          scannerState.scanSession?.capturedImages ?? const [],
        );
    final smartGuidance = ref
        .watch(smartScanGuidanceServiceProvider)
        .buildGuidance(
          category: scannerState.captureCategory,
          images: _guidanceImagesFromSlots(scannerState.captureImages),
          goal: activeGoal,
        );
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
                        baseHeight: 158,
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
                    AppSpacing.lg,
                    horizontalPadding,
                    AppSpacing.xl,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 960),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ScanStatusBar(
                                status: _scanStatusFor(scannerState),
                                confidence: scanResult?.confidence,
                                category: _scanCategoryStatus(scannerState),
                                modelStatus: _modelStatusFor(scannerState),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              _SmartScanSummary(
                                categoryLabel: _scanCategoryStatus(
                                  scannerState,
                                ),
                                headline: smartGuidance.headline,
                                guidance: smartGuidance.guidance,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _AdvancedScanOptions(
                                child: _ScanGoalSelector(
                                  selectedGoal: activeGoal,
                                  onGoalSelected: scannerController.selectGoal,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              _CategoryOptions(
                                categoryLabel: _scanCategoryStatus(
                                  scannerState,
                                ),
                                child: _CaptureCategorySelector(
                                  selectedCategory:
                                      scannerState.hasManualCaptureCategory
                                      ? scannerState.captureCategory
                                      : null,
                                  onCategorySelected:
                                      scannerController.selectCaptureCategory,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              CaptureWorkspace(
                                key: _previewKey,
                                goal: activeGoal,
                                category: scannerState.captureCategory,
                                categoryLabel: _workspaceCategoryStatus(
                                  scannerState,
                                ),
                                hasManualCategory:
                                    scannerState.hasManualCaptureCategory,
                                detectedCategory: scanResult?.category,
                                plan: activePlan,
                                slots: scannerState.photoSlots,
                                captureImages: scannerState.captureImages,
                                selectedItemTitle:
                                    scannerState.selectedItemTitle,
                                selectedItemStatus:
                                    scannerState.selectedItemStatus,
                                isBusy:
                                    scannerState.isLoading ||
                                    scannerState.isPreparingImage,
                                hasResult: scanResult != null,
                                selectedPath: selectedImagePath,
                                activeRoleId: scannerState.activeCaptureRole,
                                onPrimaryCapture: () {
                                  final role =
                                      scannerState.activeCaptureRole == null
                                      ? activePlan.nextRecommendedRole ??
                                            ScanCaptureRole.front
                                      : ScanCaptureRole.fromId(
                                          scannerState.activeCaptureRole!,
                                        );
                                  scannerController.startCameraScan(
                                    context,
                                    imageRole: role.id,
                                  );
                                },
                                onAnalyze: scannerController.analyzeWithAi,
                                onCamera: (role) => scannerController
                                    .startCameraScan(context, imageRole: role),
                                onGallery: (role) =>
                                    scannerController.pickImageFromGallery(
                                      context: context,
                                      imageRole: role,
                                    ),
                                onSelectRole:
                                    scannerController.selectCaptureRole,
                                onPreview:
                                    scannerController.selectCapturedPhoto,
                                onUseAsPrimary:
                                    scannerController.useCapturedPhotoAsPrimary,
                                onEnhance:
                                    scannerController.applyEnhancementToPhoto,
                                onSample: scannerController.useSampleScan,
                                onDelete: scannerController.deleteCapturedImage,
                                onReset: scannerController.resetScan,
                              ),
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
                                  estimatedValue: _formatScanValue(
                                    scanResult.estimatedValue,
                                    scanResult.valuationStatus,
                                  ),
                                  confidence:
                                      '${(scanResult.confidence * 100).toStringAsFixed(0)}%',
                                  condition: scanResult.condition,
                                  imagePath: scanResult.thumbnail,
                                  confidenceScore: scanResult.confidence,
                                  rawEstimatedValue: scanResult.estimatedValue,
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
                                  isSaving: scannerState.isSavingToPortfolio,
                                  photosUsed: scanResult.photosUsed,
                                  photoRoles: scanResult.photoRoles,
                                  galleryImages: scanResult.galleryImages,
                                  faceValue: scanResult.faceValue,
                                  estimatedMarketValue:
                                      scanResult.estimatedMarketValue,
                                  askingPriceWarning:
                                      scanResult.askingPriceWarning,
                                  valuationConfidence:
                                      scanResult.valuationConfidence,
                                  valuationStatus: scanResult.valuationStatus,
                                  valuationSource: scanResult.valuationSource,
                                  aiEstimatedValue: scanResult.aiEstimatedValue,
                                  onViewPortfolio: widget.onViewPortfolio,
                                  onScanAnother: ref
                                      .read(scannerControllerProvider.notifier)
                                      .resetScan,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                _ScanResultGoalSummary(
                                  goal:
                                      scannerState.scanSession?.scanGoal ??
                                      ScanGoal.identifyValue,
                                  imageCount: scannerState.captureImages.length,
                                  confidenceModel: ConfidenceModel(
                                    confidenceTarget:
                                        scannerState
                                            .scanSession
                                            ?.confidenceTarget ??
                                        ScanGoal.identifyValue.confidenceTarget,
                                    confidenceAchieved: scanResult.confidence,
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                              const ScanSectionHeader('Recent Scans'),
                              const SizedBox(height: AppSpacing.sm),
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

String _formatScanValue(double value, ValuationStatus status) {
  if (value <= 0) {
    return _valuationStatusMessage(status);
  }

  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

String _scanCategoryStatus(ScannerState state) {
  final detected = state.scanResult?.category.trim();
  if (detected != null && detected.isNotEmpty) {
    return 'Detected: $detected';
  }
  if (state.hasManualCaptureCategory) {
    return 'Selected: ${state.captureCategory.title}';
  }
  return 'Not selected yet';
}

String _workspaceCategoryStatus(ScannerState state) {
  if (state.scanResult != null &&
      state.scanResult!.category.trim().isNotEmpty) {
    return 'Detected: ${state.scanResult!.category.trim()}';
  }
  if (state.hasManualCaptureCategory) {
    return 'Selected: ${state.captureCategory.title}';
  }
  return 'Not selected yet';
}

String _valuationStatusMessage(ValuationStatus status) {
  return switch (status) {
    ValuationStatus.providerNotConfigured =>
      'Market value unavailable — pricing source not connected yet',
    ValuationStatus.noMarketMatch => 'No reliable market match found yet',
    ValuationStatus.lookupFailed => 'Value lookup failed — try again',
    ValuationStatus.aiEstimated => 'AI-estimated value unavailable',
    ValuationStatus.marketEstimated => 'Value unavailable',
    ValuationStatus.unavailable => 'Value unavailable',
  };
}

class _ScanGoalSelector extends StatelessWidget {
  const _ScanGoalSelector({
    required this.selectedGoal,
    required this.onGoalSelected,
  });

  final ScanGoal selectedGoal;
  final ValueChanged<ScanGoal> onGoalSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ScanGoal.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final goal = ScanGoal.values[index];
          return _CompactGoalChip(
            goal: goal,
            selected: goal == selectedGoal,
            onTap: () => onGoalSelected(goal),
          );
        },
      ),
    );
  }
}

class _SmartScanSummary extends StatelessWidget {
  const _SmartScanSummary({
    required this.categoryLabel,
    required this.headline,
    required this.guidance,
  });

  final String categoryLabel;
  final String headline;
  final String guidance;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      key: const ValueKey('scan-smart-scan-summary'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.auto_awesome_outlined, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Scan',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Auto Detect - $categoryLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  guidance,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.25,
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

class _AdvancedScanOptions extends StatelessWidget {
  const _AdvancedScanOptions({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _CollapsedScanOptions(
      key: const ValueKey('advanced-scan-options'),
      tileKey: const ValueKey('advanced-scan-options-tile'),
      title: 'Advanced scan options',
      subtitle: 'Optional controls',
      icon: Icons.tune_outlined,
      child: child,
    );
  }
}

class _CategoryOptions extends StatelessWidget {
  const _CategoryOptions({required this.categoryLabel, required this.child});

  final String categoryLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final selected = categoryLabel.startsWith('Selected:');
    return _CollapsedScanOptions(
      key: const ValueKey('scan-category-options'),
      tileKey: const ValueKey('scan-category-options-tile'),
      title: selected ? 'Choose category' : 'Can\'t identify? Choose category',
      subtitle: selected ? categoryLabel : 'Auto Detect - $categoryLabel',
      icon: Icons.category_outlined,
      child: child,
    );
  }
}

class _CollapsedScanOptions extends StatelessWidget {
  const _CollapsedScanOptions({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.tileKey,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final Key? tileKey;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            key: tileKey,
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            leading: Icon(icon, size: 19, color: colorScheme.primary),
            title: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: [child],
          ),
        ),
      ),
    );
  }
}

class _CaptureCategorySelector extends StatelessWidget {
  const _CaptureCategorySelector({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final CollectibleCategory? selectedCategory;
  final ValueChanged<CollectibleCategory> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: CollectibleCategory.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = CollectibleCategory.values[index];
          final selected = category == selectedCategory;
          return ChoiceChip(
            key: ValueKey('scan-category-${category.id}'),
            selected: selected,
            label: Text(category.title),
            onSelected: (_) => onCategorySelected(category),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _CompactGoalChip extends StatelessWidget {
  const _CompactGoalChip({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final ScanGoal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.10)
          : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 1.4 : 1,
        ),
      ),
      child: InkWell(
        key: ValueKey('scan-goal-${goal.id}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(goal.icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(
                goal.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanResultGoalSummary extends StatelessWidget {
  const _ScanResultGoalSummary({
    required this.goal,
    required this.imageCount,
    required this.confidenceModel,
  });

  final ScanGoal goal;
  final int imageCount;
  final ConfidenceModel confidenceModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final belowTarget =
        confidenceModel.confidenceAchieved != null &&
        !confidenceModel.isTargetMet;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${goal.title} - $imageCount image${imageCount == 1 ? '' : 's'}',
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          if (belowTarget) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Improve accuracy with additional guided photos.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (goal == ScanGoal.prepareForSale) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Generate Listing Assets'),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  const _RecentScanTile({required this.item});

  final ScannerHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final thumbnailPath = item.thumbnailPath;

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
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.56),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: thumbnailPath == null
                  ? Icon(
                      item.icon,
                      key: ValueKey('scan-recent-placeholder-${item.id}'),
                      color: colorScheme.primary,
                      size: AppIconSizes.md,
                    )
                  : ScanThumbnail(
                      key: ValueKey('scan-recent-thumbnail-${item.id}'),
                      imagePath: thumbnailPath,
                    ),
            ),
            if (thumbnailPath != null)
              const SizedBox(width: AppSpacing.md)
            else
              const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.h3.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w800,
                      height: 1.12,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    item.activityLabel ?? item.date,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
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
  final captureCount = state.captureImages.length;
  if (captureCount > 0) {
    final plan = state.scanSession?.capturePlan;
    if (plan?.isMinimumReadyForAnalyze ?? false) {
      return '$captureCount photo${captureCount == 1 ? '' : 's'} ready';
    }
    return '$captureCount photo${captureCount == 1 ? '' : 's'} captured';
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
  final plan = state.scanSession?.capturePlan;
  final nextRole = plan?.nextRecommendedRole;
  if (state.captureImages.isNotEmpty) {
    if (plan?.isMinimumReadyForAnalyze ?? false) {
      return 'Ready for analysis';
    }
    return nextRole == null ? 'Keep capturing' : 'Next: ${nextRole.title}';
  }

  return 'Start with the front photo';
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
    activityLabel: _recentScanActivityLabel(item),
    icon: _iconForCategory(item.category),
    thumbnailPath: _thumbnailPathForCollectible(item),
    color: AppColors.accent,
    onTap: onTap,
  );
}

String _recentScanActivityLabel(CollectibleItem item) {
  final parts = <String>[_scannedWhenLabel(item.createdAt)];
  if (_hasEnhancedGalleryImage(item)) {
    parts.add('Analyzed with AI Enhance');
  }
  if (item.confidence > 0) {
    parts.add('${(item.confidence * 100).round()}% confidence');
  }
  return parts.join(' - ');
}

String _scannedWhenLabel(DateTime createdAt) {
  final now = DateTime.now();
  final localCreated = createdAt.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final createdDay = DateTime(
    localCreated.year,
    localCreated.month,
    localCreated.day,
  );
  final days = today.difference(createdDay).inDays;
  if (days == 0) {
    return 'Scanned today';
  }
  if (days == 1) {
    return 'Scanned yesterday';
  }
  return 'Scanned ${_formatDate(createdAt)}';
}

bool _hasEnhancedGalleryImage(CollectibleItem item) {
  return item.galleryImages.any((image) {
    final preset = image.enhancementPreset?.trim().toLowerCase();
    return preset != null && preset.isNotEmpty && preset != 'original';
  });
}

List<CapturedScanImage> _guidanceImagesFromSlots(List<ScannerPhotoSlot> slots) {
  return [
    for (final slot in slots)
      CapturedScanImage(
        path: slot.path,
        role: ScanCaptureRole.fromId(slot.role),
        source: slot.source,
        originalPath: slot.originalPath,
        enhancementPreset: slot.enhancementPreset.id,
        qualityMetadata: slot.qualityMetadata,
      ),
  ];
}

String? _thumbnailPathForCollectible(CollectibleItem item) {
  final primaryPath = item.imagePath.trim();
  if (primaryPath.isNotEmpty) {
    return primaryPath;
  }
  for (final image in item.galleryImages) {
    if (image.isPrimary && image.path.trim().isNotEmpty) {
      return image.path.trim();
    }
  }
  for (final image in item.galleryImages) {
    if (image.path.trim().isNotEmpty) {
      return image.path.trim();
    }
  }
  return null;
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
