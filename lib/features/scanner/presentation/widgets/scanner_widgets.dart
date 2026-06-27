import 'dart:typed_data';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/scanner/presentation/controllers/scanner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class ScannerActionCards extends ConsumerWidget {
  const ScannerActionCards({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerState = ref.watch(scannerControllerProvider);
    final scannerController = ref.read(scannerControllerProvider.notifier);
    final isLoading = scannerState.isLoading;

    return AppResponsiveColumn(
      spacing: AppSpacing.md,
      children: [
        _ScanActionCard(
          icon: Icons.photo_camera_outlined,
          title: 'Camera',
          subtitle: 'Capture a fresh photo',
          isPrimary: true,
          isLoading: isLoading,
          onPressed: isLoading
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
        _ScanActionCard(
          icon: Icons.photo_library_outlined,
          title: 'Gallery',
          subtitle: 'Import a saved collectible photo',
          onPressed: isLoading
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
        SecondaryButton(
          label: 'Sample Scan',
          icon: Icons.science_outlined,
          onPressed: isLoading ? null : scannerController.useSampleScan,
        ),
      ],
    );
  }
}

class _ScanActionCard extends StatelessWidget {
  const _ScanActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.isPrimary = false,
    this.isLoading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final foregroundColor = isPrimary ? Colors.white : colorScheme.onSurface;
    final supportingColor = isPrimary
        ? Colors.white70
        : colorScheme.onSurfaceVariant;
    final backgroundColor = isPrimary
        ? colorScheme.primary
        : colorScheme.surface;
    final borderColor = isPrimary
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return AnimatedOpacity(
      duration: AppMotion.fadeDuration,
      curve: AppMotion.fastCurve,
      opacity: onPressed == null ? 0.58 : 1,
      child: AppCard(
        onTap: onPressed,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        shadows: isPrimary ? AppShadows.medium : AppShadows.subtle,
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.16)
                    : colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: AnimatedSwitcher(
                duration: AppMotion.fadeDuration,
                child: isLoading && isPrimary
                    ? const SizedBox(
                        key: ValueKey('camera-loading'),
                        width: 22,
                        height: 22,
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          ),
                        ),
                      )
                    : Icon(
                        icon,
                        key: ValueKey(title),
                        color: isPrimary ? Colors.white : colorScheme.primary,
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: supportingColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: supportingColor),
          ],
        ),
      ),
    );
  }
}

class ScanSelectedImageCard extends StatelessWidget {
  const ScanSelectedImageCard({
    required this.imagePath,
    required this.image,
    required this.title,
    required this.status,
    this.isHighlighted = false,
    super.key,
  });

  final String imagePath;
  final XFile? image;
  final String title;
  final String status;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: AppMotion.scaleDuration,
      curve: AppMotion.standardCurve,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(
          color: isHighlighted
              ? colorScheme.primary
              : colorScheme.outlineVariant,
          width: isHighlighted ? 1.6 : 1,
        ),
        boxShadow: isHighlighted ? AppShadows.focus : AppShadows.subtle,
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
                  borderRadius: BorderRadius.circular(AppRadius.medium),
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
                      'Review your image, then analyze.',
                      style: textTheme.bodyMedium?.copyWith(
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
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: ScanImagePreview(imagePath: imagePath, image: image),
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
            style: textTheme.bodyMedium?.copyWith(
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

    return PrimaryButton(
      label: isLoading ? 'Analyzing...' : 'Analyze with AI',
      icon: Icons.auto_awesome_outlined,
      isLoading: isLoading,
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
    );
  }
}

class ScannerResultPanel extends ConsumerWidget {
  const ScannerResultPanel({
    required this.title,
    required this.category,
    required this.estimatedValue,
    required this.confidence,
    required this.condition,
    required this.recommendation,
    this.image,
    super.key,
  });

  final String title;
  final String category;
  final String estimatedValue;
  final String confidence;
  final String condition;
  final String recommendation;
  final Widget? image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scannerController = ref.read(scannerControllerProvider.notifier);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppResponsiveColumn(
      spacing: AppSpacing.md,
      children: [
        const SectionHeader(title: 'AI Result'),
        ResultCard(
          title: title,
          category: category,
          estimatedValue: estimatedValue,
          confidence: confidence,
          condition: condition,
          image: image,
          action: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Recommendation',
                style: textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(recommendation, style: textTheme.bodyMedium),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: 'Save to Portfolio',
                icon: Icons.bookmark_add_outlined,
                onPressed: () async {
                  await scannerController.saveScanResultToPortfolio();
                  if (!context.mounted) {
                    return;
                  }
                  _showScannerSnackBar(context, 'Saved to portfolio');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ScanImagePreview extends StatelessWidget {
  const ScanImagePreview({
    required this.imagePath,
    required this.image,
    super.key,
  });

  final String imagePath;
  final XFile? image;

  static final Map<String, Uint8List> _byteCache = {};
  static final Map<String, Future<Uint8List>> _byteFutureCache = {};

  static Future<void> precacheSelectedImage(
    BuildContext context, {
    required String imagePath,
    required XFile? image,
  }) async {
    if (imagePath.startsWith('sample://') || image == null) {
      return;
    }

    final bytes = await _bytesFor(imagePath, image);
    if (!context.mounted) {
      return;
    }
    await precacheImage(MemoryImage(bytes), context);
  }

  static Future<Uint8List> _bytesFor(String imagePath, XFile image) {
    final cachedBytes = _byteCache[imagePath];
    if (cachedBytes != null) {
      return Future.value(cachedBytes);
    }

    return _byteFutureCache.putIfAbsent(imagePath, () async {
      final bytes = await image.readAsBytes();
      _byteCache[imagePath] = bytes;
      return bytes;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (imagePath.startsWith('sample://')) {
      return _fallback(colorScheme, Icons.style_outlined);
    }

    final selectedImage = image;
    if (selectedImage == null) {
      return _fallback(colorScheme, Icons.image_outlined);
    }

    final cachedBytes = _byteCache[imagePath];
    if (cachedBytes != null) {
      return _memoryImage(cachedBytes, colorScheme);
    }

    return FutureBuilder(
      future: _bytesFor(imagePath, selectedImage),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _fallback(colorScheme, Icons.image_outlined);
        }

        return _memoryImage(snapshot.data!, colorScheme);
      },
    );
  }

  Widget _memoryImage(Uint8List bytes, ColorScheme colorScheme) {
    return Image.memory(
      bytes,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return _fallback(colorScheme, Icons.broken_image_outlined);
      },
    );
  }

  Widget _fallback(ColorScheme colorScheme, IconData icon) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: colorScheme.primaryContainer,
      child: Icon(icon, color: colorScheme.primary, size: 34),
    );
  }
}

void _showScannerSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
