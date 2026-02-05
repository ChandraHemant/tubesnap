import 'quality_model.dart';

/// Video Information Model
class VideoInfo {
  final String id;
  final String title;
  final String channelName;
  final String channelId;
  final String thumbnailUrl;
  final String description;
  final Duration duration;
  final int viewCount;
  final int likeCount;
  final DateTime publishedAt;
  final List<QualityOption> qualities;
  final List<AudioQualityOption> audioQualities;
  final bool isLive;
  final bool hasSubtitles;

  VideoInfo({
    required this.id,
    required this.title,
    required this.channelName,
    required this.channelId,
    required this.thumbnailUrl,
    required this.description,
    required this.duration,
    required this.viewCount,
    this.likeCount = 0,
    required this.publishedAt,
    required this.qualities,
    required this.audioQualities,
    this.isLive = false,
    this.hasSubtitles = false,
  });

  /// Get formatted duration
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get formatted view count
  String get formattedViews {
    if (viewCount < 1000) return viewCount.toString();
    if (viewCount < 1000000) return '${(viewCount / 1000).toStringAsFixed(1)}K';
    if (viewCount < 1000000000) return '${(viewCount / 1000000).toStringAsFixed(1)}M';
    return '${(viewCount / 1000000000).toStringAsFixed(1)}B';
  }

  /// Get high quality thumbnail
  String get hqThumbnail => 'https://img.youtube.com/vi/$id/maxresdefault.jpg';

  /// Get medium quality thumbnail
  String get mqThumbnail => 'https://img.youtube.com/vi/$id/hqdefault.jpg';

  /// Create from JSON (for API response)
  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      channelName: json['channelName'] ?? '',
      channelId: json['channelId'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      description: json['description'] ?? '',
      duration: Duration(seconds: json['duration'] ?? 0),
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      qualities: (json['qualities'] as List?)
          ?.map((q) => QualityOption.fromJson(q))
          .toList() ??
          [],
      audioQualities: (json['audioQualities'] as List?)
          ?.map((q) => AudioQualityOption.fromJson(q))
          .toList() ??
          [],
      isLive: json['isLive'] ?? false,
      hasSubtitles: json['hasSubtitles'] ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'channelName': channelName,
      'channelId': channelId,
      'thumbnailUrl': thumbnailUrl,
      'description': description,
      'duration': duration.inSeconds,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'publishedAt': publishedAt.toIso8601String(),
      'qualities': qualities.map((q) => q.toJson()).toList(),
      'audioQualities': audioQualities.map((q) => q.toJson()).toList(),
      'isLive': isLive,
      'hasSubtitles': hasSubtitles,
    };
  }

  /// Create dummy video for testing
  factory VideoInfo.dummy() {
    return VideoInfo(
      id: 'dQw4w9WgXcQ',
      title: 'Flutter Complete Course 2024 - Build Amazing Apps',
      channelName: 'Flutter Academy',
      channelId: 'UC123456',
      thumbnailUrl: 'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      description: 'Learn Flutter from scratch...',
      duration: const Duration(hours: 2, minutes: 34, seconds: 56),
      viewCount: 1250000,
      likeCount: 45000,
      publishedAt: DateTime.now().subtract(const Duration(days: 30)),
      qualities: QualityOption.allQualities,
      audioQualities: AudioQualityOption.allQualities,
    );
  }
}