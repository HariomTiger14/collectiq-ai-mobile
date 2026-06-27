import 'dart:async';

import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/features/scanner/presentation/widgets/scanner_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _scrollController = ScrollController();
  final _previewKey = GlobalKey();
  final _resultKey = GlobalKey();
  late final ProviderSubscription<ScannerState> _scannerSubscription;
  Timer? _highlightTimer;
  String? _lastSelectedImagePath;
  String? _lastScanResultId;
  bool _highlightPreview = false;

  @override
  void initState() {
    super.initState();
    _scannerSubscription = ref.listenManual(
      scannerControllerProvider,
      _handleScannerStateChange,
    );
  }

  @override
  void dispose() {
    _scannerSubscription.close();
    _highlightTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScannerStateChange(ScannerState? previous, ScannerState next) {
    final selectedImagePath = next.selectedImagePath;
    if (selectedImagePath != null &&
        selectedImagePath != _lastSelectedImagePath) {
      _lastSelectedImagePath = selectedImagePath;
      setState(() {
        _highlightPreview = true;
      });
      _scrollTo(_previewKey, alignment: 0.08);
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 900), () {
        if (!mounted) {
          return;
        }
        setState(() {
          _highlightPreview = false;
        });
      });
    }

    final scanResultId = next.scanResult?.id;
    if (scanResultId != null && scanResultId != _lastScanResultId) {
      _lastScanResultId = scanResultId;
      _scrollTo(_resultKey, alignment: 0.08);
    }
  }

  void _scrollTo(GlobalKey key, {required double alignment}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = key.currentContext;
      if (context == null) {
        return;
      }

      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: alignment,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scannerState = ref.watch(scannerControllerProvider);
    final selectedImagePath = scannerState.selectedImagePath;
    final scanResult = scannerState.scanResult;
    final isAnalyzing = scannerState.isAnalyzing;

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
                      const SizedBox(height: AppSpacing.xl),
                      const ScanHeroCard(),
                      const SizedBox(height: AppSpacing.xl),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: selectedImagePath == null
                            ? const SizedBox.shrink(
                                key: ValueKey('no-selected-image'),
                              )
                            : _AnimatedScanSection(
                                key: _previewKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ScanPreviewCard(
                                      imagePath: selectedImagePath,
                                      image: scannerState.selectedImage,
                                      title:
                                          scannerState.selectedItemTitle ??
                                          'Captured image',
                                      status:
                                          scannerState.selectedItemStatus ??
                                          'Ready for AI analysis',
                                      isHighlighted: _highlightPreview,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    const ScanAnalyzeButton(),
                                  ],
                                ),
                              ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: isAnalyzing
                            ? const Padding(
                                key: ValueKey('processing-panel'),
                                padding: EdgeInsets.only(top: AppSpacing.md),
                                child: ProcessingPanel(),
                              )
                            : const SizedBox.shrink(
                                key: ValueKey('processing-panel-empty'),
                              ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: scanResult == null
                            ? const SizedBox.shrink(key: ValueKey('no-result'))
                            : Padding(
                                key: ValueKey(scanResult.id),
                                padding: const EdgeInsets.only(
                                  top: AppSpacing.xl,
                                ),
                                child: KeyedSubtree(
                                  key: _resultKey,
                                  child: AiResultCard(
                                    item: scanResult.title,
                                    category: scanResult.category,
                                    estimatedValue:
                                        'AUD ${scanResult.estimatedValue.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',')}',
                                    confidence:
                                        '${(scanResult.confidence * 100).toStringAsFixed(0)}%',
                                    condition: scanResult.condition,
                                    recommendation:
                                        scannerState.aiRecommendation ??
                                        'Consider grading before selling.',
                                  ),
                                ),
                              ),
                      ),
                      if (selectedImagePath == null) ...[
                        const SizedBox(height: AppSpacing.xxl),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tips_and_updates_outlined,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  'Use a clear, well-lit photo for the best valuation.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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

class _AnimatedScanSection extends StatelessWidget {
  const _AnimatedScanSection({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: Transform.scale(
              scale: 0.98 + (0.02 * value),
              alignment: Alignment.topCenter,
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}
