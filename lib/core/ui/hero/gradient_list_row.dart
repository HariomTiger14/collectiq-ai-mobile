import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:flutter/material.dart';

/// Semantic color for [GradientListRow.trailingText]. Defaults to
/// [neutral], which keeps the original actionable-vs-status color rule;
/// [positive]/[warning] override that for a status that's genuinely good
/// or genuinely needs attention (e.g. notification permission state).
enum GradientRowTone { neutral, positive, warning }

/// A frosted, gradient-icon-badge list row matching the visual language of
/// [CloudSyncDiagnosticTile]/[AboutInfoTile]'s tile shell, but keeping
/// Settings' own [ModernSettingsRow] convention: [trailingText] reads as a
/// status value (muted) unless the row is actually tappable (accent-colored
/// with a chevron) -- neither of the existing gradient-hero tile widgets
/// have a text-status trailing slot or enforce that pairing, so this fills
/// that gap rather than losing the convention on re-skin.
class GradientListRow extends StatefulWidget {
  const GradientListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailingText,
    this.trailingTone = GradientRowTone.neutral,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
  final GradientRowTone trailingTone;
  final VoidCallback? onTap;

  @override
  State<GradientListRow> createState() => _GradientListRowState();
}

class _GradientListRowState extends State<GradientListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActionable = widget.onTap != null;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: MotionTapScale(
        onTap: widget.onTap,
        scale: 0.985,
        child: AnimatedContainer(
          duration: PackLoxMotionTheme.medium,
          curve: PackLoxMotionTheme.hoverCurve,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: _hovered && isActionable
                ? colorScheme.primary.withValues(
                    alpha: PackLoxMotionTheme.hoverOpacity,
                  )
                : isDark
                ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.44),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primaryContainer.withValues(alpha: 0.42),
                      colorScheme.secondaryContainer.withValues(alpha: 0.24),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(widget.icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailingText != null) ...[
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 116),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _trailingColor(
                        colorScheme,
                        isActionable,
                      ).withValues(alpha: 0.16),
                      // A fixed pill radius stretches into an odd oval if
                      // this wraps to 2 lines, so use a rounded-rect chip.
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: _trailingColor(
                          colorScheme,
                          isActionable,
                        ).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      widget.trailingText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textTheme.labelMedium?.copyWith(
                        color: _trailingColor(colorScheme, isActionable),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
              // A chevron appears only when the row navigates, so
              // trailingText can be read as status (not a fake "tap me"
              // affordance) -- same rule ModernSettingsRow already enforces.
              if (isActionable) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _trailingColor(ColorScheme colorScheme, bool isActionable) {
    return switch (widget.trailingTone) {
      GradientRowTone.positive => HomeTokens.positive,
      GradientRowTone.warning => HomeTokens.warning,
      GradientRowTone.neutral =>
        isActionable ? colorScheme.primary : colorScheme.onSurfaceVariant,
    };
  }
}
