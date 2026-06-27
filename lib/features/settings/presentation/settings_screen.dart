import 'package:collectiq_ai/shared/widgets/app_placeholder_screen.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppPlaceholderScreen(
      title: 'Settings',
      icon: Icons.settings_outlined,
    );
  }
}
