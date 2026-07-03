import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseConfigProvider = Provider<SupabaseConfig>((ref) {
  final config = SupabaseConfig.fromEnvironment();
  config.logStartupDiagnostics();
  return config;
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

  bool get hasUrl => url.isNotEmpty;

  bool get hasAnonKey => anonKey.isNotEmpty;

  int get anonKeyLength => anonKey.length;

  String get maskedAnonKeyLengthLabel {
    if (!hasAnonKey) {
      return '0';
    }
    return '$anonKeyLength characters';
  }

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

  void logStartupDiagnostics() {
    // Never log Supabase secrets. These booleans are enough to debug setup.
    debugPrint('[Supabase] enabled: $isEnabled');
    debugPrint('[Supabase] URL configured: $hasUrl');
    debugPrint('[Supabase] anon key configured: $hasAnonKey');
    debugPrint('[Supabase] anon key length: $anonKeyLength');
  }
}
