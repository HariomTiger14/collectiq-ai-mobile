import 'dart:async';

import 'package:collectiq_ai/core/assets/packlox_assets.dart';
import 'package:collectiq_ai/core/cloud/cloud_service_registry.dart';
import 'package:collectiq_ai/core/cloud/services/cloud_portfolio_sync_service.dart';
import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/theme/app_theme.dart';
import 'package:collectiq_ai/features/home/domain/entities/smart_collector_insights.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:collectiq_ai/features/image_sync/presentation/controllers/image_sync_controller.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_comp.dart';
import 'package:collectiq_ai/features/market/domain/entities/market_summary.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert.dart';
import 'package:collectiq_ai/features/price_alerts/domain/entities/price_alert_notification.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_notification_controller.dart';
import 'package:collectiq_ai/features/price_alerts/presentation/controllers/price_alert_providers.dart';
import 'package:collectiq_ai/features/portfolio/presentation/controllers/portfolio_controller.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:collectiq_ai/features/scanner/domain/entities/image_enhancement_preset.dart';
import 'package:collectiq_ai/features/scanner/presentation/pages/image_enhancement_preview_page.dart';
import 'package:collectiq_ai/features/scanner/services/scan_pricing_quote_service.dart';
import 'package:collectiq_ai/features/scanner/services/scanner_providers.dart';
import 'package:collectiq_ai/features/subscription/domain/entities/subscription_exception.dart';
import 'package:collectiq_ai/features/subscription/presentation/controllers/subscription_controller.dart';
import 'package:collectiq_ai/features/wishlist/domain/entities/wishlist_status_entry.dart';
import 'package:collectiq_ai/features/wishlist/presentation/controllers/wishlist_providers.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:collectiq_ai/shared/domain/entities/collectible_item.dart';
import 'package:collectiq_ai/shared/domain/entities/pricing_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

final _portfolioValuationSnapshotsProvider =
    FutureProvider.family<List<PortfolioValuationSnapshot>, String>((
      ref,
      itemId,
    ) async {
      final cloudSnapshots = await ref
          .watch(cloudServiceRegistryProvider)
          .cloudPortfolioSyncService
          .fetchValuationSnapshots(itemId);
      final localSnapshots = await ref
          .watch(valuationSnapshotRepositoryProvider)
          .getSnapshots(itemId);
      return _mergeValuationSnapshots(localSnapshots, cloudSnapshots);
    });

