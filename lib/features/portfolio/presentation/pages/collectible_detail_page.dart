import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
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
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Detail page for a saved portfolio collectible.
class CollectibleDetailPage extends ConsumerStatefulWidget {
  /// Creates a collectible detail page.
  const CollectibleDetailPage({
    required this.item,
    this.onDelete,
    this.qaInitialScrollOffset = 0,
    this.qaShowDeleteConfirmation = false,
    this.qaShowEditSheet = false,
    super.key,
  });

  /// Item displayed on the detail page.
  final CollectibleItem item;

  /// Called when the user asks to delete the item.
  final Future<bool> Function(String itemId)? onDelete;

  /// Initial scroll offset used by visual QA capture routes.
  final double qaInitialScrollOffset;

  /// Opens the delete confirmation after first layout for visual QA.
  final bool qaShowDeleteConfirmation;

  /// Opens the edit sheet after first layout for visual QA.
  final bool qaShowEditSheet;

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
    _scrollController = ScrollController(
      initialScrollOffset: widget.qaInitialScrollOffset,
      keepScrollOffset: false,
    );
    if (widget.qaShowDeleteConfirmation && widget.onDelete != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _confirmDetailDelete(context, widget.item, widget.onDelete!);
      });
    } else if (widget.qaShowEditSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showEditCollectibleDialog(
          context: context,
          ref: ref,
          item: widget.item,
        );
      });
    }
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: HomeTokens.background,
        systemNavigationBarDividerColor: HomeTokens.background,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarContrastEnforced: false,
      ),
      child: Theme(
        data: AppTheme.dark,
        child: Scaffold(
          backgroundColor: HomeTokens.background,
          body: SafeArea(
            bottom: false,
            child: ColoredBox(
              key: const ValueKey('collectible-detail-packlox-surface'),
              color: HomeTokens.background,
              child: HomeStateContainer(
                key: const ValueKey('collectible-detail-scroll-view'),
                controller: _scrollController,
                sections: [
                  const HomeSection(child: HomeBrandLockup()),
                  HomeSection(
                    child: _DetailTitleBlock(
                      item: currentItem,
                      valuationStateLabel: _detailValueStatusLabel(currentItem),
                    ),
                  ),
                  HomeSection(
                    child: _DetailAuthorityHeader(
                      item: currentItem,
                      isFavorited: _isFavorited,
                      onBack: () => Navigator.of(context).maybePop(),
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
                    ),
                  ),
                  HomeSection(
                    child: _DetailAuthorityOverview(
                      item: currentItem,
                      selectedImage: selectedImage,
                      isFavorited: _isFavorited,
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
                  ),
                  if (currentItem.confidence < 0.70)
                    const HomeSection(child: _LowConfidenceBanner()),
                  HomeSection(
                    bottomPadding: AppSpacing.xl,
                    child: _DetailInlineContent(
                      item: currentItem,
                      galleryImages: galleryImages,
                      isFavorited: _isFavorited,
                      onImageSelected: (image) {
                        setState(() => _selectedGalleryPath = image.path);
                      },
                      selectedImage: selectedImage,
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
                  ),
                ],
              ),
            ),
          ),
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
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .62),
    isScrollControlled: true,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      const destructiveColor = Color(0xFFFF5A66);
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
          child: DecoratedBox(
            key: const ValueKey('collectible-delete-confirmation-sheet'),
            decoration: BoxDecoration(
              color: HomeTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: destructiveColor.withValues(alpha: .42),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .34),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: HomeTokens.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: destructiveColor.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: destructiveColor.withValues(alpha: .42),
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: destructiveColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Remove collectible?',
                          style: Theme.of(sheetContext).textTheme.titleMedium
                              ?.copyWith(
                                color: HomeTokens.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    item.title,
                    key: const ValueKey('collectible-delete-item-name'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(sheetContext).textTheme.titleSmall
                        ?.copyWith(
                          color: HomeTokens.textPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This removes the saved item from your Portfolio. Dismissing this sheet will keep it saved.',
                    style: Theme.of(sheetContext).textTheme.bodyMedium
                        ?.copyWith(
                          color: HomeTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          key: const ValueKey(
                            'collectible-delete-cancel-action',
                          ),
                          onPressed: () =>
                              Navigator.of(sheetContext).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: HomeTokens.textPrimary,
                            side: const BorderSide(color: HomeTokens.border),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                            minimumSize: const Size.fromHeight(46),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: FilledButton.icon(
                          key: const ValueKey(
                            'collectible-delete-confirm-action',
                          ),
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Remove'),
                          style: FilledButton.styleFrom(
                            backgroundColor: destructiveColor,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                            minimumSize: const Size.fromHeight(46),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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

class _DetailTitleBlock extends StatelessWidget {
  const _DetailTitleBlock({
    required this.item,
    required this.valuationStateLabel,
  });

  final CollectibleItem item;
  final String valuationStateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Portfolio Detail',
          key: const ValueKey('collectible-detail-packlox-title'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: HomeTokens.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_fallback(item.category)} / $valuationStateLabel',
          key: const ValueKey('collectible-detail-packlox-subtitle'),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: HomeTokens.textSecondary,
            fontWeight: FontWeight.w600,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _DetailAuthorityHeader extends StatelessWidget {
  const _DetailAuthorityHeader({
    required this.item,
    required this.isFavorited,
    required this.onBack,
    required this.onEdit,
    required this.onShare,
    required this.onFavorite,
  });

  final CollectibleItem item;
  final bool isFavorited;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Collectible Details. ${item.title}.',
      child: Container(
        key: const ValueKey('collectible-detail-authority-header'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HomeTokens.surfaceRaised.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(HomeTokens.cardRadius),
          border: Border.all(color: HomeTokens.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _DetailIconButton(
                  key: const ValueKey('collectible-detail-back'),
                  tooltip: 'Back',
                  icon: Icons.arrow_back,
                  onPressed: onBack,
                ),
                const Spacer(),
                _DetailIconButton(
                  key: const ValueKey('collectible-detail-favorite-action'),
                  tooltip: isFavorited ? 'Favorited' : 'Favorite',
                  icon: isFavorited ? Icons.favorite : Icons.favorite_border,
                  selected: isFavorited,
                  onPressed: onFavorite,
                ),
                const SizedBox(width: AppSpacing.xs),
                _DetailIconButton(
                  key: const ValueKey('collectible-detail-share-action'),
                  tooltip: 'Share',
                  icon: Icons.ios_share_outlined,
                  onPressed: onShare,
                ),
                const SizedBox(width: AppSpacing.xs),
                _DetailIconButton(
                  key: const ValueKey('collectible-detail-edit-button'),
                  tooltip: 'Edit collectible',
                  icon: Icons.edit_outlined,
                  onPressed: onEdit,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved collectible',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelMedium?.copyWith(
                      color: HomeTokens.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      color: HomeTokens.textPrimary,
                      fontWeight: FontWeight.w900,
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

class _DetailIconButton extends StatelessWidget {
  const _DetailIconButton({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: SizedBox.square(
        dimension: 42,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          style: IconButton.styleFrom(
            foregroundColor: selected
                ? colorScheme.primary
                : HomeTokens.textPrimary,
            backgroundColor: selected
                ? colorScheme.primary.withValues(alpha: 0.16)
                : HomeTokens.surfaceRaised.withValues(alpha: 0.94),
            side: BorderSide(
              color: selected
                  ? colorScheme.primary.withValues(alpha: 0.62)
                  : HomeTokens.border.withValues(alpha: 0.92),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(HomeTokens.controlRadius),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailAuthorityOverview extends StatelessWidget {
  const _DetailAuthorityOverview({
    required this.item,
    required this.selectedImage,
    required this.isFavorited,
    required this.onImageSelected,
    required this.onImageTap,
  });

  final CollectibleItem item;
  final CollectibleImage? selectedImage;
  final bool isFavorited;
  final ValueChanged<CollectibleImage> onImageSelected;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    final images = item.effectiveGalleryImages;
    final textTheme = Theme.of(context).textTheme;

    return _DetailAuthorityPanel(
      key: const ValueKey('collectible-detail-authority-overview'),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final useSingleColumn = constraints.maxWidth < 520;
              final imagePreview = _DetailOverviewImagePreview(
                item: item,
                selectedImage: selectedImage,
                images: images,
                onImageTap: onImageTap,
              );
              final summary = _DetailOverviewSummary(
                item: item,
                isFavorited: isFavorited,
                textTheme: textTheme,
              );

              if (useSingleColumn) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    imagePreview,
                    const SizedBox(height: AppSpacing.sm),
                    summary,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: imagePreview),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(flex: 4, child: summary),
                ],
              );
            },
          ),
          if (images.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailGalleryFilmstrip(
              item: item,
              selectedPath: selectedImage?.path,
              onSelected: onImageSelected,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailOverviewImagePreview extends StatelessWidget {
  const _DetailOverviewImagePreview({
    required this.item,
    required this.selectedImage,
    required this.images,
    required this.onImageTap,
  });

  final CollectibleItem item;
  final CollectibleImage? selectedImage;
  final List<CollectibleImage> images;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: selectedImage != null,
      label:
          'Open image preview. ${selectedImage == null ? 'State artwork shown' : _galleryRoleLabel(selectedImage!)}.',
      child: InkWell(
        key: const ValueKey('collectible-detail-image-preview'),
        onTap: onImageTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: AspectRatio(
          aspectRatio: 1.28,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _DetailImageSurface(
                  key: ValueKey(
                    'collectible-detail-hero-${selectedImage?.path ?? item.imagePath}',
                  ),
                  item: item,
                  image: selectedImage,
                ),
                if (images.isNotEmpty)
                  Positioned(
                    left: AppSpacing.xs,
                    top: AppSpacing.xs,
                    child: _ReviewPill(
                      label:
                          '${images.indexWhere((image) => image.path == selectedImage?.path) + 1}/${images.length}',
                    ),
                  ),
                if (selectedImage?.isPrimary ?? false)
                  const Positioned(
                    right: AppSpacing.xs,
                    top: AppSpacing.xs,
                    child: _PrimaryImageBadge(compact: true),
                  ),
                if (_isAiEnhanced(selectedImage))
                  const Positioned(
                    right: AppSpacing.xs,
                    bottom: AppSpacing.xs,
                    child: _AiEnhancedDetailBadge(compact: true),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailOverviewSummary extends StatelessWidget {
  const _DetailOverviewSummary({
    required this.item,
    required this.isFavorited,
    required this.textTheme,
  });

  final CollectibleItem item;
  final bool isFavorited;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          key: const ValueKey('collectible-detail-title'),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: textTheme.headlineSmall?.copyWith(
            color: HomeTokens.textPrimary,
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _DetailAuthorityBadge(
              icon: Icons.category_outlined,
              label: _fallback(item.category),
            ),
            _DetailAuthorityBadge(
              icon: isFavorited ? Icons.favorite : Icons.favorite_border,
              label: isFavorited ? 'Favorited' : 'Saved',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        _DetailAuthorityValueBlock(item: item),
        const SizedBox(height: AppSpacing.sm),
        _DetailValuationStatePanel(item: item),
        const SizedBox(height: AppSpacing.sm),
        _DetailAuthorityConditionMini(item: item),
      ],
    );
  }
}

class _DetailInlineContent extends StatelessWidget {
  const _DetailInlineContent({
    required this.item,
    required this.galleryImages,
    required this.isFavorited,
    required this.selectedImage,
    required this.onImageSelected,
    required this.onImageTap,
    required this.onEdit,
    required this.onShare,
    required this.onFavorite,
    required this.onDelete,
  });

  final CollectibleItem item;
  final List<CollectibleImage> galleryImages;
  final bool isFavorited;
  final CollectibleImage? selectedImage;
  final ValueChanged<CollectibleImage> onImageSelected;
  final VoidCallback? onImageTap;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('collectible-detail-inline-content'),
      children: [
        _DetailOverviewSection(item: item),
        if (galleryImages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _DetailGallerySection(
            item: item,
            galleryImages: galleryImages,
            selectedImage: selectedImage,
            onImageSelected: onImageSelected,
            onImageTap: onImageTap,
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        _DetailInfoSection(item: item),
        const SizedBox(height: AppSpacing.sm),
        _DetailMarketSection(item: item),
        const SizedBox(height: AppSpacing.sm),
        _DetailInsightsSection(item: item),
        const SizedBox(height: AppSpacing.sm),
        _DetailNotesAndStatusSection(item: item),
        const SizedBox(height: AppSpacing.sm),
        _DetailActionsMenuSection(
          item: item,
          isFavorited: isFavorited,
          onEdit: onEdit,
          onShare: onShare,
          onFavorite: onFavorite,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _DetailAuthorityPanel extends StatelessWidget {
  const _DetailAuthorityPanel({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return HomeSurface(
      padding: padding,
      radius: HomeTokens.cardRadius,
      backgroundColor: HomeTokens.surfaceRaised.withValues(alpha: 0.94),
      borderColor: HomeTokens.border,
      child: child,
    );
  }
}

class _DetailAuthorityBadge extends StatelessWidget {
  const _DetailAuthorityBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeTokens.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: HomeTokens.border.withValues(alpha: 0.78)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: HomeTokens.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailAuthorityValueBlock extends StatelessWidget {
  const _DetailAuthorityValueBlock({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isPending = _isValuationPending(item);
    final accentColor = isPending
        ? const Color(0xFFF59E0B)
        : Theme.of(context).colorScheme.primary;
    return Container(
      key: const ValueKey('collectible-detail-value-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accentColor.withValues(alpha: 0.34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated value',
            style: textTheme.labelSmall?.copyWith(
              color: PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _detailValueLabel(context, item),
            key: const ValueKey('collectible-detail-value-card-value'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _detailValueStatusLabel(item),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelSmall?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailValuationStatePanel extends StatelessWidget {
  const _DetailValuationStatePanel({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final confirmed = _hasConfirmedValuation(item);
    final pending = _isValuationPending(item);
    final color = confirmed
        ? HomeTokens.positive
        : pending
        ? HomeTokens.warning
        : HomeTokens.accent;
    final icon = confirmed
        ? Icons.verified_outlined
        : pending
        ? Icons.pending_actions_outlined
        : Icons.add_photo_alternate_outlined;
    final title = confirmed
        ? 'Valuation ready'
        : pending
        ? 'Valuation pending'
        : 'No valuation saved';
    final body = confirmed
        ? _detailValueStatusLabel(item)
        : pending
        ? 'Market pricing is not confirmed yet. Keep the item saved while PackLox waits for a usable comp.'
        : 'Add a portfolio photo or richer details when you are ready to estimate this item.';

    return Container(
      key: ValueKey(
        confirmed
            ? 'collectible-detail-valued-state'
            : pending
            ? 'collectible-detail-pending-valuation-state'
            : 'collectible-detail-unvalued-state',
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(HomeTokens.controlRadius),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: HomeTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: HomeTokens.textSecondary,
                    fontWeight: FontWeight.w700,
                    height: 1.22,
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

class _DetailAuthorityConditionMini extends StatelessWidget {
  const _DetailAuthorityConditionMini({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _DetailMiniStat(
            label: 'Condition',
            value: _fallback(item.condition, fallback: 'Unspecified'),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _DetailMiniStat(
            label: 'Confidence',
            value: _confidencePercent(item.confidence),
          ),
        ),
      ],
    );
  }
}

class _DetailMiniStat extends StatelessWidget {
  const _DetailMiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: HomeTokens.surface.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(HomeTokens.controlRadius),
        border: Border.all(color: HomeTokens.border.withValues(alpha: 0.78)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: HomeTokens.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: HomeTokens.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailOverviewSection extends StatelessWidget {
  const _DetailOverviewSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    return _DetailAuthorityPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(title: 'At a glance', icon: Icons.info_outline),
          const SizedBox(height: AppSpacing.sm),
          _DetailAuthorityRows(
            rows: [
              _DetailInfoRowData('Category', _fallback(item.category)),
              _DetailInfoRowData('Rarity', _rarityLabel(item)),
              _DetailInfoRowData(
                'Confidence',
                '${_confidenceBand(item.confidence)} (${_confidencePercent(item.confidence)})',
              ),
              _DetailInfoRowData('Recommendation', item.recommendation),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailGallerySection extends StatelessWidget {
  const _DetailGallerySection({
    required this.item,
    required this.galleryImages,
    required this.selectedImage,
    required this.onImageSelected,
    required this.onImageTap,
  });

  final CollectibleItem item;
  final List<CollectibleImage> galleryImages;
  final CollectibleImage? selectedImage;
  final ValueChanged<CollectibleImage> onImageSelected;
  final VoidCallback? onImageTap;

  @override
  Widget build(BuildContext context) {
    return _DetailAuthorityPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(
            title: 'Image Gallery',
            icon: Icons.photo_library_outlined,
            trailing: galleryImages.isEmpty
                ? 'No images'
                : '${galleryImages.length} image${galleryImages.length == 1 ? '' : 's'}',
          ),
          const SizedBox(height: AppSpacing.sm),
          if (galleryImages.isEmpty)
            const _DetailEmptyCopy('No saved image is available for this item.')
          else ...[
            AspectRatio(
              aspectRatio: 1.35,
              child: InkWell(
                onTap: onImageTap,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: _DetailImageSurface(item: item, image: selectedImage),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _DetailGalleryFilmstrip(
              item: item,
              selectedPath: selectedImage?.path,
              onSelected: onImageSelected,
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailInfoSection extends StatelessWidget {
  const _DetailInfoSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final rows = _detailMetadataRows(item);
    return _DetailAuthorityPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(title: 'Details & Info', icon: Icons.tune),
          const SizedBox(height: AppSpacing.sm),
          if (rows.isEmpty)
            const _DetailEmptyCopy(
              'No additional metadata has been saved for this collectible yet.',
            )
          else
            _DetailAuthorityRows(rows: rows),
          const SizedBox(height: AppSpacing.md),
          _DetailSectionTitle(
            title: 'Condition',
            icon: Icons.fact_check_outlined,
            compact: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailConfidenceMeter(confidence: item.confidence),
        ],
      ),
    );
  }
}

class _DetailMarketSection extends StatelessWidget {
  const _DetailMarketSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final rows = _detailMarketRows(item);
    return _DetailAuthorityPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(title: 'Market & Value', icon: Icons.paid),
          const SizedBox(height: AppSpacing.sm),
          _DetailAuthorityValueBlock(item: item),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            const _DetailEmptyCopy(
              'No market pricing evidence has been saved for this collectible.',
            )
          else
            _DetailAuthorityRows(rows: rows),
          const SizedBox(height: AppSpacing.md),
          _DetailEmptyCopy(
            item.marketSummary == null
                ? 'No saved price-history series is available yet.'
                : 'Saved market evidence is shown without fabricating price history.',
          ),
        ],
      ),
    );
  }
}

class _DetailInsightsSection extends StatelessWidget {
  const _DetailInsightsSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final summary = _storedAiSummaryFor(item);
    return _DetailAuthorityPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(
            title: 'AI Insights',
            icon: Icons.psychology_alt_outlined,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              SizedBox.square(
                dimension: 72,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: item.confidence.clamp(0.0, 1.0),
                      strokeWidth: 7,
                      color: _confidenceMeterColor(context, item.confidence),
                      backgroundColor: PackLoxTokens.surface,
                    ),
                    Center(
                      child: Text(
                        _confidencePercent(item.confidence),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: PackLoxTokens.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: summary == null
                    ? const _DetailEmptyCopy(
                        'No stored AI review is available for this collectible yet.',
                      )
                    : Text(
                        summary,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: PackLoxTokens.textPrimary,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailNotesAndStatusSection extends StatelessWidget {
  const _DetailNotesAndStatusSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NotesCard(item: item),
        const SizedBox(height: AppSpacing.sm),
        _WishlistStatusSection(item: item),
        const SizedBox(height: AppSpacing.sm),
        _DetailSyncStatusPanel(item: item),
        const SizedBox(height: AppSpacing.sm),
        _PriceAlertSection(item: item),
      ],
    );
  }
}

class _DetailSyncStatusPanel extends StatelessWidget {
  const _DetailSyncStatusPanel({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    return _DetailAuthorityPanel(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(
            title: 'Sync Status',
            icon: Icons.cloud_sync_outlined,
            compact: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _DetailAuthorityRows(
            rows: [
              _DetailInfoRowData('Status', _syncStatusLabel(item.syncStatus)),
              if (item.lastSyncedAt != null)
                _DetailInfoRowData(
                  'Last synced',
                  _formatDate(item.lastSyncedAt!),
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
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailActionsMenuSection extends StatelessWidget {
  const _DetailActionsMenuSection({
    required this.item,
    required this.isFavorited,
    required this.onEdit,
    required this.onShare,
    required this.onFavorite,
    required this.onDelete,
  });

  final CollectibleItem item;
  final bool isFavorited;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return _DetailAuthorityPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(title: 'Actions Menu', icon: Icons.more_horiz),
          const SizedBox(height: AppSpacing.sm),
          _DetailActionMenuRow(
            key: const ValueKey('collectible-detail-primary-edit-action'),
            icon: Icons.edit_outlined,
            label: 'Edit item',
            description: 'Update saved details',
            onTap: onEdit,
          ),
          _DetailActionMenuRow(
            key: const ValueKey('collectible-detail-action-favorite-row'),
            icon: isFavorited ? Icons.favorite : Icons.favorite_border,
            label: isFavorited ? 'Favorited' : 'Add to Wishlist',
            description: 'Save for quick access',
            onTap: onFavorite,
          ),
          _DetailActionMenuRow(
            key: const ValueKey('collectible-detail-action-share-row'),
            icon: Icons.ios_share_outlined,
            label: 'Share item',
            description: 'Uses real saved item data',
            onTap: onShare,
          ),
          if (onDelete != null)
            _DetailActionMenuRow(
              key: const ValueKey('collectible-detail-delete-action'),
              icon: Icons.delete_outline,
              label: 'Delete item',
              description: 'Remove permanently',
              destructive: true,
              onTap: onDelete!,
            ),
        ],
      ),
    );
  }
}

class _DetailActionMenuRow extends StatelessWidget {
  const _DetailActionMenuRow({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : PackLoxTokens.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: PackLoxTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: PackLoxTokens.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({
    required this.title,
    required this.icon,
    this.trailing,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final String? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: compact ? 16 : 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            style:
                (compact
                        ? Theme.of(context).textTheme.titleSmall
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(
                      color: PackLoxTokens.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: PackLoxTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
      ],
    );
  }
}

class _DetailEmptyCopy extends StatelessWidget {
  const _DetailEmptyCopy(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(
      message,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: PackLoxTokens.textSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _DetailInfoRowData {
  const _DetailInfoRowData(this.label, this.value);

  final String label;
  final String value;
}

class _DetailAuthorityRows extends StatelessWidget {
  const _DetailAuthorityRows({required this.rows});

  final List<_DetailInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 116,
                child: Text(
                  row.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: PackLoxTokens.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  row.value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: PackLoxTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (row != rows.last)
            Divider(color: PackLoxTokens.border.withValues(alpha: 0.44)),
        ],
      ],
    );
  }
}

List<_DetailInfoRowData> _detailMetadataRows(CollectibleItem item) {
  final rows = [
    _detailRow('Brand', item.brand),
    _detailRow('Series', item.series),
    _detailRow('Year', item.year),
    _detailRow('Set', item.setName),
    _detailRow('Card #', item.cardNumber),
    _detailRow('Character', item.playerOrCharacter),
    _detailRow('Rarity', item.rarity),
    _detailRow('Grade', item.estimatedGrade),
    _detailRow('Language', item.language),
    _detailRow('Edition', item.edition),
    _detailRow('Country', item.country),
    _detailRow('Mint', item.mint),
    _detailRow('Material', item.material),
  ].whereType<_DetailInfoRowData>().toList(growable: false);
  return rows;
}

List<_DetailInfoRowData> _detailMarketRows(CollectibleItem item) {
  final pricing = item.pricing;
  final market = item.marketSummary;
  return [
    if (pricing != null) ...[
      _DetailInfoRowData(
        'Value range',
        '${_formatMoney(pricing.lowEstimate, pricing.currency)} - ${_formatMoney(pricing.highEstimate, pricing.currency)}',
      ),
      _DetailInfoRowData('Source', pricing.pricingSource),
      _DetailInfoRowData(
        'Confidence',
        '${(pricing.pricingConfidence * 100).toStringAsFixed(0)}%',
      ),
      _DetailInfoRowData('Updated', _formatPricingDate(pricing.lastUpdated)),
    ],
    if (market != null) ...[
      _DetailInfoRowData('Trend', market.trendLabel),
      _DetailInfoRowData('Sales', '${market.salesCount}'),
      _DetailInfoRowData('Sources', market.sources.join(', ')),
    ],
  ];
}

_DetailInfoRowData? _detailRow(String label, String? value) {
  final clean = _clean(value);
  if (clean == null) {
    return null;
  }
  return _DetailInfoRowData(label, clean);
}

String _detailValueLabel(BuildContext context, CollectibleItem item) {
  if (!_shouldShowDetailValue(item)) {
    return 'Value unavailable';
  }
  if (item.estimatedValue == 0) {
    return '${_currencySymbolForLocale(Localizations.localeOf(context))}0';
  }
  return _formatPortfolioValue(context, item.estimatedValue);
}

String _detailValueStatusLabel(CollectibleItem item) {
  return switch (item.valuationStatus) {
    ValuationStatus.marketEstimated => 'Estimated from saved market data',
    ValuationStatus.aiEstimated => 'AI estimate from saved scan data',
    ValuationStatus.providerNotConfigured => 'Pricing source not configured',
    ValuationStatus.noMarketMatch => 'No saved market match',
    ValuationStatus.lookupFailed => 'Pricing lookup unavailable',
    ValuationStatus.unavailable => 'No valuation saved',
  };
}

bool _shouldShowDetailValue(CollectibleItem item) {
  return switch (item.valuationStatus) {
    ValuationStatus.marketEstimated || ValuationStatus.aiEstimated => true,
    ValuationStatus.providerNotConfigured ||
    ValuationStatus.noMarketMatch ||
    ValuationStatus.lookupFailed ||
    ValuationStatus.unavailable => item.estimatedValue > 0,
  };
}

bool _hasConfirmedValuation(CollectibleItem item) {
  return switch (item.valuationStatus) {
    ValuationStatus.marketEstimated || ValuationStatus.aiEstimated => true,
    ValuationStatus.providerNotConfigured ||
    ValuationStatus.noMarketMatch ||
    ValuationStatus.lookupFailed ||
    ValuationStatus.unavailable => false,
  };
}

bool _isValuationPending(CollectibleItem item) {
  return switch (item.valuationStatus) {
    ValuationStatus.providerNotConfigured ||
    ValuationStatus.noMarketMatch ||
    ValuationStatus.lookupFailed => !_shouldShowDetailValue(item),
    ValuationStatus.marketEstimated ||
    ValuationStatus.aiEstimated ||
    ValuationStatus.unavailable => false,
  };
}

String _detailFallbackAssetFor(CollectibleItem item) {
  if (_isValuationPending(item)) {
    return PackLoxAssets.portfolioDetailPendingValuation;
  }
  if (_hasConfirmedValuation(item)) {
    return PackLoxAssets.portfolioDetailValuedItem;
  }
  return PackLoxAssets.portfolioDetailMissingImage;
}

String _detailFallbackTitleFor(CollectibleItem item, CollectibleImage? image) {
  if (image != null) {
    return _galleryRoleLabel(image);
  }
  if (_isValuationPending(item)) {
    return 'Valuation pending';
  }
  if (_hasConfirmedValuation(item)) {
    return 'Valuation ready';
  }
  return 'Image needed';
}

String _detailFallbackSubtitleFor(
  CollectibleItem item,
  CollectibleImage? image,
) {
  if (image != null) {
    return 'Preview unavailable';
  }
  if (_isValuationPending(item)) {
    return 'Waiting for a usable market comp';
  }
  if (_hasConfirmedValuation(item)) {
    return _detailValueStatusLabel(item);
  }
  return _fallback(item.category, fallback: 'Add a portfolio photo');
}

String _syncStatusLabel(CloudItemSyncStatus status) {
  return switch (status) {
    CloudItemSyncStatus.localOnly => 'Local only',
    CloudItemSyncStatus.pendingUpload => 'Pending upload',
    CloudItemSyncStatus.synced => 'Synced',
    CloudItemSyncStatus.failed => 'Sync failed',
  };
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

    return LayoutBuilder(
      key: const ValueKey('collectible-detail-missing-image-fallback'),
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 120 || constraints.maxWidth < 140;
        final stateAsset = _detailFallbackAssetFor(item);
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                stateAsset,
                key: ValueKey('collectible-detail-state-art-$stateAsset'),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: compact ? 0.12 : 0.04),
                      Colors.black.withValues(alpha: compact ? 0.44 : 0.32),
                    ],
                  ),
                ),
              ),
              if (!compact)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: _DetailImageFallbackCaption(
                      title: _detailFallbackTitleFor(item, image),
                      subtitle: _detailFallbackSubtitleFor(item, image),
                      textTheme: textTheme,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailImageFallbackCaption extends StatelessWidget {
  const _DetailImageFallbackCaption({
    required this.title,
    required this.subtitle,
    required this.textTheme,
  });

  final String title;
  final String subtitle;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w700,
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
        child: Wrap(
          spacing: 4,
          runSpacing: 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            Icon(
              Icons.auto_fix_high,
              size: compact ? 12 : 14,
              color: colorScheme.onPrimary,
            ),
            if (!compact) ...[
              Text(
                'AI Enhanced',
                key: const ValueKey('collectible-detail-ai-enhanced-badge'),
                softWrap: true,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          Icon(Icons.report_problem_outlined, color: colorScheme.error),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 0, maxWidth: 280),
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

Future<void> _showEditCollectibleDialog({
  required BuildContext context,
  required WidgetRef ref,
  required CollectibleItem item,
}) async {
  final editedItem = await showModalBottomSheet<CollectibleItem>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .62),
    isScrollControlled: true,
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
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .9,
          ),
          child: DecoratedBox(
            key: const ValueKey('edit-collectible-sheet'),
            decoration: BoxDecoration(
              color: HomeTokens.surfaceRaised,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: const Color(0xFF8BE7FF).withValues(alpha: .36),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .34),
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 42,
                              height: 4,
                              decoration: BoxDecoration(
                                color: HomeTokens.border,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0EA5E9,
                                  ).withValues(alpha: .16),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF8BE7FF,
                                    ).withValues(alpha: .38),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Color(0xFF8BE7FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Edit item details',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: HomeTokens.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.item.title,
                            key: const ValueKey('edit-collectible-item-name'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: HomeTokens.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Update saved local details for this Portfolio item.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: HomeTokens.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-title-field',
                            ),
                            controller: _titleController,
                            label: 'Title',
                            validator: _requiredText,
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-category-field',
                            ),
                            controller: _categoryController,
                            label: 'Category',
                            validator: _requiredText,
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-manufacturer-field',
                            ),
                            controller: _manufacturerController,
                            label: 'Manufacturer',
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-series-field',
                            ),
                            controller: _seriesController,
                            label: 'Series',
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-year-field',
                            ),
                            controller: _yearController,
                            label: 'Year',
                            keyboardType: TextInputType.number,
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-country-field',
                            ),
                            controller: _countryController,
                            label: 'Country',
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-low-value-field',
                            ),
                            controller: _lowValueController,
                            label: 'Estimated value low',
                            keyboardType: TextInputType.number,
                            validator: _requiredMoney,
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-high-value-field',
                            ),
                            controller: _highValueController,
                            label: 'Estimated value high',
                            keyboardType: TextInputType.number,
                            validator: _requiredMoney,
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-notes-field',
                            ),
                            controller: _notesController,
                            label: 'Notes',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: const ValueKey(
                              'edit-collectible-cancel-button',
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: HomeTokens.textPrimary,
                              side: const BorderSide(color: HomeTokens.border),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                              minimumSize: const Size.fromHeight(46),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: FilledButton.icon(
                            key: const ValueKey('edit-collectible-save-button'),
                            onPressed: _save,
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: const Text('Save'),
                            style: FilledButton.styleFrom(
                              backgroundColor: HomeTokens.accentStrong,
                              foregroundColor: HomeTokens.textPrimary,
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                              minimumSize: const Size.fromHeight(46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
    required this.fieldKey,
    required this.controller,
    required this.label,
    this.keyboardType,
    this.validator,
    this.maxLines = 1,
  });

  final Key fieldKey;
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
        key: fieldKey,
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        cursorColor: const Color(0xFF8BE7FF),
        style: const TextStyle(
          color: HomeTokens.textPrimary,
          fontWeight: FontWeight.w700,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: HomeTokens.textSecondary),
          errorMaxLines: 2,
          filled: true,
          fillColor: HomeTokens.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: HomeTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF8BE7FF), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF5A66)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF5A66), width: 1.5),
          ),
        ),
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
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(_wishlistStatusIcon(status), color: color),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  status.label,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

// Retained for historical comparison while Phase 3 routes runtime detail
// presentation through the approved authority tabs above.
// ignore: unused_element
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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Text(
                  comp.title,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _formatMoney(comp.soldPrice, comp.currency),
                  style: textTheme.labelLarge?.copyWith(
                    color: _valueGold,
                    fontWeight: FontWeight.w900,
                  ),
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
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: AppTwoLineTitle(
                  match.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${(match.confidence * 100).toStringAsFixed(0)}%',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
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
    final pricing = item.pricing;
    final market = item.marketSummary;
    final metadata = <AppMetadataItem>[
      if (pricing != null) ...[
        AppMetadataItem(
          label: 'Estimated market value',
          value: _formatMoney(pricing.estimatedMarketValue, pricing.currency),
        ),
        AppMetadataItem(
          label: 'Estimated range',
          value:
              '${_formatMoney(pricing.lowEstimate, pricing.currency)} - ${_formatMoney(pricing.highEstimate, pricing.currency)}',
        ),
        AppMetadataItem(label: 'Pricing source', value: pricing.pricingSource),
        AppMetadataItem(
          label: 'Pricing confidence',
          value: '${(pricing.pricingConfidence * 100).toStringAsFixed(0)}%',
        ),
      ],
      if (market != null) ...[
        AppMetadataItem(label: 'Market trend', value: market.trendLabel),
        AppMetadataItem(label: 'Recent sales', value: '${market.salesCount}'),
        AppMetadataItem(
          label: 'Market confidence',
          value: '${(market.confidence * 100).toStringAsFixed(0)}%',
        ),
      ],
    ];

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
            'Value Evidence',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Stored pricing evidence only. PackLox does not have a saved price-history series for this item yet.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (metadata.isEmpty)
            Text(
              'No market pricing evidence has been saved for this collectible.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            AppCompactMetadata(items: metadata),
        ],
      ),
    );
  }
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
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(
                triggered
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_none_outlined,
                color: color,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _alertRuleLabel(alert.rule),
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      alert.message ?? alert.status.label,
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Text(
                  alert.status.label,
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (triggered) ...[
                OutlinedButton(
                  onPressed: () => _resetAlert(context, ref, alert),
                  child: const Text('Reset'),
                ),
              ],
              OutlinedButton(
                onPressed: () => _deleteAlert(context, ref, alert),
                child: const Text('Delete'),
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

String? _storedAiSummaryFor(CollectibleItem item) {
  final parts = [
    _clean(item.aiReasoning),
    _clean(item.confidenceExplanation),
    _clean(item.detectionQuality),
  ].whereType<String>().toList(growable: false);
  if (parts.isEmpty) {
    return null;
  }
  return parts.join('\n\n');
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
  return 'Rarity unavailable';
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
    valuationStatus: pricing?.valuationStatus ?? item.valuationStatus,
    valuationSource: pricing?.valuationSource ?? item.valuationSource,
    aiEstimatedValue: pricing?.aiEstimatedValue ?? item.aiEstimatedValue,
    pricingExplanation: pricing?.pricingExplanation,
    reasonCode: pricing?.reasonCode,
    valuationStrategy: pricing?.valuationStrategy,
    attributionText: pricing?.attributionText,
    displayString: pricing?.displayString,
    originalPrice: pricing?.originalPrice,
    originalCurrency: pricing?.originalCurrency,
    exchangeRateUsed: pricing?.exchangeRateUsed,
    exchangeRateDate: pricing?.exchangeRateDate,
    lowEstimateAud: pricing?.lowEstimateAud,
    highEstimateAud: pricing?.highEstimateAud,
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
