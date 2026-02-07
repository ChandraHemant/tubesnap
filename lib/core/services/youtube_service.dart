import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../../models/video_model.dart';
import '../../models/quality_model.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

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

  // Helper to extract kbps from various stream objects safely
  int _getStreamKbps(dynamic s) {
    try {
      final b = s.bitrate;
      if (b != null) {
        try {
          // bitsPerSecond is common
          final bps = b.bitsPerSecond ?? b.bitRate ?? b.bitrate;
          if (bps is int) return (bps ~/ 1000);
        } catch (_) {}
        try {
          final kb = b.kbps;
          if (kb is int) return kb;
        } catch (_) {}
      }
      // Try other common fallbacks
      try {
        final avg = s.averageBitrate;
        if (avg is int) return (avg ~/ 1000);
      } catch (_) {}
      try {
        final kb2 = s.bitrateKbps;
        if (kb2 is int) return kb2;
      } catch (_) {}
    } catch (_) {}
    return 0;
  }

  // Helper to extract resolution label from stream safely
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

  /// Fetch video information and available qualities/audio streams
  /// Throws [YouTubeException] on failure.
  Future<VideoInfo> fetchVideoInfo(String url) async {
    if (!isValidUrl(url)) throw YouTubeServiceException('Invalid YouTube URL');

    final videoId = extractVideoId(url);
    if (videoId == null) throw YouTubeServiceException('Could not extract video ID');

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

      // Ensure a MAX (Maximum Quality / No Compression) option is present and points to the highest available stream.
      try {
        final hasMax = qualities.any((q) => q.resolution == 'MAX');
        if (!hasMax && qualities.isNotEmpty) {
          // Determine top stream and its URL
          String topUrl = '';
          String topExt = qualities.first.extension;
          int topSize = qualities.first.fileSize;
          // Prefer highest video-only stream
          if (videoOnly.isNotEmpty) {
            final vlist = videoOnly.toList();
            vlist.sort((a, b) {
              final ah = int.tryParse(_extractResolution(a).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final bh = int.tryParse(_extractResolution(b).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return bh.compareTo(ah);
            });
            final top = vlist.first;
            try { topUrl = _extractUrl(top); } catch (_) {}
            try { topExt = _extractCodec(top).toLowerCase().contains('vp9') || _extractCodec(top).toLowerCase().contains('vp8') ? 'webm' : topExt; } catch (_) {}
            try { topSize = _extractSize(top); } catch (_) {}
          } else if (muxed.isNotEmpty) {
            final mlist = muxed.toList();
            mlist.sort((a, b) {
              final ah = int.tryParse((a.qualityLabel ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final bh = int.tryParse((b.qualityLabel ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return bh.compareTo(ah);
            });
            final top = mlist.first;
            try { topUrl = _extractUrl(top); } catch (_) {}
            try { topExt = _extractCodec(top).toLowerCase().contains('vp9') || _extractCodec(top).toLowerCase().contains('vp8') ? 'webm' : topExt; } catch (_) {}
            try { topSize = _extractSize(top); } catch (_) {}
          }

          final estimatedSize = topSize > 0 ? (topSize * 1.1).toInt() : (2000 * 1024 * 1024);
          final maxOption = QualityOption(
            resolution: 'MAX',
            label: 'Maximum Quality (No Compression)',
            labelHi: 'अधिकतम गुणवत्ता (कोई संपीड़न नहीं)',
            fileSize: estimatedSize,
            extension: topExt,
            downloadUrl: topUrl,
            bitrate: qualities.first.bitrate,
            fps: qualities.first.fps,
            codec: qualities.first.codec,
          );
          qualities.insert(0, maxOption);
        }
      } catch (_) {}

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

      throw YouTubeServiceException('Failed to fetch video: ${e.toString()}');
    }
  }

  /// Download a stream by URL
  /// Writes to [targetFile] and reports progress via [onProgress]
  /// If [cancelToken] is canceled the partial file will be removed and an exception thrown.
  Future<String> downloadStream({
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
        throw YouTubeServiceException('No streams available');
      }

      debugPrint('  Selected: $chosenInfo (${chosen.size.totalBytes} bytes)');

      // If chosen is video-only, download a matching audio stream and mux them
      if (chosen is VideoOnlyStreamInfo) {
        debugPrint('youtube_service: chosen stream is video-only; will download audio and mux');

        // Pick best audio-only stream (highest bitrate)
        AudioOnlyStreamInfo? bestAudio;
        try {
          final audioList = manifest.audioOnly.toList();
          audioList.sort((a, b) {
            final aRate = _getStreamKbps(a);
            final bRate = _getStreamKbps(b);
            return bRate.compareTo(aRate);
          });
          if (audioList.isNotEmpty) bestAudio = audioList.first;
        } catch (_) {}

        if (bestAudio == null) {
          throw YouTubeServiceException('No audio stream available to mux with video-only stream');
        }

        // Prepare temp files
        final tmpDir = targetFile.parent;
        final videoTmp = File('${tmpDir.path}/${DateTime.now().millisecondsSinceEpoch}_video.tmp');
        final audioTmp = File('${tmpDir.path}/${DateTime.now().millisecondsSinceEpoch}_audio.tmp');

        // Download video-only to videoTmp
        final videoStream = _yt.videos.streamsClient.get(chosen);
        final videoSink = videoTmp.openWrite();
        int videoDownloaded = 0;
        final videoTotal = chosen.size.totalBytes;
        try {
          await for (final chunk in videoStream) {
            if (cancelToken?.isCanceled == true) {
              await videoSink.flush();
              await videoSink.close();
              if (await videoTmp.exists()) await videoTmp.delete();
              if (await audioTmp.exists()) await audioTmp.delete();
              throw YouTubeServiceException('Download cancelled');
            }
            videoDownloaded += chunk.length;
            videoSink.add(chunk);
            // Combine progress: video contributes first 60%
            if (onProgress != null) {
              final p = videoTotal > 0 ? (videoDownloaded / videoTotal) * 0.6 : 0.0;
              onProgress((p * videoTotal).toInt(), (videoTotal + (bestAudio.size.totalBytes)));
            }
          }
          await videoSink.flush();
          await videoSink.close();
        } catch (e) {
          try { await videoSink.close(); } catch (_) {}
          rethrow;
        }

        // Download audio-only to audioTmp
        final audioStream = _yt.videos.streamsClient.get(bestAudio);
        final audioSink = audioTmp.openWrite();
        int audioDownloaded = 0;
        final audioTotal = bestAudio.size.totalBytes;
        try {
          await for (final chunk in audioStream) {
            if (cancelToken?.isCanceled == true) {
              await audioSink.flush();
              await audioSink.close();
              if (await videoTmp.exists()) await videoTmp.delete();
              if (await audioTmp.exists()) await audioTmp.delete();
              throw YouTubeServiceException('Download cancelled');
            }
            audioDownloaded += chunk.length;
            audioSink.add(chunk);
            // Audio contributes remaining 40%
            if (onProgress != null) {
              final vp = videoTotal > 0 ? (videoDownloaded / videoTotal) * 0.6 : 0.6;
              final ap = audioTotal > 0 ? (audioDownloaded / audioTotal) * 0.4 : 0.0;
              final overall = vp + ap;
              onProgress((overall * (videoTotal + audioTotal)).toInt(), (videoTotal + audioTotal));
            }
          }
          await audioSink.flush();
          await audioSink.close();
        } catch (e) {
          try { await audioSink.close(); } catch (_) {}
          // Clean up partial video file
          try { if (await videoTmp.exists()) await videoTmp.delete(); } catch (_) {}
          rethrow;
        }

        // Mux using ffmpeg (copy codecs - no re-encoding, preserve original quality)
        // Ensure output container matches video extension to avoid container incompatibilities
        final outputPath = targetFile.path;
        final cmd = '-i "${videoTmp.path}" -i "${audioTmp.path}" -c:v copy -c:a copy -y "$outputPath"';
        debugPrint('youtube_service: muxing with ffmpeg (COPY MODE - NO RE-ENCODING): $cmd');
        final session = await FFmpegKit.execute(cmd);
        final rc = await session.getReturnCode();
        if (ReturnCode.isSuccess(rc)) {
          // Clean temp files
          try { if (await videoTmp.exists()) await videoTmp.delete(); } catch (_) {}
          try { if (await audioTmp.exists()) await audioTmp.delete(); } catch (_) {}
          final finalSize = await targetFile.length();
          debugPrint('youtube_service: Mux successful - $finalSize bytes');
          if (finalSize == 0) throw YouTubeServiceException('Muxed file is empty');
          return targetFile.path;
        } else {
          final output = await session.getOutput();
          debugPrint('youtube_service: FFmpeg mux failed: $output');
          // cleanup
          try { if (await videoTmp.exists()) await videoTmp.delete(); } catch (_) {}
          try { if (await audioTmp.exists()) await audioTmp.delete(); } catch (_) {}
          throw YouTubeServiceException('Failed to mux audio and video: $output');
        }
      } else {
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
              throw YouTubeServiceException('Download cancelled');
            }
            downloaded += chunk.length;
            sink.add(chunk);
            if (onProgress != null) onProgress(downloaded, total);
          }

          await sink.flush();
          await sink.close();

          final finalSize = await targetFile.length();
          debugPrint('youtube_service: Done - $finalSize bytes');

          if (finalSize == 0) throw YouTubeServiceException('Downloaded file is empty');
          return targetFile.path;
        } catch (e) {
          try { await sink.close(); } catch (_) {}
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('youtube_service.downloadStream ERROR: $e');
      rethrow;
    }
    // Should never reach here, but Dart needs a return type on all paths.
    return targetFile.path;
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
   Future<String?> resolveStreamUrl(String videoId, {String? resolution, int? bitrateKbps, bool audioOnly = false, String? preferredStreamUrl}) async {
    try {
      debugPrint('youtube_service.resolveStreamUrl: videoId=$videoId, resolution=$resolution, bitrate=$bitrateKbps, audioOnly=$audioOnly');

      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final List<dynamic> candidates = [];

      if (audioOnly) {
        candidates.addAll(manifest.audioOnly);
        debugPrint('  Audio-only streams available: ${manifest.audioOnly.length}');
      } else {
        // Prefer video-only streams (higher quality) then muxed streams.
        candidates.addAll(manifest.videoOnly);
        candidates.addAll(manifest.muxed);
        debugPrint('  Video-only streams available: ${manifest.videoOnly.length}');
        debugPrint('  Muxed streams available: ${manifest.muxed.length}');
      }

      // If a preferredStreamUrl is provided (from earlier manifest parsing), try to match it first.
      if (preferredStreamUrl != null && preferredStreamUrl.isNotEmpty) {
        try {
          debugPrint('  Trying to match preferredStreamUrl from cached QualityOption...');
          for (final s in candidates) {
            try {
              final u = s.url?.toString() ?? s.uri?.toString() ?? s.downloadUrl?.toString();
              if (u != null && u.isNotEmpty) {
                // Prefer exact match first, then contains
                if (u == preferredStreamUrl) {
                  debugPrint('  ✓ Preferred URL exact match found');
                  return u.toString();
                }
              }
            } catch (_) {}
          }
          // If exact not found, try contains
          for (final s in candidates) {
            try {
              final u = s.url?.toString() ?? s.uri?.toString() ?? s.downloadUrl?.toString();
              if (u != null && u.isNotEmpty && u.contains(preferredStreamUrl)) {
                debugPrint('  ✓ Preferred URL partial match found');
                return u.toString();
              }
            } catch (_) {}
          }
        } catch (_) {}
        debugPrint('  Preferred URL not found in manifest, falling back to resolution/bitrate heuristics');
      }

      if (candidates.isEmpty) {
        debugPrint('  ✗ NO streams available!');
        return null;
      }

      // Special handling for "MAX" quality - pick the HIGHEST resolution stream available
      if (resolution == 'MAX') {
        debugPrint('  🎬 MAXIMUM QUALITY MODE: Selecting highest resolution stream without compression...');
        if (!audioOnly) {
          // For video, prefer video-only streams (higher quality) then muxed
          final videoOnlyList = manifest.videoOnly.toList();
          if (videoOnlyList.isNotEmpty) {
            // Sort by resolution (highest first)
            videoOnlyList.sort((a, b) {
              final aHeight = int.tryParse(_extractResolution(a).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final bHeight = int.tryParse(_extractResolution(b).replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return bHeight.compareTo(aHeight);
            });
            final highest = videoOnlyList.first;
            final url = highest.url.toString();
            if (url.isNotEmpty) {
              final label = _extractResolution(highest);
              debugPrint('  ✓ Selected MAXIMUM: $label (video-only, highest available)');
              return url;
            }
          }
          // Fallback to muxed if no video-only
          if (manifest.muxed.isNotEmpty) {
            final muxedList = manifest.muxed.toList();
            muxedList.sort((a, b) {
              final aHeight = int.tryParse(a.qualityLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              final bHeight = int.tryParse(b.qualityLabel.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              return bHeight.compareTo(aHeight);
            });
            final highest = muxedList.first;
            final url = highest.url.toString();
            debugPrint('  ✓ Selected MAXIMUM: ${highest.qualityLabel} (muxed, highest available)');
            return url;
          }
        } else {
          // For audio, pick highest bitrate
          final audioList = manifest.audioOnly.toList();
          if (audioList.isNotEmpty) {
            audioList.sort((a, b) {
              final aKbps = _getStreamKbps(a);
              final bKbps = _getStreamKbps(b);
              return bKbps.compareTo(aKbps);
            });
            final highest = audioList.first;
            final url = highest.url.toString();
            if (url.isNotEmpty) {
              final kbps = _getStreamKbps(highest);
              debugPrint('  ✓ Selected MAXIMUM audio: ${kbps}kbps (highest available)');
              return url;
            }
          }
        }
      }

      // Extract target resolution number (e.g., "720p" -> 720, "1080p60" -> 1080)
      int? targetHeight;
      if (resolution != null && resolution.isNotEmpty && resolution != 'MAX') {
        final match = RegExp(r'(\d+)p').firstMatch(resolution);
        if (match != null) {
          targetHeight = int.tryParse(match.group(1)!);
        }
      }

      debugPrint('  Target height: $targetHeight');

      // Quick pass: if we have a numeric targetHeight, prefer video-only streams
      // that match the resolution label, then fallback to muxed streams.
      if (targetHeight != null) {
        try {
          final resStr = '${targetHeight}p';
          // Check video-only streams first (prefer higher quality video-only)
          try {
            for (final s in manifest.videoOnly) {
              try {
                final qlabel = (_extractResolution(s))?.toString() ?? '';
                if (qlabel.isNotEmpty && qlabel.contains(resStr)) {
                  final u = s.url?.toString();
                  if (u != null && u.isNotEmpty) {
                    debugPrint('  Quick-match (video-only) by label: $qlabel -> using this stream');
                    return u.toString();
                  }
                }
              } catch (_) {}
            }
          } catch (_) {}

          // Then check muxed streams
          try {
            for (final s in manifest.muxed) {
              try {
                final qlabel = (s.qualityLabel ?? s.videoQuality?.name ?? '')?.toString() ?? '';
                if (qlabel.isNotEmpty && qlabel.contains(resStr)) {
                  final u = s.url?.toString();
                  if (u != null && u.isNotEmpty) {
                    debugPrint('  Quick-match (muxed) by label: $qlabel -> using this stream');
                    return u.toString();
                  }
                }
              } catch (_) {}
            }
          } catch (_) {}
        } catch (_) {}
      }

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
              // Score by closeness to targetHeight (smaller diff is better).
              // Add small bonus if streamHeight >= targetHeight so we prefer equal/higher when available.
              final diff = (streamHeight - targetHeight).abs();
              final bonus = streamHeight >= targetHeight ? 1000 : 0;
              final score = 100000 - (diff * 10) + bonus + streamHeight;
              if (score > bestScore) {
                bestScore = score.toInt();
                bestMatch = s;
                bestLabel = qlabel;
                if (diff == 0) debugPrint('  Found EXACT match: $qlabel (height=$streamHeight)');
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

  /// Find a StreamInfo object matching the given stream URL for a video.
  /// Returns null if not found.
  Future<StreamInfo?> findStreamByUrl(String videoId, String streamUrl) async {
    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      final List<StreamInfo> all = [
        ...manifest.muxed,
        ...manifest.videoOnly,
        ...manifest.audioOnly,
      ];
      for (final s in all) {
        try {
          final u = s.url?.toString() ?? '';
          if (u == streamUrl) return s;
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('findStreamByUrl failed: $e');
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

/// YouTube service exception
class YouTubeServiceException implements Exception {
  final String message;
  YouTubeServiceException(this.message);

  @override
  String toString() => message;
}

/// Backward compatible alias for code that expects `YouTubeException`.
class YouTubeException extends YouTubeServiceException {
  YouTubeException(String message) : super(message);
}
