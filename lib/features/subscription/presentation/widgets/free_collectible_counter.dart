import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
import 'package:flutter/material.dart';

/// Live free-tier portfolio usage ("9 of 10 free collectibles" / "Free
/// collection full — upgrade to save more"), shared across every surface
/// that shows it (Portfolio, the scan result screen, Home) so the copy and
/// at-cap logic can never drift between them. Always reads from the same
/// [savedCount]/[cap] the caller derives from `PlanLimits`/portfolio state
/// -- this widget has no cap logic of its own.
class FreeCollectibleCounter extends StatelessWidget {
  const FreeCollectibleCounter({
    required this.savedCount,
    required this.cap,
    required this.onUpgrade,
    this.compact = false,
    super.key,
  });

  final int savedCount;
  final int cap;
  final VoidCallback onUpgrade;

  /// A quieter, boxless row for surfaces (like Home) that want an ambient
  /// reminder rather than the Portfolio screen's boxed pill.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final atCap = savedCount >= cap;
    final accent = atCap ? HomeTokens.accent : HomeTokens.textSecondary;
    final label = atCap
        ? 'Free collection full — upgrade to save more'
        : '$savedCount of $cap free collectibles saved';

    if (compact) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onUpgrade,
        child: Padding(
          key: const ValueKey('free-collectible-counter-compact'),
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                atCap ? Icons.lock_outline_rounded : Icons.inventory_2_outlined,
                size: 14,
                color: accent,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onUpgrade,
      child: Container(
        key: const ValueKey('free-collectible-counter'),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: atCap
              ? HomeTokens.accent.withValues(alpha: 0.10)
              : HomeTokens.surfaceInteractive.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(HomeTokens.controlRadius),
          border: Border.all(
            color: atCap
                ? HomeTokens.accent.withValues(alpha: 0.34)
                : HomeTokens.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              atCap ? Icons.lock_outline_rounded : Icons.inventory_2_outlined,
              size: 17,
              color: accent,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: atCap ? HomeTokens.textPrimary : HomeTokens.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (atCap)
              Text(
                'Pro',
                style: textTheme.labelLarge?.copyWith(
                  color: HomeTokens.accent,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
