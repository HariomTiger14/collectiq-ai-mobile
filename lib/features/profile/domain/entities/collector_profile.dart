class CollectorProfile {
  const CollectorProfile({required this.displayName, this.avatarPath});

  static const defaultDisplayName = 'PackLox Collector';

  final String displayName;
  final String? avatarPath;

  CollectorProfile copyWith({String? displayName, String? avatarPath}) {
    return CollectorProfile(
      displayName: displayName ?? this.displayName,
      avatarPath: avatarPath ?? this.avatarPath,
    );
  }
}
