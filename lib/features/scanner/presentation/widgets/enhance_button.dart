import 'package:flutter/material.dart';

class EnhanceButton extends StatefulWidget {
  const EnhanceButton({
    required this.onPressed,
    required this.active,
    this.large = true,
    super.key,
  });

  final VoidCallback? onPressed;
  final bool active;
  final bool large;

  @override
  State<EnhanceButton> createState() => _EnhanceButtonState();
}

class _EnhanceButtonState extends State<EnhanceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    if (widget.active) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant EnhanceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) {
      return;
    }
    if (widget.active) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _tap() {
    setState(() => _pressed = true);
    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() => _pressed = false);
      }
    });
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final size = widget.large ? 58.0 : 48.0;
    return AnimatedBuilder(
      key: const ValueKey('scan-enhance-pulse'),
      animation: _pulseController,
      builder: (context, child) {
        final pulse = widget.active
            ? 0.12 + (_pulseController.value * 0.08)
            : 0.0;
        final glowColor = Color.lerp(
          const Color(0xFF14B8A6),
          const Color(0xFF7DD3FC),
          _pulseController.value,
        )!;
        return AnimatedScale(
          key: const ValueKey('scan-enhance-scale'),
          scale: _pressed ? 0.94 : 1,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: DecoratedBox(
            key: const ValueKey('scan-enhance-glow'),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.active
                  ? [
                      BoxShadow(
                        color: glowColor.withValues(alpha: pulse),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: const Color(
                          0xFF2563EB,
                        ).withValues(alpha: pulse * 0.55),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
            child: child,
          ),
        );
      },
      child: Tooltip(
        message: 'AI Enhance',
        child: IconButton(
          key: const ValueKey('scan-live-enhance'),
          onPressed: enabled ? _tap : null,
          icon: Icon(
            Icons.auto_fix_high,
            color: enabled ? Colors.white : Colors.white54,
          ),
          style: IconButton.styleFrom(
            fixedSize: Size.square(size),
            backgroundColor: widget.active
                ? const Color(0xFF14B8A6).withValues(alpha: 0.46)
                : Colors.black.withValues(alpha: 0.42),
            disabledBackgroundColor: Colors.black.withValues(alpha: 0.22),
            shape: const CircleBorder(),
          ),
        ),
      ),
    );
  }
}
