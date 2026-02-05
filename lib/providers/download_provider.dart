import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/download_model.dart';
import '../models/video_model.dart';
import '../models/quality_model.dart';
import '../core/services/download_service.dart';
import '../core/services/storage_service.dart';

/// Download Provider - Manages download state
/// ALL FEATURES ARE FREE - No restrictions!
class DownloadProvider extends ChangeNotifier {
  final DownloadService _downloadService = DownloadService();
  final StorageService _storageService = StorageService();

  // State
  List<DownloadTask> _activeDownloads = [];
  List<DownloadTask> _completedDownloads = [];
  List<DownloadTask> _failedDownloads = [];
  bool _isLoading = false;
  String? _error;

  // Subscriptions
  StreamSubscription? _progressSubscription;
  StreamSubscription? _statusSubscription;

  // Getters
  List<DownloadTask> get activeDownloads => _activeDownloads;
  List<DownloadTask> get completedDownloads => _completedDownloads;
  List<DownloadTask> get failedDownloads => _failedDownloads;
  List<DownloadTask> get allDownloads => [..._activeDownloads, ..._completedDownloads, ..._failedDownloads];
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get activeCount => _activeDownloads.length;
  int get completedCount => _completedDownloads.length;
  int get totalCount => allDownloads.length;

  DownloadProvider() {
    _init();
  }

  /// Initialize provider
  Future<void> _init() async {
    await _loadDownloadHistory();
    _listenToDownloads();
  }

  /// Load download history from storage
  Future<void> _loadDownloadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      final history = await _storageService.getDownloadHistory();

      _activeDownloads = history.where((t) => t.isActive).toList();
      _completedDownloads = history.where((t) => t.status == DownloadStatus.completed).toList();
      _failedDownloads = history.where((t) => t.status == DownloadStatus.failed).toList();

      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Listen to download updates
  void _listenToDownloads() {
    _progressSubscription = _downloadService.progressStream.listen((progress) {
      _updateTaskProgress(progress);
    });

    _statusSubscription = _downloadService.statusStream.listen((update) {
      // Call async handler but don't block the stream
      _updateTaskStatus(update);
    });
  }

  /// Update task progress
  void _updateTaskProgress(DownloadProgress progress) {
    try {
      debugPrint('DownloadProvider: progress update received for ${progress.taskId} - ${ (progress.progress * 100).toStringAsFixed(1)}% (${progress.downloadedBytes}/${progress.totalBytes})');
      final index = _activeDownloads.indexWhere((t) => t.id == progress.taskId);
      if (index != -1) {
        _activeDownloads[index] = _activeDownloads[index].copyWith(
          progress: progress.progress,
          downloadedBytes: progress.downloadedBytes,
          speed: progress.speed,
          eta: progress.eta,
        );
      } else {
        // If we don't know about this task yet, create a placeholder active task so UI can show progress
        final placeholder = DownloadTask(
          id: progress.taskId,
          videoId: '',
          title: 'Downloading...',
          thumbnailUrl: '',
          quality: '',
          fileSize: progress.totalBytes,
          filePath: '',
          downloadUrl: '',
          status: DownloadStatus.downloading,
          progress: progress.progress,
          createdAt: DateTime.now(),
          downloadedBytes: progress.downloadedBytes,
        );
        _activeDownloads.add(placeholder);
      }
      notifyListeners();
      debugPrint('DownloadProvider: active=${_activeDownloads.length}, completed=${_completedDownloads.length}, failed=${_failedDownloads.length}');
    } catch (e, st) {
      debugPrint('Error in _updateTaskProgress: $e\n$st');
    }
  }

