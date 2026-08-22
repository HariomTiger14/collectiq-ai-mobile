import 'package:collectiq_ai/core/cloud/services/signed_image_url_cache.dart';
import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef CollectibleImagePlaceholderBuilder = Widget Function();

/// Renders a collectible's photo, preferring the local file (fast, no
/// network) and falling back to a freshly-resolved cloud URL when the local
/// file isn't there -- which happens after any reinstall, on a second
/// device, or whenever the item was never synced with its image locally
/// present. Never trusts a previously-stored cloud URL directly: the
/// storage bucket is private, so any such URL is a signed one that expires,
/// and treating it as permanent is exactly the bug this widget exists to
/// stop repeating at every image call site (found live: a freshly-scanned
/// item's photo showed "Preview unavailable" everywhere once its local
/// file path no longer existed).
class ResilientCollectibleImage extends ConsumerStatefulWidget {
  const ResilientCollectibleImage({
    required this.localPath,
    this.storagePath,
    this.fit = BoxFit.cover,
    this.placeholderBuilder,
    super.key,
  });

  /// The device-local file path (or a direct `http(s)://`/`assets/`/
  /// `sample://` source) recorded for this image.
  final String localPath;

  /// The image's path within the cloud storage bucket, used to resolve a
  /// fresh signed URL when [localPath] doesn't resolve to a real file.
  final String? storagePath;

  final BoxFit fit;
  final CollectibleImagePlaceholderBuilder? placeholderBuilder;

  @override
  ConsumerState<ResilientCollectibleImage> createState() =>
      _ResilientCollectibleImageState();
}

class _ResilientCollectibleImageState
    extends ConsumerState<ResilientCollectibleImage> {
  late bool _tryLocal;
  Future<String?>? _signedUrlFuture;

  @override
  void initState() {
    super.initState();
    _resetForCurrentPaths();
  }

  @override
  void didUpdateWidget(covariant ResilientCollectibleImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.localPath != widget.localPath ||
        oldWidget.storagePath != widget.storagePath) {
      _resetForCurrentPaths();
    }
  }

  void _resetForCurrentPaths() {
    final trimmedLocal = widget.localPath.trim();
    _tryLocal =
        trimmedLocal.isNotEmpty &&
        !_isRemoteOrBundledSource(trimmedLocal) &&
        localPortfolioImageExists(trimmedLocal);
    _signedUrlFuture = _tryLocal ? null : _resolveCloudFallback();
  }

  Future<String?> _resolveCloudFallback() {
    final storagePath = widget.storagePath?.trim();
    if (storagePath == null || storagePath.isEmpty) {
      return Future<String?>.value(null);
    }
    return ref.read(signedImageUrlCacheProvider).resolve(storagePath);
  }

  void _fallBackToCloud() {
    if (!mounted || !_tryLocal) {
      return;
    }
    setState(() {
      _tryLocal = false;
      _signedUrlFuture = _resolveCloudFallback();
    });
  }

  Widget _placeholder() =>
      widget.placeholderBuilder?.call() ?? const _DefaultImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    final trimmedLocal = widget.localPath.trim();

    if (trimmedLocal.startsWith('http://') ||
        trimmedLocal.startsWith('https://')) {
      return Image.network(
        trimmedLocal,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    if (trimmedLocal.startsWith('assets/')) {
      return Image.asset(
        trimmedLocal,
        fit: widget.fit,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }

    if (_tryLocal) {
      return buildLocalPortfolioImage(
        imagePath: trimmedLocal,
        fit: widget.fit,
        placeholderBuilder: () {
          // The file existed at the last existence check but the decoder
          // still failed (corrupt/partial write) -- fall back to the cloud
          // on the next frame rather than triggering a rebuild mid-build.
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fallBackToCloud(),
          );
          return _placeholder();
        },
      );
    }

    final storagePath = widget.storagePath?.trim();
    if (storagePath == null || storagePath.isEmpty) {
      return _placeholder();
    }

    return FutureBuilder<String?>(
      future: _signedUrlFuture,
      builder: (context, snapshot) {
        final url = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done || url == null) {
          return _placeholder();
        }
        return Image.network(
          url,
          fit: widget.fit,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _placeholder(),
        );
      },
    );
  }
}

bool _isRemoteOrBundledSource(String path) {
  return path.startsWith('http://') ||
      path.startsWith('https://') ||
      path.startsWith('assets/') ||
      path.startsWith('sample://');
}

class _DefaultImagePlaceholder extends StatelessWidget {
  const _DefaultImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Theme.of(context).colorScheme.primary,
        size: 30,
      ),
    );
  }
}
