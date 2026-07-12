import 'package:flutter/material.dart';

typedef AppShellDestinationBuilder = Widget Function(BuildContext context);

class AppShellDestination {
  const AppShellDestination({
    required this.index,
    required this.label,
    required this.icon,
    required this.builder,
    IconData? selectedIcon,
  }) : selectedIcon = selectedIcon ?? icon;

  final int index;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final AppShellDestinationBuilder builder;
}
