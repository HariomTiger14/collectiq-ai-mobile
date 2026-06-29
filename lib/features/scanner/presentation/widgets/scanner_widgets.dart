import 'dart:io';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/scan_result.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScannerStep {
  const ScannerStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
}

class ScannerHistoryItem {
  const ScannerHistoryItem({
    required this.name,
    required this.estimatedValue,
    required this.date,
    required this.icon,
    required this.color,
  });

  final String name;
  final String estimatedValue;
  final String date;
  final IconData icon;
  final Color color;
}

class ScannerHeader extends StatelessWidget {
  const ScannerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Scanner',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Instantly identify and value collectibles.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class ScanHeroCard extends StatelessWidget {
  const ScanHeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [...AppElevation.level1, ...AppElevation.accentGlow],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 700;
          final illustration = const _ScanIllustration();
          final actions = _ScanActions(textTheme: textTheme);

          if (isWide) {
            return Row(
              children: [
                Expanded(child: illustration),
                const SizedBox(width: AppSpacing.xxl),
                Expanded(child: actions),
              ],
            );
          }

          return Column(
            children: [
              illustration,
              const SizedBox(height: AppSpacing.xl),
              actions,
            ],
          );
        },
      ),
    );
  }
}

class _ScanIllustration extends StatelessWidget {
  const _ScanIllustration();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 1.24,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 176,
              height: 176,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.14),
                    colorScheme.secondary.withValues(alpha: 0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            Container(
              width: 112,
              height: 148,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: colorScheme.outlineVariant),
                boxShadow: AppElevation.level1,
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            Positioned(
              top: 40,
              right: 52,
              child: _SignalDot(icon: Icons.auto_awesome_outlined),
            ),
            Positioned(
              bottom: 44,
              left: 48,
              child: _SignalDot(icon: Icons.query_stats_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignalDot extends StatelessWidget {
  const _SignalDot({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      child: Icon(icon, size: 19, color: colorScheme.primary),
    );
  }
}

class _ScanActions extends ConsumerWidget {
  const _ScanActions({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final scannerState = ref.watch(scannerControllerProvider);
    final scannerController = ref.read(scannerControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Start a new scan',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Capture or upload a collectible to receive a structured AI valuation workflow.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _GradientScanButton(
          isLoading: scannerState.isLoading,
          onPressed: scannerState.isLoading
              ? null
              : () async {
                  await scannerController.startCameraScan(context);
                  if (!context.mounted) {
                    return;
                  }
                  final errorMessage = ref
                      .read(scannerControllerProvider)
                      .errorMessage;
                  if (errorMessage != null) {
                    _showScannerSnackBar(context, errorMessage);
                  }
                },
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: scannerState.isLoading
              ? null
              : () async {
                  await scannerController.pickImageFromGallery();
                  if (!context.mounted) {
                    return;
                  }
                  final errorMessage = ref
                      .read(scannerControllerProvider)
                      .errorMessage;
                  if (errorMessage != null) {
                    _showScannerSnackBar(context, errorMessage);
                  }
                },
          icon: const Icon(Icons.photo_library_outlined),
          label: const Text('Choose from Gallery'),
        ),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: scannerState.isLoading
              ? null
              : scannerController.useSampleScan,
          icon: const Icon(Icons.science_outlined),
          label: const Text('Use Sample Scan'),
        ),
      ],
    );
  }
}

class _GradientScanButton extends StatelessWidget {
  const _GradientScanButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppElevation.accentGlow,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.4,
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_camera_outlined, color: Colors.white),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Scan with Camera',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

void _showScannerSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Displays the selected scanner image and its current analysis readiness.
class ScanPreviewCard extends ConsumerWidget {
  /// Creates a scan preview card.
  const ScanPreviewCard({
    required this.imagePath,
    required this.title,
    required this.status,
    super.key,
  });

  /// Local path, web display name, or sample identifier for the selected image.
  final String imagePath;

  /// Display title for the selected scan.
  final String title;

  /// Display status for the selected scan.
  final String status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isLoading = ref.watch(
      scannerControllerProvider.select((state) => state.isLoading),
    );
    final scannerController = ref.read(scannerControllerProvider.notifier);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: _ScanPreviewThumbnail(
              imagePath: imagePath,
              colorScheme: colorScheme,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTwoLineTitle(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  status,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            await scannerController.analyzeWithAi();
                            if (!context.mounted) {
                              return;
                            }
                            final errorMessage = ref
                                .read(scannerControllerProvider)
                                .errorMessage;
                            if (errorMessage != null) {
                              _showScannerSnackBar(context, errorMessage);
                            }
                          },
                    child: SizedBox(
                      height: 20,
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Analyze with AI'),
                      ),
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: isLoading
                      ? const Padding(
                          key: ValueKey('processing-panel'),
                          padding: EdgeInsets.only(top: AppSpacing.md),
                          child: _ProcessingPanel(),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessingPanel extends StatelessWidget {
  const _ProcessingPanel();

  static const _steps = [
    'Scanning collectible',
    'Identifying item',
    'Estimating value',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Analyzing image',
                  style: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final step in _steps)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                '$step...',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScanPreviewThumbnail extends StatelessWidget {
  const _ScanPreviewThumbnail({
    required this.imagePath,
    required this.colorScheme,
  });

  final String imagePath;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return _StableScanPreviewImage(
      key: ValueKey('scan-preview-image-$imagePath'),
      imagePath: imagePath,
      colorScheme: colorScheme,
    );
  }
}

class _StableScanPreviewImage extends StatefulWidget {
  const _StableScanPreviewImage({
    required this.imagePath,
    required this.colorScheme,
    super.key,
  });

  final String imagePath;
  final ColorScheme colorScheme;

  @override
  State<_StableScanPreviewImage> createState() =>
      _StableScanPreviewImageState();
}

class _StableScanPreviewImageState extends State<_StableScanPreviewImage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final imagePath = widget.imagePath;
    final colorScheme = widget.colorScheme;

    if (imagePath.startsWith('sample://')) {
      return Container(
        width: 88,
        height: 88,
        color: colorScheme.primaryContainer,
        child: Icon(Icons.style_outlined, color: colorScheme.primary),
      );
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackThumbnail(colorScheme);
        },
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        width: 88,
        height: 88,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) {
          return _fallbackThumbnail(colorScheme);
        },
      );
    }

    return Image.file(
      File(imagePath),
      width: 88,
      height: 88,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return _fallbackThumbnail(colorScheme);
      },
    );
  }

  Widget _fallbackThumbnail(ColorScheme colorScheme) {
    return Container(
      width: 88,
      height: 88,
      color: colorScheme.primaryContainer,
      child: Icon(Icons.image_outlined, color: colorScheme.primary),
    );
  }
}

