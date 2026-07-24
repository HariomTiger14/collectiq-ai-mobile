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
    final bottomPadding = isSaved ? AppSpacing.xxl * 2 : AppSpacing.xl;
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
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              bottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                _FadeInMetadata(
                  delay: const Duration(milliseconds: 120),
                  child: _ResultInsightGrid(result: result),
                ),
                const SizedBox(height: AppSpacing.md),
                _FadeInMetadata(
                  delay: const Duration(milliseconds: 150),
                  child: _ResultSection(
                    title: 'Market check',
                    icon: Icons.query_stats_outlined,
                    child: _MarketEvidence(result: result),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _FadeInMetadata(
                  delay: const Duration(milliseconds: 180),
                  child: _ResultSection(
                    title: 'Identification',
                    icon: Icons.fingerprint_outlined,
                    child: _IdentificationDetails(result: result),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _FadeInMetadata(
                  delay: const Duration(milliseconds: 210),
                  child: _ResultSection(
                    title: 'Condition notes',
                    icon: Icons.fact_check_outlined,
                    child: _ConditionNotes(result: result),
                  ),
                ),
                if (result.alternativeMatches.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  _FadeInMetadata(
                    delay: const Duration(milliseconds: 240),
                    child: _ResultSection(
                      title: 'Possible alternatives',
                      icon: Icons.compare_arrows_outlined,
                      child: _AlternativeMatches(
                        matches: result.alternativeMatches,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _FadeInMetadata(
                  delay: const Duration(milliseconds: 270),
                  child: _ResultSection(
                    title: 'Next best action',
                    icon: Icons.lightbulb_outline,
                    child: Text(
                      _recommendationFor(result),
                      style: textTheme.bodyMedium?.copyWith(
                        color: ScannerVisualTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _ResultActionBar(
          isSaved: isSaved,
          isSaving: isSaving,
          onSave: onSave,
          onScanAnother: onScanAnother,
          onViewPortfolio: onViewPortfolio,
        ),
      ),
    );
  }
}

class _ResultInsightGrid extends StatelessWidget {
  const _ResultInsightGrid({required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: itemWidth,
              child: _InsightTile(
                label: 'Condition',
                value: _fallback(result.condition, 'Needs review'),
                icon: Icons.health_and_safety_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InsightTile(
                label: 'Value range',
                value: _valueRange(result),
                icon: Icons.show_chart_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InsightTile(
                label: 'Photos used',
                value: _photosUsedLabel(result),
                icon: Icons.photo_library_outlined,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _InsightTile(
                label: 'Review status',
                value: _reviewStatus(result),
                icon: Icons.verified_user_outlined,
                accent: _reviewStatusColor(result),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _InsightTile extends StatelessWidget {
  const _InsightTile({
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? ScannerVisualTheme.cyan;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ScannerVisualTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: ScannerVisualTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: ScannerVisualTheme.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: ScannerVisualTheme.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultSection extends StatelessWidget {
  const _ResultSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ScannerVisualTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: ScannerVisualTheme.border),
        boxShadow: AppElevation.level1,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: ScannerVisualTheme.cyan, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: ScannerVisualTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _MarketEvidence extends StatelessWidget {
  const _MarketEvidence({required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final pricing = result.pricing;
    return Column(
      children: [
        _ResultRow(
          label: 'Estimated market value',
          value: _formatScanValue(
            pricing.estimatedMarketValue > 0
                ? pricing.estimatedMarketValue
                : result.estimatedValue,
            result.valuationStatus,
          ),
        ),
        _ResultRow(label: 'Estimated range', value: _valueRange(result)),
        _ResultRow(
          label: 'Pricing source',
          value: _fallback(pricing.pricingSource, _valueSourceLabel(result)),
        ),
        _ResultRow(
          label: 'Pricing confidence',
          value: '${(pricing.pricingConfidence.clamp(0, 1) * 100).round()}%',
        ),
        _ResultRow(
          label: 'Last checked',
          value: _formatShortDate(pricing.lastUpdated),
          isLast: true,
        ),
      ],
    );
  }
}

class _IdentificationDetails extends StatelessWidget {
  const _IdentificationDetails({required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final details = [
      _Detail('Primary match', result.primaryMatch),
      _Detail('Category', result.category),
      _Detail('Year', result.year),
      _Detail('Brand', result.brand),
      _Detail('Set', result.setName),
      _Detail('Series', result.series),
      _Detail('Card number', result.cardNumber),
      _Detail('Character', result.playerOrCharacter),
      _Detail('Rarity', result.rarity),
      _Detail('Edition', result.edition),
      _Detail('Language', result.language),
      _Detail('Material', result.material),
    ].where((detail) => detail.value.trim().isNotEmpty).take(8).toList();

    if (details.isEmpty) {
      return Text(
        'PackLox found the main item identity. Add more angles to improve variant-level details.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ScannerVisualTheme.textSecondary,
          height: 1.35,
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < details.length; index++)
          _ResultRow(
            label: details[index].label,
            value: details[index].value,
            isLast: index == details.length - 1,
          ),
      ],
    );
  }
}

class _ConditionNotes extends StatelessWidget {
  const _ConditionNotes({required this.result});

  final ScanResult result;

  @override
  Widget build(BuildContext context) {
    final notes = [
      _fallback(result.confidenceExplanation, ''),
      if (result.detectionQuality.trim().isNotEmpty)
        'Detection quality: ${result.detectionQuality}',
      _fallback(result.aiReasoning, ''),
      if (result.notes?.trim().isNotEmpty == true) result.notes!.trim(),
      if (result.askingPriceWarning?.trim().isNotEmpty == true)
        result.askingPriceWarning!.trim(),
    ].where((line) => line.trim().isNotEmpty).join('\n\n');

    return Text(
      notes.isEmpty
          ? 'Condition is an estimate from the available photos. Add close-ups of corners, surface, and back before final valuation.'
          : notes,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: ScannerVisualTheme.textPrimary,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
    );
  }
}

class _AlternativeMatches extends StatelessWidget {
  const _AlternativeMatches({required this.matches});

  final List<ScanAlternativeMatch> matches;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < matches.take(3).length; index++)
          _AlternativeTile(
            match: matches[index],
            isLast: index == matches.take(3).length - 1,
          ),
      ],
    );
  }
}

class _AlternativeTile extends StatelessWidget {
  const _AlternativeTile({required this.match, required this.isLast});

  final ScanAlternativeMatch match;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: ScannerVisualTheme.cyan.withValues(alpha: 0.14),
            child: Text(
              '${(match.confidence.clamp(0, 1) * 100).round()}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ScannerVisualTheme.cyan,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: ScannerVisualTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${match.category} - ${match.reason}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ScannerVisualTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ScannerVisualTheme.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ScannerVisualTheme.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail {
  const _Detail(this.label, String? value) : value = value ?? '';

  final String label;
  final String value;
}

class _ResultActionBar extends StatelessWidget {
  const _ResultActionBar({
    required this.isSaved,
    required this.isSaving,
    required this.onSave,
    required this.onScanAnother,
    required this.onViewPortfolio,
  });

  final bool isSaved;
  final bool isSaving;
  final Future<void> Function() onSave;
  final VoidCallback onScanAnother;
  final VoidCallback? onViewPortfolio;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ScannerVisualTheme.background.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: ScannerVisualTheme.border.withValues(alpha: 0.7),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: _SlideInAction(
            child: isSaved && onViewPortfolio != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: ScannerVisualTheme.success,
                            size: 22,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Saved to Portfolio',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: ScannerVisualTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton.icon(
                        key: const ValueKey('result-primary-add-to-portfolio'),
                        onPressed: onViewPortfolio,
                        icon: const Icon(Icons.inventory_2_outlined),
                        label: const Text('View Portfolio'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: onScanAnother,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Scan another'),
                      ),
                    ],
                  )
                : FilledButton.icon(
                    key: const ValueKey('result-primary-add-to-portfolio'),
                    onPressed: isSaving ? null : onSave,
                    icon: Icon(
                      isSaving
                          ? Icons.hourglass_top_outlined
                          : Icons.bookmark_add_outlined,
                    ),
                    label: Text(isSaving ? 'Saving...' : 'Add to Portfolio'),
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
          aspectRatio: 1.18,
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
                      color: ScannerVisualTheme.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${(clamped * 100).round()}%',
                  key: const ValueKey('result-confidence-value'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: ScannerVisualTheme.textPrimary,
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
            ScannerVisualTheme.surfaceElevated,
            ScannerVisualTheme.surface.withValues(alpha: 0.96),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: ScannerVisualTheme.cyan.withValues(alpha: 0.32),
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
                color: ScannerVisualTheme.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              key: const ValueKey('result-estimated-value'),
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: ScannerVisualTheme.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              source,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: ScannerVisualTheme.textSecondary,
                fontWeight: FontWeight.w800,
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

String _fallback(String? value, String fallback) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
}

String _valueRange(ScanResult result) {
  final low = result.pricing.lowEstimate;
  final high = result.pricing.highEstimate;
  if (low > 0 && high > 0 && high >= low) {
    return '${_formatScanValue(low, result.valuationStatus)} - '
        '${_formatScanValue(high, result.valuationStatus)}';
  }
  if (result.estimatedValue > 0) {
    final lower = result.estimatedValue * 0.82;
    final upper = result.estimatedValue * 1.18;
    return '${_formatScanValue(lower, result.valuationStatus)} - '
        '${_formatScanValue(upper, result.valuationStatus)}';
  }
  return 'Needs market check';
}

String _photosUsedLabel(ScanResult result) {
  final count = result.photosUsed ?? result.galleryImages.length;
  if (count <= 0) {
    return result.photoRoles.isEmpty
        ? '1 scan'
        : '${result.photoRoles.length} angles';
  }
  return count == 1 ? '1 photo' : '$count photos';
}

String _reviewStatus(ScanResult result) {
  if (result.confidence >= 0.85 && result.estimatedValue > 0) {
    return 'Ready to save';
  }
  if (result.confidence >= 0.70) {
    return 'Review details';
  }
  return 'Needs more photos';
}

Color _reviewStatusColor(ScanResult result) {
  if (result.confidence >= 0.85 && result.estimatedValue > 0) {
    return ScannerVisualTheme.success;
  }
  if (result.confidence >= 0.70) {
    return const Color(0xFFF59E0B);
  }
  return ScannerVisualTheme.danger;
}

String _formatShortDate(DateTime? date) {
  if (date == null) {
    return 'Not checked yet';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

String _recommendationFor(ScanResult result) {
  if (result.estimatedValue <= 0) {
    return 'Save it as pending, then add clearer photos or connect market pricing before making a sale or insurance decision.';
  }
  if (result.confidence < 0.70) {
    return 'Take another scan with the front, back, and condition close-ups before relying on this value.';
  }
  if (result.valuationStatus == ValuationStatus.providerNotConfigured ||
      result.valuationStatus == ValuationStatus.unavailable) {
    return 'Save this result, but treat the value as provisional until market pricing is connected and recent comps are checked.';
  }
  return 'Save this item with condition notes, then compare recent sold listings before selling, grading, or insuring it.';
}
