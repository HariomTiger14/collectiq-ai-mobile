import 'dart:math' as math;
import 'dart:ui';

import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:collectiq_ai/core/theme/packlox_motion_theme.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:collectiq_ai/core/widgets/gradient_header.dart';
import 'package:collectiq_ai/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:flutter/material.dart';

class CloudSyncHeroHeader extends StatelessWidget {
  const CloudSyncHeroHeader({
    required this.scrollOffset,
    this.gradientStyle = GradientStyle.blueIndigo,
    super.key,
  });

  final double scrollOffset;
  final GradientStyle gradientStyle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _cloudSyncGradientColors(context, gradientStyle);

    return MotionElasticHero(
      baseHeight: 184,
      scrollOffset: scrollOffset,
      child: MotionParallax(
        scrollOffset: scrollOffset,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.xxl),
          ),
          child: MotionAmbientGradient(
            gradientBuilder: _ambientGradientFor(gradientStyle),
            child: Container(
              height: 184,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.xxl),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.last.withValues(alpha: isDark ? 0.26 : 0.32),
                    blurRadius: isDark ? 32 : 46,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        Icons.cloud_sync_rounded,
                        color: colorScheme.onPrimary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cloud Sync',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.headlineSmall?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PackLox Backup & Restore',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onPrimary.withValues(
                                alpha: 0.80,
                              ),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CloudSyncStatusCard extends StatefulWidget {
  const CloudSyncStatusCard({
    required this.lastSync,
    required this.syncState,
    required this.itemsBackedUp,
    required this.itemsPending,
    this.message,
    super.key,
  });

  final DateTime? lastSync;
  final SyncState syncState;
  final int itemsBackedUp;
  final int itemsPending;
  final String? message;

  @override
  State<CloudSyncStatusCard> createState() => _CloudSyncStatusCardState();
}

class _CloudSyncStatusCardState extends State<CloudSyncStatusCard>
    with TickerProviderStateMixin {
  late final AnimationController _syncController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _syncController = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.waveDuration,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: PackLoxMotionTheme.pulseDuration,
    );
    _updateAnimations();
  }

