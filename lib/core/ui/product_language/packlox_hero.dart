import 'package:collectiq_ai/core/ui/product_language/packlox_button.dart';
import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:flutter/material.dart';

enum PackLoxHeroVariant { standard, scanner, portfolio, analysis, emptyState }

/// PackLox Hero 1.0.1 (PLX-CMP-HERO@1.0.1).
class PackLoxHero extends StatelessWidget {
  const PackLoxHero({
    required this.variant,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.icon,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.metric,
    this.semanticLabel,
    super.key,
  });
  final PackLoxHeroVariant variant;
  final String eyebrow, title, subtitle;
  final IconData? icon;
  final String? primaryActionLabel, secondaryActionLabel, metric, semanticLabel;
  final VoidCallback? onPrimaryAction, onSecondaryAction;
  @override
  Widget build(BuildContext context) {
    final compactWidth = MediaQuery.sizeOf(context).width <= 360;
    final scanner = variant == PackLoxHeroVariant.scanner;
    final outerPadding = scanner
        ? (compactWidth ? 16.0 : 20.0)
        : (compactWidth ? 20.0 : 24.0);
    final contentGap = scanner ? 8.0 : 12.0;
    final iconContainerSize = scanner ? 42.0 : 44.0;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Container(
        key: const ValueKey('scan-hub-hero-card'),
        width: double.infinity,
        padding: EdgeInsets.all(outerPadding),
        decoration: BoxDecoration(
          gradient: PackLoxTokens.heroGradient,
          borderRadius: BorderRadius.circular(
            MediaQuery.sizeOf(context).width <= 360 ? 20 : 24,
          ),
          border: Border.all(
            color: const Color(0xFF60A5FA).withValues(alpha: .45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow.toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF93C5FD),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      SizedBox(height: contentGap),
                      Text(
                        title,
                        style: const TextStyle(
                          color: PackLoxTokens.textPrimary,
                          fontSize: 30,
                          height: 1.04,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.7,
                        ),
                      ),
                    ],
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 16),
                  Container(
                    key: const ValueKey('packlox-hero-icon-container'),
                    width: iconContainerSize,
                    height: iconContainerSize,
                    decoration: BoxDecoration(
                      color: PackLoxTokens.cyan.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: PackLoxTokens.cyan.withValues(alpha: .45),
                      ),
                    ),
                    child: ExcludeSemantics(
                      child: Icon(icon, size: 24, color: PackLoxTokens.cyan),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: contentGap),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (metric != null) ...[
              const SizedBox(height: 16),
              Text(
                metric!,
                style: const TextStyle(
                  color: PackLoxTokens.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (primaryActionLabel != null || secondaryActionLabel != null) ...[
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  if (primaryActionLabel != null)
                    PackLoxButton(
                      label: primaryActionLabel!,
                      onPressed: onPrimaryAction,
                      size: PackLoxButtonSize.large,
                    ),
                  if (secondaryActionLabel != null)
                    PackLoxButton(
                      label: secondaryActionLabel!,
                      onPressed: onSecondaryAction,
                      variant: PackLoxButtonVariant.quiet,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
