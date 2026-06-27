import 'package:collectiq_ai/core/design_system/tokens/tokens.dart';
import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, this.icon, this.color, super.key});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: chipColor.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: chipColor),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: chipColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ValueBadge extends StatelessWidget {
  const ValueBadge({required this.value, super.key});

  final String value;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: value,
      icon: Icons.paid_outlined,
      color: AppColors.estimatedValueGold,
    );
  }
}

class ConfidenceBadge extends StatelessWidget {
  const ConfidenceBadge({required this.confidence, super.key});

  final String confidence;

  @override
  Widget build(BuildContext context) {
    return StatusChip(
      label: confidence,
      icon: Icons.verified_outlined,
      color: AppColors.confidenceBlue,
    );
  }
}
