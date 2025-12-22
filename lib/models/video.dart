// lib/models/video.dart

class Video {
  final String? emoji;
  final String? description;
  final String? weekId;
  final String? storageDownloadUrl;
  final String? uploadStatus;

  Video({
    this.emoji,
    this.description,
    this.weekId,
    this.storageDownloadUrl,
    this.uploadStatus,
  });

  factory Video.fromMap(Map<String, dynamic> map) {
    return Video(
      emoji: map['emoji'] as String?,
      description: map['description'] as String?,
      weekId: map['weekId'] as String?,
      storageDownloadUrl: map['storageDownloadUrl'] as String?,
      uploadStatus: map['uploadStatus'] as String?,
    );
  }
}

