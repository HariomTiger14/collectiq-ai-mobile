import 'package:collectiq_ai/core/ui/product_language/product_language_tokens.dart';
import 'package:flutter/material.dart';

enum PackLoxButtonVariant {
  primary,
  secondary,
  tertiary,
  quiet,
  destructive,
  success,
}

enum PackLoxButtonSize { compact, standard, large, fullWidth }

/// PackLox Button System 1.0.0 (PLX-CMP-BUTTON@1.0.0).
class PackLoxButton extends StatelessWidget {
  const PackLoxButton({
    required this.label,
    required this.onPressed,
    this.variant = PackLoxButtonVariant.primary,
    this.size = PackLoxButtonSize.standard,
    this.leadingIcon,
    this.trailingIcon,
    this.loading = false,
    this.semanticLabel,
    super.key,
  });
  const PackLoxButton.icon({
    required IconData icon,
    required String semanticLabel,
    required VoidCallback? onPressed,
    Key? key,
  }) : this(
         label: '',
         onPressed: onPressed,
         leadingIcon: icon,
         semanticLabel: semanticLabel,
         key: key,
       );
  final String label;
  final VoidCallback? onPressed;
  final PackLoxButtonVariant variant;
  final PackLoxButtonSize size;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool loading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final height = switch (size) {
      PackLoxButtonSize.compact => 44.0,
      PackLoxButtonSize.standard => 48.0,
      _ => 56.0,
    };
    final background = switch (variant) {
      PackLoxButtonVariant.primary => PackLoxTokens.blue,
      PackLoxButtonVariant.secondary => PackLoxTokens.surfaceRaised,
      PackLoxButtonVariant.tertiary => PackLoxTokens.blue.withValues(
        alpha: .16,
      ),
      PackLoxButtonVariant.quiet => Colors.transparent,
      PackLoxButtonVariant.destructive => PackLoxTokens.error.withValues(
        alpha: .2,
      ),
      PackLoxButtonVariant.success => PackLoxTokens.success.withValues(
        alpha: .2,
      ),
    };
    final foreground = variant == PackLoxButtonVariant.quiet
        ? const Color(0xFF93C5FD)
        : PackLoxTokens.textPrimary;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel ?? label,
      value: loading ? 'Loading' : null,
      excludeSemantics: true,
      child: SizedBox(
        width: size == PackLoxButtonSize.fullWidth ? double.infinity : null,
        child: TextButton(
          onPressed: enabled ? onPressed : null,
          style: ButtonStyle(
            minimumSize: WidgetStatePropertyAll(Size(height, height)),
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(
                horizontal: size == PackLoxButtonSize.large ? 26 : 20,
                vertical: 11,
              ),
            ),
            backgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.disabled)
                  ? background.withValues(alpha: .45)
                  : background,
            ),
            foregroundColor: WidgetStatePropertyAll(foreground),
            overlayColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: .08),
            ),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  size == PackLoxButtonSize.compact ? 12 : 14,
                ),
                side: BorderSide(
                  color: variant == PackLoxButtonVariant.primary
                      ? const Color(0xFF60A5FA)
                      : PackLoxTokens.border,
                ),
              ),
            ),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PackLoxTokens.textPrimary,
                  ),
                )
              else if (leadingIcon != null)
                Icon(leadingIcon, size: 20),
              if ((loading || leadingIcon != null) && label.isNotEmpty)
                const SizedBox(width: 10),
              if (label.isNotEmpty)
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                  ),
                ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 10),
                Icon(trailingIcon, size: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
