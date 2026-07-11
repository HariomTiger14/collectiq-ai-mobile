import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class ScannerVisualTheme {
  const ScannerVisualTheme._();

  static const background = Color(0xFF050B16);
  static const backgroundDeep = Color(0xFF020712);
  static const surface = Color(0xFF0B1422);
  static const surfaceElevated = Color(0xFF111C2D);
  static const surfaceGlass = Color(0xCC0B1422);
  static const border = Color(0xFF263A55);
  static const borderStrong = Color(0xFF2C7DFF);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFFB8C5D8);
  static const textMuted = Color(0xFF8394AB);
  static const blue = Color(0xFF0A84FF);
  static const indigo = Color(0xFF1456D9);
  static const cyan = Color(0xFF22D3EE);
  static const purple = Color(0xFF8A5CF6);
  static const success = Color(0xFF22C55E);
  static const danger = Color(0xFFEF4444);

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundDeep, background, Color(0xFF071A33)],
  );

  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [blue, indigo, purple],
  );

  static const surfaceGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surfaceElevated, surface, Color(0xFF07111F)],
  );

  static List<BoxShadow> blueGlow({double alpha = 0.24}) => [
    BoxShadow(
      color: blue.withValues(alpha: alpha),
      blurRadius: 32,
      offset: const Offset(0, 16),
    ),
  ];
}

