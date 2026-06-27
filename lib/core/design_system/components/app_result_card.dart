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
    this.condition,
    this.image,
    this.action,
    super.key,
  });

  final String title;
  final String category;
  final String estimatedValue;
  final String confidence;
  final String? condition;
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
          _EstimatedValuePanel(value: estimatedValue),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Flexible(child: ConfidenceBadge(confidence: confidence)),
              if (condition != null) ...[
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: StatusChip(
                    label: condition!,
                    icon: Icons.workspace_premium_outlined,
                  ),
                ),
              ],
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

class _EstimatedValuePanel extends StatelessWidget {
  const _EstimatedValuePanel({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.estimatedValueGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.estimatedValueGold.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.estimatedValueGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: const Icon(
              Icons.paid_outlined,
              color: AppColors.estimatedValueGold,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimated Value',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  value,
                  style: textTheme.headlineSmall?.copyWith(
                    color: AppColors.estimatedValueGold,
                    fontWeight: FontWeight.w900,
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
