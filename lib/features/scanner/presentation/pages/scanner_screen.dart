import 'dart:async';

import 'package:collectiq_ai/core/design_system/design_system.dart';
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
      _highlightTimer = Timer(AppMotion.scaleDuration * 4, () {
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
        duration: AppMotion.slideDuration * 2,
        curve: AppMotion.standardCurve,
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

    return AppScaffold(
      controller: _scrollController,
      title: 'Scan Collectible',
      subtitle:
          'Capture or upload a collectible to identify and estimate value.',
      child: AppResponsiveColumn(
        spacing: AppSpacing.xl,
        children: [
          const ScannerActionCards(),
          AnimatedSwitcher(
            duration: AppMotion.slideDuration,
            switchInCurve: AppMotion.standardCurve,
            switchOutCurve: AppMotion.fastCurve,
            child: selectedImagePath == null
                ? const SizedBox.shrink(key: ValueKey('no-selected-image'))
                : _AnimatedScanSection(
                    key: _previewKey,
                    child: AppResponsiveColumn(
                      spacing: AppSpacing.md,
                      children: [
                        ScanSelectedImageCard(
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
                        const ScanAnalyzeButton(),
                      ],
                    ),
                  ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.slideDuration,
            switchInCurve: AppMotion.standardCurve,
            switchOutCurve: AppMotion.fastCurve,
            child: isAnalyzing
                ? const _AnimatedScanSection(
                    key: ValueKey('processing-panel'),
                    child: LoadingPanel(
                      title: 'Analyzing your collectible',
                      messages: [
                        'Scanning collectible...',
                        'Identifying item...',
                        'Estimating value...',
                      ],
                    ),
                  )
                : const SizedBox.shrink(
                    key: ValueKey('processing-panel-empty'),
                  ),
          ),
          AnimatedSwitcher(
            duration: AppMotion.slideDuration,
            switchInCurve: AppMotion.standardCurve,
            switchOutCurve: AppMotion.fastCurve,
            child: scanResult == null
                ? const SizedBox.shrink(key: ValueKey('no-result'))
                : KeyedSubtree(
                    key: _resultKey,
                    child: _AnimatedScanSection(
                      key: ValueKey(scanResult.id),
                      child: ScannerResultPanel(
                        title: scanResult.title,
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
          if (selectedImagePath == null)
            AppCard(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
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

class _AnimatedScanSection extends StatelessWidget {
  const _AnimatedScanSection({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.slideDuration,
      curve: AppMotion.standardCurve,
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