class ScannerFocusTheme extends StatelessWidget {
  const ScannerFocusTheme({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final scannerScheme = ColorScheme.fromSeed(
      seedColor: ScannerVisualTheme.blue,
      brightness: Brightness.dark,
      surface: ScannerVisualTheme.background,
    );
    return Theme(
      data: base.copyWith(
        brightness: Brightness.dark,
        colorScheme: scannerScheme.copyWith(
          primary: ScannerVisualTheme.blue,
          secondary: ScannerVisualTheme.cyan,
          tertiary: ScannerVisualTheme.purple,
          surface: ScannerVisualTheme.background,
          surfaceContainerLow: ScannerVisualTheme.surface,
          surfaceContainerHighest: ScannerVisualTheme.surfaceElevated,
          outline: ScannerVisualTheme.border,
          outlineVariant: ScannerVisualTheme.border,
          onSurface: ScannerVisualTheme.textPrimary,
          onSurfaceVariant: ScannerVisualTheme.textSecondary,
        ),
        scaffoldBackgroundColor: ScannerVisualTheme.background,
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: ScannerVisualTheme.background,
          foregroundColor: ScannerVisualTheme.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            foregroundColor: ScannerVisualTheme.textPrimary,
            backgroundColor: ScannerVisualTheme.blue,
            minimumSize: const Size(0, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: base.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: ScannerVisualTheme.textPrimary,
            backgroundColor: ScannerVisualTheme.surfaceGlass,
            minimumSize: const Size(0, 50),
            side: const BorderSide(color: ScannerVisualTheme.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: ScannerVisualTheme.cyan,
            textStyle: base.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

class ScannerBackground extends StatelessWidget {
  const ScannerBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('scanner-dark-background'),
      decoration: const BoxDecoration(
        gradient: ScannerVisualTheme.backgroundGradient,
      ),
      child: child,
    );
  }
}

class ScannerFocusedScaffold extends StatelessWidget {
  const ScannerFocusedScaffold({
    required this.child,
    this.backgroundColor = ScannerVisualTheme.background,
    this.useSafeArea = true,
    super.key,
  });

  final Widget child;
  final Color backgroundColor;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final body = ScannerBackground(child: child);
    return ScannerFocusTheme(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: useSafeArea ? SafeArea(child: body) : body,
      ),
    );
  }
}

class ScannerPageHeader extends StatelessWidget {
  const ScannerPageHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: ScannerVisualTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: 0,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ScannerVisualTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}

class ScannerSurface extends StatelessWidget {
  const ScannerSurface({
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.selected = false,
    this.radius = AppRadius.lg,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: ScannerVisualTheme.surfaceGradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: selected
              ? ScannerVisualTheme.borderStrong
              : ScannerVisualTheme.border.withValues(alpha: 0.78),
          width: selected ? 1.6 : 1,
        ),
        boxShadow: selected
            ? ScannerVisualTheme.blueGlow(alpha: 0.22)
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class ScannerPrimaryButton extends StatelessWidget {
  const ScannerPrimaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    Key? key,
  }) : _buttonKey = key,
       super(key: null);

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Key? _buttonKey;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : ScannerVisualTheme.primaryGradient,
        color: onPressed == null
            ? ScannerVisualTheme.surfaceElevated.withValues(alpha: 0.72)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: onPressed == null
            ? null
            : ScannerVisualTheme.blueGlow(alpha: 0.28),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: FilledButton.icon(
          key: _buttonKey,
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 56),
            foregroundColor: ScannerVisualTheme.textPrimary,
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: ScannerVisualTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class ScannerSecondaryButton extends StatelessWidget {
  const ScannerSecondaryButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    Key? key,
  }) : _buttonKey = key,
       super(key: null);

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Key? _buttonKey;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      key: _buttonKey,
      onPressed: onPressed,
      icon: Icon(icon, size: 19),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: FilledButton.styleFrom(
        foregroundColor: ScannerVisualTheme.textPrimary,
        backgroundColor: ScannerVisualTheme.surfaceGlass,
        disabledForegroundColor: ScannerVisualTheme.textMuted,
        disabledBackgroundColor: ScannerVisualTheme.surfaceGlass.withValues(
          alpha: 0.45,
        ),
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        side: BorderSide(color: ScannerVisualTheme.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: ScannerVisualTheme.textPrimary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class ScannerTertiaryAction extends StatelessWidget {
  const ScannerTertiaryAction({
    required this.onPressed,
    required this.icon,
    required this.label,
    super.key,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: TextButton.styleFrom(
        foregroundColor: ScannerVisualTheme.textSecondary,
        minimumSize: const Size(0, 44),
      ),
    );
  }
}

class ScannerSegmentedSelector<T> extends StatelessWidget {
  const ScannerSegmentedSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<ScannerSegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('scanner-segmented-selector'),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: ScannerVisualTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: ScannerVisualTheme.border),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: _ScannerSegment<T>(
                option: option,
                selected: option.value == selected,
                onSelected: onSelected,
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerSegmentOption<T> {
  const ScannerSegmentOption({
    required this.value,
    required this.label,
    this.key,
  });

  final T value;
  final String label;
  final Key? key;
}

class ScannerIconButton extends StatelessWidget {
  const ScannerIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.circular = false,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          shape: circular
              ? const CircleBorder()
              : RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
          child: InkWell(
            onTap: onPressed,
            customBorder: circular
                ? const CircleBorder()
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
            child: AnimatedOpacity(
              opacity: onPressed == null ? 0.42 : 1,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: ScannerVisualTheme.surfaceGlass,
                  shape: circular ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: circular
                      ? null
                      : BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: ScannerVisualTheme.border.withValues(alpha: 0.68),
                  ),
                ),
                child: Icon(
                  icon,
                  color: ScannerVisualTheme.textPrimary,
                  size: iconSize,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScannerCameraControl extends StatelessWidget {
  const ScannerCameraControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ScannerIconButton(
      icon: icon,
      tooltip: tooltip,
      onPressed: onPressed,
      size: 48,
      iconSize: 21,
      circular: true,
    );
  }
}

class ScannerCameraShutter extends StatelessWidget {
  const ScannerCameraShutter({
    required this.isCapturing,
    required this.onPressed,
    super.key,
  });

  final bool isCapturing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Take photo',
      enabled: !isCapturing,
      child: GestureDetector(
        key: const ValueKey('camera-capture-button'),
        onTap: isCapturing ? null : onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 78,
          height: 78,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: isCapturing ? 52 : 58,
              height: isCapturing ? 52 : 58,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: isCapturing
                  ? const Padding(
                      padding: EdgeInsets.all(15),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class ScannerGuidancePanel extends StatelessWidget {
  const ScannerGuidancePanel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('camera-guidance-pill'),
      decoration: BoxDecoration(
        color: ScannerVisualTheme.surfaceGlass,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: ScannerVisualTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.25,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class ScannerPhotoThumbnail extends StatelessWidget {
  const ScannerPhotoThumbnail({
    required this.child,
    required this.label,
    this.selected = false,
    this.completed = false,
    this.width = 132,
    this.height = 142,
    this.onTap,
    super.key,
  });

  final Widget child;
  final String label;
  final bool selected;
  final bool completed;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Ink(
            decoration: BoxDecoration(
              color: ScannerVisualTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? ScannerVisualTheme.cyan
                    : ScannerVisualTheme.border,
                width: selected ? 2 : 1,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  bottom: 30,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.md - 1),
                    ),
                    child: child,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 30,
                  child: ColoredBox(
                    color: ScannerVisualTheme.surfaceGlass,
                    child: Center(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: ScannerVisualTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
                if (completed)
                  const Positioned(
                    right: 8,
                    top: 8,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: ScannerVisualTheme.success,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(3),
                        child: Icon(
                          Icons.check,
                          color: ScannerVisualTheme.textPrimary,
                          size: 14,
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
  }
}

class ScannerAnalyzingIndicator extends StatefulWidget {
  const ScannerAnalyzingIndicator({super.key});

  @override
  State<ScannerAnalyzingIndicator> createState() =>
      _ScannerAnalyzingIndicatorState();
}

class _ScannerAnalyzingIndicatorState extends State<ScannerAnalyzingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 0.96,
      end: 1.04,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        key: const ValueKey('analyze-branded-progress'),
        width: 116,
        height: 116,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: ScannerVisualTheme.cyan.withValues(alpha: 0.80),
            width: 5,
          ),
          boxShadow: ScannerVisualTheme.blueGlow(alpha: 0.20),
          gradient: ScannerVisualTheme.surfaceGradient,
        ),
        child: const Icon(
          Icons.view_in_ar_outlined,
          color: ScannerVisualTheme.blue,
          size: 42,
        ),
      ),
    );
  }
}

class ScannerStatusCard extends StatelessWidget {
  const ScannerStatusCard({
    required this.title,
    required this.body,
    required this.icon,
    this.success = false,
    this.trailing,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;
  final bool success;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final accent = success
        ? ScannerVisualTheme.success
        : ScannerVisualTheme.cyan;
    return ScannerSurface(
      key: const ValueKey('scanner-status-card'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              border: Border.all(color: accent.withValues(alpha: 0.52)),
            ),
            child: Icon(icon, color: accent, size: 19),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  key: const ValueKey('workspace-guidance-title'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                    color: ScannerVisualTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  key: const ValueKey('workspace-guidance-body'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ScannerVisualTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerSegment<T> extends StatelessWidget {
  const _ScannerSegment({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  final ScannerSegmentOption<T> option;
  final bool selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: InkWell(
        key: option.key,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => onSelected(option.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          alignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 38),
          decoration: BoxDecoration(
            color: selected ? ScannerVisualTheme.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected
                  ? ScannerVisualTheme.textPrimary
                  : ScannerVisualTheme.textSecondary,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
