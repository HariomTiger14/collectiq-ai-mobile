import 'package:collectiq_ai/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

class ScanExposureSlider extends StatelessWidget {
  const ScanExposureSlider({
    required this.visible,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool visible;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      key: const ValueKey('scan-exposure-slider'),
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      child: IgnorePointer(
        ignoring: !visible,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.36),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: Colors.white24),
          ),
          child: SizedBox(
            width: 42,
            height: 174,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 14,
                  ),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                ),
                child: Slider(
                  value: value.clamp(0, 1).toDouble(),
                  min: 0,
                  max: 1,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
