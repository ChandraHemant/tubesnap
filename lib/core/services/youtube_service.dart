import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../models/video_model.dart';
import '../../models/quality_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// YouTube Service - Real implementation using youtube_explode_dart
/// Provides methods to fetch video metadata and stream manifests,
/// and to download a chosen stream with progress reporting.
class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;
  YouTubeService._internal();

  // Single YoutubeExplode instance reused across calls. Call dispose() when app exits.
  final YoutubeExplode _yt = YoutubeExplode();

  /// Validate YouTube URL
  bool isValidUrl(String url) {
    if (url.isEmpty) return false;

    final patterns = [
      // Standard watch URL
      RegExp(r'^(https?://)?(www\.)?youtube\.com/watch\?v=[\w-]{11}'),
      // Short URL
      RegExp(r'^(https?://)?(www\.)?youtu\.be/[\w-]{11}'),
      // Shorts URL
      RegExp(r'^(https?://)?(www\.)?youtube\.com/shorts/[\w-]{11}'),
      // Mobile URL
      RegExp(r'^(https?://)?(m\.)?youtube\.com/watch\?v=[\w-]{11}'),
      // Embed URL
      RegExp(r'^(https?://)?(www\.)?youtube\.com/embed/[\w-]{11}'),
    ];

    return patterns.any((pattern) => pattern.hasMatch(url));
  }

  /// Extract video ID from URL
  String? extractVideoId(String url) {
    if (!isValidUrl(url)) return null;

    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([\w-]{11})'),
      RegExp(r'youtu\.be/([\w-]{11})'),
      RegExp(r'youtube\.com/shorts/([\w-]{11})'),
      RegExp(r'youtube\.com/embed/([\w-]{11})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null && match.groupCount >= 1) {
        return match.group(1);
      }
    }
    return null;
  }

  /// Fetch video information and available qualities/audio streams
  /// Throws [YouTubeException] on failure.
  Future<VideoInfo> fetchVideoInfo(String url) async {
    if (!isValidUrl(url)) throw YouTubeException('Invalid YouTube URL');

    final videoId = extractVideoId(url);
    if (videoId == null) throw YouTubeException('Could not extract video ID');

    dynamic video;
    dynamic manifest;

    try {
      // Get video metadata
      video = await _yt.videos.get(videoId);

      // Get stream manifest
      manifest = await _yt.videos.streamsClient.getManifest(videoId);

      // helpers to safely extract dynamic properties (some youtube_explode_dart versions differ)
      int extractBitrate(dynamic bitrateObj) {
        if (bitrateObj == null) return 0;
        try {
          if (bitrateObj is int) return bitrateObj;
        } catch (_) {}
        try {
          final kbps = bitrateObj.kbps;
          if (kbps is int) return kbps;
        } catch (_) {}
        try {
          final bps = bitrateObj.bitsPerSecond ?? bitrateObj.bitsPer_second ?? bitrateObj.bits_per_second;
          if (bps is int) return (bps ~/ 1000);
        } catch (_) {}
        try {
          final alt = bitrateObj.bitRate ?? bitrateObj.bitrate;
          if (alt is int) return (alt ~/ 1000);
        } catch (_) {}
        return 0;
      }

      // video metadata extractors
      String _extractId(dynamic videoObj) {
        if (videoObj == null) return '';
        try { final idv = videoObj.id; if (idv != null) {
            try { final v = idv.value; if (v != null) return v.toString(); } catch (_) {}
            try { return idv.toString(); } catch (_) {}
          }} catch (_) {}
        try { final vid = videoObj.videoId; if (vid != null) return vid.toString(); } catch (_) {}
        return '';
      }

      String _extractAuthor(dynamic videoObj) {
        if (videoObj == null) return '';
        try { final a = videoObj.author; if (a != null) return a.toString(); } catch (_) {}
        try { final a = videoObj.owner; if (a != null) return a.toString(); } catch (_) {}
        try { final a = videoObj.uploader; if (a != null) return a.toString(); } catch (_) {}
        return '';
      }

      String _extractChannelId(dynamic videoObj) {
        if (videoObj == null) return '';
        try { final c = videoObj.authorChannelId; if (c != null) return c.toString(); } catch (_) {}
        try { final c = videoObj.channelId; if (c != null) return c.toString(); } catch (_) {}
        try { final c = videoObj.ownerId; if (c != null) return c.toString(); } catch (_) {}
        return '';
      }

      int _extractViewCount(dynamic videoObj) {
        try { final e = videoObj.engagement; if (e != null) { final v = e.viewCount; if (v is int) return v; } } catch (_) {}
        try { final v = videoObj.viewCount; if (v is int) return v; } catch (_) {}
        return 0;
      }

      int _extractLikeCount(dynamic videoObj) {
        try { final e = videoObj.engagement; if (e != null) { final v = e.likeCount; if (v is int) return v; } } catch (_) {}
        try { final v = videoObj.likeCount; if (v is int) return v; } catch (_) {}
        return 0;
      }

      bool _extractHasSubtitles(dynamic videoObj) {
        if (videoObj == null) return false;
        try {
          final c = videoObj.caption;
          if (c is String) return c.isNotEmpty;
          if (c is Iterable) return c.isNotEmpty;
        } catch (_) {}
        try { final hc = videoObj.hasCaptions; if (hc is bool) return hc; } catch (_) {}
        try { final caps = videoObj.captions; if (caps is Iterable) return caps.isNotEmpty; } catch (_) {}
        return false;
      }

      String _extractThumbnail(dynamic videoObj) {
        if (videoObj == null) return '';
        try {
          final t = videoObj.thumbnails;
          if (t != null) {
            try { final m = t.maxResUrl; if (m != null) return m.toString(); } catch (_) {}
            try { final m = t.maxRes?.url; if (m != null) return m.toString(); } catch (_) {}
            try { final h = t.highResUrl; if (h != null) return h.toString(); } catch (_) {}
            try { final s = t.standardResUrl; if (s != null) return s.toString(); } catch (_) {}
            try { final any = t.first; if (any != null) return any.toString(); } catch (_) {}
          }
        } catch (_) {}
        return '';
      }

      String _extractResolution(dynamic s) {
        if (s == null) return '';
        try {
          final q = s.qualityLabel;
          if (q != null) return q.toString();
        } catch (_) {}
        try {
          final vq = s.videoQuality;
          if (vq != null) {
            try {
              final lab = vq.label;
              if (lab != null) return lab.toString();
            } catch (_) {}
            try {
              final h = vq.height;
              if (h != null) return '${h}p';
            } catch (_) {}
          }
        } catch (_) {}
        try {
          final h2 = s.height ?? s.resolutionHeight;
          if (h2 != null) return '${h2}p';
        } catch (_) {}
        return '';
      }

      int _extractFps(dynamic s) {
        if (s == null) return 0;
        try { final f = s.videoFrameRate; if (f is int) return f; } catch (_) {}
        try { final f = s.framerate; if (f is int) return f; } catch (_) {}
        try { final f = s.frameRate; if (f is int) return f; } catch (_) {}
        return 0;
      }

      int _extractSize(dynamic s) {
        if (s == null) return 0;
        try { final size = s.size?.totalBytes ?? s.sizeInBytes ?? s.totalBytes; if (size is int) return size; } catch (_) {}
        return 0;
      }

      String _extractUrl(dynamic s) {
        if (s == null) return '';
        try { final u = s.url; if (u != null) return u.toString(); } catch (_) {}
        try { final u = s.uri; if (u != null) return u.toString(); } catch (_) {}
        try { final u = s.downloadUrl; if (u != null) return u.toString(); } catch (_) {}
        return '';
      }

      String _extractCodec(dynamic s) {
        if (s == null) return '';
        try { final c = s.codec; if (c != null) return c.toString(); } catch (_) {}
        try { final c = s.codec?.name; if (c != null) return c.toString(); } catch (_) {}
        return '';
      }

      // Map muxed streams (audio+video combined) - these are usually lower quality
      final muxed = manifest.muxed ?? <dynamic>[];
      debugPrint('fetchVideoInfo: Found ${muxed.length} muxed streams (with audio)');

      // Map video-only streams - YouTube provides higher qualities here (720p+)
      final videoOnly = manifest.videoOnly ?? <dynamic>[];
      debugPrint('fetchVideoInfo: Found ${videoOnly.length} video-only streams');

      // Combine both muxed and video-only streams to get all available qualities
      final List<QualityOption> qualities = [];

      // Add muxed streams (these have audio built-in)
      for (final s in muxed) {
        try {
          final dyn = s as dynamic;
          final resolution = _extractResolution(dyn);
          final size = _extractSize(dyn);
          final urlStr = _extractUrl(dyn);
          final bitrate = extractBitrate(dyn.bitrate ?? dyn);
          final fps = _extractFps(dyn);
          final codec = _extractCodec(dyn);

          // Determine file extension based on codec
          String extension = 'mp4';
          final codecLower = codec.toLowerCase();
          if (codecLower.contains('webm') || codecLower.contains('vp9') || codecLower.contains('vp8')) {
            extension = 'webm';
          }

          qualities.add(QualityOption(
            resolution: resolution.isNotEmpty ? resolution : 'unknown',
            label: resolution.isNotEmpty ? resolution : 'unknown',
            labelHi: resolution.isNotEmpty ? resolution : 'unknown',
            fileSize: size,
            extension: extension,
            downloadUrl: urlStr,
            bitrate: bitrate,
            fps: fps,
            codec: codec,
          ));
          debugPrint('  Added muxed quality: $resolution (${size} bytes)');
        } catch (e) {
          debugPrint('  Error processing muxed stream: $e');
        }
      }

      // Add video-only streams (for higher qualities like 720p, 1080p, 4K)
      // Note: These will need separate audio, but we can still offer them
      for (final s in videoOnly) {
        try {
          final dyn = s as dynamic;
          final resolution = _extractResolution(dyn);
          final size = _extractSize(dyn);
          final urlStr = _extractUrl(dyn);
          final bitrate = extractBitrate(dyn.bitrate ?? dyn);
          final fps = _extractFps(dyn);
          final codec = _extractCodec(dyn);

          // Skip if we already have this resolution from muxed streams
          final alreadyExists = qualities.any((q) => q.resolution == resolution);
          if (alreadyExists) {
            debugPrint('  Skipping video-only $resolution (already have muxed version)');
            continue;
          }

          // Determine file extension based on codec
          String extension = 'mp4';
          final codecLower = codec.toLowerCase();
          if (codecLower.contains('webm') || codecLower.contains('vp9') || codecLower.contains('vp8')) {
            extension = 'webm';
          }

          qualities.add(QualityOption(
            resolution: resolution.isNotEmpty ? resolution : 'unknown',
            label: resolution.isNotEmpty ? resolution : 'unknown',
            labelHi: resolution.isNotEmpty ? resolution : 'unknown',
            fileSize: size,
            extension: extension,
            downloadUrl: urlStr,
            bitrate: bitrate,
            fps: fps,
            codec: codec,
          ));
          debugPrint('  Added video-only quality: $resolution (${size} bytes)');
        } catch (e) {
          debugPrint('  Error processing video-only stream: $e');
        }
      }

      // Sort qualities by resolution (highest first)
      qualities.sort((a, b) {
        final aRes = int.tryParse(a.resolution.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final bRes = int.tryParse(b.resolution.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return bRes.compareTo(aRes); // Descending order
      });

      debugPrint('fetchVideoInfo: Total ${qualities.length} qualities available');
      for (final q in qualities) {
        debugPrint('  - ${q.resolution} (${q.codec}, ${q.fps}fps, ${(q.fileSize / 1024 / 1024).toStringAsFixed(1)}MB)');
      }

      // Map audio-only streams
      final audioOnly = manifest.audioOnly ?? <dynamic>[];
      final List<AudioQualityOption> audioQualities = audioOnly.map<AudioQualityOption>((s) {
        final dyn = s as dynamic;
        final bitrateVal = extractBitrate(dyn.bitrate ?? dyn);
        final bitrateStr = bitrateVal > 0 ? '${bitrateVal}kbps' : '';
        final size = _extractSize(dyn);
        final urlStr = _extractUrl(dyn);
        final label = bitrateStr.isNotEmpty ? bitrateStr : 'audio';
        final codec = _extractCodec(dyn);

        // Determine audio extension based on codec
        String extension = 'mp4'; // YouTube usually serves audio in mp4/m4a container
        final codecLower = codec.toLowerCase();
        if (codecLower.contains('opus') || codecLower.contains('webm')) {
          extension = 'webm';
        } else if (codecLower.contains('mp4a') || codecLower.contains('aac')) {
          extension = 'm4a';
        }

        return AudioQualityOption(
          bitrate: bitrateStr,
          label: label,
          labelHi: label,
          fileSize: size,
          extension: extension,
          downloadUrl: urlStr,
        );
      }).toList();

      return VideoInfo(
        id: _extractId(video),
        title: video.title ?? '',
        channelName: _extractAuthor(video),
        channelId: _extractChannelId(video),
        thumbnailUrl: _extractThumbnail(video),
        description: video.description ?? '',
        duration: video.duration ?? Duration.zero,
        viewCount: _extractViewCount(video),
        likeCount: _extractLikeCount(video),
        publishedAt: video.publishDate ?? DateTime.now(),
        qualities: qualities,
        audioQualities: audioQualities,
        isLive: video.isLive,
        hasSubtitles: _extractHasSubtitles(video),
      );
    } catch (e, st) {
      // Provide detailed debug output for the user to copy/paste
      try {
        debugPrint('--- DEBUG: fetchVideoInfo failed ---');
        debugPrint('URL: $url');
        debugPrint('videoId: $videoId');
        debugPrint('Exception: $e');
        debugPrint('StackTrace:\n$st');
        if (video != null) {
          try { debugPrint('Video.runtimeType: ${video.runtimeType}'); } catch (_) {}
          try { debugPrint('Video.toString(): ${video.toString()}'); } catch (_) {}
        }
        if (manifest != null) {
          try { debugPrint('Manifest.runtimeType: ${manifest.runtimeType}'); } catch (_) {}
          try { debugPrint('Muxed count: ${manifest.muxed.length}'); } catch (_) {}
          try { debugPrint('AudioOnly count: ${manifest.audioOnly.length}'); } catch (_) {}
          // Print first stream objects for debugging (safe)
          try {
            if (manifest.muxed != null && manifest.muxed.isNotEmpty) {
              final m0 = manifest.muxed.first;
              try { debugPrint('First muxed.runtimeType: ${m0.runtimeType}'); } catch (_) {}
              try { debugPrint('First muxed.toString(): ${m0.toString()}'); } catch (_) {}
            }
          } catch (_) {}
          try {
            if (manifest.audioOnly != null && manifest.audioOnly.isNotEmpty) {
              final a0 = manifest.audioOnly.first;
              try { debugPrint('First audioOnly.runtimeType: ${a0.runtimeType}'); } catch (_) {}
              try { debugPrint('First audioOnly.toString(): ${a0.toString()}'); } catch (_) {}
            }
          } catch (_) {}
        }
        debugPrint('--- END DEBUG ---');
      } catch (_) {}

      throw YouTubeException('Failed to fetch video: ${e.toString()}');
    }
  }

  /// Download a stream by URL
  /// Writes to [targetFile] and reports progress via [onProgress]
  /// If [cancelToken] is canceled the partial file will be removed and an exception thrown.
  Future<void> downloadStream({
    required String videoId,
    required String streamUrl,
    required File targetFile,
    void Function(int downloadedBytes, int totalBytes)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      debugPrint('youtube_service.downloadStream: videoId=$videoId');

      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      debugPrint('  Streams: ${manifest.muxed.length} muxed, ${manifest.videoOnly.length} video-only, ${manifest.audioOnly.length} audio');

      // Find stream by URL match
      StreamInfo? chosen;
      String chosenInfo = '';

      // Collect all streams
      final List<StreamInfo> allStreams = [
        ...manifest.muxed,
        ...manifest.videoOnly,
        ...manifest.audioOnly,
      ];

      // Try to match by URL
      for (final s in allStreams) {
        try {
          final sUrl = s.url.toString();
          if (sUrl == streamUrl) {
            chosen = s;
            if (s is MuxedStreamInfo) {
              chosenInfo = s.qualityLabel;
            } else if (s is VideoOnlyStreamInfo) {
              chosenInfo = '${s.qualityLabel} (video-only)';
            } else if (s is AudioOnlyStreamInfo) {
              chosenInfo = '${s.bitrate.bitsPerSecond ~/ 1000}kbps audio';
            }
            break;
          }
        } catch (_) {}
      }

      // If no exact URL match, use first muxed or any available
      if (chosen == null) {
        debugPrint('  No URL match found, using best available stream');
        if (manifest.muxed.isNotEmpty) {
          // Sort by quality and pick highest
          final sorted = manifest.muxed.toList()
            ..sort((a, b) {
              final aHeight = int.tryParse(a.qualityLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final bHeight = int.tryParse(b.qualityLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return bHeight.compareTo(aHeight);
            });
          chosen = sorted.first;
          chosenInfo = sorted.first.qualityLabel;
        } else if (manifest.videoOnly.isNotEmpty) {
          chosen = manifest.videoOnly.first;
          chosenInfo = manifest.videoOnly.first.qualityLabel;
        } else if (manifest.audioOnly.isNotEmpty) {
          chosen = manifest.audioOnly.first;
          chosenInfo = '${manifest.audioOnly.first.bitrate.bitsPerSecond ~/ 1000}kbps audio';
        }
      }

      if (chosen == null) {
        throw YouTubeException('No streams available');
      }

      debugPrint('  Selected: $chosenInfo (${chosen.size.totalBytes} bytes)');

      final stream = _yt.videos.streamsClient.get(chosen);
      final total = chosen.size.totalBytes;
      int downloaded = 0;
      final sink = targetFile.openWrite();

      try {
        await for (final chunk in stream) {
          if (cancelToken?.isCanceled == true) {
            await sink.flush();
            await sink.close();
            if (await targetFile.exists()) await targetFile.delete();
            throw YouTubeException('Download cancelled');
          }
          downloaded += chunk.length;
          sink.add(chunk);
          if (onProgress != null) onProgress(downloaded, total);
        }

        await sink.flush();
        await sink.close();

        final finalSize = await targetFile.length();
        debugPrint('youtube_service: Done - $finalSize bytes');

        if (finalSize == 0) throw YouTubeException('Downloaded file is empty');
      } catch (e) {
        try { await sink.close(); } catch (_) {}
        rethrow;
      }
    } catch (e) {
      debugPrint('youtube_service.downloadStream ERROR: $e');
      rethrow;
    }
  }

  /// Get video thumbnail URL
  String getThumbnailUrl(String videoId, {ThumbnailQuality quality = ThumbnailQuality.maxres}) {
    final qualityStr = quality.toString().split('.').last;
    return 'https://img.youtube.com/vi/$videoId/${qualityStr}default.jpg';
  }

  /// Get all thumbnail URLs
  Map<ThumbnailQuality, String> getAllThumbnails(String videoId) {
    return {
      ThumbnailQuality.default_: getThumbnailUrl(videoId, quality: ThumbnailQuality.default_),
      ThumbnailQuality.mq: getThumbnailUrl(videoId, quality: ThumbnailQuality.mq),
      ThumbnailQuality.hq: getThumbnailUrl(videoId, quality: ThumbnailQuality.hq),
      ThumbnailQuality.sd: getThumbnailUrl(videoId, quality: ThumbnailQuality.sd),
      ThumbnailQuality.maxres: getThumbnailUrl(videoId, quality: ThumbnailQuality.maxres),
    };
  }

  /// Resolve a usable stream URL for a video by matching resolution or bitrate.
  Future<String?> resolveStreamUrl(String videoId, {String? resolution, int? bitrateKbps, bool audioOnly = false}) async {
    try {
      debugPrint('youtube_service.resolveStreamUrl: videoId=$videoId, resolution=$resolution, bitrate=$bitrateKbps, audioOnly=$audioOnly');

      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final List<dynamic> candidates = [];

      if (audioOnly) {
        candidates.addAll(manifest.audioOnly);
        debugPrint('  Audio-only streams available: ${manifest.audioOnly.length}');
      } else {
        // Prefer muxed streams (has audio), then video-only for higher qualities
        candidates.addAll(manifest.muxed);
        candidates.addAll(manifest.videoOnly);
        debugPrint('  Muxed streams available: ${manifest.muxed.length}');
        debugPrint('  Video-only streams available: ${manifest.videoOnly.length}');
      }

      if (candidates.isEmpty) {
        debugPrint('  ✗ NO streams available!');
        return null;
      }

      // Extract target resolution number (e.g., "720p" -> 720, "1080p60" -> 1080)
      int? targetHeight;
      if (resolution != null && resolution.isNotEmpty) {
        final match = RegExp(r'(\d+)p').firstMatch(resolution);
        if (match != null) {
          targetHeight = int.tryParse(match.group(1)!);
        }
      }

      debugPrint('  Target height: $targetHeight');

      // Score streams by closeness to target resolution
      dynamic bestMatch;
      int bestScore = -1;
      String bestLabel = '';

      for (final s in candidates) {
        try {
          final u = s.url?.toString() ?? s.uri?.toString() ?? s.downloadUrl?.toString();
          if (u == null || u.isEmpty) continue;

          final qlabel = (s.qualityLabel ?? s.videoQuality?.label ?? '')?.toString() ?? '';

          // Extract height from quality label
          int streamHeight = 0;
          final heightMatch = RegExp(r'(\d+)p').firstMatch(qlabel);
          if (heightMatch != null) {
            streamHeight = int.tryParse(heightMatch.group(1)!) ?? 0;
          }

          // For audio, match by bitrate
          if (audioOnly) {
            final kbps = (s.bitrate?.kbps ?? s.bitrate ?? s.bitrateKbps ?? s.averageBitrate ?? 0) as dynamic;
            final kb = kbps is int ? kbps : (kbps is double ? kbps.toInt() : 0);

            if (bitrateKbps != null) {
              // Prefer closest bitrate
              final diff = (kb - bitrateKbps).abs();
              final score = 10000 - diff; // Higher score = better match
              if (score > bestScore) {
                bestScore = score;
                bestMatch = s;
                bestLabel = '${kb}kbps';
              }
            } else if (bestMatch == null) {
              // Just pick highest bitrate audio
              if (kb > bestScore) {
                bestScore = kb;
                bestMatch = s;
                bestLabel = '${kb}kbps';
              }
            }
          } else {
            // For video, match by resolution height
            if (targetHeight != null && streamHeight > 0) {
              // Exact match gets highest score
              if (streamHeight == targetHeight) {
                final score = 100000 + streamHeight;
                if (score > bestScore) {
                  bestScore = score;
                  bestMatch = s;
                  bestLabel = qlabel;
                  debugPrint('  Found EXACT match: $qlabel (height=$streamHeight)');
                }
              } else if (streamHeight <= targetHeight) {
                // Prefer closest lower resolution
                final score = streamHeight;
                if (score > bestScore) {
                  bestScore = score;
                  bestMatch = s;
                  bestLabel = qlabel;
                }
              }
            } else if (streamHeight > 0) {
              // No target, prefer highest quality
              if (streamHeight > bestScore) {
                bestScore = streamHeight;
                bestMatch = s;
                bestLabel = qlabel;
              }
            }
          }
        } catch (e) {
          debugPrint('  Warning: Error checking stream: $e');
        }
      }

      // Return best match if found
      if (bestMatch != null) {
        try {
          final u = bestMatch.url?.toString() ?? bestMatch.uri?.toString() ?? bestMatch.downloadUrl?.toString();
          if (u != null && u.isNotEmpty) {
            debugPrint('  ✓ MATCHED: $bestLabel (score=$bestScore)');
            return u.toString();
          }
        } catch (_) {}
      }

      // Fallback: first muxed stream (has audio)
      debugPrint('  No match found, using fallback...');
      if (!audioOnly && manifest.muxed.isNotEmpty) {
        try {
          final s = manifest.muxed.first;
          final u = s.url.toString();
          if (u.isNotEmpty) {
            final qlabel = s.qualityLabel;
            debugPrint('  ✓ FALLBACK to first muxed stream: $qlabel');
            return u;
          }
        } catch (e) {
          debugPrint('  Warning: Error getting muxed stream: $e');
        }
      }

      // Last resort: any stream
      for (final s in candidates) {
        try {
          final u = s.url?.toString() ?? s.uri?.toString() ?? s.downloadUrl?.toString();
          if (u != null && u.isNotEmpty) {
            debugPrint('  ✓ FALLBACK to any available stream');
            return u.toString();
          }
        } catch (_) {}
      }

      debugPrint('  ✗ Could not find any valid stream URL');
    } catch (e, st) {
      debugPrint('youtube_service.resolveStreamUrl FAILED: $e');
      debugPrint('Stack trace: $st');
    }
    return null;
  }

  /// Close underlying client - call on app exit to free resources
  void dispose() => _yt.close();
}

/// Thumbnail quality options
enum ThumbnailQuality {
  default_, // 120x90
  mq, // 320x180
  hq, // 480x360
  sd, // 640x480
  maxres, // 1280x720
}

/// Lightweight cancel token
class CancelToken {
  bool _cancelled = false;
  bool get isCanceled => _cancelled;
  void cancel() => _cancelled = true;
}

/// YouTube exception
class YouTubeException implements Exception {
  final String message;
  YouTubeException(this.message);

  @override
  String toString() => message;
}