  @override
  void didUpdateWidget(covariant CloudSyncStatusCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.syncState != widget.syncState) {
      _updateAnimations();
    }
  }

  @override
  void dispose() {
    _syncController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _updateAnimations() {
    if (widget.syncState == SyncState.syncing) {
      if (PackLoxMotionTheme.ambientMotionEnabled) {
        _syncController.repeat();
      }
    } else {
      _syncController.stop();
    }

    if (widget.syncState == SyncState.synced) {
      if (PackLoxMotionTheme.ambientMotionEnabled) {
        _pulseController.repeat(reverse: true);
      }
    } else {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MotionReveal(
      offset: 18,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: MotionAmbientGradient(
          gradientBuilder: PackLoxMotionTheme.ambientPurpleDeepBlue,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: isDark
                    ? colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.42,
                      )
                    : colorScheme.surface.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.58),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(
                      alpha: isDark ? 0.20 : 0.10,
                    ),
                    blurRadius: isDark ? 28 : 40,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _SyncStateIcon(
                        state: widget.syncState,
                        syncController: _syncController,
                        pulseController: _pulseController,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _stateLabel(widget.syncState),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (widget.message != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                widget.message!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppResponsiveMetricGroup(
                    metrics: [
                      AppMetricData(
                        label: 'Last Sync Time',
                        value: _formatCloudSyncDate(widget.lastSync),
                        icon: Icons.schedule_rounded,
                      ),
                      AppMetricData(
                        label: 'Items Backed Up',
                        value: widget.itemsBackedUp.toString(),
                        icon: Icons.cloud_done_rounded,
                      ),
                      AppMetricData(
                        label: 'Items Pending',
                        value: widget.itemsPending.toString(),
                        icon: Icons.pending_actions_rounded,
                      ),
                    ],
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

class CloudSyncDiagnosticTile extends StatefulWidget {
  const CloudSyncDiagnosticTile({
    required this.title,
    required this.subtitle,
    this.icon = Icons.info_outline_rounded,
    this.trailing,
    this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final IconData? trailing;
  final VoidCallback? onTap;

  @override
  State<CloudSyncDiagnosticTile> createState() =>
      _CloudSyncDiagnosticTileState();
}

class _CloudSyncDiagnosticTileState extends State<CloudSyncDiagnosticTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            color: _hovered
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                Icon(
                  widget.trailing,
                  color: colorScheme.onSurfaceVariant,
                  size: 22,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class CloudSyncActionButton extends StatefulWidget {
  const CloudSyncActionButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.gradientStyle = GradientStyle.tealEmerald,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool enabled;
  final GradientStyle gradientStyle;

  @override
  State<CloudSyncActionButton> createState() => _CloudSyncActionButtonState();
}

class _CloudSyncActionButtonState extends State<CloudSyncActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEnabled = widget.enabled && !widget.isLoading;
    final colors = _cloudSyncGradientColors(context, widget.gradientStyle);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: MotionTapScale(
        onTap: widget.onPressed,
        enabled: isEnabled,
        scale: 0.98,
        child: AnimatedContainer(
          duration: PackLoxMotionTheme.medium,
          curve: PackLoxMotionTheme.hoverCurve,
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isEnabled
                  ? colors
                  : [
                      colorScheme.onSurface.withValues(alpha: 0.12),
                      colorScheme.onSurface.withValues(alpha: 0.08),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              if (_hovered && isEnabled)
                BoxShadow(
                  color: colors.last.withValues(alpha: 0.26),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                ] else ...[
                  Icon(Icons.sync_rounded, color: colorScheme.onPrimary),
                ],
                const SizedBox(width: 10),
                Text(
                  widget.isLoading ? 'Syncing...' : widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
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

class CloudSyncWaveAnimation extends StatefulWidget {
  const CloudSyncWaveAnimation({super.key});

  @override
  State<CloudSyncWaveAnimation> createState() => _CloudSyncWaveAnimationState();
}

class _CloudSyncWaveAnimationState extends State<CloudSyncWaveAnimation>
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = _cloudSyncGradientColors(context, GradientStyle.blueIndigo);

    return IgnorePointer(
      child: ExcludeSemantics(
        child: SizedBox(
          height: 96,
          width: double.infinity,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                painter: _CloudSyncWavePainter(
                  progress: _controller.value,
                  colors: colors,
                  opacity: isDark ? 0.14 : 0.18,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CloudSyncSectionCard extends StatelessWidget {
  const CloudSyncSectionCard({
    required this.title,
    required this.child,
    super.key,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.42)
            : colorScheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.14 : 0.58),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.16 : 0.10),
            blurRadius: isDark ? 28 : 38,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class _SyncStateIcon extends StatelessWidget {
  const _SyncStateIcon({
    required this.state,
    required this.syncController,
    required this.pulseController,
  });

  final SyncState state;
  final AnimationController syncController;
  final AnimationController pulseController;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = switch (state) {
      SyncState.failed || SyncState.conflict => colorScheme.error,
      SyncState.synced => AppColors.success,
      SyncState.syncing => colorScheme.primary,
      SyncState.pending => colorScheme.tertiary,
      SyncState.localOnly => colorScheme.onSurfaceVariant,
    };

    return AnimatedBuilder(
      animation: Listenable.merge([syncController, pulseController]),
      builder: (context, child) {
        final pulse = pulseController.value;
        return Transform.rotate(
          angle: state == SyncState.syncing
              ? syncController.value * math.pi * 2
              : 0,
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: state == SyncState.synced
                  ? LinearGradient(
                      colors: [
                        AppColors.success.withValues(alpha: 0.70 + pulse * 0.2),
                        colorScheme.primary.withValues(alpha: 0.42),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: state == SyncState.synced
                  ? null
                  : baseColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: baseColor.withValues(alpha: 0.24)),
            ),
            child: Icon(_stateIcon(state), color: baseColor),
          ),
        );
      },
    );
  }
}

class _CloudSyncWavePainter extends CustomPainter {
  const _CloudSyncWavePainter({
    required this.progress,
    required this.colors,
    required this.opacity,
  });

  final double progress;
  final List<Color> colors;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          colors.first.withValues(alpha: opacity),
          colors.last.withValues(alpha: opacity * 0.82),
        ],
      ).createShader(Offset.zero & size);

    for (var wave = 0; wave < 2; wave++) {
      final path = Path();
      final verticalOffset = size.height * (0.42 + wave * 0.16);
      path.moveTo(0, verticalOffset);
      for (var x = 0.0; x <= size.width; x += 6) {
        final phase =
            (x / size.width * math.pi * 2) + (progress * math.pi * 2) + wave;
        final y = verticalOffset + math.sin(phase) * (13 + wave * 4);
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CloudSyncWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.opacity != opacity ||
        oldDelegate.colors != colors;
  }
}

List<Color> _cloudSyncGradientColors(
  BuildContext context,
  GradientStyle style,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return switch (style) {
    GradientStyle.blueIndigo =>
      isDark
          ? const [Color(0xFF07111F), Color(0xFF1E40AF), Color(0xFF5E5CE6)]
          : const [Color(0xFF0A84FF), Color(0xFF1456D9), Color(0xFF5E5CE6)],
    GradientStyle.purpleDeepBlue =>
      isDark
          ? const [Color(0xFF1A103D), Color(0xFF5B21B6), Color(0xFF1E40AF)]
          : const [Color(0xFF8B5CF6), Color(0xFF5E5CE6), Color(0xFF0A84FF)],
    GradientStyle.tealEmerald =>
      isDark
          ? const [Color(0xFF062D35), Color(0xFF0F766E), Color(0xFF047857)]
          : const [Color(0xFF0A84FF), Color(0xFF14B8A6), Color(0xFF10B981)],
  };
}

Gradient Function(double) _ambientGradientFor(GradientStyle style) {
  return switch (style) {
    GradientStyle.purpleDeepBlue => PackLoxMotionTheme.ambientPurpleDeepBlue,
    GradientStyle.blueIndigo ||
    GradientStyle.tealEmerald => PackLoxMotionTheme.ambientBlueIndigo,
  };
}

IconData _stateIcon(SyncState state) {
  return switch (state) {
    SyncState.localOnly => Icons.phone_iphone_rounded,
    SyncState.synced => Icons.check_circle_rounded,
    SyncState.pending => Icons.pending_actions_rounded,
    SyncState.syncing => Icons.sync_rounded,
    SyncState.failed => Icons.warning_amber_rounded,
    SyncState.conflict => Icons.merge_type_rounded,
  };
}

String _stateLabel(SyncState state) {
  return switch (state) {
    SyncState.localOnly => 'Idle',
    SyncState.synced => 'Completed',
    SyncState.pending => 'Idle',
    SyncState.syncing => 'Syncing',
    SyncState.failed => 'Error',
    SyncState.conflict => 'Error',
  };
}

String _formatCloudSyncDate(DateTime? value) {
  if (value == null) {
    return 'Never';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
