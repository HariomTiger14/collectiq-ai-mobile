import 'package:collectiq_ai/core/ui/about/about_ui.dart';
import 'package:collectiq_ai/core/ui/home/home_ui.dart';
import 'package:collectiq_ai/core/ui/motion/motion_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appInfo = _AppInfo.current();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: AboutHeroHeader(
              scrollController: _scrollController,
              onBack: () => Navigator.of(context).maybePop(),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AboutAppIconCard(
                        version: appInfo.version,
                        buildNumber: appInfo.buildNumber,
                      ),
                      const SizedBox(height: 32),
                      SectionCard(
                        title: 'App Information',
                        child: MotionStagger(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AboutInfoTile(
                                icon: Icons.new_releases_outlined,
                                title: 'Version',
                                subtitle: appInfo.version,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AboutInfoTile(
                                icon: Icons.tag_rounded,
                                title: 'Build Number',
                                subtitle: appInfo.buildNumber,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AboutInfoTile(
                                icon: Icons.privacy_tip_outlined,
                                title: 'Privacy',
                                subtitle:
                                    'Your collection starts locally on this device',
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AboutInfoTile(
                                icon: Icons.cloud_done_outlined,
                                title: 'Backup',
                                subtitle: appInfo.backupMode,
                              ),
                            ),
                            AboutInfoTile(
                              icon: Icons.folder_outlined,
                              title: 'Storage Location',
                              subtitle: appInfo.storageLocation,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const AboutBrandCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppInfo {
  const _AppInfo({
    required this.version,
    required this.buildNumber,
    required this.backupMode,
    required this.storageLocation,
  });

  final String version;
  final String buildNumber;
  final String backupMode;
  final String storageLocation;

  factory _AppInfo.current() {
    return const _AppInfo(
      version: '1.0.0',
      buildNumber: '1',
      backupMode: 'Optional account backup',
      storageLocation: 'Local device storage',
    );
  }
}
