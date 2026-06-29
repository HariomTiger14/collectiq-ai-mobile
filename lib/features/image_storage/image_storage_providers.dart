import 'package:collectiq_ai/core/supabase/supabase_config.dart';
import 'package:collectiq_ai/core/supabase/supabase_service.dart';
import 'package:collectiq_ai/features/image_storage/data/repositories/supabase_image_storage_repository.dart';
import 'package:collectiq_ai/features/image_storage/domain/repositories/image_storage_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final imageStorageRepositoryProvider = Provider<ImageStorageRepository>((ref) {
  return SupabaseImageStorageRepository(
    config: ref.watch(supabaseConfigProvider),
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});
