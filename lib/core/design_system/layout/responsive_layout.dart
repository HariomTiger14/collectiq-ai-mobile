import 'package:collectiq_ai/core/design_system/tokens/tokens.dart';
import 'package:flutter/material.dart';

class AppBreakpoints {
  const AppBreakpoints._();

  static const double phone = 0;
  static const double tablet = 700;
  static const double desktop = 1024;
  static const double maxContentWidth = 960;
}

class AppResponsive {
  const AppResponsive._();

  static bool isPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < AppBreakpoints.tablet;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppBreakpoints.tablet && width < AppBreakpoints.desktop;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
  }

  static double horizontalPadding(BuildContext context) {
    return isPhone(context)
        ? AppSpacing.screenHorizontal
        : AppSpacing.screenHorizontalLarge;
  }
}

class AppResponsivePage extends StatelessWidget {
  const AppResponsivePage({
    required this.child,
    this.padding,
    this.maxWidth = AppBreakpoints.maxContentWidth,
    this.controller,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double maxWidth;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = AppResponsive.horizontalPadding(context);

    return SingleChildScrollView(
      controller: controller,
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            horizontalPadding,
            AppSpacing.xl,
            horizontalPadding,
            AppSpacing.xxl,
          ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class AppResponsiveColumn extends StatelessWidget {
  const AppResponsiveColumn({
    required this.children,
    this.spacing = AppSpacing.lg,
    super.key,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index != children.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}

class AppResponsiveSplit extends StatelessWidget {
  const AppResponsiveSplit({
    required this.primary,
    required this.secondary,
    this.spacing = AppSpacing.lg,
    super.key,
  });

  final Widget primary;
  final Widget secondary;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    if (AppResponsive.isPhone(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primary,
          SizedBox(height: spacing),
          secondary,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: primary),
        SizedBox(width: spacing),
        Expanded(child: secondary),
      ],
    );
  }
}