/// Displays the temporary AI result generated from the selected scan.
class AiResultCard extends ConsumerWidget {
  /// Creates an AI result card.
  const AiResultCard({
    required this.item,
    required this.category,
    required this.estimatedValue,
    required this.confidence,
    required this.condition,
    required this.primaryMatch,
    required this.alternativeMatches,
    required this.confidenceExplanation,
    required this.detectionQuality,
    required this.aiReasoning,
    required this.pricing,
    required this.recommendation,
    required this.isSaved,
    required this.onScanAnother,
    this.onViewPortfolio,
    this.year,
    this.brand,
    this.setName,
    this.series,
    this.cardNumber,
    this.playerOrCharacter,
    this.rarity,
    this.estimatedGrade,
    this.language,
    this.edition,
    this.country,
    this.mint,
    this.material,
    this.notes,
    super.key,
  });

  /// Result item title.
  final String item;

  /// Result category.
  final String category;

  /// Display-formatted estimated value.
  final String estimatedValue;

  /// Display-formatted confidence.
  final String confidence;

  /// Result condition.
  final String condition;

  /// Primary AI match label.
  final String primaryMatch;

  /// Top alternative matches.
  final List<ScanAlternativeMatch> alternativeMatches;

  /// Explanation for the confidence score.
  final String confidenceExplanation;

