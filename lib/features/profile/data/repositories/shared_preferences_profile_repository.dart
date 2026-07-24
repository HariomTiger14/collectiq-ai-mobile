import 'dart:io';

import 'package:collectiq_ai/features/profile/domain/entities/collector_profile.dart';
import 'package:collectiq_ai/features/profile/domain/repositories/profile_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesProfileRepository implements ProfileRepository {
  const SharedPreferencesProfileRepository();

  static const _displayNameKey = 'packlox.profile.display_name';
  static const _avatarPathKey = 'packlox.profile.avatar_path';

  @override
  Future<CollectorProfile> loadProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final displayName = preferences.getString(_displayNameKey)?.trim();
    final avatarPath = preferences.getString(_avatarPathKey)?.trim();
    return CollectorProfile(
      displayName: displayName?.isNotEmpty == true
          ? displayName!
          : CollectorProfile.defaultDisplayName,
      avatarPath: avatarPath?.isNotEmpty == true ? avatarPath : null,
    );
  }

  @override
  Future<CollectorProfile> saveProfile(CollectorProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    final name = profile.displayName.trim().isEmpty
        ? CollectorProfile.defaultDisplayName
        : profile.displayName.trim();
    await preferences.setString(_displayNameKey, name);
    final avatarPath = profile.avatarPath?.trim();
    if (avatarPath == null || avatarPath.isEmpty) {
      await preferences.remove(_avatarPathKey);
    } else {
      await preferences.setString(_avatarPathKey, avatarPath);
    }
    return CollectorProfile(displayName: name, avatarPath: avatarPath);
  }

  @override
  Future<CollectorProfile> saveAvatarFromPath(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw StateError('Selected profile image could not be found.');
    }
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final profileDirectory = Directory(
      '${documentsDirectory.path}${Platform.pathSeparator}packlox_profile',
    );
    await profileDirectory.create(recursive: true);
    final outputPath =
        '${profileDirectory.path}${Platform.pathSeparator}profile_avatar.jpg';
    await sourceFile.copy(outputPath);
    final current = await loadProfile();
    return saveProfile(current.copyWith(avatarPath: outputPath));
  }
}
