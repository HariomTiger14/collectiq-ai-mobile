import 'package:collectiq_ai/core/design_system/components/app_badges.dart';
import 'package:collectiq_ai/core/design_system/components/app_cards.dart';
import 'package:collectiq_ai/core/design_system/tokens/tokens.dart';
import 'package:flutter/material.dart';

class ResultCard extends StatelessWidget {
  const ResultCard({
    required this.title,
    required this.category,
    required this.estimatedValue,
    required this.confidence,
    this.image,
    this.action,
    super.key,
  });

  final String title;
  final String category;
  final String estimatedValue;
  final String confidence;
  final Widget? image;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (image != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: image,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            category,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Flexible(child: ValueBadge(value: estimatedValue)),
              const SizedBox(width: AppSpacing.sm),
              Flexible(child: ConfidenceBadge(confidence: confidence)),
            ],
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
