enum ImageUploadTaskStatus { pending, uploading, uploaded, failed }

class ImageUploadTask {
  const ImageUploadTask({
    required this.id,
    required this.collectibleId,
    required this.localPath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.storagePath,
    this.publicUrl,
    this.attemptCount = 0,
    this.lastError,
    this.nextRetryAt,
    this.progress = 0,
  });

  final String id;
  final String collectibleId;
  final String localPath;
  final ImageUploadTaskStatus status;
  final String? storagePath;
  final String? publicUrl;
  final int attemptCount;
  final String? lastError;
  final DateTime? nextRetryAt;
  final double progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get canUpload {
    if (status == ImageUploadTaskStatus.uploaded ||
        status == ImageUploadTaskStatus.uploading) {
      return false;
    }

    final retryAt = nextRetryAt;
    return retryAt == null || !retryAt.isAfter(DateTime.now());
  }

  ImageUploadTask copyWith({
    ImageUploadTaskStatus? status,
    String? storagePath,
    String? publicUrl,
    int? attemptCount,
    String? lastError,
    DateTime? nextRetryAt,
    double? progress,
    DateTime? updatedAt,
    bool clearLastError = false,
    bool clearNextRetryAt = false,
  }) {
    return ImageUploadTask(
      id: id,
      collectibleId: collectibleId,
      localPath: localPath,
      status: status ?? this.status,
      storagePath: storagePath ?? this.storagePath,
      publicUrl: publicUrl ?? this.publicUrl,
      attemptCount: attemptCount ?? this.attemptCount,
      lastError: clearLastError ? null : lastError ?? this.lastError,
      nextRetryAt: clearNextRetryAt ? null : nextRetryAt ?? this.nextRetryAt,
      progress: progress ?? this.progress,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ImageUploadTask.fromJson(Map<String, dynamic> json) {
    return ImageUploadTask(
      id: json['id'] as String,
      collectibleId: json['collectibleId'] as String,
      localPath: json['localPath'] as String,
      status: ImageUploadTaskStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ImageUploadTaskStatus.pending,
      ),
      storagePath: _optionalString(json['storagePath']),
      publicUrl: _optionalString(json['publicUrl']),
      attemptCount: (json['attemptCount'] as num?)?.toInt() ?? 0,
      lastError: _optionalString(json['lastError']),
      nextRetryAt: json['nextRetryAt'] is String
          ? DateTime.tryParse(json['nextRetryAt'] as String)
          : null,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collectibleId': collectibleId,
      'localPath': localPath,
      'status': status.name,
      'storagePath': storagePath,
      'publicUrl': publicUrl,
      'attemptCount': attemptCount,
      'lastError': lastError,
      'nextRetryAt': nextRetryAt?.toIso8601String(),
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

String? _optionalString(Object? value) {
  if (value is! String) {
    return null;
  }

  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}
