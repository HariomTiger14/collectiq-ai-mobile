import 'package:collectiq_ai/core/design_system/tokens/tokens.dart';
import 'package:flutter/material.dart';

class PortfolioThumbnail extends StatelessWidget {
  const PortfolioThumbnail({
    required this.child,
    this.size = 110,
    this.placeholderIcon = Icons.image_outlined,
    super.key,
  });

  final Widget? child;
  final double size;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child:
            child ??
            Center(
              child: Icon(
                placeholderIcon,
                color: colorScheme.primary,
                size: 32,
              ),
            ),
      ),
    );
  }
}
