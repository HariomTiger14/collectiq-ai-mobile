import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';

abstract class ProfileRepository {
  Future<CollectorProfile> loadProfile();

  Future<CollectorProfile> saveProfile(CollectorProfile profile);

  Future<CollectorProfile> saveAvatarFromPath(String sourcePath);
}
