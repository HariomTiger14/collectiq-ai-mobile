import 'dart:io';

import 'package:flutter/material.dart';

Widget buildPlatformLocalPortfolioImage({
  required String imagePath,
  required BoxFit fit,
  required Widget Function() placeholderBuilder,
}) {
  return Image.file(
    File(imagePath),
    fit: fit,
    errorBuilder: (_, _, _) => placeholderBuilder(),
  );
}
