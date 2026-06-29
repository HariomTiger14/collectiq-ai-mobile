import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseConfigProvider = Provider<SupabaseConfig>((ref) {
  return SupabaseConfig.fromEnvironment();
});

class SupabaseConfig {
  const SupabaseConfig({
    required this.url,
    required this.anonKey,
    required this.isEnabled,
  });

  final String url;
  final String anonKey;
  final bool isEnabled;

  bool get isConfigured => isEnabled && url.isNotEmpty && anonKey.isNotEmpty;

  Uri? get baseUri {
    if (url.isEmpty) {
      return null;
    }

    return Uri.tryParse(url);
  }

  factory SupabaseConfig.fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    const enabled = bool.fromEnvironment('SUPABASE_ENABLED');

    return SupabaseConfig(url: url, anonKey: anonKey, isEnabled: enabled);
  }
}
