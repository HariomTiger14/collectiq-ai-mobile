import 'dart:ui';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class ScanHeroHeader extends StatelessWidget {
  const ScanHeroHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadius.xl),
      ),
      child: MotionAmbientGradient(
        gradientBuilder: PackLoxMotionTheme.ambientBlueIndigo,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppGradients.premium,
            boxShadow: AppElevation.level2,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.16),
                        Colors.transparent,
                        colorScheme.secondary.withValues(alpha: 0.22),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -34,
                top: -52,
                child: _GlowDisk(
                  size: 176,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                left: -48,
                bottom: -80,
                child: _GlowDisk(
                  size: 188,
                  color: colorScheme.secondary.withValues(alpha: 0.18),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xxl,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                  AppSpacing.lg,
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: MotionReveal(
                    offset: AppSpacing.lg,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _HeroIconChip(icon: Icons.auto_awesome_outlined),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'PackLox Intelligence',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'AI Scanner',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Instantly identify and value collectibles.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScanPreviewFrame extends StatefulWidget {
  const ScanPreviewFrame({
    required this.child,
    super.key,
    this.isAnalyzing = false,
    this.scrollOffset = 0,
  });

  final Widget child;
  final bool isAnalyzing;
  final double scrollOffset;

  @override
  State<ScanPreviewFrame> createState() => _ScanPreviewFrameState();
}

class _ScanPreviewFrameState extends State<ScanPreviewFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.waveDuration * 2,
    );
    if (_scanMotionEnabled) {
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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MotionReveal(
      child: MotionParallax(
        scrollOffset: widget.scrollOffset,
        depth: 10,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final pulse = Curves.easeInOut.transform(_controller.value);
            final glowAlpha = widget.isAnalyzing ? 0.24 : 0.12 + pulse * 0.06;

            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(
                      alpha: isDark ? 0.26 : 0.12,
                    ),
                    blurRadius: 44,
                    offset: const Offset(0, 24),
                  ),
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: glowAlpha),
                    blurRadius: 34 + pulse * 14,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.36,
                            )
                          : Colors.white.withValues(alpha: 0.64),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: colorScheme.primary.withValues(
                          alpha: 0.18 + pulse * 0.08,
                        ),
                        width: 1.2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(
                                    alpha: isDark ? 0.04 : 0.32,
                                  ),
                                  colorScheme.primary.withValues(alpha: 0.03),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                        ),
                        child!,
                        Positioned.fill(
                          child: IgnorePointer(
                            child: CustomPaint(
                              painter: _ScanWavePainter(
                                progress: _controller.value,
                                color: colorScheme.primary,
                                opacity: widget.isAnalyzing ? 0.30 : 0.18,
                                scannerLine: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

class ScanPreviewGlassFrame extends StatelessWidget {
  const ScanPreviewGlassFrame({
    required this.child,
    super.key,
    this.isAnalyzing = false,
  });

  final Widget child;
  final bool isAnalyzing;

  @override
  Widget build(BuildContext context) {
    return ScanPreviewFrame(isAnalyzing: isAnalyzing, child: child);
  }
}

class ScanWaveAnimation extends StatefulWidget {
  const ScanWaveAnimation({super.key, this.height = 82});

  final double height;

  @override
  State<ScanWaveAnimation> createState() => _ScanWaveAnimationState();
}

class _ScanWaveAnimationState extends State<ScanWaveAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.waveDuration * 3,
    );
    if (_scanMotionEnabled) {
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
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ScanWavePainter(
              progress: _controller.value,
              color: colorScheme.primary,
              opacity: 0.18,
            ),
          );
        },
      ),
    );
  }
}

class ScanStatusBar extends StatelessWidget {
  const ScanStatusBar({
    required this.status,
    super.key,
    this.confidence,
    this.category,
    this.detectedCategory,
    this.modelStatus,
  });

