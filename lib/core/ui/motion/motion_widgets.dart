import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:flutter/material.dart';

class MotionTapScale extends StatefulWidget {
  const MotionTapScale({
    required this.child,
    this.onTap,
    this.enabled = true,
    this.scale = PackLoxMotionTheme.tapScale,
    this.duration = PackLoxMotionTheme.fast,
    this.curve = PackLoxMotionTheme.tapCurve,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double scale;
  final Duration duration;
  final Curve curve;
  final HitTestBehavior behavior;

  @override
  State<MotionTapScale> createState() => _MotionTapScaleState();
}

class _MotionTapScaleState extends State<MotionTapScale> {
  bool _pressed = false;

  bool get _canTap => widget.enabled && widget.onTap != null;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _canTap ? (_) => _setPressed(true) : null,
      onTapCancel: _canTap ? () => _setPressed(false) : null,
      onTapUp: _canTap
          ? (_) {
              _setPressed(false);
              widget.onTap?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed ? widget.scale : 1,
        duration: widget.duration,
        curve: widget.curve,
        child: widget.child,
      ),
    );
  }
}

class MotionHoverGlow extends StatefulWidget {
  const MotionHoverGlow({
    required this.child,
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(22)),
    this.opacity = PackLoxMotionTheme.hoverOpacity,
    this.blurRadius = PackLoxMotionTheme.hoverBlurRadius,
    this.offset = const Offset(0, 10),
    this.duration = PackLoxMotionTheme.medium,
    this.curve = PackLoxMotionTheme.hoverCurve,
    super.key,
  });

  final Widget child;
  final Color? color;
  final BorderRadius borderRadius;
  final double opacity;
  final double blurRadius;
  final Offset offset;
  final Duration duration;
  final Curve curve;

  @override
  State<MotionHoverGlow> createState() => _MotionHoverGlowState();
}

class _MotionHoverGlowState extends State<MotionHoverGlow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final glowColor = widget.color ?? Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: widget.duration,
        curve: widget.curve,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: glowColor.withValues(alpha: widget.opacity),
                    blurRadius: widget.blurRadius,
                    offset: widget.offset,
                  ),
                ]
              : const [],
        ),
        child: widget.child,
      ),
    );
  }
}

class MotionReveal extends StatelessWidget {
  const MotionReveal({
    required this.child,
    this.offset = 14,
    this.duration = PackLoxMotionTheme.medium,
    this.curve = PackLoxMotionTheme.revealCurve,
    this.delay = Duration.zero,
    super.key,
  });

  final Widget child;
  final double offset;
  final Duration duration;
  final Curve curve;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration + delay,
      curve: curve,
      builder: (context, value, child) {
        final delayMs = delay.inMilliseconds;
        final totalMs = (duration + delay).inMilliseconds;
        final active = totalMs == 0
            ? 1.0
            : ((value * totalMs - delayMs) / duration.inMilliseconds).clamp(
                0.0,
                1.0,
              );

        return Opacity(
          opacity: active,
          child: Transform.translate(
            offset: Offset(0, offset * (1 - active)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class MotionStagger extends StatelessWidget {
  const MotionStagger({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++)
          MotionReveal(
            delay: PackLoxMotionTheme.revealStagger * i,
            child: children[i],
          ),
      ],
    );
  }
}

class MotionAmbientGradient extends StatefulWidget {
  const MotionAmbientGradient({
    required this.gradientBuilder,
    required this.child,
    super.key,
  });

  final Gradient Function(double t) gradientBuilder;
  final Widget child;

  @override
  State<MotionAmbientGradient> createState() => _MotionAmbientGradientState();
}

class _MotionAmbientGradientState extends State<MotionAmbientGradient>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.waveDuration * 3,
    );
    if (PackLoxMotionTheme.ambientMotionEnabled) {
      _controller.repeat();
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PackLoxMotionTheme.isTestMode) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return DecoratedBox(
          decoration: BoxDecoration(gradient: widget.gradientBuilder(t)),
          child: widget.child,
        );
      },
    );
  }
}

class MotionParallax extends StatelessWidget {
  const MotionParallax({
    required this.scrollOffset,
    required this.child,
    this.depth = PackLoxMotionTheme.heroParallaxDepth,
    this.maxScroll = 160,
    super.key,
  });

  final double scrollOffset;
  final double depth;
  final double maxScroll;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final progress = maxScroll <= 0
        ? 0.0
        : scrollOffset.clamp(0, maxScroll).toDouble() / maxScroll;

    return Transform.translate(
      offset: Offset(0, -depth * progress),
      child: child,
    );
  }
}

class MotionElasticHero extends StatelessWidget {
  const MotionElasticHero({
    required this.baseHeight,
    required this.child,
    this.scrollOffset = 0,
    this.maxOverscroll = 80,
    this.stretchFactor = 0.35,
    super.key,
  });

  final double baseHeight;
  final double scrollOffset;
  final double maxOverscroll;
  final double stretchFactor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (PackLoxMotionTheme.isTestMode) {
      return SizedBox(
        height: baseHeight,
        child: SizedBox.expand(child: child),
      );
    }

    final overscroll = scrollOffset < 0
        ? (-scrollOffset).clamp(0.0, maxOverscroll)
        : 0.0;
    final elasticHeight = baseHeight + overscroll * stretchFactor;

    return SizedBox(
      height: elasticHeight,
      child: SizedBox.expand(child: child),
    );
  }
}

class MotionPulse extends StatefulWidget {
  const MotionPulse({
    required this.child,
    this.minScale = 1,
    this.maxScale = 1.06,
    this.minOpacity = 0.72,
    this.maxOpacity = 1,
    this.duration = PackLoxMotionTheme.pulseDuration,
    super.key,
  });

  final Widget child;
  final double minScale;
  final double maxScale;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  @override
  State<MotionPulse> createState() => _MotionPulseState();
}

class _MotionPulseState extends State<MotionPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (PackLoxMotionTheme.ambientMotionEnabled) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final pulse = PackLoxMotionTheme.transitionCurve.transform(
          _controller.value,
        );
        return Opacity(
          opacity:
              widget.minOpacity +
              (widget.maxOpacity - widget.minOpacity) * pulse,
          child: Transform.scale(
            scale:
                widget.minScale + (widget.maxScale - widget.minScale) * pulse,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
