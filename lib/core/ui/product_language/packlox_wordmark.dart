import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:flutter/material.dart';

class PackLoxWordmark extends StatelessWidget {
  const PackLoxWordmark({
    this.style,
    this.packColor = PackLoxTokens.textPrimary,
    this.loxColor = const Color(0xFF0087FF),
    this.textAlign = TextAlign.start,
    this.maxLines = 1,
    this.overflow = TextOverflow.ellipsis,
    super.key,
  });

  final TextStyle? style;
  final Color packColor;
  final Color loxColor;
  final TextAlign textAlign;
  final int maxLines;
  final TextOverflow overflow;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        style ?? Theme.of(context).textTheme.headlineSmall ?? const TextStyle();
    return Semantics(
      label: 'PackLox',
      child: ExcludeSemantics(
        child: RichText(
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
          text: TextSpan(
            style: effectiveStyle.copyWith(color: packColor),
            children: [
              const TextSpan(text: 'Pack'),
              TextSpan(
                text: 'Lox',
                style: effectiveStyle.copyWith(color: loxColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
