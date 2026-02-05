/// Download Status Enum
enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
  cancelled,
}

/// Download Task Model
class DownloadTask {
  final String id;
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String quality;
  final int fileSize;
  final String filePath;
  final String downloadUrl;
  DownloadStatus status;
  double progress;
  final DateTime createdAt;
  DateTime? completedAt;
  String? errorMessage;
  int downloadedBytes;
  String? speed;
  String? eta;

  DownloadTask({
    required this.id,
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.quality,
    required this.fileSize,
    required this.filePath,
    required this.downloadUrl,
    required this.status,
    required this.progress,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.downloadedBytes = 0,
    this.speed,
    this.eta,
  });

  /// Get formatted file size
  String get formattedSize {
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(0)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Get progress percentage
  int get progressPercent => (progress * 100).toInt();

  /// Get status label
  String get statusLabel {
    switch (status) {
      case DownloadStatus.queued:
        return 'Queued';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      case DownloadStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get status label in Hindi
  String get statusLabelHi {
    switch (status) {
      case DownloadStatus.queued:
        return 'कतार में';
      case DownloadStatus.downloading:
        return 'डाउनलोड हो रहा है';
      case DownloadStatus.paused:
        return 'रोका गया';
      case DownloadStatus.completed:
        return 'पूर्ण';
      case DownloadStatus.failed:
        return 'विफल';
      case DownloadStatus.cancelled:
        return 'रद्द';
    }
  }

  /// Check if download is active
  bool get isActive => status == DownloadStatus.downloading || status == DownloadStatus.queued;

  /// Copy with
  DownloadTask copyWith({
    String? id,
    String? videoId,
    String? title,
    String? thumbnailUrl,
    String? quality,
    int? fileSize,
    String? filePath,
    String? downloadUrl,
    DownloadStatus? status,
    double? progress,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    int? downloadedBytes,
    String? speed,
    String? eta,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      quality: quality ?? this.quality,
      fileSize: fileSize ?? this.fileSize,
      filePath: filePath ?? this.filePath,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      speed: speed ?? this.speed,
      eta: eta ?? this.eta,
    );
  }

  /// From JSON
  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      id: json['id'] ?? '',
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      quality: json['quality'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      filePath: json['filePath'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      status: DownloadStatus.values[json['status'] ?? 0],
      progress: (json['progress'] ?? 0).toDouble(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
      errorMessage: json['errorMessage'],
      downloadedBytes: json['downloadedBytes'] ?? 0,
      speed: json['speed'],
      eta: json['eta'],
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'videoId': videoId,
      'title': title,
      'thumbnailUrl': thumbnailUrl,
      'quality': quality,
      'fileSize': fileSize,
      'filePath': filePath,
      'downloadUrl': downloadUrl,
      'status': status.index,
      'progress': progress,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'downloadedBytes': downloadedBytes,
      'speed': speed,
      'eta': eta,
    };
  }
}