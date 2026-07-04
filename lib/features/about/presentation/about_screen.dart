import 'package:collectiq_ai/core/supabase/supabase_config.dart';
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
    final supabaseConfig = ref.watch(supabaseConfigProvider);
    final appInfo = _AppInfo.fromSupabaseConfig(supabaseConfig);

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
                                icon: Icons.flutter_dash_rounded,
                                title: 'Flutter',
                                subtitle: appInfo.flutterVersion,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AboutInfoTile(
                                icon: Icons.cloud_done_outlined,
                                title: 'Supabase Project',
                                subtitle: appInfo.supabaseProject,
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
                      SectionCard(
                        title: 'Links',
                        child: MotionStagger(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AboutLinkTile(
                                icon: Icons.privacy_tip_outlined,
                                title: 'Privacy Policy',
                                subtitle: 'How we handle your data',
                                onTap: () => _showLinkPlaceholder(
                                  context,
                                  'Privacy policy',
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AboutLinkTile(
                                icon: Icons.description_outlined,
                                title: 'Terms of Service',
                                subtitle: 'Legal information',
                                onTap: () =>
                                    _showLinkPlaceholder(context, 'Terms'),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AboutLinkTile(
                                icon: Icons.mail_outline_rounded,
                                title: 'Contact Support',
                                subtitle: 'Get help with PackLox',
                                onTap: () => _showLinkPlaceholder(
                                  context,
                                  'Contact support',
                                ),
                              ),
                            ),
                            AboutLinkTile(
                              icon: Icons.menu_book_outlined,
                              title: 'Documentation',
                              subtitle: 'Developer & API docs',
                              onTap: () => _showLinkPlaceholder(
                                context,
                                'Documentation',
                              ),
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

  void _showLinkPlaceholder(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$label will open here before release.')),
      );
  }
}

class _AppInfo {
  const _AppInfo({
    required this.version,
    required this.buildNumber,
    required this.flutterVersion,
    required this.supabaseProject,
    required this.storageLocation,
  });

  final String version;
  final String buildNumber;
  final String flutterVersion;
  final String supabaseProject;
  final String storageLocation;

  factory _AppInfo.fromSupabaseConfig(SupabaseConfig supabaseConfig) {
    return _AppInfo(
      version: '1.0.0',
      buildNumber: '1',
      flutterVersion: const String.fromEnvironment(
        'FLUTTER_VERSION',
        defaultValue: 'Flutter SDK',
      ),
      supabaseProject: _supabaseProjectLabel(supabaseConfig),
      storageLocation: supabaseConfig.isConfigured
          ? 'Local device + Supabase cloud'
          : 'Local device storage',
    );
  }

  static String _supabaseProjectLabel(SupabaseConfig config) {
    final host = config.baseUri?.host;
    if (!config.isConfigured || host == null || host.isEmpty) {
      return 'Not configured';
    }
    return host;
  }
}