  /// Image and detection quality assessment.
  final String detectionQuality;

  /// AI reasoning for the primary match.
  final String aiReasoning;

  /// Result recommendation.
  final String recommendation;

  /// Market pricing supplied by the pricing provider.
  final PricingInfo pricing;

  final bool isSaved;
  final VoidCallback? onViewPortfolio;
  final VoidCallback onScanAnother;

  final String? year;
  final String? brand;
  final String? setName;
  final String? series;
  final String? cardNumber;
  final String? playerOrCharacter;
  final String? rarity;
  final String? estimatedGrade;
  final String? language;
  final String? edition;
  final String? country;
  final String? mint;
  final String? material;
  final String? notes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scannerController = ref.read(scannerControllerProvider.notifier);
    final collectibleDetails = _metadataRows();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Result',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTwoLineTitle(
                      item,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      primaryMatch,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _ConfidenceBadge(label: confidence),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _AiResultRow(label: 'Category', value: category),
          _AiResultRow(label: 'Estimated Value', value: estimatedValue),
          _AiResultRow(label: 'Condition', value: condition),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Market Value',
            style: textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _AiResultRow(
            label: 'Market Value',
            value: _formatMoney(pricing.estimatedMarketValue, pricing.currency),
          ),
          _AiResultRow(
            label: 'Estimated Range',
            value:
                '${_formatMoney(pricing.lowEstimate, pricing.currency)} - ${_formatMoney(pricing.highEstimate, pricing.currency)}',
          ),
          _AiResultRow(label: 'Pricing Source', value: pricing.pricingSource),
          _AiResultRow(
            label: 'Pricing Confidence',
            value: '${(pricing.pricingConfidence * 100).toStringAsFixed(0)}%',
          ),
          _AiResultRow(
            label: 'Last Updated',
            value: _formatPricingDate(pricing.lastUpdated),
          ),
          if (collectibleDetails.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Collectible Details',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final detail in collectibleDetails)
              _AiResultRow(label: detail.label, value: detail.value),
          ],
          const SizedBox(height: AppSpacing.md),
          _AiReviewSection(
            title: 'Why this match?',
            body:
                '$confidenceExplanation\n\nDetection quality: $detectionQuality\n\n$aiReasoning',
          ),
          if (alternativeMatches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Alternative matches',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final match in alternativeMatches.take(3))
              _AlternativeMatchTile(match: match),
          ],
          const SizedBox(height: AppSpacing.md),
          _AiReviewSection(title: 'Recommendation', body: recommendation),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaved
                  ? null
                  : () async {
                      final didSave = await scannerController
                          .saveScanResultToPortfolio();
                      if (!context.mounted || !didSave) {
                        return;
                      }
                      _showScannerSnackBar(context, 'Saved to portfolio');
                    },
              icon: Icon(
                isSaved
                    ? Icons.check_circle_outline
                    : Icons.bookmark_add_outlined,
              ),
              label: Text(isSaved ? 'Saved' : 'Save to Portfolio'),
            ),
          ),
          if (isSaved) ...[
            const SizedBox(height: AppSpacing.md),
            if (onViewPortfolio != null)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onViewPortfolio,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('View in Portfolio'),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onScanAnother,
                icon: const Icon(Icons.refresh_outlined),
                label: const Text('Scan Another'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_MetadataDetail> _metadataRows() {
    return [
      _MetadataDetail('Year', year),
      _MetadataDetail('Brand', brand),
      _MetadataDetail('Set', setName),
      _MetadataDetail('Series', series),
      _MetadataDetail('Card #', cardNumber),
      _MetadataDetail('Player/Character', playerOrCharacter),
      _MetadataDetail('Rarity', rarity),
      _MetadataDetail('Estimated Grade', estimatedGrade),
      _MetadataDetail('Language', language),
      _MetadataDetail('Edition', edition),
      _MetadataDetail('Country', country),
      _MetadataDetail('Mint', mint),
      _MetadataDetail('Material', material),
      _MetadataDetail('Profile Notes', notes),
    ].where((detail) => detail.value.trim().isNotEmpty).toList();
  }
}

String _formatMoney(double value, String currency) {
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '$currency $withCommas';
}

String _formatPricingDate(DateTime? date) {
  if (date == null) {
    return 'Unknown';
  }

  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

class _MetadataDetail {
  const _MetadataDetail(this.label, String? value) : value = value ?? '';

  final String label;
  final String value;
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AiReviewSection extends StatelessWidget {
  const _AiReviewSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(body, style: textTheme.bodyMedium),
      ],
    );
  }
}

