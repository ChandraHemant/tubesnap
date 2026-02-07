import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tubesnap/models/quality_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../models/download_model.dart';
import '../../models/video_model.dart';
import 'youtube_service.dart';
import 'storage_service.dart';
import 'audio_converter_service.dart';

/// Download Service - Handles all download operations
/// All features are FREE - No restrictions!
class DownloadService {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  // Active downloads map
  final Map<String, DownloadTask> _activeDownloads = {};

  // Cancel tokens per task
  final Map<String, CancelToken> _cancelTokens = {};

  // Track downloaded bytes per task (to ensure something was written)
  final Map<String, int> _downloadedBytes = {};

  // Download queue
  final List<DownloadTask> _downloadQueue = [];

  // Max concurrent downloads (FREE - No limit!)
  final int maxConcurrent = 5;

  // Stream controllers for progress updates
  final _progressController = StreamController<DownloadProgress>.broadcast();
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  final _statusController = StreamController<DownloadStatusUpdate>.broadcast();
  Stream<DownloadStatusUpdate> get statusStream => _statusController.stream;

  final StorageService _storage = StorageService();

  /// Get download directory
  Future<Directory> getDownloadDirectory() async {
    Directory? directory;

    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download/TubeSnap');
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
      directory = Directory('${directory.path}/TubeSnap');
    } else {
      directory = await getDownloadsDirectory();
      directory = Directory('${directory?.path ?? '.'}/TubeSnap');
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    return directory;
  }

  /// Start a new download - ALL QUALITIES FREE!
  Future<DownloadTask> startDownload({
    required VideoInfo video,
    required QualityOption quality,
    String? customPath,
  }) async {
    final downloadDir = await getDownloadDirectory();
    // Ensure we have a valid title, fallback to video ID if title is empty
    final videoTitle = video.title.isNotEmpty ? video.title : 'video_${video.id}';
    final fileName = _sanitizeFileName('${videoTitle}_${quality.resolution}.${quality.extension}');
    final filePath = customPath ?? '${downloadDir.path}/$fileName';

    debugPrint('DownloadService.startDownload: Creating download task');
    debugPrint('  Video ID: ${video.id}');
    debugPrint('  Title: ${video.title}');
    debugPrint('  Quality: ${quality.resolution}');
    debugPrint('  File path: $filePath');

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      videoId: video.id,
      title: video.title,
      thumbnailUrl: video.thumbnailUrl,
      quality: quality.resolution,
      fileSize: quality.fileSize,
      filePath: filePath,
      downloadUrl: quality.downloadUrl,
      status: DownloadStatus.queued,
      progress: 0.0,
      createdAt: DateTime.now(),
    );

    _downloadQueue.add(task);
    // Notify listeners that task is queued
    _statusController.add(DownloadStatusUpdate(taskId: task.id, status: DownloadStatus.queued));
    debugPrint('DownloadService: queued task ${task.id} for video ${task.videoId} -> ${task.filePath}');
    _processQueue();