  final String status;
  final double? confidence;
  final String? category;
  final String? detectedCategory;
  final String? modelStatus;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confidenceValue = (confidence ?? 0).clamp(0.0, 1.0);
    final categoryLabel = _emptyToFallback(
      category ?? detectedCategory,
      'Awaiting image',
    );
    final modelLabel = _emptyToFallback(modelStatus, status);

    return MotionReveal(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.38)
                  : Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.38),
              ),
              boxShadow: AppElevation.level1,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _StatusPill(
                      icon: Icons.memory_outlined,
                      label: modelLabel,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: AppTextStyles.h3.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: _MetricLabel(
                        icon: Icons.category_outlined,
                        label: 'Category',
                        value: categoryLabel,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    _MetricLabel(
                      icon: Icons.query_stats_outlined,
                      label: 'Confidence',
                      value: confidence == null
                          ? '--'
                          : '${(confidenceValue * 100).toStringAsFixed(0)}%',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    minHeight: AppSpacing.xs,
                    value: confidence == null ? 0 : confidenceValue,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.10,
                    ),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScanActionRow extends StatelessWidget {
  const ScanActionRow({
    required this.onCapture,
    required this.onGallery,
    required this.onSample,
    required this.onReset,
    super.key,
    this.isBusy = false,
    this.canReset = false,
    this.captureLabel = 'Capture',
    this.galleryLabel = 'Gallery',
    this.sampleLabel = 'Sample',
    this.resetLabel = 'Reset',
    this.captureIcon = Icons.photo_camera_outlined,
  });

  final VoidCallback? onCapture;
  final VoidCallback? onGallery;
  final VoidCallback? onSample;
  final VoidCallback? onReset;
  final bool isBusy;
  final bool canReset;
  final String captureLabel;
  final String galleryLabel;
  final String sampleLabel;
  final String resetLabel;
  final IconData captureIcon;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ScanAction(
        label: isBusy ? 'Scanning' : captureLabel,
        icon: isBusy ? Icons.hourglass_top_outlined : captureIcon,
        onTap: isBusy ? null : onCapture,
        emphasized: true,
      ),
      _ScanAction(
        label: galleryLabel,
        icon: Icons.photo_library_outlined,
        onTap: isBusy ? null : onGallery,
      ),
      _ScanAction(
        label: sampleLabel,
        icon: Icons.science_outlined,
        onTap: isBusy ? null : onSample,
      ),
      _ScanAction(
        label: resetLabel,
        icon: Icons.refresh_outlined,
        onTap: canReset && !isBusy ? onReset : null,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        final children = [
          for (final action in actions)
            isWide
                ? Expanded(child: _ScanActionTile(action: action))
                : _ScanActionTile(action: action),
        ];

        return MotionStagger(
          children: [
            if (isWide)
              Row(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      const SizedBox(width: AppSpacing.md),
                  ],
                ],
              )
            else
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final child in children)
                    SizedBox(
                      width: (constraints.maxWidth - AppSpacing.md) / 2,
                      child: child,
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class ScanSectionHeader extends StatelessWidget {
  const ScanSectionHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.h2.copyWith(color: colorScheme.onSurface),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.md),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class ScanCardGroup extends StatelessWidget {
  const ScanCardGroup({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (children.isEmpty) {
      return GlassCard(
        child: Row(
          children: [
            Icon(
              Icons.history_outlined,
              color: colorScheme.primary,
              size: AppIconSizes.md,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'Recent scans will appear here after you save an item.',
                style: AppTextStyles.body.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return MotionStagger(
      children: [
        for (var index = 0; index < children.length; index++)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == children.length - 1 ? 0 : AppSpacing.md,
            ),
            child: GlassCard(child: children[index]),
          ),
      ],
    );
  }
}

class ScanActionButtons extends StatelessWidget {
  const ScanActionButtons({
    required this.onStart,
    required this.onRetake,
    required this.onSave,
    super.key,
    this.onCamera,
    this.onGallery,
    this.onSample,
    this.isBusy = false,
    this.canRetake = false,
    this.canSave = false,
    this.isSaved = false,
  });

  final VoidCallback? onStart;
  final VoidCallback? onRetake;
  final VoidCallback? onSave;
  final VoidCallback? onCamera;
  final VoidCallback? onGallery;
  final VoidCallback? onSample;
  final bool isBusy;
  final bool canRetake;
  final bool canSave;
  final bool isSaved;

  @override
  Widget build(BuildContext context) {
    return ScanActionRow(
      onCapture: onStart,
      onGallery: onGallery,
      onSample: onSample,
      onReset: onRetake,
      isBusy: isBusy,
      canReset: canRetake,
      captureLabel: canRetake && !canSave && !isSaved ? 'Analyze' : 'Capture',
      captureIcon: canRetake && !canSave && !isSaved
          ? Icons.auto_awesome_outlined
          : Icons.photo_camera_outlined,
    );
  }
}

class _ScanActionTile extends StatelessWidget {
  const _ScanActionTile({required this.action});

  final _ScanAction action;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = action.onTap != null;

    return MotionTapScale(
      onTap: action.onTap,
      enabled: enabled,
      scale: 0.97,
      child: TextButton(
        onPressed: enabled ? action.onTap : null,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        ),
        child: GlassCard(
          enablePress: false,
          child: AnimatedOpacity(
            opacity: enabled ? 1 : 0.46,
            duration: PackLoxMotionTheme.fast,
            child: SizedBox(
              height: 76,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: action.emphasized ? AppGradients.primary : null,
                      color: action.emphasized
                          ? null
                          : colorScheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Icon(
                      action.icon,
                      color: action.emphasized
                          ? Colors.white
                          : colorScheme.primary,
                      size: AppIconSizes.md,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: enabled ? action.onTap : null,
                    child: Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanAction {
  const _ScanAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.emphasized = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool emphasized;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: AppIconSizes.sm),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricLabel extends StatelessWidget {
  const _MetricLabel({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colorScheme.primary, size: AppIconSizes.sm),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.h3.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroIconChip extends StatelessWidget {
  const _HeroIconChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Icon(icon, color: Colors.white, size: AppIconSizes.sm),
    );
  }
}

class _GlowDisk extends StatelessWidget {
  const _GlowDisk({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _ScanWavePainter extends CustomPainter {
  const _ScanWavePainter({
    required this.progress,
    required this.color,
    required this.opacity,
    this.scannerLine = false,
  });

  final double progress;
  final Color color;
  final double opacity;
  final bool scannerLine;

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: opacity * 0.35),
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.35),
        ],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = scannerLine ? 1.4 : 2.2;

    for (var wave = 0; wave < 3; wave++) {
      final path = Path();
      final vertical = size.height * (0.26 + wave * 0.22);
      final amplitude = scannerLine ? 5.0 + wave : 10.0 + wave * 3;
      final phase = progress * size.width * 1.5 + wave * 52;
      path.moveTo(0, vertical);

      for (var x = 0.0; x <= size.width; x += 8) {
        final y =
            vertical + amplitude * (0.5 - ((x + phase) % 96) / 96).abs() * 2;
        path.lineTo(x, y);
      }

      canvas.drawPath(path, wavePaint);
    }

    if (!scannerLine) {
      return;
    }

    final scanY = size.height * ((progress + 0.08) % 1);
    final linePaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: opacity * 2.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 12, size.width, 24));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 12, size.width, 24), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ScanWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.opacity != opacity ||
        oldDelegate.scannerLine != scannerLine;
  }
}

String _emptyToFallback(String? value, String fallback) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return fallback;
  }
  return trimmed;
}

bool get _scanMotionEnabled {
  return PackLoxMotionTheme.ambientMotionEnabled;
}