  /// Update task status
  Future<void> _updateTaskStatus(DownloadStatusUpdate update) async {
    try {
      debugPrint('DownloadProvider: status update received for ${update.taskId} -> ${update.status} ${update.error != null ? ' error=${update.error}' : ''} file=${update.filePath}');
      var task = _findTask(update.taskId);

      if (task == null) {
        // Task not found - this should not happen if startDownload was called properly
        debugPrint('WARNING: DownloadProvider received status update for unknown task ${update.taskId}');
        debugPrint('This task was not properly initialized. Ignoring status update.');
        return;
      }

      // Remove from current lists
      _activeDownloads.removeWhere((t) => t.id == update.taskId);
      _completedDownloads.removeWhere((t) => t.id == update.taskId);
      _failedDownloads.removeWhere((t) => t.id == update.taskId);

      // Update task status
      var updatedTask = task.copyWith(
        status: update.status,
        errorMessage: update.error,
        completedAt: update.status == DownloadStatus.completed ? DateTime.now() : task.completedAt,
        progress: update.status == DownloadStatus.completed ? 1.0 : task.progress,
      );

      // If completed, verify the file exists and has size before accepting completion
      if (update.status == DownloadStatus.completed) {
        final path = update.filePath ?? updatedTask.filePath;
        var fileOk = false;
        var fileSize = 0;

        debugPrint('========== PROVIDER FILE VERIFICATION ==========');
        debugPrint('Task ID: ${update.taskId}');
        debugPrint('Checking path: $path');

        if (path != null && path.isNotEmpty) {
          try {
            final f = File(path);
            // Wait for file system
            await Future.delayed(Duration(milliseconds: 300));

            if (await f.exists()) {
              fileSize = await f.length();
              fileOk = fileSize > 0;
              debugPrint('File exists: YES');
              debugPrint('File size: $fileSize bytes');
              debugPrint('Verification result: $fileOk');
            } else {
              debugPrint('File exists: NO');
              debugPrint('Path checked: $path');
            }
          } catch (e) {
            debugPrint('ERROR checking file: $e');
          }
        } else {
          debugPrint('ERROR: path is null or empty: $path');
        }

        debugPrint('===========================================');

        if (fileOk) {
          // File verified - mark completed
          updatedTask = updatedTask.copyWith(filePath: path ?? updatedTask.filePath);
          _completedDownloads.insert(0, updatedTask);
          await _storageService.addToDownloadHistory(updatedTask);
          debugPrint('DownloadProvider: ${update.taskId} VERIFIED and moved to completed. File size: $fileSize bytes');
        } else {
          // File NOT verified - move to failed
          final failedTask = updatedTask.copyWith(
            status: DownloadStatus.failed,
            errorMessage: 'File verification failed - does not exist or is empty at: $path'
          );
          _failedDownloads.add(failedTask);
          debugPrint('DownloadProvider: ${update.taskId} FAILED - file verification failed');
        }
      } else {
        // Add to appropriate list for other statuses
        switch (update.status) {
          case DownloadStatus.queued:
          case DownloadStatus.downloading:
          case DownloadStatus.paused:
            _activeDownloads.add(updatedTask);
            break;
          case DownloadStatus.failed:
            _failedDownloads.add(updatedTask);
            break;
          case DownloadStatus.cancelled:
          // Don't add to any list
            break;
          default:
            break;
        }
      }

      debugPrint('DownloadProvider: after status update active=${_activeDownloads.length}, completed=${_completedDownloads.length}, failed=${_failedDownloads.length}');
      // Persist updated lists so items (completed/failed) are not lost
      await _saveHistory();
      notifyListeners();
    } catch (e, st) {
      debugPrint('Error in _updateTaskStatus: $e\n$st');
    }
  }

  /// Find task by ID
  DownloadTask? _findTask(String taskId) {
    try {
      return allDownloads.firstWhere((t) => t.id == taskId);
    } catch (e) {
      return null;
    }
  }