    return task;
  }

  /// Process download queue
  void _processQueue() {
    while (_activeDownloads.length < maxConcurrent && _downloadQueue.isNotEmpty) {
      final task = _downloadQueue.removeAt(0);
      _startDownloadTask(task);
    }
  }

  /// Start individual download task
  Future<void> _startDownloadTask(DownloadTask task) async {
    _activeDownloads[task.id] = task;
    debugPrint('DownloadService: starting task ${task.id}');

    // create cancel token
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    _statusController.add(DownloadStatusUpdate(
      taskId: task.id,
      status: DownloadStatus.downloading,
    ));

    // Emit an initial progress update (0%) so UI shows immediate state
    _progressController.add(DownloadProgress(
      taskId: task.id,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: task.fileSize,
      speed: '',
      eta: '',
    ));

    try {
      // On Android ensure we have storage permission before writing to external Download dir
      if (Platform.isAndroid) {
        try {
          var status = await Permission.storage.request();
          if (!status.isGranted) {
            // Try manage external storage (Android 11+)
            final manageStatus = await Permission.manageExternalStorage.request();
            if (!manageStatus.isGranted) {
              debugPrint('DownloadService: storage permission denied for task ${task.id}');
              _statusController.add(DownloadStatusUpdate(taskId: task.id, status: DownloadStatus.failed, error: 'Storage permission denied'));
              // Remove from active map if present
              _activeDownloads.remove(task.id);
              _processQueue();
              return;
            }
          }
        } catch (e) {
          debugPrint('DownloadService: permission check failed: $e');
        }
      }
      final targetFile = File(task.filePath);
      if (!(await targetFile.parent.exists())) {
        await targetFile.parent.create(recursive: true);
      }

      // ALWAYS resolve stream URL fresh (YouTube URLs expire within minutes!)
      // Never trust stored URLs
      debugPrint('DownloadService: Resolving FRESH stream URL for video ${task.videoId}, quality ${task.quality}');

      String? streamUrl;
      try {
        // Use preferred stream URL if the QualityOption includes one (to ensure exact match)
        final preferred = (task.downloadUrl.isNotEmpty) ? task.downloadUrl : null;
        // Try to resolve by resolution first, preferring the stored downloadUrl
        streamUrl = await YouTubeService().resolveStreamUrl(task.videoId, resolution: task.quality, preferredStreamUrl: preferred);

        if (streamUrl == null || streamUrl.isEmpty) {
          // Try audio-only if quality looks like bitrate (e.g., "320kbps")
          debugPrint('DownloadService: No video stream found, trying audio-only');
          int? kbps;
          try {
            kbps = int.parse(task.quality.replaceAll(RegExp(r'[^0-9]'), ''));
          } catch (_) {}

          if (kbps != null) {
            streamUrl = await YouTubeService().resolveStreamUrl(task.videoId, bitrateKbps: kbps, audioOnly: true, preferredStreamUrl: preferred);
          }
        }

        if (streamUrl != null && streamUrl.isNotEmpty) {
          debugPrint('DownloadService: ✓ Resolved stream URL (${streamUrl.length} chars)');
          debugPrint('  URL preview: ${streamUrl.substring(0, streamUrl.length > 80 ? 80 : streamUrl.length)}...');
        }
      } catch (e) {
        debugPrint('DownloadService: ✗ Failed to resolve stream URL: $e');
        throw YouTubeServiceException('Could not resolve stream URL: $e');
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        throw YouTubeServiceException('No stream URL available. Video might be unavailable or quality not supported.');
      }

      // Use YouTubeService to download the stream and report progress
      String savedPath = task.filePath;
      // Detect stream info to adjust extension/container when needed
      try {
        final streamInfo = await YouTubeService().findStreamByUrl(task.videoId, streamUrl);
        if (streamInfo != null) {
          // If video-only, ensure target file has proper container extension (webm/mp4)
          if (streamInfo is VideoOnlyStreamInfo) {
            final codec = (streamInfo.codec ?? '').toString().toLowerCase();
            final ext = codec.contains('vp9') || codec.contains('vp8') ? 'webm' : task.filePath.split('.').last;
            final newPath = task.filePath.replaceAll(RegExp(r'\.[^\.]+$'), '.$ext');
            if (newPath != task.filePath) {
              // update file path and targetFile
              debugPrint('DownloadService: Adjusting target file extension for video-only stream: $newPath');
              savedPath = newPath;
            }
          }
        }
      } catch (e) {
        debugPrint('DownloadService: could not detect stream info: $e');
      }

      final finalTargetFile = File(savedPath);
      if (!(await finalTargetFile.parent.exists())) await finalTargetFile.parent.create(recursive: true);

      final downloadedSavedPath = await YouTubeService().downloadStream(
        videoId: task.videoId,
        streamUrl: streamUrl,
        targetFile: finalTargetFile,
        cancelToken: cancelToken,
        onProgress: (downloadedBytes, totalBytes) {
          // Track bytes for this task
          _downloadedBytes[task.id] = downloadedBytes;
          final progress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;

          // Update the active task with current progress
          final activeTask = _activeDownloads[task.id];
          if (activeTask != null) {
            activeTask.progress = progress;
            activeTask.downloadedBytes = downloadedBytes;
          }

          _progressController.add(DownloadProgress(
            taskId: task.id,
            progress: progress,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            speed: '',
            eta: '',
          ));
        },
      );

      // If download returned saved path, use it for verification and persistence
      if (downloadedSavedPath != null && downloadedSavedPath.isNotEmpty) {
        task = task.copyWith(filePath: downloadedSavedPath);
      }

      // Completed - verify file then persist and emit completed only after saved
      await Future.delayed(Duration(milliseconds: 500)); // Wait for file system to sync
      final exists = await File(task.filePath).exists();
      final fileLen = exists ? await File(task.filePath).length() : 0;
      final wroteBytes = _downloadedBytes[task.id] ?? 0;

      debugPrint('========== DOWNLOAD COMPLETION CHECK ==========');
      debugPrint('Task ID: ${task.id}');
      debugPrint('File Path: ${task.filePath}');
      debugPrint('File Exists: $exists');
      debugPrint('File Size: $fileLen bytes');
      debugPrint('Bytes Written (tracked): $wroteBytes bytes');
      debugPrint('Stream URL Used: $streamUrl');
      debugPrint('============================================');

      // STRICT: require all 3 conditions
      if (!exists) {
        _activeDownloads.remove(task.id);
        _cancelTokens.remove(task.id);
        _downloadedBytes.remove(task.id);
        final error = 'File does not exist at ${task.filePath}';
        _statusController.add(DownloadStatusUpdate(taskId: task.id, status: DownloadStatus.failed, error: error));
        debugPrint('DownloadService: task ${task.id} FAILED - $error');
        _processQueue();
        return;
      }

      if (fileLen == 0) {
        _activeDownloads.remove(task.id);
        _cancelTokens.remove(task.id);
        _downloadedBytes.remove(task.id);
        final error = 'Downloaded file is empty (0 bytes)';
        _statusController.add(DownloadStatusUpdate(taskId: task.id, status: DownloadStatus.failed, error: error));
        debugPrint('DownloadService: task ${task.id} FAILED - $error');
        _processQueue();
        return;
      }

      if (wroteBytes == 0) {
        _activeDownloads.remove(task.id);
        _cancelTokens.remove(task.id);
        _downloadedBytes.remove(task.id);
        final error = 'No data was actually downloaded (0 bytes tracked)';
        _statusController.add(DownloadStatusUpdate(taskId: task.id, status: DownloadStatus.failed, error: error));
        debugPrint('DownloadService: task ${task.id} FAILED - $error');
        _processQueue();
        return;
      }

      final completedTask = task.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
        downloadedBytes: fileLen, // Use actual file size from disk
      );

      // Persist to history first
      await _storage.addToDownloadHistory(completedTask);

      // Remove active and cancel token after persistence
      _activeDownloads.remove(task.id);
      _cancelTokens.remove(task.id);
      _downloadedBytes.remove(task.id);

      // Emit completed status after persistence
      _statusController.add(DownloadStatusUpdate(
        taskId: task.id,
        status: DownloadStatus.completed,
        filePath: completedTask.filePath,
      ));

      debugPrint('DownloadService: completed task ${task.id}, saved to ${completedTask.filePath}');


      // Continue queue
      _processQueue();
    } catch (e) {
      debugPrint('DownloadService: task ${task.id} failed: $e');
      try {
        debugPrint(e.toString());
      } catch (_) {}
      // Remove active and cancel token
      _activeDownloads.remove(task.id);
      _cancelTokens.remove(task.id);

      _statusController.add(DownloadStatusUpdate(
        taskId: task.id,
        status: DownloadStatus.failed,
        error: e.toString(),
      ));

      // Continue queue
      _processQueue();
    }
  }

  /// Pause download
  void pauseDownload(String taskId) {
    // Pause not supported by youtube_explode_dart stream directly; emulate by cancelling
    cancelDownload(taskId);
    _statusController.add(DownloadStatusUpdate(
      taskId: taskId,
      status: DownloadStatus.paused,
    ));
  }

  /// Resume download
  void resumeDownload(String taskId) {
    // Not full resume; user needs to restart the download. For simplicity, mark queued again.
    // In a full implementation implement ranged requests/resume.
    _statusController.add(DownloadStatusUpdate(
      taskId: taskId,
      status: DownloadStatus.queued,
    ));
    _processQueue();
  }

  /// Cancel download
  void cancelDownload(String taskId) {
    // Cancel running download if token exists
    try {
      final token = _cancelTokens[taskId];
      if (token != null) token.cancel();
    } catch (_) {}

    _activeDownloads.remove(taskId);
    _downloadQueue.removeWhere((task) => task.id == taskId);

    _statusController.add(DownloadStatusUpdate(
      taskId: taskId,
      status: DownloadStatus.cancelled,
    ));

    _processQueue();
  }

  /// Cancel all downloads
  void cancelAllDownloads() {
    for (final taskId in _activeDownloads.keys.toList()) {
      cancelDownload(taskId);
    }
    _downloadQueue.clear();
  }

  /// Get active downloads count
  int get activeDownloadsCount => _activeDownloads.length;

  /// Get queued downloads count
  int get queuedDownloadsCount => _downloadQueue.length;

  /// Get list of active downloads
  List<DownloadTask> get activeDownloads => _activeDownloads.values.toList();

  /// Get list of queued downloads
  List<DownloadTask> get queuedDownloads => List.from(_downloadQueue);

  /// Start audio download with MP3 conversion
  Future<DownloadTask> startAudioDownload({
    required VideoInfo video,
    required AudioQualityOption quality,
    String? customPath,
  }) async {
    final downloadDir = await getDownloadDirectory();
    final videoTitle = video.title.isNotEmpty ? video.title : 'audio_${video.id}';
    final fileName = _sanitizeFileName('${videoTitle}_${quality.bitrate}.mp3');
    final filePath = customPath ?? '${downloadDir.path}/$fileName';

    // Create temporary file for downloaded audio before conversion
    final tempFileName = _sanitizeFileName('${videoTitle}_${quality.bitrate}_temp.webm');
    final tempFilePath = '${downloadDir.path}/$tempFileName';

    debugPrint('DownloadService.startAudioDownload: Creating audio download task');
    debugPrint('  Video ID: ${video.id}');
    debugPrint('  Title: ${video.title}');
    debugPrint('  Bitrate: ${quality.bitrate} (${quality.bitrateKbps}kbps)');
    debugPrint('  Temp path: $tempFilePath');
    debugPrint('  Final path: $filePath');

    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      videoId: video.id,
      title: video.title,
      thumbnailUrl: video.thumbnailUrl,
      quality: quality.bitrate,
      fileSize: quality.fileSize,
      filePath: filePath, // Final MP3 path
      downloadUrl: quality.downloadUrl,
      status: DownloadStatus.queued,
      progress: 0.0,
      createdAt: DateTime.now(),
    );

    // Store in active downloads (NOT in queue - audio is processed directly)
    _activeDownloads[task.id] = task;

    // Note: Don't add to _downloadQueue since audio is processed directly
    _statusController.add(DownloadStatusUpdate(taskId: task.id, status: DownloadStatus.queued));
    debugPrint('DownloadService: starting audio task ${task.id} (direct processing)');

    // Process with special audio handling (direct, not queued)
    _processAudioDownload(task, tempFilePath, quality.bitrateKbps);

    return task;
  }

  /// Process audio download with MP3 conversion
  Future<void> _processAudioDownload(DownloadTask task, String tempFilePath, int bitrateKbps) async {
    debugPrint('DownloadService: starting audio task ${task.id}');

    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;

    _statusController.add(DownloadStatusUpdate(
      taskId: task.id,
      status: DownloadStatus.downloading,
    ));

    _progressController.add(DownloadProgress(
      taskId: task.id,
      progress: 0.0,
      downloadedBytes: 0,
      totalBytes: task.fileSize,
      speed: '',
      eta: '',
    ));

    try {
      // Request storage permissions (Android)
      if (Platform.isAndroid) {
        try {
          var status = await Permission.storage.request();
          if (!status.isGranted) {
            final manageStatus = await Permission.manageExternalStorage.request();
            if (!manageStatus.isGranted) {
              debugPrint('DownloadService: storage permission denied for audio task ${task.id}');
              _statusController.add(DownloadStatusUpdate(
                taskId: task.id,
                status: DownloadStatus.failed,
                error: 'Storage permission denied',
              ));
              _activeDownloads.remove(task.id);
              return;
            }
          }
        } catch (e) {
          debugPrint('DownloadService: permission check failed: $e');
        }
      }

      // Create temp file for audio download
      final tempFile = File(tempFilePath);
      if (!(await tempFile.parent.exists())) {
        await tempFile.parent.create(recursive: true);
      }

      // Resolve fresh audio stream URL
      debugPrint('DownloadService: Resolving FRESH audio stream URL');
      String? streamUrl;
      try {
        final preferred = (task.downloadUrl.isNotEmpty) ? task.downloadUrl : null;
        streamUrl = await YouTubeService().resolveStreamUrl(
          task.videoId,
          audioOnly: true,
          bitrateKbps: null,
          preferredStreamUrl: preferred,
        );

        if (streamUrl != null && streamUrl.isNotEmpty) {
          debugPrint('DownloadService: ✓ Resolved audio stream URL');
        }
      } catch (e) {
        debugPrint('DownloadService: ✗ Failed to resolve audio stream URL: $e');
        throw YouTubeServiceException('Could not resolve audio stream URL: $e');
      }

      if (streamUrl == null || streamUrl.isEmpty) {
        throw YouTubeServiceException('No audio stream available for download');
      }

      // Download audio stream to temp file (80% of progress)
      int downloadBytes = 0;
      await YouTubeService().downloadStream(
        videoId: task.videoId,
        streamUrl: streamUrl,
        targetFile: tempFile,
        cancelToken: cancelToken,
        onProgress: (downloadedBytes, totalBytes) {
          downloadBytes = downloadedBytes;
          // 0-80% for download
          final downloadProgress = totalBytes > 0 ? (downloadedBytes / totalBytes) * 0.8 : 0.0;

          final activeTask = _activeDownloads[task.id];
          if (activeTask != null) {
            activeTask.progress = downloadProgress;
            activeTask.downloadedBytes = downloadedBytes;
          }

          _progressController.add(DownloadProgress(
            taskId: task.id,
            progress: downloadProgress,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            speed: '',
            eta: '',
          ));
        },
      );

      debugPrint('DownloadService: Audio downloaded to temp file, starting MP3 conversion...');

      // Update progress to show conversion starting (80%)
      _progressController.add(DownloadProgress(
        taskId: task.id,
        progress: 0.8,
        downloadedBytes: downloadBytes,
        totalBytes: task.fileSize,
        speed: '',
        eta: '',
      ));

      // Convert to MP3 (80-100% of progress)
      final converter = AudioConverterService();
      final conversionSuccess = await converter.convertToMp3(
        inputPath: tempFilePath,
        outputPath: task.filePath,
        bitrateKbps: bitrateKbps,
        onProgress: (conversionProgress) {
          // 80-100% for conversion
          final totalProgress = 0.8 + (conversionProgress * 0.2);
          _progressController.add(DownloadProgress(
            taskId: task.id,
            progress: totalProgress,
            downloadedBytes: (task.fileSize * totalProgress).toInt(),
            totalBytes: task.fileSize,
            speed: '',
            eta: '',
          ));
        },
      );

      if (!conversionSuccess) {
        throw YouTubeServiceException('Failed to convert audio to MP3');
      }

      debugPrint('DownloadService: ✓ MP3 conversion successful!');

      // Verify final MP3 file
      await Future.delayed(Duration(milliseconds: 500));
      final finalFile = File(task.filePath);
      final exists = await finalFile.exists();
      final fileLen = exists ? await finalFile.length() : 0;

      debugPrint('========== AUDIO DOWNLOAD COMPLETION ==========');
      debugPrint('Task ID: ${task.id}');
      debugPrint('Final MP3 Path: ${task.filePath}');
      debugPrint('File Exists: $exists');
      debugPrint('MP3 File Size: $fileLen bytes');
      debugPrint('==============================================');

      if (!exists || fileLen == 0) {
        _activeDownloads.remove(task.id);
        _cancelTokens.remove(task.id);
        final error = exists ? 'MP3 file is empty (0 bytes)' : 'MP3 file was not created';
        _statusController.add(DownloadStatusUpdate(
          taskId: task.id,
          status: DownloadStatus.failed,
          error: error,
        ));
        debugPrint('DownloadService: audio task ${task.id} FAILED - $error');
        return;
      }

      // Mark as completed
      final completedTask = task.copyWith(
        status: DownloadStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
        downloadedBytes: fileLen,
      );

      await _storage.addToDownloadHistory(completedTask);

      _activeDownloads.remove(task.id);
      _cancelTokens.remove(task.id);

      _statusController.add(DownloadStatusUpdate(
        taskId: task.id,
        status: DownloadStatus.completed,
        filePath: completedTask.filePath,
      ));

      debugPrint('DownloadService: ✓ Audio task completed - MP3 saved to ${completedTask.filePath}');
    } catch (e) {
      debugPrint('DownloadService: audio task ${task.id} failed: $e');

      // Clean up temp file if it exists
      try {
        final tempFile = File(tempFilePath);
        if (await tempFile.exists()) {
          await tempFile.delete();
          debugPrint('DownloadService: Cleaned up temp file');
        }
      } catch (_) {}

      _activeDownloads.remove(task.id);
      _cancelTokens.remove(task.id);

      _statusController.add(DownloadStatusUpdate(
        taskId: task.id,
        status: DownloadStatus.failed,
        error: e.toString(),
      ));
    }
  }

  /// Sanitize file name
  String _sanitizeFileName(String fileName) {
    final sanitized = fileName
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    // Limit length using sanitized string's length, not original
    return sanitized.length > 200 ? sanitized.substring(0, 200) : sanitized;
  }

  /// Dispose
  void dispose() {
    _progressController.close();
    _statusController.close();
  }
}

/// Download Progress Update
class DownloadProgress {
  final String taskId;
  final double progress;
  final int downloadedBytes;
  final int totalBytes;
  final String speed;
  final String eta;

  DownloadProgress({
    required this.taskId,
    required this.progress,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.speed,
    required this.eta,
  });
}

/// Download Status Update
class DownloadStatusUpdate {
  final String taskId;
  final DownloadStatus status;
  final String? filePath;
  final String? error;

  DownloadStatusUpdate({
    required this.taskId,
    required this.status,
    this.filePath,
    this.error,
  });
}

