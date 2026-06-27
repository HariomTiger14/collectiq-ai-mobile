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