  /// Start a new download - ALL QUALITIES FREE!
  Future<void> startDownload({
    required VideoInfo video,
    required QualityOption quality,
  }) async {
    debugPrint('DownloadProvider.startDownload called');
    debugPrint('  Video: ${video.id} - ${video.title}');
    debugPrint('  Quality: ${quality.resolution} (${quality.downloadUrl.length} chars URL)');
    try {
      final task = await _downloadService.startDownload(
        video: video,
        quality: quality,
      );

      // Add the task to active downloads immediately so we have the full info
      // when status updates come in (prevents "Unknown" title and empty quality)
      _activeDownloads.add(task);
      notifyListeners();

      debugPrint('DownloadProvider: startDownload requested task ${task.id}');
    } catch (e, st) {
      debugPrint('DownloadProvider.startDownload ERROR: $e');
      debugPrint('Stack trace: $st');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Start audio download - FREE! Downloads and converts to MP3
  Future<void> startAudioDownload({
    required VideoInfo video,
    required AudioQualityOption quality,
  }) async {
    debugPrint('DownloadProvider.startAudioDownload called');
    debugPrint('  Video: ${video.id} - ${video.title}');
    debugPrint('  Quality: ${quality.bitrate} (${quality.bitrateKbps}kbps)');
    try {
      // Use dedicated audio download method that handles MP3 conversion
      final task = await _downloadService.startAudioDownload(
        video: video,
        quality: quality,
      );

      // Add the task to active downloads immediately so we have the full info
      _activeDownloads.add(task);
      notifyListeners();

      debugPrint('DownloadProvider: startAudioDownload requested task ${task.id} (MP3 conversion enabled)');
    } catch (e, st) {
      debugPrint('DownloadProvider.startAudioDownload ERROR: $e');
      debugPrint('Stack trace: $st');
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Pause download
  void pauseDownload(String taskId) {
    _downloadService.pauseDownload(taskId);
  }

  /// Resume download
  void resumeDownload(String taskId) {
    _downloadService.resumeDownload(taskId);
  }

  /// Cancel download
  void cancelDownload(String taskId) {
    _downloadService.cancelDownload(taskId);
    _activeDownloads.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  /// Retry failed download
  Future<void> retryDownload(DownloadTask task) async {
    _failedDownloads.removeWhere((t) => t.id == task.id);

    // Create new task with same parameters
    final newTask = task.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      status: DownloadStatus.queued,
      progress: 0.0,
      downloadedBytes: 0,
      errorMessage: null,
      createdAt: DateTime.now(),
    );

    _activeDownloads.add(newTask);
    notifyListeners();

    // Restart download
    _downloadService.startDownload(
      video: VideoInfo.dummy(), // In real app, fetch video info again
      quality: QualityOption.allQualities.firstWhere(
            (q) => q.resolution == task.quality,
        orElse: () => QualityOption.allQualities.first,
      ),
    );
  }

  /// Delete download
  Future<void> deleteDownload(String taskId) async {
    _activeDownloads.removeWhere((t) => t.id == taskId);
    _completedDownloads.removeWhere((t) => t.id == taskId);
    _failedDownloads.removeWhere((t) => t.id == taskId);

    await _storageService.removeFromDownloadHistory(taskId);
    notifyListeners();
  }

  /// Clear all completed downloads
  Future<void> clearCompleted() async {
    _completedDownloads.clear();
    await _saveHistory();
    notifyListeners();
  }

  /// Clear all failed downloads
  Future<void> clearFailed() async {
    _failedDownloads.clear();
    notifyListeners();
  }

  /// Clear all history
  Future<void> clearAllHistory() async {
    _completedDownloads.clear();
    _failedDownloads.clear();
    await _storageService.clearDownloadHistory();
    notifyListeners();
  }

  /// Save history to storage
  Future<void> _saveHistory() async {
    await _storageService.saveDownloadHistory([
      ..._activeDownloads,
      ..._completedDownloads,
      ..._failedDownloads,
    ]);
  }

  /// Cancel all active downloads
  void cancelAllDownloads() {
    _downloadService.cancelAllDownloads();
    _activeDownloads.clear();
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Refresh downloads
  Future<void> refresh() async {
    await _loadDownloadHistory();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _statusSubscription?.cancel();
    _downloadService.dispose();
    super.dispose();
  }
}