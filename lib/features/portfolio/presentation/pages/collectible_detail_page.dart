import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_comp.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/image_enhancement_preview_page.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/features/wishlist/presentation/controllers/wishlist_providers.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Detail page for a saved portfolio collectible.
class CollectibleDetailPage extends ConsumerStatefulWidget {
  /// Creates a collectible detail page.
  const CollectibleDetailPage({required this.item, this.onDelete, super.key});

  /// Item displayed on the detail page.
  final CollectibleItem item;

  /// Called when the user asks to delete the item.
  final Future<bool> Function(String itemId)? onDelete;

  @override
  ConsumerState<CollectibleDetailPage> createState() =>
      _CollectibleDetailPageState();
}

class _CollectibleDetailPageState extends ConsumerState<CollectibleDetailPage> {
  late final ScrollController _scrollController;
  bool _isFavorited = false;
  String? _selectedGalleryPath;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final portfolioItems = ref.watch(portfolioControllerProvider).items;
    final currentItem =
        portfolioItems
            .where((portfolioItem) => portfolioItem.id == widget.item.id)
            .firstOrNull ??
        widget.item;
    final galleryImages = currentItem.effectiveGalleryImages;
    final selectedImage = _selectedImageFor(currentItem, _selectedGalleryPath);
    _selectedGalleryPath ??= selectedImage?.path;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Collectible Details'),
        actions: [
          IconButton(
            key: const ValueKey('collectible-detail-edit-button'),
            tooltip: 'Edit collectible',
            onPressed: () => _showEditCollectibleDialog(
              context: context,
              ref: ref,
              item: currentItem,
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PremiumDetailHero(
                          item: currentItem,
                          selectedImage: selectedImage,
                          onImageSelected: (image) {
                            setState(() => _selectedGalleryPath = image.path);
                          },
                          onImageTap: selectedImage == null
                              ? null
                              : () => _showImageViewer(
                                  context,
                                  item: currentItem,
                                  initialImage: selectedImage,
                                  onUseAsPrimary: _setPrimaryImage,
                                  onDelete: _deleteGalleryImage,
                                  onEdit: _editGalleryImage,
                                ),
                        ),
                        if (currentItem.confidence < 0.70) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const _LowConfidenceBanner(),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _AiSummarySection(item: currentItem),
                        const SizedBox(height: AppSpacing.lg),
                        _KeyAttributeChipsSection(item: currentItem),
                        const SizedBox(height: AppSpacing.lg),
                        if (galleryImages.length == 1)
                          _SingleImageHint(image: galleryImages.single),
                        if (galleryImages.length == 1)
                          const SizedBox(height: AppSpacing.lg),
                        _NotesCard(item: currentItem),
                        const SizedBox(height: AppSpacing.lg),
                        _DetailActionSection(
                          isFavorited: _isFavorited,
                          onEdit: () => _showEditCollectibleDialog(
                            context: context,
                            ref: ref,
                            item: currentItem,
                          ),
                          onShare: () => _shareItem(context, currentItem),
                          onFavorite: () {
                            setState(() => _isFavorited = !_isFavorited);
                            _showDetailSnackBar(
                              context,
                              _isFavorited
                                  ? 'Added to favorites'
                                  : 'Removed from favorites',
                            );
                          },
                          onDelete: widget.onDelete == null
                              ? null
                              : () => _confirmDetailDelete(
                                  context,
                                  currentItem,
                                  widget.onDelete!,
                                ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _WishlistStatusSection(item: currentItem),
                        const SizedBox(height: AppSpacing.lg),
                        _DetailSections(item: currentItem),
                        const SizedBox(height: AppSpacing.lg),
                        _PriceAlertSection(item: currentItem),
                        const SizedBox(height: AppSpacing.lg),
                        const _SimilarCollectiblesSection(),
                        const SizedBox(height: AppSpacing.xxl),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setPrimaryImage(
    CollectibleItem item,
    CollectibleImage image,
  ) async {
    final normalized = _normalizedGalleryWithPrimary(item, image.path);
    if (normalized.isEmpty) {
      return;
    }
    setState(() => _selectedGalleryPath = image.path);
    await ref
        .read(portfolioControllerProvider.notifier)
        .updateItem(
          item.copyWith(imagePath: image.path, galleryImages: normalized),
        );
    if (mounted) {
      _showDetailSnackBar(context, 'Primary image updated');
    }
  }

  Future<void> _deleteGalleryImage(
    CollectibleItem item,
    CollectibleImage image,
  ) async {
    final existing = item.effectiveGalleryImages;
    if (existing.length <= 1) {
      if (mounted) {
        _showDetailSnackBar(context, 'Keep at least one portfolio image');
      }
      return;
    }

    final remaining = existing
        .where((candidate) => candidate.path != image.path)
        .toList(growable: false);
    final nextPrimary = remaining.any((candidate) => candidate.isPrimary)
        ? remaining.firstWhere((candidate) => candidate.isPrimary)
        : remaining.first;
    final normalized = [
      for (final candidate in remaining)
        CollectibleImage(
          path: candidate.path,
          role: candidate.role,
          source: candidate.source,
          originalPath: candidate.originalPath,
          enhancementPreset: candidate.enhancementPreset,
          qualityMetadata: candidate.qualityMetadata,
          isPrimary: candidate.path == nextPrimary.path,
        ),
    ];

    setState(() => _selectedGalleryPath = nextPrimary.path);
    await ref
        .read(portfolioControllerProvider.notifier)
        .updateItem(
          item.copyWith(imagePath: nextPrimary.path, galleryImages: normalized),
        );
    if (mounted) {
      _showDetailSnackBar(context, 'Photo removed');
    }
  }

  Future<CollectibleImage?> _editGalleryImage(
    CollectibleItem item,
    CollectibleImage image,
  ) async {
    final originalPath = _originalImagePathForEdit(image);
    if (originalPath.isEmpty) {
      _showDetailSnackBar(context, 'Original image unavailable');
      return null;
    }

    final result = await ImageEnhancementPreviewPage.show(
      context,
      image: XFile(originalPath),
      initialPreset: _presetForPortfolioImage(image),
      title: 'Edit Photo',
      subtitle: 'Choose the clearest version for this portfolio image.',
      enhancementService: ref.read(imageEnhancementServiceProvider),
      assessmentService: ref.read(imageQualityAssessmentServiceProvider),
    );
    if (!mounted || result == null) {
      return null;
    }

    final images = item.effectiveGalleryImages;
    final editedIndex = images.indexWhere(
      (candidate) => candidate.path == image.path,
    );
    if (editedIndex < 0) {
      _showDetailSnackBar(context, 'Photo no longer available');
      return null;
    }

    final activePath = result.activeImage.path;
    final updatedImage = CollectibleImage(
      path: activePath,
      role: image.role,
      source: image.source,
      originalPath: result.originalImage.path,
      enhancementPreset: result.preset.id,
      qualityMetadata: {
        ...image.qualityMetadata,
        ...result.metadata,
        'originalImagePath': result.originalImage.path,
        'activeImagePath': activePath,
        'enhancementPreset': result.preset.id,
        'selectedEnhancement': result.preset.isEnhanced
            ? 'aiEnhance'
            : 'original',
        'enhancementLabel': result.preset.label,
        'enhanced': result.preset.isEnhanced,
      },
      isPrimary: image.isPrimary,
    );
    final updatedImages = [
      for (var index = 0; index < images.length; index += 1)
        if (index == editedIndex) updatedImage else images[index],
    ];
    final updatedItem = item.copyWith(
      imagePath: image.isPrimary ? activePath : item.imagePath,
      galleryImages: updatedImages,
    );

    setState(() => _selectedGalleryPath = activePath);
    await ref
        .read(portfolioControllerProvider.notifier)
        .updateItem(updatedItem);
    if (mounted) {
      _showDetailSnackBar(context, 'Photo updated');
    }
    return updatedImage;
  }
}

void _shareItem(BuildContext context, CollectibleItem item) {
  _showDetailSnackBar(context, 'Sharing coming soon');
}

Future<void> _confirmDetailDelete(
  BuildContext context,
  CollectibleItem item,
  Future<bool> Function(String itemId) onDelete,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Delete collectible?'),
        content: Text('${item.title} will be removed from your portfolio.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) {
    return;
  }

  final deleted = await onDelete(item.id);
  if (!context.mounted) {
    return;
  }
  if (deleted) {
    Navigator.of(context).maybePop();
  }
}

CollectibleImage? _selectedImageFor(
  CollectibleItem item,
  String? selectedPath,
) {
  final images = item.effectiveGalleryImages;
  if (images.isEmpty) {
    return null;
  }
  final normalizedPath = selectedPath?.trim();
  if (normalizedPath != null && normalizedPath.isNotEmpty) {
    for (final image in images) {
      if (image.path == normalizedPath) {
        return image;
      }
    }
  }
  for (final image in images) {
    if (image.isPrimary || image.path == item.imagePath) {
      return image;
    }
  }
  return images.first;
}

List<CollectibleImage> _normalizedGalleryWithPrimary(
  CollectibleItem item,
  String primaryPath,
) {
  final images = item.effectiveGalleryImages;
  if (images.isEmpty) {
    return const [];
  }
  return [
    for (final image in images)
      CollectibleImage(
        path: image.path,
        role: image.role,
        source: image.source,
        originalPath: image.originalPath,
        enhancementPreset: image.enhancementPreset,
        qualityMetadata: image.qualityMetadata,
        isPrimary: image.path == primaryPath,
      ),
  ];
}

String _originalImagePathForEdit(CollectibleImage image) {
  final original = image.originalPath?.trim();
  if (original != null && original.isNotEmpty) {
    return original;
  }
  return image.path.trim();
}

ImageEnhancementPreset _presetForPortfolioImage(CollectibleImage image) {
  final preset = image.enhancementPreset?.trim();
  if (preset == ImageEnhancementPreset.autoEnhance.id ||
      image.qualityMetadata['selectedEnhancement'] == 'aiEnhance' ||
      image.qualityMetadata['enhanced'] == true) {
    return ImageEnhancementPreset.autoEnhance;
  }
  return ImageEnhancementPreset.original;
}

bool _isAiEnhanced(CollectibleImage? image) {
  if (image == null) {
    return false;
  }
  return _presetForPortfolioImage(image).isEnhanced;
}

void _showImageViewer(
  BuildContext context, {
  required CollectibleItem item,
  required CollectibleImage initialImage,
  required Future<void> Function(CollectibleItem item, CollectibleImage image)
  onUseAsPrimary,
  required Future<void> Function(CollectibleItem item, CollectibleImage image)
  onDelete,
  required Future<CollectibleImage?> Function(
    CollectibleItem item,
    CollectibleImage image,
  )
  onEdit,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.92),
    builder: (_) => _PortfolioGalleryReview(
      item: item,
      initialImage: initialImage,
      onUseAsPrimary: onUseAsPrimary,
      onDelete: onDelete,
      onEdit: onEdit,
    ),
  );
}

class _PremiumDetailHero extends StatelessWidget {
  const _PremiumDetailHero({
    required this.item,
    required this.selectedImage,
    required this.onImageSelected,
    required this.onImageTap,
  });

  final CollectibleItem item;
  final CollectibleImage? selectedImage;
  final ValueChanged<CollectibleImage> onImageSelected;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: AppElevation.level2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: 'Open image preview',
            child: InkWell(
              key: const ValueKey('collectible-detail-image-preview'),
              onTap: onImageTap,
              child: AspectRatio(
                aspectRatio: 16 / 11,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _HeroImageUpdateAnimation(
                      imageKey: selectedImage?.path ?? item.imagePath,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        reverseDuration: const Duration(milliseconds: 100),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: _DetailImageSurface(
                          key: ValueKey(
                            'collectible-detail-hero-${selectedImage?.path ?? item.imagePath}',
                          ),
                          item: item,
                          image: selectedImage,
                        ),
                      ),
                    ),
                    if (_isAiEnhanced(selectedImage))
                      const Positioned(
                        left: AppSpacing.md,
                        top: AppSpacing.md,
                        child: _AiEnhancedDetailBadge(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _DetailGalleryFilmstrip(
            item: item,
            selectedPath: selectedImage?.path,
            onSelected: onImageSelected,
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AnimatedDetailMetadata(
                  id: 'summary-chips',
                  value: '${item.category}-${item.confidence}-${item.rarity}',
                  child: Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      _DetailChip(
                        icon: Icons.category_outlined,
                        label: _fallback(item.category),
                      ),
                      _DetailChip(
                        icon: Icons.verified_outlined,
                        label:
                            '${_confidenceBand(item.confidence)} (${_confidencePercent(item.confidence)})',
                      ),
                      _DetailRarityBadge(label: _rarityLabel(item)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _AnimatedDetailMetadata(
                  id: 'title',
                  value: item.title,
                  child: AppTwoLineTitle(
                    item.title,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.12,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _DetailConfidenceMeter(confidence: item.confidence),
                const SizedBox(height: AppSpacing.md),
                _PremiumDetailValueCard(value: item.estimatedValue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailImageSurface extends StatelessWidget {
  const _DetailImageSurface({required this.item, super.key, this.image});

  final CollectibleItem item;
  final CollectibleImage? image;

  @override
  Widget build(BuildContext context) {
    final imagePath = (image?.path ?? item.cloudImageUrl ?? item.imagePath)
        .trim();
    final placeholder = _DetailImagePlaceholder(item: item, image: image);
    if (imagePath.isEmpty || imagePath.startsWith('sample://')) {
      return placeholder;
    }
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return buildLocalPortfolioImage(
      imagePath: imagePath,
      fit: BoxFit.cover,
      placeholderBuilder: () => placeholder,
    );
  }
}

class _DetailImagePlaceholder extends StatelessWidget {
  const _DetailImagePlaceholder({required this.item, this.image});

  final CollectibleItem item;
  final CollectibleImage? image;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary.withValues(alpha: 0.28),
            colorScheme.tertiary.withValues(alpha: 0.18),
            colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_outlined,
              color: colorScheme.primary,
              size: AppIconSizes.xl,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              image == null
                  ? _fallback(item.category, fallback: 'Collectible image')
                  : _galleryRoleLabel(image!),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailGalleryFilmstrip extends StatelessWidget {
  const _DetailGalleryFilmstrip({
    required this.item,
    required this.selectedPath,
    required this.onSelected,
  });

  final CollectibleItem item;
  final String? selectedPath;
  final ValueChanged<CollectibleImage> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final images = item.effectiveGalleryImages;
    return Container(
      key: const ValueKey('collectible-detail-gallery-filmstrip'),
      height: 132,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: ListView.separated(
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final image = images[index];
          final selected = image.path == selectedPath;
          return TweenAnimationBuilder<double>(
            key: ValueKey('collectible-detail-gallery-${image.path}'),
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.scale(
                  scale: 0.98 + (value * 0.02),
                  child: child,
                ),
              );
            },
            child: SizedBox(
              width: 116,
              child: InkWell(
                onTap: () => onSelected(image),
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: selected || image.isPrimary
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: selected ? 2.5 : 1,
                    ),
                    boxShadow: selected || image.isPrimary
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: selected ? 0.22 : 0.14,
                              ),
                              blurRadius: selected ? 16 : 10,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : AppElevation.level1,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                                child: _DetailGalleryImage(
                                  image: image,
                                  item: item,
                                ),
                              ),
                              if (image.isPrimary)
                                Positioned(
                                  top: 6,
                                  left: 6,
                                  child: _PrimaryImageBadge(compact: true),
                                ),
                              if (_isAiEnhanced(image))
                                const Positioned(
                                  right: 6,
                                  bottom: 6,
                                  child: _AiEnhancedDetailBadge(compact: true),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _shortGalleryRoleLabel(image),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DetailGalleryImage extends StatelessWidget {
  const _DetailGalleryImage({required this.image, required this.item});

  final CollectibleImage image;
  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final path = image.path.trim();
    final placeholder = _DetailImagePlaceholder(item: item);
    if (path.isEmpty || path.startsWith('sample://')) {
      return placeholder;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
      );
    }
    return buildLocalPortfolioImage(
      imagePath: path,
      fit: BoxFit.cover,
      placeholderBuilder: () => placeholder,
    );
  }
}

class _AnimatedDetailMetadata extends StatelessWidget {
  const _AnimatedDetailMetadata({
    required this.id,
    required this.value,
    required this.child,
  });

  final String id;
  final Object? value;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 100),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(
        key: ValueKey('collectible-detail-metadata-$id-$value'),
        child: child,
      ),
    );
  }
}

class _HeroImageUpdateAnimation extends StatelessWidget {
  const _HeroImageUpdateAnimation({
    required this.imageKey,
    required this.child,
  });

  final String imageKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('collectible-detail-hero-scale-$imageKey'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final scale = value < 0.5
            ? 1 + (value * 0.04)
            : 1.02 - ((value - 0.5) * 0.04);
        return Transform.scale(scale: scale, child: child);
      },
      child: child,
    );
  }
}

class _PremiumDetailValueCard extends StatelessWidget {
  const _PremiumDetailValueCard({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: const ValueKey('collectible-detail-value-card-animation'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: DecoratedBox(
        key: const ValueKey('collectible-detail-value-card'),
        decoration: BoxDecoration(
          gradient: AppGradients.premium,
          borderRadius: BorderRadius.circular(12),
          boxShadow: AppElevation.level2,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _AnimatedDetailMetadata(
            id: 'value',
            value: value,
            child: _ValueCardContent(value: value),
          ),
        ),
      ),
    );
  }
}

class _ValueCardContent extends StatelessWidget {
  const _ValueCardContent({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Estimated value',
          style: textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.86),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _formatPortfolioValue(context, value),
          key: const ValueKey('collectible-detail-value-card-value'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DetailRarityBadge extends StatelessWidget {
  const _DetailRarityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return TweenAnimationBuilder<double>(
      key: ValueKey('collectible-detail-rarity-badge-animation-$label'),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      builder: (context, opacity, child) {
        return Opacity(opacity: opacity, child: child);
      },
      child: DecoratedBox(
        key: const ValueKey('collectible-detail-rarity-badge'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.tertiary,
              colorScheme.primary.withValues(alpha: 0.84),
            ],
          ),
          borderRadius: BorderRadius.circular(999),
          boxShadow: AppElevation.level1,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.diamond_outlined,
                size: 14,
                color: colorScheme.onPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                key: const ValueKey('collectible-detail-rarity-badge-label'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailConfidenceMeter extends StatelessWidget {
  const _DetailConfidenceMeter({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final bounded = confidence.clamp(0.0, 1.0);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return _AnimatedDetailMetadata(
      id: 'confidence-meter',
      value: bounded,
      child: DecoratedBox(
        key: const ValueKey('collectible-detail-confidence-meter'),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Confidence',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Text(
                    _confidencePercent(bounded),
                    key: const ValueKey('collectible-detail-confidence-value'),
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: _confidenceMeterColor(context, bounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: TweenAnimationBuilder<double>(
                      key: const ValueKey('collectible-detail-confidence-fill'),
                      tween: Tween(begin: 0, end: bounded),
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      builder: (context, value, _) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: value,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: _confidenceMeterColor(context, bounded),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        );
                      },
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

class _PortfolioGalleryReview extends StatefulWidget {
  const _PortfolioGalleryReview({
    required this.item,
    required this.initialImage,
    required this.onUseAsPrimary,
    required this.onDelete,
    required this.onEdit,
  });

  final CollectibleItem item;
  final CollectibleImage initialImage;
  final Future<void> Function(CollectibleItem item, CollectibleImage image)
  onUseAsPrimary;
  final Future<void> Function(CollectibleItem item, CollectibleImage image)
  onDelete;
  final Future<CollectibleImage?> Function(
    CollectibleItem item,
    CollectibleImage image,
  )
  onEdit;

  @override
  State<_PortfolioGalleryReview> createState() =>
      _PortfolioGalleryReviewState();
}

class _PortfolioGalleryReviewState extends State<_PortfolioGalleryReview> {
  late final PageController _pageController;
  late List<CollectibleImage> _images;
  late int _index;

  @override
  void initState() {
    super.initState();
    _images = widget.item.effectiveGalleryImages.toList(growable: true);
    _index = _images.indexWhere(
      (image) => image.path == widget.initialImage.path,
    );
    if (_index < 0) {
      _index = 0;
    }
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _images[_index];
    final canDelete = _images.length > 1;
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              key: const ValueKey('portfolio-gallery-page-view'),
              controller: _pageController,
              itemCount: _images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: _DetailImageSurface(
                      item: widget.item,
                      image: _images[index],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ReviewPill(
                          label: 'Photo ${_index + 1} of ${_images.length}',
                        ),
                        _ReviewPill(label: _shortGalleryRoleLabel(image)),
                        if (image.isPrimary) const _PrimaryImageBadge(),
                        if (_isAiEnhanced(image))
                          const _AiEnhancedDetailBadge(compact: true),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    key: const ValueKey('portfolio-gallery-close'),
                    tooltip: 'Close image preview',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Positioned(
              left: AppSpacing.md,
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('portfolio-gallery-primary'),
                    onPressed: image.isPrimary
                        ? null
                        : () async {
                            await widget.onUseAsPrimary(widget.item, image);
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _images = [
                                for (final candidate in _images)
                                  CollectibleImage(
                                    path: candidate.path,
                                    role: candidate.role,
                                    source: candidate.source,
                                    originalPath: candidate.originalPath,
                                    enhancementPreset:
                                        candidate.enhancementPreset,
                                    qualityMetadata: candidate.qualityMetadata,
                                    isPrimary: candidate.path == image.path,
                                  ),
                              ];
                            });
                          },
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Use as Primary'),
                  ),
                  FilledButton.icon(
                    key: const ValueKey('portfolio-gallery-edit-photo'),
                    onPressed: () async {
                      final edited = await widget.onEdit(widget.item, image);
                      if (!mounted || edited == null) {
                        return;
                      }
                      setState(() {
                        _images[_index] = edited;
                      });
                    },
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Edit Photo'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('portfolio-gallery-delete'),
                    onPressed: canDelete
                        ? () async {
                            final deleting = _images[_index];
                            await widget.onDelete(widget.item, deleting);
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _images.removeAt(_index);
                              if (_index >= _images.length) {
                                _index = _images.length - 1;
                              }
                            });
                            _pageController.jumpToPage(_index);
                          }
                        : null,
                    icon: const Icon(Icons.delete_outline),
                    label: Text(
                      canDelete ? 'Delete photo' : 'Keep final photo',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewPill extends StatelessWidget {
  const _ReviewPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _PrimaryImageBadge extends StatelessWidget {
  const _PrimaryImageBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 9,
          vertical: compact ? 3 : 5,
        ),
        child: Text(
          compact ? 'Primary' : 'Primary image',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AiEnhancedDetailBadge extends StatelessWidget {
  const _AiEnhancedDetailBadge({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      key: ValueKey(
        compact
            ? 'collectible-detail-ai-enhanced-badge-compact'
            : 'collectible-detail-ai-enhanced-badge-shell',
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF14B8A6), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        boxShadow: AppElevation.level1,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: compact ? 4 : 6,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_fix_high,
              size: compact ? 12 : 14,
              color: colorScheme.onPrimary,
            ),
            if (!compact) ...[
              const SizedBox(width: 6),
              Text(
                'AI Enhanced',
                key: const ValueKey('collectible-detail-ai-enhanced-badge'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SingleImageHint extends StatelessWidget {
  const _SingleImageHint({required this.image});

  final CollectibleImage image;

  @override
  Widget build(BuildContext context) {
    return Text(
      '${_shortGalleryRoleLabel(image)} image saved',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LowConfidenceBanner extends StatelessWidget {
  const _LowConfidenceBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.report_problem_outlined, color: colorScheme.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Needs Review',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Review the collectible information before relying on this identification.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onErrorContainer,
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

class _AiSummarySection extends StatelessWidget {
  const _AiSummarySection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    return AppProfileSection(
      title: 'AI Summary',
      children: [
        Text(
          _aiSummaryFor(item),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _KeyAttributeChipsSection extends StatelessWidget {
  const _KeyAttributeChipsSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final chips = _attributeChipsFor(item);

    return AppProfileSection(
      title: 'Key Attributes',
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final chip in chips)
              _DetailChip(icon: Icons.sell_outlined, label: chip),
          ],
        ),
      ],
    );
  }
}

class _NotesCard extends ConsumerStatefulWidget {
  const _NotesCard({required this.item});

  final CollectibleItem item;

  @override
  ConsumerState<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<_NotesCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void didUpdateWidget(covariant _NotesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id ||
        oldWidget.item.notes != widget.item.notes) {
      _controller.text = widget.item.notes ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppProfileSection(
      title: 'Notes',
      children: [
        TextField(
          key: const ValueKey('collectible-detail-notes-field'),
          controller: _controller,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Add private collection notes',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            key: const ValueKey('collectible-detail-notes-save-button'),
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save notes'),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    await ref
        .read(portfolioControllerProvider.notifier)
        .updateItem(widget.item.copyWith(notes: _controller.text.trim()));
    if (mounted) {
      _showDetailSnackBar(context, 'Notes saved');
    }
  }
}

class _DetailActionSection extends StatelessWidget {
  const _DetailActionSection({
    required this.isFavorited,
    required this.onEdit,
    required this.onShare,
    required this.onFavorite,
    required this.onDelete,
  });

  final bool isFavorited;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return AppProfileSection(
      title: 'Actions',
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            key: const ValueKey('collectible-detail-primary-edit-action'),
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            OutlinedButton.icon(
              key: const ValueKey('collectible-detail-share-action'),
              onPressed: onShare,
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('Share'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('collectible-detail-favorite-action'),
              onPressed: onFavorite,
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border_outlined,
              ),
              label: Text(isFavorited ? 'Favorited' : 'Favorite'),
            ),
            if (onDelete != null)
              OutlinedButton.icon(
                key: const ValueKey('collectible-detail-delete-action'),
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete'),
              ),
          ],
        ),
      ],
    );
  }
}

class _SimilarCollectiblesSection extends StatelessWidget {
  const _SimilarCollectiblesSection();

  @override
  Widget build(BuildContext context) {
    return AppProfileSection(
      title: 'Similar Collectibles',
      children: [
        Text(
          'Similar collectible suggestions will appear here as PackLox learns more from your portfolio.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.icon, required this.label});

  final IconData icon;
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
        color: colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppIconSizes.sm, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showEditCollectibleDialog({
  required BuildContext context,
  required WidgetRef ref,
  required CollectibleItem item,
}) async {
  final editedItem = await showDialog<CollectibleItem>(
    context: context,
    builder: (_) => _EditCollectibleDialog(item: item),
  );
  if (editedItem == null) {
    return;
  }

  await ref.read(portfolioControllerProvider.notifier).updateItem(editedItem);
  if (context.mounted) {
    _showDetailSnackBar(context, 'Collectible updated');
  }
}

class _EditCollectibleDialog extends StatefulWidget {
  const _EditCollectibleDialog({required this.item});

  final CollectibleItem item;

  @override
  State<_EditCollectibleDialog> createState() => _EditCollectibleDialogState();
}

class _EditCollectibleDialogState extends State<_EditCollectibleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _manufacturerController;
  late final TextEditingController _seriesController;
  late final TextEditingController _yearController;
  late final TextEditingController _countryController;
  late final TextEditingController _lowValueController;
  late final TextEditingController _highValueController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final pricing = widget.item.pricing;
    final fallbackValue = widget.item.estimatedValue;
    _titleController = TextEditingController(text: widget.item.title);
    _categoryController = TextEditingController(text: widget.item.category);
    _manufacturerController = TextEditingController(
      text: widget.item.brand ?? '',
    );
    _seriesController = TextEditingController(text: widget.item.series ?? '');
    _yearController = TextEditingController(text: widget.item.year ?? '');
    _countryController = TextEditingController(text: widget.item.country ?? '');
    _lowValueController = TextEditingController(
      text: _decimalText(pricing?.lowEstimate ?? fallbackValue),
    );
    _highValueController = TextEditingController(
      text: _decimalText(pricing?.highEstimate ?? fallbackValue),
    );
    _notesController = TextEditingController(text: widget.item.notes ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _manufacturerController.dispose();
    _seriesController.dispose();
    _yearController.dispose();
    _countryController.dispose();
    _lowValueController.dispose();
    _highValueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit collectible'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _EditTextField(
                  key: const ValueKey('edit-collectible-title-field'),
                  controller: _titleController,
                  label: 'Title',
                  validator: _requiredText,
                ),
                _EditTextField(
                  key: const ValueKey('edit-collectible-category-field'),
                  controller: _categoryController,
                  label: 'Category',
                  validator: _requiredText,
                ),
                _EditTextField(
                  key: const ValueKey('edit-collectible-manufacturer-field'),
                  controller: _manufacturerController,
                  label: 'Manufacturer',
                ),
                _EditTextField(
                  key: const ValueKey('edit-collectible-series-field'),
                  controller: _seriesController,
                  label: 'Series',
                ),
                _EditTextField(
                  key: const ValueKey('edit-collectible-year-field'),
                  controller: _yearController,
                  label: 'Year',
                  keyboardType: TextInputType.number,
                ),
                _EditTextField(
                  key: const ValueKey('edit-collectible-country-field'),
                  controller: _countryController,
                  label: 'Country',
                ),
                _EditTextField(
                  key: const ValueKey('edit-collectible-low-value-field'),
                  controller: _lowValueController,
                  label: 'Estimated value low',
                  keyboardType: TextInputType.number,
                  validator: _requiredMoney,
                ),
                _EditTextField(
                  key: const ValueKey('edit-collectible-high-value-field'),
                  controller: _highValueController,
                  label: 'Estimated value high',
                  keyboardType: TextInputType.number,
                  validator: _requiredMoney,
                ),
                _EditTextField(
                  key: const ValueKey('edit-collectible-notes-field'),
                  controller: _notesController,
                  label: 'Notes',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const ValueKey('edit-collectible-save-button'),
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }

  void _save() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final low = _parseMoney(_lowValueController.text);
    final high = _parseMoney(_highValueController.text);
    final normalizedLow = low <= high ? low : high;
    final normalizedHigh = high >= low ? high : low;
    final estimatedValue = (normalizedLow + normalizedHigh) / 2;
    Navigator.of(context).pop(
      widget.item.copyWith(
        title: _titleController.text.trim(),
        category: _categoryController.text.trim(),
        estimatedValue: estimatedValue,
        pricing: _updatedPricing(
          widget.item,
          normalizedLow,
          normalizedHigh,
          estimatedValue,
        ),
        marketSummary: _updatedMarketSummary(
          widget.item.marketSummary,
          normalizedLow,
          normalizedHigh,
          estimatedValue,
        ),
        year: _yearController.text.trim(),
        brand: _manufacturerController.text.trim(),
        series: _seriesController.text.trim(),
        country: _countryController.text.trim(),
        notes: _notesController.text.trim(),
      ),
    );
  }

  String? _requiredText(String? value) {
    return (value ?? '').trim().isEmpty ? 'Required' : null;
  }

  String? _requiredMoney(String? value) {
    final parsed = _parseMoney(value ?? '');
    if (parsed <= 0) {
      return 'Enter a value above 0';
    }
    return null;
  }
}

class _EditTextField extends StatelessWidget {
  const _EditTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

class _WishlistStatusSection extends ConsumerWidget {
  const _WishlistStatusSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(wishlistStatusForItemProvider(item.id));

    return AppProfileSection(
      title: 'Wishlist Status',
      children: [
        Text(
          'Track whether this collectible is owned, wanted, or still missing.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        selectedStatus.when(
          data: (status) => _WishlistStatusSelector(
            selectedStatus: status,
            onChanged: (nextStatus) => _saveStatus(context, ref, nextStatus),
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => _WishlistStatusSelector(
            selectedStatus: WishlistStatus.owned,
            onChanged: (nextStatus) => _saveStatus(context, ref, nextStatus),
          ),
        ),
      ],
    );
  }

  Future<void> _saveStatus(
    BuildContext context,
    WidgetRef ref,
    WishlistStatus status,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(wishlistRepositoryProvider)
        .saveStatus(item: item, status: status);
    ref.invalidate(wishlistEntriesProvider);
    ref.invalidate(wishlistStatusForItemProvider(item.id));
    messenger.showSnackBar(
      SnackBar(content: Text('Wishlist status set to ${status.label}')),
    );
  }
}

class _WishlistStatusSelector extends StatelessWidget {
  const _WishlistStatusSelector({
    required this.selectedStatus,
    required this.onChanged,
  });

  final WishlistStatus selectedStatus;
  final ValueChanged<WishlistStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final status in WishlistStatus.values) ...[
          _WishlistStatusOption(
            status: status,
            selected: selectedStatus == status,
            onTap: () => onChanged(status),
          ),
          if (status != WishlistStatus.values.last)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _WishlistStatusOption extends StatelessWidget {
  const _WishlistStatusOption({
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final WishlistStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _wishlistStatusColor(context, status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: selected ? null : onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.1)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? color : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Icon(_wishlistStatusIcon(status), color: color),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  status.label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailSections extends StatelessWidget {
  const _DetailSections({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final collectibleDetails = _metadataRows(item);

    return Column(
      children: [
        if (item.pricing != null) ...[
          _DetailExpansionSection(
            title: 'Market Evidence',
            icon: Icons.paid_outlined,
            children: [
              AppCompactMetadata(
                items: [
                  AppMetadataItem(
                    label: 'Market Value',
                    value: _formatMoney(
                      item.pricing!.estimatedMarketValue,
                      item.pricing!.currency,
                    ),
                  ),
                  AppMetadataItem(
                    label: 'Estimated Range',
                    value:
                        '${_formatMoney(item.pricing!.lowEstimate, item.pricing!.currency)} - ${_formatMoney(item.pricing!.highEstimate, item.pricing!.currency)}',
                  ),
                  AppMetadataItem(
                    label: 'Pricing Source',
                    value: item.pricing!.pricingSource,
                  ),
                  AppMetadataItem(
                    label: 'Pricing Confidence',
                    value:
                        '${(item.pricing!.pricingConfidence * 100).toStringAsFixed(0)}%',
                  ),
                  AppMetadataItem(
                    label: 'Last Updated',
                    value: _formatPricingDate(item.pricing!.lastUpdated),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (item.marketSummary != null) ...[
          _DetailExpansionSection(
            title: 'Market Summary',
            icon: Icons.query_stats_outlined,
            children: [
              _MarketIntelligenceSection(summary: item.marketSummary!),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (collectibleDetails.isNotEmpty) ...[
          _DetailExpansionSection(
            title: 'Primary Metadata',
            icon: Icons.tune_outlined,
            children: [AppCompactMetadata(items: collectibleDetails)],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        _DetailExpansionSection(
          title: 'Raw Diagnostics',
          icon: Icons.data_object_outlined,
          children: [
            AppCompactMetadata(
              items: [
                AppMetadataItem(
                  label: 'Status',
                  value: _syncStatusLabel(item.syncStatus),
                ),
                if (item.lastSyncedAt != null)
                  AppMetadataItem(
                    label: 'Last synced',
                    value: _formatDate(item.lastSyncedAt!),
                  ),
              ],
            ),
            if (item.syncStatus == CloudItemSyncStatus.failed &&
                (item.syncError ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                item.syncError!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        if (_hasAiReview(item)) ...[
          _DetailExpansionSection(
            title: 'AI Analysis',
            icon: Icons.psychology_alt_outlined,
            children: [
              if ((item.primaryMatch ?? '').trim().isNotEmpty)
                AppLabelValueRow(
                  label: 'Primary Match',
                  value: item.primaryMatch!,
                ),
              if ((item.confidenceExplanation ?? '').trim().isNotEmpty)
                _DetailTextBlock(
                  title: 'Why this match?',
                  body: item.confidenceExplanation!,
                ),
              if ((item.detectionQuality ?? '').trim().isNotEmpty)
                _DetailTextBlock(
                  title: 'Detection Quality',
                  body: item.detectionQuality!,
                ),
              if ((item.aiReasoning ?? '').trim().isNotEmpty)
                _DetailTextBlock(
                  title: 'AI Reasoning',
                  body: item.aiReasoning!,
                ),
              if (item.alternativeMatches.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                for (final match in item.alternativeMatches.take(3))
                  _AlternativeMatchRow(match: match),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        _DetailExpansionSection(
          title: 'Recommendation',
          icon: Icons.lightbulb_outline,
          initiallyExpanded: true,
          children: [
            Text(
              item.recommendation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _PriceHistorySection(item: item),
      ],
    );
  }

  String _syncStatusLabel(CloudItemSyncStatus status) {
    return switch (status) {
      CloudItemSyncStatus.localOnly => 'Local only',
      CloudItemSyncStatus.pendingUpload => 'Pending upload',
      CloudItemSyncStatus.synced => 'Synced',
      CloudItemSyncStatus.failed => 'Sync failed',
    };
  }

  bool _hasAiReview(CollectibleItem item) {
    return (item.primaryMatch ?? '').trim().isNotEmpty ||
        (item.confidenceExplanation ?? '').trim().isNotEmpty ||
        (item.detectionQuality ?? '').trim().isNotEmpty ||
        (item.aiReasoning ?? '').trim().isNotEmpty ||
        item.alternativeMatches.isNotEmpty;
  }

  List<AppMetadataItem> _metadataRows(CollectibleItem item) {
    return [
      _metadataItem('Year', item.year),
      _metadataItem('Set', item.setName),
      _metadataItem('Series', item.series),
      _metadataItem('Card #', item.cardNumber),
      _metadataItem('Player/Character', item.playerOrCharacter),
      _metadataItem('Rarity', item.rarity),
      _metadataItem('Estimated Grade', item.estimatedGrade),
      _metadataItem('Language', item.language),
      _metadataItem('Edition', item.edition),
      _metadataItem('Country', item.country),
      _metadataItem('Mint', item.mint),
      _metadataItem('Material', item.material),
    ].where((detail) => detail.value.trim().isNotEmpty).toList();
  }

  AppMetadataItem _metadataItem(String label, String? value) {
    return AppMetadataItem(label: label, value: value ?? '');
  }
}

class _DetailExpansionSection extends StatelessWidget {
  const _DetailExpansionSection({
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Material(
          color: Colors.transparent,
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            leading: Icon(icon, color: colorScheme.primary),
            title: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            children: children,
          ),
        ),
      ),
    );
  }
}

class _MarketIntelligenceSection extends StatelessWidget {
  const _MarketIntelligenceSection({required this.summary});

  final MarketSummary summary;

  @override
  Widget build(BuildContext context) {
    final currency = _marketCurrency(summary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCompactMetadata(
          items: [
            AppMetadataItem(
              label: 'Average Price',
              value: _formatMoney(summary.averagePrice, currency),
            ),
            AppMetadataItem(
              label: 'Median Price',
              value: _formatMoney(summary.medianPrice, currency),
            ),
            AppMetadataItem(
              label: 'Market Range',
              value:
                  '${_formatMoney(summary.lowPrice, currency)} - ${_formatMoney(summary.highPrice, currency)}',
            ),
            AppMetadataItem(
              label: 'Sales Count',
              value: '${summary.salesCount}',
            ),
            AppMetadataItem(label: 'Trend', value: summary.trendLabel),
            AppMetadataItem(
              label: 'Confidence',
              value: '${(summary.confidence * 100).toStringAsFixed(0)}%',
            ),
            AppMetadataItem(
              label: 'Sources',
              value: summary.sources.join(', '),
            ),
            AppMetadataItem(
              label: 'Last Updated',
              value: _formatPricingDate(summary.lastUpdated),
            ),
          ],
        ),
        if (summary.comps.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Text(
            'Recent comparable sales',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ComparableSalesVisualList(
            comps: summary.comps.take(5).toList(growable: false),
            currency: currency,
          ),
        ],
      ],
    );
  }
}

class _ComparableSalesVisualList extends StatelessWidget {
  const _ComparableSalesVisualList({
    required this.comps,
    required this.currency,
  });

  final List<MarketComp> comps;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final highest = comps
        .map((comp) => comp.soldPrice)
        .fold<double>(0, (current, next) => current > next ? current : next);

    return Column(
      children: [
        for (final comp in comps) ...[
          _ComparableSaleVisualRow(
            comp: comp,
            highestPrice: highest,
            displayCurrency: currency,
          ),
          if (comp != comps.last) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _ComparableSaleVisualRow extends StatelessWidget {
  const _ComparableSaleVisualRow({
    required this.comp,
    required this.highestPrice,
    required this.displayCurrency,
  });

  final MarketComp comp;
  final double highestPrice;
  final String displayCurrency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final widthFactor = highestPrice <= 0
        ? 0.0
        : (comp.soldPrice / highestPrice).clamp(0.08, 1.0);

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
          Row(
            children: [
              Expanded(
                child: Text(
                  comp.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _formatMoney(comp.soldPrice, comp.currency),
                style: textTheme.labelLarge?.copyWith(
                  color: _valueGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: widthFactor,
              minHeight: 8,
              backgroundColor: colorScheme.outlineVariant,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              semanticsLabel:
                  'Comparable sale ${_formatMoney(comp.soldPrice, displayCurrency)}',
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${comp.source} / ${comp.condition} / ${_formatPricingDate(comp.soldDate)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTextBlock extends StatelessWidget {
  const _DetailTextBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _AlternativeMatchRow extends StatelessWidget {
  const _AlternativeMatchRow({required this.match});

  final CollectibleAlternativeMatch match;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
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
            children: [
              Expanded(
                child: AppTwoLineTitle(
                  match.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
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
            '${match.category} / ${match.reason}',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceHistorySection extends StatelessWidget {
  const _PriceHistorySection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final prices = _pricesFor(item);
    final currentValue = prices.last.value;
    final lowestValue = prices
        .map((point) => point.value)
        .reduce((current, next) => current < next ? current : next);
    final highestValue = prices
        .map((point) => point.value)
        .reduce((current, next) => current > next ? current : next);
    final change = currentValue - prices.first.value;
    final changePercent = prices.first.value == 0
        ? 0
        : change / prices.first.value * 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
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
            'Price History',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Item value summary with accessible labels and local trend estimates.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _ItemValueSummaryVisual(item: item),
          const SizedBox(height: AppSpacing.xl),
          AppResponsiveMetricGroup(
            metrics: [
              AppMetricData(
                label: 'Current Value',
                value: _formatAud(currentValue.toDouble()),
              ),
              AppMetricData(
                label: '6-month Change',
                value:
                    '+${_formatAud(change.toDouble())} (${changePercent.toStringAsFixed(0)}%)',
              ),
              AppMetricData(
                label: 'Highest Value',
                value: _formatAud(highestValue.toDouble()),
              ),
              AppMetricData(
                label: 'Lowest Value',
                value: _formatAud(lowestValue.toDouble()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _PriceBars(points: prices, highestValue: highestValue),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.38),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              'Market trend looks positive. Consider holding or grading before selling.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PricePoint {
  const _PricePoint({required this.month, required this.value});

  final String month;
  final int value;
}

class _ItemValueSummaryVisual extends StatelessWidget {
  const _ItemValueSummaryVisual({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final pricing = item.pricing;
    final current = pricing?.estimatedMarketValue ?? item.estimatedValue;
    final low = pricing?.lowEstimate ?? current * 0.82;
    final high = pricing?.highEstimate ?? current * 1.18;
    final span = high - low;
    final position = span <= 0 ? 0.5 : ((current - low) / span).clamp(0.0, 1.0);

    return Semantics(
      label:
          'Item value summary. Current value ${_formatMoney(current, pricing?.currency ?? 'AUD')}. Range ${_formatMoney(low, pricing?.currency ?? 'AUD')} to ${_formatMoney(high, pricing?.currency ?? 'AUD')}.',
      container: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _valueGold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.stacked_line_chart_outlined,
                    color: _valueGold,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Item Value Summary',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        _formatMoney(current, pricing?.currency ?? 'AUD'),
                        style: textTheme.titleLarge?.copyWith(
                          color: _valueGold,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: LinearProgressIndicator(
                value: position,
                minHeight: 10,
                backgroundColor: colorScheme.outlineVariant,
                valueColor: const AlwaysStoppedAnimation<Color>(_valueGold),
                semanticsLabel: 'Current value position in estimated range',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Low ${_formatMoney(low, pricing?.currency ?? 'AUD')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'High ${_formatMoney(high, pricing?.currency ?? 'AUD')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceBars extends StatelessWidget {
  const _PriceBars({required this.points, required this.highestValue});

  final List<_PricePoint> points;
  final int highestValue;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 156,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _formatAud(point.value.toDouble()),
                      maxLines: 1,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 24,
                    height: 88 * point.value / highestValue,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    point.month,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (point != points.last) const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

List<_PricePoint> _pricesFor(CollectibleItem item) {
  final current = (item.pricing?.estimatedMarketValue ?? item.estimatedValue)
      .round()
      .clamp(1, 1000000000)
      .toInt();
  final factors = [
    1200 / 1850,
    1350 / 1850,
    1480 / 1850,
    1620 / 1850,
    1760 / 1850,
    1.0,
  ];
  final values = factors
      .map((factor) => (current * factor).round().clamp(1, 1000000000).toInt())
      .toList(growable: false);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
  return [
    for (var index = 0; index < months.length; index++)
      _PricePoint(month: months[index], value: values[index]),
  ];
}

class _PriceAlertSection extends ConsumerWidget {
  const _PriceAlertSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(itemPriceAlertsProvider(item.id));

    return AppProfileSection(
      title: 'Price Alerts',
      children: [
        Text(
          'Track value changes locally. Push notifications are not enabled yet.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _CreateAlertButtons(item: item),
        const SizedBox(height: AppSpacing.lg),
        alerts.when(
          data: (itemAlerts) => itemAlerts.isEmpty
              ? const _NoAlertsMessage()
              : Column(
                  children: [
                    for (final alert in itemAlerts) ...[
                      _PriceAlertRow(alert: alert),
                      if (alert != itemAlerts.last)
                        const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => Text(
            'Unable to load local alerts right now.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _CreateAlertButtons extends ConsumerWidget {
  const _CreateAlertButtons({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _AlertActionButton(
          label: 'Alert if value rises 10%',
          icon: Icons.trending_up_outlined,
          onPressed: () => _createAlert(
            context,
            ref,
            item,
            PriceAlertRuleType.percentageIncrease,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AlertActionButton(
          label: 'Alert if value drops 10%',
          icon: Icons.trending_down_outlined,
          onPressed: () => _createAlert(
            context,
            ref,
            item,
            PriceAlertRuleType.percentageDecrease,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _AlertActionButton(
          label: 'Remind when pricing is stale',
          icon: Icons.schedule_outlined,
          onPressed: () => _createAlert(
            context,
            ref,
            item,
            PriceAlertRuleType.stalePricingReminder,
          ),
        ),
      ],
    );
  }

  Future<void> _createAlert(
    BuildContext context,
    WidgetRef ref,
    CollectibleItem item,
    PriceAlertRuleType type,
  ) async {
    final repository = ref.read(priceAlertRepositoryProvider);
    await repository.saveAlert(buildPriceAlert(item: item, type: type));
    ref.invalidate(itemPriceAlertsProvider(item.id));
    ref.invalidate(priceAlertSummaryProvider);
    if (context.mounted) {
      _showDetailSnackBar(context, 'Price alert created');
    }
  }
}

class _AlertActionButton extends StatelessWidget {
  const _AlertActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _NoAlertsMessage extends StatelessWidget {
  const _NoAlertsMessage();

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
      child: Row(
        children: [
          Icon(Icons.notifications_none_outlined, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'No alerts for this collectible yet. Create a local alert below to watch price moves or stale pricing.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceAlertRow extends ConsumerWidget {
  const _PriceAlertRow({required this.alert});

  final PriceAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final triggered = alert.status == PriceAlertStatus.triggered;
    final color = triggered ? AppColors.success : colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                triggered
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
                color: color,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alertRuleLabel(alert.rule),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      alert.message ?? alert.status.label,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                alert.status.label,
                style: textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (triggered) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _resetAlert(context, ref, alert),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _deleteAlert(context, ref, alert),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _resetAlert(
    BuildContext context,
    WidgetRef ref,
    PriceAlert alert,
  ) async {
    final repository = ref.read(priceAlertRepositoryProvider);
    await repository.saveAlert(
      alert.copyWith(
        status: PriceAlertStatus.active,
        updatedAt: DateTime.now(),
        clearMessage: true,
        clearTriggeredAt: true,
      ),
    );
    ref.invalidate(itemPriceAlertsProvider(alert.itemId));
    ref.invalidate(priceAlertSummaryProvider);
    if (context.mounted) {
      _showDetailSnackBar(context, 'Price alert reset');
    }
  }

  Future<void> _deleteAlert(
    BuildContext context,
    WidgetRef ref,
    PriceAlert alert,
  ) async {
    final repository = ref.read(priceAlertRepositoryProvider);
    await repository.deleteAlert(alert.id);
    ref.invalidate(itemPriceAlertsProvider(alert.itemId));
    ref.invalidate(priceAlertSummaryProvider);
    if (context.mounted) {
      _showDetailSnackBar(context, 'Price alert deleted');
    }
  }
}

void _showDetailSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

IconData _wishlistStatusIcon(WishlistStatus status) {
  return switch (status) {
    WishlistStatus.owned => Icons.check_circle_outline,
    WishlistStatus.wanted => Icons.bookmark_add_outlined,
    WishlistStatus.missing => Icons.playlist_add_check_outlined,
  };
}

Color _wishlistStatusColor(BuildContext context, WishlistStatus status) {
  return switch (status) {
    WishlistStatus.owned => AppColors.success,
    WishlistStatus.wanted => Theme.of(context).colorScheme.primary,
    WishlistStatus.missing => const Color(0xFFD97706),
  };
}

String _fallback(String? value, {String fallback = 'Unknown'}) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _confidenceBand(double confidence) {
  if (confidence >= 0.85) {
    return 'High confidence';
  }
  if (confidence >= 0.70) {
    return 'Medium confidence';
  }
  return 'Needs review';
}

String _confidencePercent(double confidence) {
  final bounded = confidence.clamp(0.0, 1.0);
  return '${(bounded * 100).toStringAsFixed(0)}%';
}

String _aiSummaryFor(CollectibleItem item) {
  final category = _fallback(item.category).toLowerCase();
  final evidence = <String>{
    if (_clean(item.brand) != null) 'visible branding',
    if (_clean(item.year) != null) 'date cues',
    if (_clean(item.condition) != null) 'condition details',
    if (_clean(item.rarity) != null || _clean(item.edition) != null)
      'variant cues',
    'category cues',
  }.join(', ');
  final title = _fallback(item.title, fallback: 'this collectible');
  final confidenceNote = item.confidence < 0.70
      ? ' Confidence is lower because some details may be unclear in the image.'
      : ' Review year, variant, and condition before making sale or grading decisions.';

  return '$title appears to be a $category identified from $evidence.$confidenceNote';
}

List<String> _attributeChipsFor(CollectibleItem item) {
  final chips = <String?>{
    _clean(item.year),
    _clean(item.setName),
    _clean(item.edition),
    _clean(item.rarity),
    _clean(item.estimatedGrade),
    _clean(item.condition),
    _clean(item.language),
    _clean(item.country),
    _clean(item.material),
    _clean(item.playerOrCharacter),
  }.whereType<String>().toList(growable: false);

  if (chips.isEmpty) {
    return const ['Unknown'];
  }
  return chips.take(8).toList(growable: false);
}

String? _clean(String? value) {
  final trimmed = (value ?? '').trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _galleryRoleLabel(CollectibleImage image) {
  final role = (image.role ?? '').trim();
  if (role.isEmpty) {
    return image.isPrimary ? 'Primary' : 'Photo';
  }
  final spaced = role
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) {
        return '${match.group(1)} ${match.group(2)}';
      })
      .replaceAll('_', ' ')
      .replaceAll('-', ' ');
  return spaced
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _shortGalleryRoleLabel(CollectibleImage image) {
  final label = _galleryRoleLabel(image).toLowerCase();
  if (label.contains('front') || label.contains('obverse')) {
    return 'Front';
  }
  if (label.contains('back') || label.contains('reverse')) {
    return 'Back';
  }
  if (label.contains('base') ||
      label.contains('underside') ||
      label.contains('bottom')) {
    return 'Base';
  }
  if (label.contains('detail') ||
      label.contains('logo') ||
      label.contains('barcode') ||
      label.contains('close')) {
    return 'Detail';
  }
  if (label.contains('primary')) {
    return 'Primary';
  }
  return _galleryRoleLabel(image);
}

String _formatAud(double value) {
  if (value <= 0) {
    return 'Value unavailable';
  }
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '\$$withCommas';
}

String _formatPortfolioValue(BuildContext context, double value) {
  if (value <= 0) {
    return 'Value unavailable';
  }
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return '${_currencySymbolForLocale(Localizations.localeOf(context))}$withCommas';
}

String _currencySymbolForLocale(Locale locale) {
  final countryCode = locale.countryCode?.toUpperCase();
  if (countryCode == 'GB') {
    return '£';
  }
  if (countryCode == 'DE' ||
      countryCode == 'ES' ||
      countryCode == 'FR' ||
      countryCode == 'IT' ||
      countryCode == 'NL') {
    return '€';
  }
  return '\$';
}

String _rarityLabel(CollectibleItem item) {
  final explicit = _clean(item.rarity);
  if (explicit != null) {
    return explicit;
  }
  if (item.confidence >= 0.95) {
    return 'Ultra Rare';
  }
  if (item.confidence >= 0.88) {
    return 'Rare';
  }
  if (item.confidence >= 0.72) {
    return 'Uncommon';
  }
  return 'Common';
}

Color _confidenceMeterColor(BuildContext context, double confidence) {
  if (confidence >= 0.80) {
    return const Color(0xFF16A34A);
  }
  if (confidence >= 0.60) {
    return const Color(0xFFEAB308);
  }
  return Theme.of(context).colorScheme.error;
}

double _parseMoney(String value) {
  final normalized = value.replaceAll(',', '').replaceAll(r'$', '').trim();
  return double.tryParse(normalized) ?? 0;
}

String _decimalText(double value) {
  if (value % 1 == 0) {
    return value.toStringAsFixed(0);
  }
  return value.toStringAsFixed(2);
}

PricingInfo _updatedPricing(
  CollectibleItem item,
  double low,
  double high,
  double estimatedValue,
) {
  final pricing = item.pricing;
  return PricingInfo(
    estimatedMarketValue: estimatedValue,
    lowEstimate: low,
    highEstimate: high,
    currency: pricing?.currency ?? 'AUD',
    pricingSource: pricing?.pricingSource ?? 'Local edit',
    pricingConfidence: pricing?.pricingConfidence ?? 0,
    lastUpdated: pricing?.lastUpdated,
  );
}

MarketSummary? _updatedMarketSummary(
  MarketSummary? summary,
  double low,
  double high,
  double estimatedValue,
) {
  if (summary == null) {
    return null;
  }

  return MarketSummary(
    averagePrice: estimatedValue,
    medianPrice: estimatedValue,
    lowPrice: low,
    highPrice: high,
    salesCount: summary.salesCount,
    trendLabel: summary.trendLabel,
    confidence: summary.confidence,
    lastUpdated: summary.lastUpdated,
    sources: summary.sources,
    comps: summary.comps,
  );
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatMoney(double value, String currency) {
  if (value <= 0) {
    return 'Value unavailable';
  }
  final whole = value.toStringAsFixed(0);
  final withCommas = whole.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  if (currency.trim().isEmpty || currency.toUpperCase() == 'AUD') {
    return '\$$withCommas';
  }
  return '$currency $withCommas';
}

String _formatPricingDate(DateTime? date) {
  if (date == null) {
    return 'Unknown';
  }

  return _formatDate(date);
}

String _alertRuleLabel(PriceAlertRule rule) {
  switch (rule.type) {
    case PriceAlertRuleType.priceRisesAboveAmount:
      return 'Rises above ${_formatAud(rule.amount ?? 0)}';
    case PriceAlertRuleType.priceDropsBelowAmount:
      return 'Drops below ${_formatAud(rule.amount ?? 0)}';
    case PriceAlertRuleType.percentageIncrease:
      return 'Increases by ${_formatRulePercent(rule.percentage)}';
    case PriceAlertRuleType.percentageDecrease:
      return 'Decreases by ${_formatRulePercent(rule.percentage)}';
    case PriceAlertRuleType.stalePricingReminder:
      return 'Stale pricing reminder';
  }
}

String _formatRulePercent(double? value) {
  return '${((value ?? 0) * 100).toStringAsFixed(0)}%';
}

const _valueGold = Color(0xFFD97706);

String _marketCurrency(MarketSummary summary) {
  if (summary.comps.isEmpty) {
    return 'AUD';
  }

  return summary.comps.first.currency;
}
