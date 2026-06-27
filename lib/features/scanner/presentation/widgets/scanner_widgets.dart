import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
          'Scan Collectible',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.12,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Choose camera or gallery, then analyze your item.',
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level1,
      ),
      child: _ScanActions(textTheme: textTheme),
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
          'Start scan',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Pick the best image source for this collectible.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PrimaryScanActionCard(
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
        _SecondaryScanActionCard(
          icon: Icons.photo_library_outlined,
          title: 'Choose from Gallery',
          subtitle: 'Import a saved collectible photo',
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
        ),
        const SizedBox(height: AppSpacing.md),
        _SecondaryScanActionCard(
          icon: Icons.science_outlined,
          title: 'Sample Scan',
          subtitle: 'Try the flow with demo data',
          onPressed: scannerState.isLoading
              ? null
              : scannerController.useSampleScan,
        ),
      ],
    );
  }
}

class _PrimaryScanActionCard extends StatelessWidget {
  const _PrimaryScanActionCard({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: onPressed == null ? 0.62 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.primary,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppElevation.accentGlow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: isLoading
                          ? const SizedBox(
                              key: ValueKey('camera-loading'),
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.4,
                              ),
                            )
                          : const Icon(
                              Icons.photo_camera_outlined,
                              key: ValueKey('camera-icon'),
                              color: Colors.white,
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Camera',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'Capture a fresh photo',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SecondaryScanActionCard extends StatelessWidget {
  const _SecondaryScanActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: onPressed == null ? 0.58 : 1,
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
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
    required this.image,
    required this.title,
    required this.status,
    this.isHighlighted = false,
    super.key,
  });

  /// Local path, web display name, or sample identifier for the selected image.
  final String imagePath;

  /// Selected scanner image file.
  final XFile? image;

  /// Display title for the selected scan.
  final String title;

  /// Display status for the selected scan.
  final String status;

  /// Whether the selected image card should show a temporary highlight.
  final bool isHighlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isHighlighted
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: isHighlighted ? 1.6 : 1,
        ),
        boxShadow: isHighlighted
            ? [...AppElevation.level1, ...AppElevation.accentGlow]
            : AppElevation.level1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Image selected',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Review your image, then tap Analyze.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AspectRatio(
            aspectRatio: 4 / 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: _ScanPreviewThumbnail(
                imagePath: imagePath,
                image: image,
                colorScheme: colorScheme,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            status,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ScanAnalyzeButton extends ConsumerWidget {
  const ScanAnalyzeButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      scannerControllerProvider.select((state) => state.isLoading),
    );
    final scannerController = ref.read(scannerControllerProvider.notifier);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: SizedBox(
        key: ValueKey(isLoading),
        width: double.infinity,
        child: FilledButton.icon(
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
          icon: isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome_outlined),
          label: Text(isLoading ? 'Analyzing...' : 'Analyze with AI'),
        ),
      ),
    );
  }
}

class ProcessingPanel extends StatelessWidget {
  const ProcessingPanel({super.key});

  static const _messages = [
    _ProcessingMessage(
      icon: Icons.center_focus_strong_outlined,
      label: 'Scanning collectible...',
    ),
    _ProcessingMessage(
      icon: Icons.manage_search_outlined,
      label: 'Identifying item...',
    ),
    _ProcessingMessage(
      icon: Icons.price_check_outlined,
      label: 'Estimating value...',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.97, end: 1),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          alignment: Alignment.topCenter,
          child: child,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
          boxShadow: [...AppElevation.level1, ...AppElevation.accentGlow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analyzing your collectible',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Hold tight while CollectIQ reads the image and market signals.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            for (var index = 0; index < _messages.length; index++) ...[
              _ProcessingStatusRow(
                message: _messages[index],
                delay: Duration(milliseconds: 120 * index),
              ),
              if (index != _messages.length - 1)
                const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProcessingMessage {
  const _ProcessingMessage({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _ProcessingStatusRow extends StatelessWidget {
  const _ProcessingStatusRow({required this.message, required this.delay});

  final _ProcessingMessage message;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final adjustedValue = (value - delay.inMilliseconds / 1000).clamp(
          0.0,
          1.0,
        );
        return Opacity(
          opacity: adjustedValue,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - adjustedValue)),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          Icon(message.icon, size: 19, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message.label,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 54,
            child: LinearProgressIndicator(
              minHeight: 4,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              color: colorScheme.primary,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
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
    required this.image,
    required this.colorScheme,
    this.width = 104,
    this.height = 104,
  });

  final String imagePath;
  final XFile? image;
  final ColorScheme colorScheme;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('sample://')) {
      return Container(
        width: width,
        height: height,
        color: colorScheme.primaryContainer,
        child: Icon(Icons.style_outlined, color: colorScheme.primary),
      );
    }

    final selectedImage = image;
    if (selectedImage == null) {
      return _fallbackThumbnail();
    }

    return FutureBuilder(
      future: selectedImage.readAsBytes(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _fallbackThumbnail();
        }

        return Image.memory(
          snapshot.data!,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _fallbackThumbnail();
          },
        );
      },
    );
  }

  Widget _fallbackThumbnail() {
    return Container(
      width: width,
      height: height,
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
    required this.recommendation,
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

  /// Result recommendation.
  final String recommendation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scannerController = ref.read(scannerControllerProvider.notifier);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 12 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(Icons.auto_awesome, color: colorScheme.primary),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'AI Result',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            _ResultHeroMetric(
              label: 'Estimated Value',
              value: estimatedValue,
              icon: Icons.paid_outlined,
            ),
            const SizedBox(height: AppSpacing.md),
            _ResultMiniMetric(label: 'Item', value: item),
            const SizedBox(height: AppSpacing.md),
            _ResultMiniMetric(label: 'Category', value: category),
            const SizedBox(height: AppSpacing.md),
            _ResultMiniMetric(label: 'Confidence', value: confidence),
            const SizedBox(height: AppSpacing.md),
            _ResultMiniMetric(label: 'Condition', value: condition),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Recommendation',
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(recommendation, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await scannerController.saveScanResultToPortfolio();
                  if (!context.mounted) {
                    return;
                  }
                  _showScannerSnackBar(context, 'Saved to portfolio');
                },
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('Save to Portfolio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultHeroMetric extends StatelessWidget {
  const _ResultHeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: textTheme.headlineSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
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

class _ResultMiniMetric extends StatelessWidget {
  const _ResultMiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
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
