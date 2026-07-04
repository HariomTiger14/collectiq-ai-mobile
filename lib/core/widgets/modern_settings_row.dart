import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:flutter/material.dart';

/// Modern, divider-free settings row with soft micro-interactions.
class ModernSettingsRow extends StatefulWidget {
  /// Creates a settings row.
  const ModernSettingsRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.trailingText,
    this.onTap,
  });

  /// Leading icon.
  final IconData icon;

  /// Primary label.
  final String title;

  /// Supporting label.
  final String subtitle;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Optional trailing text.
  final String? trailingText;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  State<ModernSettingsRow> createState() => _ModernSettingsRowState();
}

class _ModernSettingsRowState extends State<ModernSettingsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _pressed = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    _pulseController.repeat(reverse: true);
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    _pulseController
      ..stop()
      ..reset();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final trailing = widget.trailing ?? _buildTrailingText(context);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.985, end: 1),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
      builder: (context, revealScale, child) {
        return Transform.scale(scale: revealScale, child: child);
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
          onTapCancel: widget.onTap == null ? null : () => _setPressed(false),
          onTapUp: widget.onTap == null
              ? null
              : (_) {
                  _setPressed(false);
                  widget.onTap?.call();
                },
          onLongPressStart: widget.onTap == null ? null : _handleLongPressStart,
          onLongPressEnd: widget.onTap == null ? null : _handleLongPressEnd,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _pressed ? 0.92 : 1,
            curve: Curves.easeOutCubic,
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: _pressed ? 0.98 : 1,
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: _hovered
                      ? colorScheme.primary.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = _pulseController.value;
                        return Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primaryContainer.withValues(
                                  alpha: 0.38 + pulse * 0.12,
                                ),
                                colorScheme.secondaryContainer.withValues(
                                  alpha: _pressed ? 0.48 : 0.22,
                                ),
                              ],
                              begin: Alignment(-1 + pulse * 0.8, -1),
                              end: const Alignment(1, 1),
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: colorScheme.outlineVariant.withValues(
                                alpha: 0.22,
                              ),
                            ),
                            boxShadow: [
                              if (_pressed || pulse > 0)
                                BoxShadow(
                                  color: colorScheme.primary.withValues(
                                    alpha: _pressed ? 0.14 : pulse * 0.10,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: colorScheme.primary,
                            size: AppIconSizes.md,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: AppSpacing.md),
                      trailing,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildTrailingText(BuildContext context) {
    final text = widget.trailingText;
    if (text == null) {
      return null;
    }
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 118),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.end,
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