class _AlternativeMatchTile extends StatelessWidget {
  const _AlternativeMatchTile({required this.match});

  final ScanAlternativeMatch match;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTwoLineTitle(
                    match.title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${(match.confidence * 100).toStringAsFixed(0)}%',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              match.category,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(match.reason, style: textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _AiResultRow extends StatelessWidget {
  const _AiResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppLabelValueRow(label: label, value: value);
  }
}

class ScannerSectionTitle extends StatelessWidget {
  const ScannerSectionTitle({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class SupportedCategoriesWrap extends StatelessWidget {
  const SupportedCategoriesWrap({required this.categories, super.key});

  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final category in categories)
          Chip(
            label: Text(category),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
          ),
      ],
    );
  }
}

class ScannerStepsRow extends StatelessWidget {
  const ScannerStepsRow({required this.steps, super.key});

  final List<ScannerStep> steps;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final spacing = AppSpacing.lg;
        final itemWidth = isWide
            ? (constraints.maxWidth - spacing * (steps.length - 1)) /
                  steps.length
            : 248.0;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                SizedBox(
                  width: itemWidth,
                  child: _ScannerStepCard(step: steps[index]),
                ),
                if (index != steps.length - 1) SizedBox(width: spacing),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ScannerStepCard extends StatelessWidget {
  const _ScannerStepCard({required this.step});

  final ScannerStep step;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: 184,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [...AppElevation.level1, ...AppElevation.accentGlow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(step.icon, color: colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            step.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: Text(
              step.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerHistoryList extends StatelessWidget {
  const ScannerHistoryList({required this.items, super.key});

  final List<ScannerHistoryItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _ScannerHistoryCard(item: items[index]),
            if (index != items.length - 1)
              Divider(
                height: 1,
                indent: AppSpacing.xl,
                endIndent: AppSpacing.xl,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _ScannerHistoryCard extends StatelessWidget {
  const _ScannerHistoryCard({required this.item});

  final ScannerHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Icon(item.icon, color: colorScheme.primary),
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
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  item.date,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            item.estimatedValue,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class ScannerPremiumCard extends StatelessWidget {
  const ScannerPremiumCard({super.key});

  static const _features = [
    'Unlimited scans',
    'Price history',
    'Portfolio tracking',
    'Faster AI processing',
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppGradients.premium,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [...AppElevation.level2, ...AppElevation.accentGlow],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 620;

          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unlimited AI Scans',
                style: textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final feature in _features)
                    _PremiumFeaturePill(label: feature),
                ],
              ),
            ],
          );

          final button = FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.ink,
            ),
            onPressed: () {},
            child: const Text('Upgrade to Pro'),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: content),
                const SizedBox(width: AppSpacing.xl),
                button,
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              content,
              const SizedBox(height: AppSpacing.xl),
              button,
            ],
          );
        },
      ),
    );
  }
}

class _PremiumFeaturePill extends StatelessWidget {
  const _PremiumFeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
