import 'package:collectiq_ai/core/theme/design_system.dart';
import 'package:collectiq_ai/features/home/presentation/widgets/home_shared_components.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final width = MediaQuery.sizeOf(context).width;
    final dense = width < 360;
    final iconSize = dense ? 30.0 : 32.0;
    final rowPadding = dense ? 4.0 : 6.0;
    final contentGap = dense ? 9.0 : 10.0;
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
                padding: EdgeInsets.all(rowPadding),
                decoration: BoxDecoration(
                  color: _hovered
                      ? HomeTokens.surfaceInteractive.withValues(alpha: 0.82)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(HomeTokens.controlRadius),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final pulse = _pulseController.value;
                        return Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: HomeTokens.surfaceInteractive,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: HomeTokens.border.withValues(
                                alpha: 0.78 + pulse * 0.18,
                              ),
                            ),
                            boxShadow: [
                              if (_pressed || pulse > 0)
                                BoxShadow(
                                  color: HomeTokens.accent.withValues(
                                    alpha: _pressed ? 0.14 : pulse * 0.10,
                                  ),
                                  blurRadius: 16,
                                  offset: const Offset(0, 8),
                                ),
                            ],
                          ),
                          child: Icon(
                            widget.icon,
                            color: HomeTokens.accent,
                            size: dense ? 16 : 18,
                          ),
                        );
                      },
                    ),
                    SizedBox(width: contentGap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.titleMedium?.copyWith(
                              color: HomeTokens.textPrimary,
                              fontSize: dense ? 14.5 : 15.5,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodySmall?.copyWith(
                              color: HomeTokens.textSecondary,
                              fontSize: dense ? 11 : 12,
                              height: 1.22,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      SizedBox(width: dense ? AppSpacing.sm : AppSpacing.md),
                      SizedBox(
                        width: dense ? 78 : 104,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: trailing,
                        ),
                      ),
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
    final textTheme = Theme.of(context).textTheme;

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: textTheme.labelMedium?.copyWith(
        color: HomeTokens.accent,
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