List<PortfolioValuationSnapshot> _mergeValuationSnapshots(
  List<PortfolioValuationSnapshot> localSnapshots,
  List<PortfolioValuationSnapshot> cloudSnapshots,
) {
  final byKey = <String, PortfolioValuationSnapshot>{};
  for (final snapshot in [...localSnapshots, ...cloudSnapshots]) {
    final key = [
      snapshot.portfolioItemId,
      snapshot.pricedAt.toIso8601String(),
      snapshot.valueAud?.toStringAsFixed(2) ?? '',
      snapshot.valuationStatus.wireValue,
    ].join('|');
    byKey[key] = snapshot;
  }
  final merged = byKey.values.toList();
  merged.sort((left, right) => left.pricedAt.compareTo(right.pricedAt));
  return merged;
}

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
  String? _selectedGalleryPath;
  var _isRefreshingValue = false;

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
    final wishlistStatus = ref.watch(
      wishlistStatusForItemProvider(currentItem.id),
    );
    final isFavorited = wishlistStatus.maybeWhen(
      data: (status) => status == WishlistStatus.wanted,
      orElse: () => false,
    );

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
                      isFavorited: isFavorited,
                      onBack: () => Navigator.of(context).maybePop(),
                      onEdit: () => _showEditCollectibleDialog(
                        context: context,
                        ref: ref,
                        item: currentItem,
                      ),
                      onShare: () => _shareItem(context, currentItem),
                      onFavorite: () =>
                          _toggleWishlistFavorite(currentItem, wishlistStatus),
                    ),
                  ),
                  HomeSection(
                    child: _DetailAuthorityOverview(
                      item: currentItem,
                      selectedImage: selectedImage,
                      isFavorited: isFavorited,
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
                      isFavorited: isFavorited,
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
                      onAddPhoto: () =>
                          _addPortfolioPhotoFromGallery(currentItem),
                      isRefreshingValue: _isRefreshingValue,
                      onRefreshValue: () => _refreshPortfolioValue(currentItem),
                      onEdit: () => _showEditCollectibleDialog(
                        context: context,
                        ref: ref,
                        item: currentItem,
                      ),
                      onShare: () => _shareItem(context, currentItem),
                      onFavorite: () =>
                          _toggleWishlistFavorite(currentItem, wishlistStatus),
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

  Future<void> _toggleWishlistFavorite(
    CollectibleItem item,
    AsyncValue<WishlistStatus> currentStatus,
  ) async {
    final status = currentStatus.maybeWhen(
      data: (value) => value,
      orElse: () => WishlistStatus.owned,
    );
    final nextStatus = status == WishlistStatus.wanted
        ? WishlistStatus.owned
        : WishlistStatus.wanted;
    await ref
        .read(wishlistRepositoryProvider)
        .saveStatus(item: item, status: nextStatus);
    ref.invalidate(wishlistEntriesProvider);
    ref.invalidate(wishlistStatusForItemProvider(item.id));
    if (!mounted) {
      return;
    }
    _showDetailSnackBar(
      context,
      nextStatus == WishlistStatus.wanted
          ? 'Added to wishlist'
          : 'Removed from wishlist',
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

  Future<void> _addPortfolioPhotoFromGallery(CollectibleItem item) async {
    try {
      final planLimits = ref.read(activePlanLimitsProvider);
      final currentPhotoCount = item.effectiveGalleryImages.length;
      if (!planLimits.canAddPhoto(currentPhotoCount)) {
        _showDetailSnackBar(
          context,
          'Your ${planLimits.plan.displayName} plan supports ${planLimits.photosPerItemLabel}. Upgrade to add more photos.',
        );
        return;
      }

      final galleryService = ref.read(galleryServiceProvider);
      final pickedImage = await galleryService.pickImage();
      if (pickedImage == null) {
        return;
      }
      await galleryService.validateImage(pickedImage);
      final persistedImage = await galleryService.persistSelectedImage(
        pickedImage,
      );
      final portfolioImage = CollectibleImage(
        path: persistedImage.path,
        role: 'front',
        source: 'gallery',
        originalPath: pickedImage.path,
        isPrimary: true,
      );
      final updatedItem = _itemWithAddedPortfolioPhoto(item, portfolioImage);
      setState(() => _selectedGalleryPath = portfolioImage.path);
      await ref
          .read(portfolioControllerProvider.notifier)
          .updateItem(updatedItem);
      unawaited(
        ref
            .read(imageSyncControllerProvider.notifier)
            .enqueueImage(
              collectibleId: updatedItem.id,
              localPath: portfolioImage.path,
            ),
      );
      if (mounted) {
        _showDetailSnackBar(context, 'Photo added to portfolio item');
      }
    } catch (_) {
      if (mounted) {
        _showDetailSnackBar(context, 'Unable to add photo');
      }
    }
  }

  Future<void> _refreshPortfolioValue(CollectibleItem item) async {
    if (_isRefreshingValue) {
      return;
    }

    try {
      await ref
          .read(subscriptionControllerProvider.notifier)
          .ensureCanRefreshValue();
    } on SubscriptionException catch (error) {
      if (mounted) {
        _showDetailSnackBar(context, error.message);
      }
      return;
    }
    if (!mounted) {
      return;
    }

    setState(() => _isRefreshingValue = true);
    ValuationStatus? refreshedStatus;
    try {
      final quote = await ref
          .read(scanPricingQuoteServiceProvider)
          .quoteItem(item);
      refreshedStatus = quote.valuationStatus;
      final refreshedAt = DateTime.now();
      final hasRefreshedValue =
          quote.valuationStatus == ValuationStatus.marketEstimated &&
          quote.estimatedValue > 0;
      final refreshedItem = item.copyWith(
        estimatedValue: hasRefreshedValue
            ? quote.estimatedValue
            : item.estimatedValue,
        pricing: hasRefreshedValue ? quote.pricing : item.pricing,
        marketSummary: hasRefreshedValue
            ? quote.marketSummary ?? item.marketSummary
            : item.marketSummary,
        valuationStatus: hasRefreshedValue
            ? quote.valuationStatus
            : item.valuationStatus,
        valuationSource: hasRefreshedValue
            ? quote.valuationSource
            : item.valuationSource,
        aiEstimatedValue: quote.aiEstimatedValue ?? item.aiEstimatedValue,
        valueAtScan: item.valueAtScan ?? item.estimatedValue,
        lastValueRefreshedAt: hasRefreshedValue
            ? refreshedAt
            : item.lastValueRefreshedAt,
      );
      if (hasRefreshedValue) {
        await ref
            .read(portfolioControllerProvider.notifier)
            .updateItemWithValuationSnapshot(refreshedItem);
      } else {
        await ref
            .read(portfolioControllerProvider.notifier)
            .updateItem(refreshedItem);
      }
      await ref
          .read(subscriptionControllerProvider.notifier)
          .recordSuccessfulPriceRefresh();
    } catch (_) {
      refreshedStatus = null;
    } finally {
      if (mounted) {
        setState(() => _isRefreshingValue = false);
      }
    }

    if (mounted) {
      _showDetailSnackBar(context, _valueRefreshMessage(refreshedStatus));
    }
  }
}

void _shareItem(BuildContext context, CollectibleItem item) {
  unawaited(_shareItemNative(context, item));
}

Future<void> _shareItemNative(
  BuildContext context,
  CollectibleItem item,
) async {
  final summary = _shareSummary(item);
  try {
    await SharePlus.instance.share(
      ShareParams(
        title: 'Share ${item.title}',
        subject: '${item.title} in PackLox',
        text: summary,
        sharePositionOrigin: _shareOriginFor(context),
      ),
    );
  } catch (_) {
    await Clipboard.setData(ClipboardData(text: summary));
    if (context.mounted) {
      _showDetailSnackBar(context, 'Share unavailable. Summary copied.');
    }
  }
}

Rect? _shareOriginFor(BuildContext context) {
  final renderBox = context.findRenderObject();
  if (renderBox is! RenderBox || !renderBox.hasSize) {
    return null;
  }
  final topLeft = renderBox.localToGlobal(Offset.zero);
  return topLeft & renderBox.size;
}

String _shareSummary(CollectibleItem item) {
  final lines = <String>[
    item.title,
    'Category: ${_fallback(item.category)}',
    'Condition: ${_fallback(item.condition)}',
    'Value: ${_formatMoney(item.estimatedValue, item.pricing?.currency ?? 'AUD')}',
  ];
  final source = item.pricing?.pricingSource.trim();
  if (source != null && source.isNotEmpty) {
    lines.add('Source: $source');
  }
  lines.add('Saved in PackLox');
  return lines.join('\n');
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

CollectibleItem _itemWithAddedPortfolioPhoto(
  CollectibleItem item,
  CollectibleImage newImage,
) {
  final existing = item.galleryImages
      .where((image) => image.path.trim().isNotEmpty)
      .toList(growable: false);
  final nextGallery = [
    for (final image in existing)
      CollectibleImage(
        path: image.path,
        role: image.role,
        source: image.source,
        originalPath: image.originalPath,
        enhancementPreset: image.enhancementPreset,
        qualityMetadata: image.qualityMetadata,
        imageStoragePath: image.imageStoragePath,
        cloudImageUrl: image.cloudImageUrl,
        isPrimary: false,
      ),
    CollectibleImage(
      path: newImage.path,
      role: newImage.role,
      source: newImage.source,
      originalPath: newImage.originalPath,
      enhancementPreset: newImage.enhancementPreset,
      qualityMetadata: newImage.qualityMetadata,
      imageStoragePath: newImage.imageStoragePath,
      cloudImageUrl: newImage.cloudImageUrl,
      isPrimary: true,
    ),
  ];
  return item.copyWith(imagePath: newImage.path, galleryImages: nextGallery);
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
    required this.onAddPhoto,
    required this.isRefreshingValue,
    required this.onRefreshValue,
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
  final VoidCallback onAddPhoto;
  final bool isRefreshingValue;
  final VoidCallback onRefreshValue;
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
        if (_usesCatalogPlaceholderImage(item)) ...[
          const SizedBox(height: AppSpacing.sm),
          _DetailPhotoEvidencePrompt(onAddPhoto: onAddPhoto, onEdit: onEdit),
        ],
        if (galleryImages.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          _DetailGallerySection(
            item: item,
            galleryImages: galleryImages,
            selectedImage: selectedImage,
            onImageSelected: onImageSelected,
            onImageTap: onImageTap,
            onAddPhoto: onAddPhoto,
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
          isRefreshingValue: isRefreshingValue,
          onRefreshValue: onRefreshValue,
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
      key: const ValueKey('collectible-detail-overview-section'),
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
    required this.onAddPhoto,
  });

  final CollectibleItem item;
  final List<CollectibleImage> galleryImages;
  final CollectibleImage? selectedImage;
  final ValueChanged<CollectibleImage> onImageSelected;
  final VoidCallback? onImageTap;
  final VoidCallback onAddPhoto;

  @override
  Widget build(BuildContext context) {
    return _DetailAuthorityPanel(
      key: const ValueKey('collectible-detail-gallery-section'),
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
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                key: const ValueKey(
                  'collectible-detail-gallery-add-photo-action',
                ),
                onPressed: onAddPhoto,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Add photo'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HomeTokens.textPrimary,
                  side: const BorderSide(color: HomeTokens.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailPhotoEvidencePrompt extends StatelessWidget {
  const _DetailPhotoEvidencePrompt({
    required this.onAddPhoto,
    required this.onEdit,
  });

  final VoidCallback onAddPhoto;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _DetailAuthorityPanel(
      key: const ValueKey('collectible-detail-photo-evidence-prompt'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(
            title: 'Add your photos',
            icon: Icons.add_photo_alternate_outlined,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This item was saved from catalog search, so PackLox is showing a category placeholder. Add your own photos to make the portfolio record personal and evidence-backed.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                key: const ValueKey('collectible-detail-add-photo-action'),
                onPressed: onAddPhoto,
                icon: const Icon(Icons.photo_library_outlined, size: 18),
                label: const Text('Add your photos'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8BE7FF),
                  foregroundColor: const Color(0xFF07111D),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              OutlinedButton.icon(
                key: const ValueKey('collectible-detail-review-details-action'),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Review details'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: HomeTokens.textPrimary,
                  side: const BorderSide(color: HomeTokens.border),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
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
      key: const ValueKey('collectible-detail-info-section'),
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
    final catalogSnapshot = _catalogSnapshotFor(item);
    return _DetailAuthorityPanel(
      key: const ValueKey('collectible-detail-market-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(title: 'Market & Value', icon: Icons.paid),
          const SizedBox(height: AppSpacing.sm),
          _DetailAuthorityValueBlock(item: item),
          const SizedBox(height: AppSpacing.md),
          _DetailValueHistoryPanel(item: item),
          const SizedBox(height: AppSpacing.md),
          _PricingTrustPanel(item: item),
          if (catalogSnapshot != null) ...[
            const SizedBox(height: AppSpacing.md),
            _CatalogSnapshotPanel(snapshot: catalogSnapshot),
          ],
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            const _DetailEmptyCopy(
              'No market pricing evidence has been saved for this collectible.',
            )
          else
            _DetailAuthorityRows(rows: rows, alignValuesRight: true),
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

class _PricingTrustPanel extends StatelessWidget {
  const _PricingTrustPanel({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final pricing = item.pricing;
    final status = _effectiveValuationStatus(item);
    final trustColor = _pricingTrustColor(context, status);
    final rows = _pricingTrustRows(item);
    return Container(
      key: const ValueKey('collectible-detail-pricing-trust-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceRaised.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: HomeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(
            title: 'Pricing Trust',
            icon: Icons.verified_user_outlined,
            compact: true,
            trailing: _pricingTrustTrailing(status),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: trustColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: trustColor.withValues(alpha: 0.32)),
                ),
                child: Icon(
                  _pricingTrustIcon(status),
                  color: trustColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pricingTrustTitle(status),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: HomeTokens.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _pricingTrustMessage(item),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HomeTokens.textSecondary,
                        fontWeight: FontWeight.w700,
                        height: 1.32,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailAuthorityRows(rows: rows),
          ],
          if (pricing?.attributionText?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailEmptyCopy(pricing!.attributionText!.trim()),
          ],
        ],
      ),
    );
  }
}

class _CatalogSnapshotPanel extends StatelessWidget {
  const _CatalogSnapshotPanel({required this.snapshot});

  final _CatalogSnapshotData snapshot;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final pricing = snapshot.pricing;
    return Container(
      key: const ValueKey('collectible-detail-catalog-snapshot-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceRaised.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: HomeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DetailSectionTitle(
            title: 'Saved valuation snapshot',
            icon: Icons.lock_clock_rounded,
            compact: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This value was saved with the portfolio item. Opening Portfolio does not call pricing APIs.',
            style: textTheme.bodyMedium?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w700,
              height: 1.32,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _SnapshotMetricChip(
                label: 'Snapshot value',
                value: _displayValue(
                  pricing,
                  fallbackValue: snapshot.savedValue,
                ),
              ),
              _SnapshotMetricChip(
                label: 'Source',
                value: pricing.pricingSource,
              ),
              if (snapshot.catalogId != null)
                _SnapshotMetricChip(
                  label: 'Catalog ID',
                  value: snapshot.catalogId!,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _SnapshotEvidenceRows(snapshot: snapshot),
        ],
      ),
    );
  }
}

class _SnapshotMetricChip extends StatelessWidget {
  const _SnapshotMetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 112),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: HomeTokens.background.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: HomeTokens.border.withValues(alpha: 0.62)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: HomeTokens.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SnapshotEvidenceRows extends StatelessWidget {
  const _SnapshotEvidenceRows({required this.snapshot});

  final _CatalogSnapshotData snapshot;

  @override
  Widget build(BuildContext context) {
    final pricing = snapshot.pricing;
    final rows = [
      _DetailInfoRowData('Attribution', snapshot.attribution),
      if (pricing.lastUpdated != null)
        _DetailInfoRowData(
          'Provider checked',
          _formatPricingDate(pricing.lastUpdated),
        ),
      if (pricing.valuationStrategy?.trim().isNotEmpty ?? false)
        _DetailInfoRowData(
          'Strategy',
          _humanizeToken(pricing.valuationStrategy!),
        ),
      if (pricing.reasonCode?.trim().isNotEmpty ?? false)
        _DetailInfoRowData('Reason', _humanizeToken(pricing.reasonCode!)),
    ];
    return _DetailAuthorityRows(rows: rows, alignValuesRight: true);
  }
}

class _DetailValueHistoryPanel extends ConsumerWidget {
  const _DetailValueHistoryPanel({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planLimits = ref.watch(activePlanLimitsProvider);
    final snapshotsAsync = ref.watch(
      _portfolioValuationSnapshotsProvider(item.id),
    );
    final snapshots = snapshotsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <PortfolioValuationSnapshot>[],
    );
    final chartValues = _valueHistoryChartValues(item, snapshots);
    final currency = item.pricing?.currency ?? 'AUD';
    final scanValue = _valueAtScanFor(item);
    final currentValue = _currentValueFor(item);
    final delta = currentValue - scanValue;
    final hasMovement = scanValue > 0 && currentValue > 0 && delta.abs() > 0.01;
    final isPositive = delta >= 0;
    final movementColor = !hasMovement
        ? HomeTokens.textSecondary
        : isPositive
        ? HomeTokens.positive
        : Theme.of(context).colorScheme.error;
    final movementLabel = hasMovement
        ? '${isPositive ? '+' : '-'}${_formatMoney(delta.abs(), currency)}'
        : null;
    final movementPercent = hasMovement && scanValue > 0
        ? '${isPositive ? '+' : '-'}${((delta.abs() / scanValue) * 100).toStringAsFixed(1)}%'
        : null;
    final footerLabel = snapshotsAsync.isLoading
        ? 'Loading value history'
        : snapshots.isNotEmpty
        ? _snapshotHistoryLabel(snapshots)
        : _lastRefreshedLabel(item);

    return Container(
      key: const ValueKey('collectible-detail-value-history-panel'),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: HomeTokens.surfaceRaised.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: HomeTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(
            title: 'Value History',
            icon: Icons.show_chart_rounded,
            compact: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _DetailValueHistoryMetric(
                  label: 'At scan',
                  value: _formatMoney(scanValue, currency),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _DetailValueHistoryMetric(
                  label: 'Current',
                  value: _formatMoney(currentValue, currency),
                ),
              ),
              if (hasMovement) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _DetailValueHistoryMetric(
                    label: 'Gain/Loss',
                    value: movementLabel!,
                    valueColor: movementColor,
                    subtitle: movementPercent,
                  ),
                ),
              ],
            ],
          ),
          if (!hasMovement) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  Icons.timeline_rounded,
                  size: 14,
                  color: HomeTokens.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Trend begins after next refresh.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: HomeTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (!planLimits.canUseFullValueHistory)
            _DetailPlanLockedPanel(
              icon: Icons.lock_outline_rounded,
              title: 'Full history is a Pro tool',
              message:
                  'Free shows value at scan and current value. Upgrade for trend charts and deeper valuation history.',
            )
          else
            Container(
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                color: HomeTokens.background.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                  color: HomeTokens.border.withValues(alpha: 0.62),
                ),
              ),
              child: CustomPaint(
                painter: _ValueHistorySparklinePainter(
                  color: movementColor,
                  values: chartValues,
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Text(
                      footerLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: HomeTokens.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailPlanLockedPanel extends StatelessWidget {
  const _DetailPlanLockedPanel({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: HomeTokens.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: HomeTokens.accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: HomeTokens.accent, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: HomeTokens.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HomeTokens.textSecondary,
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

class _DetailValueHistoryMetric extends StatelessWidget {
  const _DetailValueHistoryMetric({
    required this.label,
    required this.value,
    this.valueColor,
    this.subtitle,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: HomeTokens.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: valueColor ?? HomeTokens.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: HomeTokens.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
      ],
    );
  }
}

class _ValueHistorySparklinePainter extends CustomPainter {
  const _ValueHistorySparklinePainter({
    required this.color,
    required this.values,
  });

  final Color color;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final cleanedValues = values.where((value) => value >= 0).toList();
    if (cleanedValues.isEmpty) {
      return;
    }
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final left = AppSpacing.sm;
    final right = size.width - AppSpacing.sm;
    final top = size.height * 0.22;
    final bottom = size.height * 0.76;
    final minValue = cleanedValues.reduce((a, b) => a < b ? a : b);
    final maxValue = cleanedValues.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    Offset pointFor(int index, double value) {
      final x = cleanedValues.length == 1
          ? size.width / 2
          : left + ((right - left) * index / (cleanedValues.length - 1));
      final normalized = range <= 0 ? 0.5 : (value - minValue) / range;
      return Offset(x, bottom - ((bottom - top) * normalized));
    }

    final firstPoint = pointFor(0, cleanedValues.first);
    path.moveTo(firstPoint.dx, firstPoint.dy);
    for (var index = 1; index < cleanedValues.length; index += 1) {
      final point = pointFor(index, cleanedValues[index]);
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ValueHistorySparklinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.values != values;
  }
}

class _DetailInsightsSection extends StatelessWidget {
  const _DetailInsightsSection({required this.item});

  final CollectibleItem item;

  @override
  Widget build(BuildContext context) {
    final summary = _storedAiSummaryFor(item);
    return _DetailAuthorityPanel(
      key: const ValueKey('collectible-detail-insights-section'),
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
      key: const ValueKey('collectible-detail-notes-status-section'),
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
    required this.isRefreshingValue,
    required this.onRefreshValue,
    required this.onEdit,
    required this.onShare,
    required this.onFavorite,
    required this.onDelete,
  });

  final CollectibleItem item;
  final bool isFavorited;
  final bool isRefreshingValue;
  final VoidCallback onRefreshValue;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onFavorite;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return _DetailAuthorityPanel(
      key: const ValueKey('collectible-detail-actions-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSectionTitle(title: 'Actions Menu', icon: Icons.more_horiz),
          const SizedBox(height: AppSpacing.sm),
          _DetailActionMenuRow(
            key: const ValueKey('collectible-detail-primary-edit-action'),
            icon: Icons.edit_outlined,
            label: 'Review details',
            description: 'Correct identifiers and retry pricing',
            onTap: onEdit,
          ),
          _DetailActionMenuRow(
            key: const ValueKey('collectible-detail-refresh-value-action'),
            icon: isRefreshingValue
                ? Icons.hourglass_top_rounded
                : Icons.refresh_rounded,
            label: isRefreshingValue ? 'Refreshing value' : 'Refresh value',
            description: 'Get the latest available pricing snapshot',
            onTap: onRefreshValue,
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
  const _DetailAuthorityRows({
    required this.rows,
    this.alignValuesRight = false,
  });

  final List<_DetailInfoRowData> rows;
  final bool alignValuesRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
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
                flex: 7,
                child: Text(
                  row.value,
                  textAlign: alignValuesRight ? TextAlign.right : null,
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
        'Current value',
        _displayValue(pricing, fallbackValue: item.estimatedValue),
      ),
      _DetailInfoRowData(
        'Value at scan',
        _formatMoney(item.valueAtScan ?? item.estimatedValue, pricing.currency),
      ),
      if (item.lastValueRefreshedAt != null)
        _DetailInfoRowData(
          'Last refreshed',
          _formatPricingDate(item.lastValueRefreshedAt),
        ),
      if (_sourceMarketValue(pricing) != null)
        _DetailInfoRowData('Source market value', _sourceMarketValue(pricing)!),
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

List<_DetailInfoRowData> _pricingTrustRows(CollectibleItem item) {
  final pricing = item.pricing;
  final market = item.marketSummary;
  final status = _effectiveValuationStatus(item);
  final confidence = pricing?.pricingConfidence ?? market?.confidence;
  final rows = <_DetailInfoRowData>[
    _DetailInfoRowData('Status', _pricingTrustTitle(status)),
    if (pricing?.pricingSource.trim().isNotEmpty == true)
      _DetailInfoRowData('Provider', pricing!.pricingSource),
    if (confidence != null)
      _DetailInfoRowData(
        'Confidence',
        '${_pricingConfidenceBand(confidence)} (${_confidencePercent(confidence)})',
      ),
    if (pricing?.valuationStrategy?.trim().isNotEmpty == true)
      _DetailInfoRowData(
        'Match basis',
        _pricingStrategyLabel(pricing!.valuationStrategy!),
      ),
    if (_pricingUnavailableReason(item) != null)
      _DetailInfoRowData('Reason', _pricingUnavailableReason(item)!),
    if (_sourceMarketValue(pricing ?? _emptyPricingFor(item)) != null)
      _DetailInfoRowData(
        'Original value',
        _sourceMarketValue(pricing ?? _emptyPricingFor(item))!,
      ),
    if (pricing?.lastUpdated != null)
      _DetailInfoRowData(
        'Last checked',
        _formatPricingDate(pricing!.lastUpdated),
      ),
  ];
  return rows;
}

ValuationStatus _effectiveValuationStatus(CollectibleItem item) {
  if (item.valuationStatus != ValuationStatus.unavailable) {
    return item.valuationStatus;
  }
  final pricingStatus = item.pricing?.valuationStatus;
  if (pricingStatus != null && pricingStatus != ValuationStatus.unavailable) {
    return pricingStatus;
  }
  return ValuationStatus.unavailable;
}

String _pricingTrustTitle(ValuationStatus status) {
  return switch (status) {
    ValuationStatus.marketEstimated => 'Trusted market valuation',
    ValuationStatus.aiEstimated => 'Needs market verification',
    ValuationStatus.providerNotConfigured => 'Provider not connected',
    ValuationStatus.noMarketMatch => 'No trusted match yet',
    ValuationStatus.lookupFailed => 'Lookup did not complete',
    ValuationStatus.unavailable => 'Trusted value unavailable',
  };
}

String _pricingTrustTrailing(ValuationStatus status) {
  return switch (status) {
    ValuationStatus.marketEstimated => 'Verified',
    ValuationStatus.aiEstimated => 'Review',
    ValuationStatus.providerNotConfigured ||
    ValuationStatus.noMarketMatch ||
    ValuationStatus.lookupFailed ||
    ValuationStatus.unavailable => 'Unavailable',
  };
}

String _pricingTrustMessage(CollectibleItem item) {
  final pricing = item.pricing;
  final explanation = _clean(pricing?.pricingExplanation);
  if (explanation != null) {
    return explanation;
  }
  final status = _effectiveValuationStatus(item);
  final reason = _pricingUnavailableReason(item);
  return switch (status) {
    ValuationStatus.marketEstimated =>
      'PackLox is showing a provider-backed value from saved market evidence, not an AI-only guess.',
    ValuationStatus.aiEstimated =>
      'This item has an AI estimate only. Reprice it before relying on portfolio value.',
    ValuationStatus.providerNotConfigured =>
      'PackLox does not have a connected pricing provider for this category yet.',
    ValuationStatus.noMarketMatch =>
      '${reason ?? 'No trusted catalog or sold-comps match was found.'} Review identity fields and retry pricing.',
    ValuationStatus.lookupFailed =>
      'The pricing lookup did not complete. The last trusted value is preserved until a new value is found.',
    ValuationStatus.unavailable =>
      reason ??
          'PackLox is not showing a value because trusted market evidence is unavailable.',
  };
}

String? _pricingUnavailableReason(CollectibleItem item) {
  final pricing = item.pricing;
  final status = _effectiveValuationStatus(item);
  if (status == ValuationStatus.marketEstimated) {
    return null;
  }
  final reason = pricing?.reasonCode?.trim().toUpperCase();
  return switch (reason) {
    'PROVIDER_NOT_CONFIGURED' =>
      'Pricing source not connected for this category',
    'NO_MARKET_MATCH' => 'No trusted catalog or sold-comps match yet',
    'INSUFFICIENT_TRUSTED_MARKET_DATA' =>
      'Not enough trusted market evidence yet',
    'WEAK_IDENTITY_MATCH' =>
      'Identity match is too weak for a trusted valuation',
    'LOW_PRICING_CONFIDENCE' => 'Pricing confidence is too low to show a value',
    'SPECIALIST_SOURCE_NOT_CONNECTED' =>
      'Specialist pricing source is not connected yet',
    'LOOKUP_FAILED' => 'Pricing lookup did not complete',
    null || '' => switch (status) {
      ValuationStatus.noMarketMatch => 'No trusted market match yet',
      ValuationStatus.providerNotConfigured =>
        'Pricing source not connected for this category',
      ValuationStatus.lookupFailed => 'Pricing lookup did not complete',
      ValuationStatus.aiEstimated =>
        'Market provider has not verified this value',
      _ => null,
    },
    _ => _humanizeToken(reason),
  };
}

String _pricingConfidenceBand(double confidence) {
  if (confidence >= 0.85) {
    return 'High';
  }
  if (confidence >= 0.70) {
    return 'Medium';
  }
  if (confidence > 0) {
    return 'Low';
  }
  return 'Not scored';
}

String _pricingStrategyLabel(String strategy) {
  final normalized = strategy.trim().toLowerCase();
  return switch (normalized) {
    'catalog_lookup' => 'Catalog match',
    'sold_completed' => 'Sold-comps market data',
    'active_listing' => 'Active listing signal',
    'unavailable' => 'Unavailable',
    _ => _humanizeToken(strategy),
  };
}

IconData _pricingTrustIcon(ValuationStatus status) {
  return switch (status) {
    ValuationStatus.marketEstimated => Icons.verified_user_outlined,
    ValuationStatus.aiEstimated => Icons.manage_search_outlined,
    ValuationStatus.lookupFailed => Icons.sync_problem_outlined,
    ValuationStatus.providerNotConfigured => Icons.extension_off_outlined,
    ValuationStatus.noMarketMatch ||
    ValuationStatus.unavailable => Icons.info_outline_rounded,
  };
}

Color _pricingTrustColor(BuildContext context, ValuationStatus status) {
  return switch (status) {
    ValuationStatus.marketEstimated => HomeTokens.positive,
    ValuationStatus.aiEstimated => HomeTokens.warning,
    ValuationStatus.lookupFailed => Theme.of(context).colorScheme.error,
    ValuationStatus.providerNotConfigured ||
    ValuationStatus.noMarketMatch ||
    ValuationStatus.unavailable => HomeTokens.accent,
  };
}

PricingInfo _emptyPricingFor(CollectibleItem item) {
  return PricingInfo(
    estimatedMarketValue: 0,
    lowEstimate: 0,
    highEstimate: 0,
    currency: item.pricing?.currency ?? 'AUD',
    pricingSource: item.valuationSource,
    pricingConfidence: 0,
    lastUpdated: null,
    valuationStatus: item.valuationStatus,
    valuationSource: item.valuationSource,
  );
}

class _CatalogSnapshotData {
  const _CatalogSnapshotData({
    required this.pricing,
    required this.savedValue,
    required this.attribution,
    this.catalogId,
  });

  final PricingInfo pricing;
  final double savedValue;
  final String attribution;
  final String? catalogId;
}

_CatalogSnapshotData? _catalogSnapshotFor(CollectibleItem item) {
  final pricing = item.pricing;
  if (pricing == null) {
    return null;
  }
  final catalogId = _catalogIdFromNotes(item.notes);
  final strategy = pricing.valuationStrategy?.trim().toLowerCase();
  final reason = pricing.reasonCode?.trim().toUpperCase();
  final source = pricing.pricingSource.trim().toLowerCase();
  final isCatalogSnapshot =
      strategy == 'catalog_lookup' ||
      reason == 'CATALOG_SEARCH_MATCH' ||
      catalogId != null ||
      source.contains('pricecharting');
  if (!isCatalogSnapshot) {
    return null;
  }
  final attribution =
      _clean(pricing.attributionText) ??
      (source.contains('pricecharting')
          ? 'Pricing data by PriceCharting'
          : 'Pricing data by ${pricing.pricingSource}');
  return _CatalogSnapshotData(
    pricing: pricing,
    savedValue: item.estimatedValue,
    attribution: attribution,
    catalogId: catalogId,
  );
}

String? _catalogIdFromNotes(String? notes) {
  final text = notes ?? '';
  final match = RegExp(
    r'Catalog ID:\s*([^\n\r]+)',
    caseSensitive: false,
  ).firstMatch(text);
  return _clean(match?.group(1));
}

String _humanizeToken(String value) {
  final clean = value
      .trim()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .toLowerCase();
  if (clean.isEmpty) {
    return 'Unknown';
  }
  return clean
      .split(' ')
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}

double _valueAtScanFor(CollectibleItem item) {
  final valueAtScan = item.valueAtScan;
  if (valueAtScan != null && valueAtScan > 0) {
    return valueAtScan;
  }
  return item.estimatedValue;
}

double _currentValueFor(CollectibleItem item) {
  final marketValue = item.pricing?.estimatedMarketValue;
  if (marketValue != null && marketValue > 0) {
    return marketValue;
  }
  return item.estimatedValue;
}

List<double> _valueHistoryChartValues(
  CollectibleItem item,
  List<PortfolioValuationSnapshot> snapshots,
) {
  final values = <double>[];
  final scanValue = _valueAtScanFor(item);
  if (scanValue > 0) {
    values.add(scanValue);
  }
  final sortedSnapshots = [...snapshots]
    ..sort((left, right) => left.pricedAt.compareTo(right.pricedAt));
  for (final snapshot in sortedSnapshots) {
    final value = snapshot.valueAud;
    if (value != null && value > 0) {
      values.add(value);
    }
  }
  final currentValue = _currentValueFor(item);
  if (currentValue > 0 &&
      (values.isEmpty || (values.last - currentValue).abs() > 0.01)) {
    values.add(currentValue);
  }
  if (values.isEmpty) {
    return const [0, 0];
  }
  if (values.length == 1) {
    return [values.first, values.first];
  }
  return values;
}

String _snapshotHistoryLabel(List<PortfolioValuationSnapshot> snapshots) {
  final sortedSnapshots = [...snapshots]
    ..sort((left, right) => left.pricedAt.compareTo(right.pricedAt));
  final latest = sortedSnapshots.last;
  final count = sortedSnapshots.length;
  return '$count valuation snapshot${count == 1 ? '' : 's'} · latest ${_formatPricingDate(latest.pricedAt)}';
}

String _lastRefreshedLabel(CollectibleItem item) {
  final refreshedAt = item.lastValueRefreshedAt;
  if (refreshedAt != null) {
    return 'Last refreshed ${_formatPricingDate(refreshedAt)}';
  }
  return 'Refresh value to start history';
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
  final currency = item.pricing?.currency ?? 'AUD';
  if (item.estimatedValue == 0) {
    return _formatZeroMoney(currency);
  }
  return _formatMoney(item.estimatedValue, currency);
}

String _formatZeroMoney(String currency) {
  final normalizedCurrency = currency.trim().toUpperCase();
  if (normalizedCurrency == 'USD') {
    return 'USD \$0';
  }
  if (normalizedCurrency == 'AUD' || normalizedCurrency.isEmpty) {
    return '\$0 AUD';
  }
  if (normalizedCurrency == 'GBP') {
    return '£0';
  }
  if (normalizedCurrency == 'CAD') {
    return 'CAD \$0';
  }
  return '$normalizedCurrency 0';
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
  final editResult = await showModalBottomSheet<_EditCollectibleResult>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .62),
    isScrollControlled: true,
    builder: (_) => _EditCollectibleDialog(item: item),
  );
  if (editResult == null) {
    return;
  }

  var nextItem = editResult.item;
  ValuationStatus? refreshedStatus;
  var hasRefreshedValue = false;
  if (editResult.retryPricing) {
    try {
      final quote = await ref
          .read(scanPricingQuoteServiceProvider)
          .quoteItem(nextItem);
      refreshedStatus = quote.valuationStatus;
      hasRefreshedValue =
          quote.valuationStatus == ValuationStatus.marketEstimated &&
          quote.estimatedValue > 0;
      nextItem = nextItem.copyWith(
        estimatedValue: hasRefreshedValue
            ? quote.estimatedValue
            : nextItem.estimatedValue,
        pricing: hasRefreshedValue ? quote.pricing : nextItem.pricing,
        marketSummary: hasRefreshedValue
            ? quote.marketSummary ?? nextItem.marketSummary
            : nextItem.marketSummary,
        valuationStatus: hasRefreshedValue
            ? quote.valuationStatus
            : nextItem.valuationStatus,
        valuationSource: hasRefreshedValue
            ? quote.valuationSource
            : nextItem.valuationSource,
        aiEstimatedValue: quote.aiEstimatedValue ?? nextItem.aiEstimatedValue,
        valueAtScan: nextItem.valueAtScan ?? nextItem.estimatedValue,
        lastValueRefreshedAt: hasRefreshedValue
            ? DateTime.now()
            : nextItem.lastValueRefreshedAt,
      );
    } catch (_) {
      refreshedStatus = null;
    }
  }

  if (editResult.retryPricing && hasRefreshedValue) {
    await ref
        .read(portfolioControllerProvider.notifier)
        .updateItemWithValuationSnapshot(nextItem);
  } else {
    await ref.read(portfolioControllerProvider.notifier).updateItem(nextItem);
  }
  if (context.mounted) {
    _showDetailSnackBar(
      context,
      editResult.retryPricing
          ? _pricingRetryMessage(refreshedStatus)
          : 'Collectible updated',
    );
  }
}

String _pricingRetryMessage(ValuationStatus? status) {
  return switch (status) {
    ValuationStatus.marketEstimated => 'Details saved and pricing refreshed',
    ValuationStatus.noMarketMatch =>
      'Details saved. No reliable market match yet.',
    ValuationStatus.providerNotConfigured ||
    ValuationStatus.lookupFailed ||
    ValuationStatus.unavailable ||
    ValuationStatus.aiEstimated => 'Details saved. Pricing still needs review.',
    null => 'Details saved. Pricing retry failed.',
  };
}

String _valueRefreshMessage(ValuationStatus? status) {
  return switch (status) {
    ValuationStatus.marketEstimated => 'Portfolio value refreshed',
    ValuationStatus.noMarketMatch => 'No reliable market match yet',
    ValuationStatus.providerNotConfigured ||
    ValuationStatus.lookupFailed ||
    ValuationStatus.unavailable ||
    ValuationStatus.aiEstimated => 'Pricing still needs review',
    null => 'Value refresh failed',
  };
}

class _EditCollectibleResult {
  const _EditCollectibleResult({
    required this.item,
    required this.retryPricing,
  });

  final CollectibleItem item;
  final bool retryPricing;
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
  late final TextEditingController _setController;
  late final TextEditingController _seriesController;
  late final TextEditingController _cardNumberController;
  late final TextEditingController _rarityController;
  late final TextEditingController _conditionController;
  late final TextEditingController _languageController;
  late final TextEditingController _editionController;
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
    _setController = TextEditingController(text: widget.item.setName ?? '');
    _seriesController = TextEditingController(text: widget.item.series ?? '');
    _cardNumberController = TextEditingController(
      text: widget.item.cardNumber ?? '',
    );
    _rarityController = TextEditingController(text: widget.item.rarity ?? '');
    _conditionController = TextEditingController(text: widget.item.condition);
    _languageController = TextEditingController(
      text: widget.item.language ?? '',
    );
    _editionController = TextEditingController(text: widget.item.edition ?? '');
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
    _setController.dispose();
    _seriesController.dispose();
    _cardNumberController.dispose();
    _rarityController.dispose();
    _conditionController.dispose();
    _languageController.dispose();
    _editionController.dispose();
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
                            'Update saved details, or retry pricing after correcting identifiers like set, card number, edition, language, and condition.',
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
                              'edit-collectible-set-field',
                            ),
                            controller: _setController,
                            label: 'Set',
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
                              'edit-collectible-card-number-field',
                            ),
                            controller: _cardNumberController,
                            label: 'Card / model number',
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-rarity-field',
                            ),
                            controller: _rarityController,
                            label: 'Rarity',
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-condition-field',
                            ),
                            controller: _conditionController,
                            label: 'Condition',
                            validator: _requiredText,
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-language-field',
                            ),
                            controller: _languageController,
                            label: 'Language',
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-edition-field',
                            ),
                            controller: _editionController,
                            label: 'Edition / variant',
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
                          ),
                          _EditTextField(
                            fieldKey: const ValueKey(
                              'edit-collectible-high-value-field',
                            ),
                            controller: _highValueController,
                            label: 'Estimated value high',
                            keyboardType: TextInputType.number,
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
                            onPressed: () => _save(retryPricing: false),
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: FilledButton.icon(
                      key: const ValueKey(
                        'edit-collectible-save-retry-pricing-button',
                      ),
                      onPressed: () => _save(retryPricing: true),
                      icon: const Icon(Icons.manage_search_outlined, size: 18),
                      label: const Text('Save & retry pricing'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8BE7FF),
                        foregroundColor: const Color(0xFF07111D),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                        minimumSize: const Size.fromHeight(46),
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

  void _save({required bool retryPricing}) {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    final low = _parseMoney(_lowValueController.text);
    final high = _parseMoney(_highValueController.text);
    final normalizedLow = low <= high ? low : high;
    final normalizedHigh = high >= low ? high : low;
    final estimatedValue = (normalizedLow + normalizedHigh) / 2;
    Navigator.of(context).pop(
      _EditCollectibleResult(
        retryPricing: retryPricing,
        item: widget.item.copyWith(
          title: _titleController.text.trim(),
          category: _categoryController.text.trim(),
          estimatedValue: estimatedValue,
          condition: _conditionController.text.trim(),
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
          setName: _setController.text.trim(),
          series: _seriesController.text.trim(),
          cardNumber: _cardNumberController.text.trim(),
          rarity: _rarityController.text.trim(),
          language: _languageController.text.trim(),
          edition: _editionController.text.trim(),
          country: _countryController.text.trim(),
          notes: _notesController.text.trim(),
        ),
      ),
    );
  }

  String? _requiredText(String? value) {
    return (value ?? '').trim().isEmpty ? 'Required' : null;
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
          label: 'Value at scan',
          value: _displayValue(pricing, fallbackValue: item.estimatedValue),
        ),
        if (_sourceMarketValue(pricing) != null)
          AppMetadataItem(
            label: 'Source market value',
            value: _sourceMarketValue(pricing)!,
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
    final notificationState = ref.watch(
      priceAlertNotificationControllerProvider,
    );

    return AppProfileSection(
      title: 'Price Alerts',
      children: [
        Text(
          notificationState.settingsSubtitle,
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
    final planLimits = ref.read(activePlanLimitsProvider);
    final repository = ref.read(priceAlertRepositoryProvider);
    final allAlerts = await repository.getAlerts();
    final activeAlertCount = allAlerts
        .where((alert) => alert.status == PriceAlertStatus.active)
        .length;
    if (!planLimits.canCreatePriceAlert(activeAlertCount)) {
      if (context.mounted) {
        _showDetailSnackBar(
          context,
          'Your ${planLimits.plan.displayName} plan supports ${planLimits.priceAlertsLabel}. Upgrade to create more alerts.',
        );
      }
      return;
    }

    var notificationState = ref.read(priceAlertNotificationControllerProvider);
    if (notificationState.enabled &&
        !notificationState.permissionStatus.canNotify &&
        notificationState.permissionStatus !=
            PriceAlertNotificationPermissionStatus.notSupported) {
      await ref
          .read(priceAlertNotificationControllerProvider.notifier)
          .requestPermission();
      notificationState = ref.read(priceAlertNotificationControllerProvider);
    }

    await repository.saveAlert(buildPriceAlert(item: item, type: type));
    ref.invalidate(itemPriceAlertsProvider(item.id));
    ref.invalidate(priceAlertSummaryProvider);
    if (context.mounted) {
      final message =
          notificationState.enabled &&
              notificationState.permissionStatus.canNotify
          ? 'Price alert created. You will be notified on this device.'
          : 'Price alert saved. Enable notifications to be alerted.';
      _showDetailSnackBar(context, message);
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

bool _usesCatalogPlaceholderImage(CollectibleItem item) {
  return _isPackLoxCategoryPlaceholderPath(item.imagePath);
}

bool _isPackLoxCategoryPlaceholderPath(String path) {
  return path.trim().startsWith(
    'assets/packlox/icons/categories/3d/packlox_category_',
  );
}

String _formatAud(double value) {
  if (value <= 0) {
    return 'Value unavailable';
  }
  final amount = _formatMoneyAmount(value);
  final withCommas = amount.replaceFirstMapped(
    RegExp(r'^\d+'),
    (match) => match
        .group(0)!
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ','),
  );
  return '\$$withCommas';
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
    cacheTtlSeconds: pricing?.cacheTtlSeconds,
    cacheExpiresAt: pricing?.cacheExpiresAt,
    cachePolicyReason: pricing?.cachePolicyReason,
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

String _displayValue(PricingInfo pricing, {required double fallbackValue}) {
  final displayString = pricing.displayString?.trim();
  if (displayString != null && displayString.isNotEmpty) {
    return displayString;
  }
  final value = pricing.estimatedMarketValue > 0
      ? pricing.estimatedMarketValue
      : fallbackValue;
  return _formatMoney(value, pricing.currency);
}

String? _sourceMarketValue(PricingInfo pricing) {
  final originalPrice = pricing.originalPrice;
  final originalCurrency = pricing.originalCurrency?.trim();
  if (originalPrice == null ||
      originalPrice <= 0 ||
      originalCurrency == null ||
      originalCurrency.isEmpty ||
      originalCurrency.toUpperCase() == pricing.currency.toUpperCase()) {
    return null;
  }
  return _formatMoney(originalPrice, originalCurrency);
}

String _formatMoney(double value, String currency) {
  if (value <= 0) {
    return 'Value unavailable';
  }
  final amount = _formatMoneyAmount(value);
  final withCommas = amount.replaceFirstMapped(
    RegExp(r'^\d+'),
    (match) => match
        .group(0)!
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ','),
  );
  final normalizedCurrency = currency.trim().toUpperCase();
  if (normalizedCurrency == 'AUD' || normalizedCurrency.isEmpty) {
    return '\$$withCommas AUD';
  }
  if (normalizedCurrency == 'USD') {
    return 'USD \$$withCommas';
  }
  if (normalizedCurrency == 'GBP') {
    return '£$withCommas';
  }
  if (normalizedCurrency == 'CAD') {
    return 'CAD \$$withCommas';
  }
  return '$normalizedCurrency $withCommas';
}

String _formatMoneyAmount(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
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
