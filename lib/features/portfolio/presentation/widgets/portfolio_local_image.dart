import 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image_stub.dart'
    if (dart.library.io) 'package:collectiq_ai/features/portfolio/presentation/widgets/portfolio_local_image_io.dart';
import 'package:flutter/material.dart';

typedef PortfolioImagePlaceholderBuilder = Widget Function();

Widget buildLocalPortfolioImage({
  required String imagePath,
  required BoxFit fit,
  required PortfolioImagePlaceholderBuilder placeholderBuilder,
}) {
  return buildPlatformLocalPortfolioImage(
    imagePath: imagePath,
    fit: fit,
    placeholderBuilder: placeholderBuilder,
  );
}

/// Cheap, synchronous existence check for a local portfolio image path.
/// Always false on web (there is no local filesystem there). Used to decide
/// upfront whether a local render is worth attempting at all, rather than
/// only finding out via [Image]'s async error callback.
bool localPortfolioImageExists(String imagePath) {
  return platformLocalPortfolioImageExists(imagePath);
}
