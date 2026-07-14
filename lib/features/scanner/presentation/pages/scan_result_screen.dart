import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/presentation/scanner_visual_theme.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';

class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({
    required this.result,
    required this.activeSlot,
    required this.isSaved,
    required this.isSaving,
    required this.onSave,
    required this.onScanAnother,
    required this.onViewPortfolio,
    super.key,
  });

  final ScanResult result;
  final ScannerPhotoSlot? activeSlot;
  final bool isSaved;
  final bool isSaving;
  final Future<void> Function() onSave;
  final VoidCallback onScanAnother;
  final VoidCallback? onViewPortfolio;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imagePath = activeSlot?.path ?? result.thumbnail;
    final isEnhanced = activeSlot?.isEnhanced == true;
    return ScannerFocusTheme(
      child: Scaffold(
        key: ValueKey('scan-result-${result.id}'),
        backgroundColor: ScannerVisualTheme.background,
        appBar: AppBar(
          title: const Text('Analysis Complete'),
          actions: [
            IconButton(
              key: const ValueKey('result-scan-another'),
              onPressed: onScanAnother,
              icon: const Icon(Icons.close),
              tooltip: 'Scan another',
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isSaved) ...[
                  const ScannerStatusCard(
                    title: 'Saved to Portfolio',
                    body: 'Your item has been added successfully.',
                    icon: Icons.check_circle_outline,
                    success: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                _ResultHeroImage(path: imagePath, isEnhanced: isEnhanced),
                const SizedBox(height: AppSpacing.md),
                _FadeInMetadata(
                  delay: Duration.zero,
                  child: Text(
                    result.title,
                    key: const ValueKey('result-item-name'),
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                      color: ScannerVisualTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FadeInMetadata(
                  delay: const Duration(milliseconds: 30),
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _ResultChip(
                        key: const ValueKey('result-category-chip'),
                        icon: Icons.category_outlined,
                        label: result.category,
                      ),
                      _ResultChip(
                        key: const ValueKey('result-rarity-indicator'),
                        icon: Icons.diamond_outlined,
                        label: _rarityLabel(result),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _FadeInMetadata(
                  delay: const Duration(milliseconds: 60),
                  child: _ConfidenceMeter(confidence: result.confidence),
                ),
                const SizedBox(height: AppSpacing.md),
                _FadeInMetadata(
                  delay: const Duration(milliseconds: 90),
                  child: _ValueCard(
                    value: _formatScanValue(
                      result.estimatedValue,
                      result.valuationStatus,
                    ),
                    source: _valueSourceLabel(result),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _SlideInAction(
                  child: FilledButton.icon(
                    key: const ValueKey('result-primary-add-to-portfolio'),
                    onPressed: isSaved || isSaving ? null : onSave,
                    icon: Icon(
                      isSaving
                          ? Icons.hourglass_top_outlined
                          : isSaved
                          ? Icons.check_circle_outline
                          : Icons.bookmark_add_outlined,
                    ),
                    label: Text(
                      isSaving
                          ? 'Saving...'
                          : isSaved
                          ? 'Saved to Portfolio'
                          : 'Add to Portfolio',
                    ),
                  ),
                ),
                if (isSaved && onViewPortfolio != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: onViewPortfolio,
                    icon: const Icon(Icons.inventory_2_outlined),
                    label: const Text('View Portfolio'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultHeroImage extends StatelessWidget {
  const _ResultHeroImage({required this.path, required this.isEnhanced});

  final String path;
  final bool isEnhanced;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: AppElevation.level2,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: AspectRatio(
          aspectRatio: 1,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ResultImage(path: path),
              if (isEnhanced)
                const Positioned(
                  left: AppSpacing.md,
                  top: AppSpacing.md,
                  child: _AiEnhancedBadge(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceMeter extends StatelessWidget {
  const _ConfidenceMeter({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final clamped = confidence.clamp(0, 1).toDouble();
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: const ValueKey('result-confidence-meter'),
      decoration: BoxDecoration(
        color: ScannerVisualTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: ScannerVisualTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Confidence',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${(clamped * 100).round()}%',
                  key: const ValueKey('result-confidence-value'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: 9,
                backgroundColor: colorScheme.surface,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({required this.value, required this.source});

  final String value;
  final String source;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('result-value-card'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
            const Color(0xFF14B8A6).withValues(alpha: 0.10),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
        ),
        boxShadow: AppElevation.level1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated value',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              key: const ValueKey('result-estimated-value'),
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              source,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FadeInMetadata extends StatefulWidget {
  const _FadeInMetadata({required this.child, required this.delay});

  final Widget child;
  final Duration delay;

  @override
  State<_FadeInMetadata> createState() => _FadeInMetadataState();
}

class _FadeInMetadataState extends State<_FadeInMetadata> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _visible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: widget.child,
    );
  }
}

class _SlideInAction extends StatefulWidget {
  const _SlideInAction({required this.child});

  final Widget child;

  @override
  State<_SlideInAction> createState() => _SlideInActionState();
}

class _SlideInActionState extends State<_SlideInAction> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _visible = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      key: const ValueKey('result-add-button-slide-animation'),
      offset: _visible ? Offset.zero : const Offset(0, 0.18),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _ResultImage extends StatelessWidget {
  const _ResultImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('sample://')) {
      return ColoredBox(
        key: const ValueKey('result-primary-image'),
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.style_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 56,
        ),
      );
    }
    final file = File(path);
    if (file.existsSync()) {
      return Image.file(
        file,
        key: const ValueKey('result-primary-image'),
        fit: BoxFit.cover,
      );
    }
    return const ColoredBox(
      key: ValueKey('result-primary-image'),
      color: Color(0xFFE5E7EB),
      child: Icon(Icons.broken_image_outlined, size: 42),
    );
  }
}

class _AiEnhancedBadge extends StatelessWidget {
  const _AiEnhancedBadge();

  @override
  Widget build(BuildContext context) {
    return const KeyedSubtree(
      key: ValueKey('scan-result-analyzed-with-enhancement'),
      child: PremiumBadge(
        label: 'AI Enhanced',
        icon: Icons.auto_awesome,
        tone: PremiumBadgeTone.neutral,
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  const _ResultChip({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return PremiumBadge(
      label: label,
      icon: icon,
      tone: PremiumBadgeTone.neutral,
      maxWidth: 160,
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

String _valuationStatusMessage(ValuationStatus status) {
  return switch (status) {
    ValuationStatus.providerNotConfigured =>
      'Market value unavailable - pricing source not connected yet',
    ValuationStatus.noMarketMatch => 'No reliable market match found yet',
    ValuationStatus.lookupFailed => 'Value lookup failed - try again',
    ValuationStatus.aiEstimated => 'AI-estimated value unavailable',
    ValuationStatus.marketEstimated => 'Market value unavailable',
    ValuationStatus.unavailable => 'Value unavailable',
  };
}

String _rarityLabel(ScanResult result) {
  final rarity = result.rarity?.trim();
  if (rarity != null && rarity.isNotEmpty) {
    return rarity;
  }
  if (result.confidence >= 0.85) {
    return 'Strong match';
  }
  if (result.confidence >= 0.70) {
    return 'Likely match';
  }
  return 'Needs review';
}

String _valueSourceLabel(ScanResult result) {
  if (result.valuationStatus == ValuationStatus.marketEstimated) {
    return 'Market-informed estimate';
  }
  if (result.valuationStatus == ValuationStatus.aiEstimated) {
    return 'AI-estimated, not market verified';
  }
  return result.valuationSource == 'unknown'
      ? 'Pricing source pending'
      : result.valuationSource;
}
