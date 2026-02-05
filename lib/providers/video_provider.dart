import 'package:flutter/foundation.dart';
import '../core/services/youtube_service.dart';
import '../models/video_model.dart';
import '../models/quality_model.dart';

/// Video Provider - Manages video fetching state
/// ALL FEATURES ARE FREE!
class VideoProvider extends ChangeNotifier {
  final YouTubeService _youtubeService = YouTubeService();

  // State
  VideoInfo? _currentVideo;
  bool _isLoading = false;
  String? _error;
  String _selectedQuality = '1080p';
  String _selectedAudioQuality = '320kbps';
  bool _isAudioOnly = false;
  String _url = '';

  // Getters
  VideoInfo? get currentVideo => _currentVideo;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedQuality => _selectedQuality;
  String get selectedAudioQuality => _selectedAudioQuality;
  bool get isAudioOnly => _isAudioOnly;
  String get url => _url;
  bool get hasVideo => _currentVideo != null;
  bool get hasError => _error != null;

  /// Get selected quality option
  QualityOption? get selectedQualityOption {
    if (_currentVideo == null) return null;
    try {
      return _currentVideo!.qualities.firstWhere(
            (q) => q.resolution == _selectedQuality,
      );
    } catch (e) {
      return _currentVideo!.qualities.isNotEmpty
          ? _currentVideo!.qualities.first
          : null;
    }
  }

  /// Get selected audio quality option - Uses fixed MP3 bitrate options
  AudioQualityOption? get selectedAudioQualityOption {
    if (_currentVideo == null) return null;
    // Use fixed MP3 quality options instead of YouTube's variable bitrates
    try {
      return AudioQualityOption.allQualities.firstWhere(
            (q) => q.bitrate == _selectedAudioQuality,
      );
    } catch (e) {
      return AudioQualityOption.allQualities.first;
    }
  }

  /// Get fixed audio quality options (32-320 kbps)
  List<AudioQualityOption> get audioQualityOptions => AudioQualityOption.allQualities;

  /// Validate URL
  bool isValidUrl(String url) {
    return _youtubeService.isValidUrl(url);
  }

  /// Fetch video info from URL - ALL FREE!
  Future<void> fetchVideo(String url) async {
    if (url.isEmpty) {
      _error = 'Please enter a URL';
      notifyListeners();
      return;
    }

    if (!_youtubeService.isValidUrl(url)) {
      _error = 'Invalid YouTube URL';
      notifyListeners();
      return;
    }

    _url = url;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentVideo = await _youtubeService.fetchVideoInfo(url);

      // Auto-select best available quality
      if (_currentVideo!.qualities.isNotEmpty) {
        // Try to select 1080p, fallback to first available
        final has1080 = _currentVideo!.qualities.any((q) => q.resolution == '1080p');
        _selectedQuality = has1080 ? '1080p' : _currentVideo!.qualities.first.resolution;
      }

      // Use fixed MP3 quality - default to 192kbps (good balance of quality/size)
      _selectedAudioQuality = '192kbps';

      _error = null;
    } on YouTubeException catch (e, st) {
      // Preserve the user-friendly message but print full debug info for copy/paste
      _error = e.message;
      _currentVideo = null;
      // Print detailed debug info to console (copy/pasteable)
      debugPrint('--- DEBUG: YouTubeException in fetchVideo ---');
      debugPrint('URL: $url');
      debugPrint('Exception: ${e.message}');
      debugPrint('StackTrace:\n$st');
      debugPrint('--- END DEBUG ---');
    } catch (e, st) {
      _error = 'Failed to fetch video. Please try again.';
      _currentVideo = null;
      // Print detailed debug info to console (copy/pasteable)
      debugPrint('--- DEBUG: Exception in fetchVideo ---');
      debugPrint('URL: $url');
      debugPrint('Exception: $e');
      debugPrint('StackTrace:\n$st');
      debugPrint('--- END DEBUG ---');
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Set selected video quality
  void setQuality(String quality) {
    _selectedQuality = quality;
    notifyListeners();
  }

  /// Set selected audio quality
  void setAudioQuality(String quality) {
    _selectedAudioQuality = quality;
    notifyListeners();
  }

  /// Toggle audio only mode
  void toggleAudioOnly() {
    _isAudioOnly = !_isAudioOnly;
    notifyListeners();
  }

  /// Set audio only mode
  void setAudioOnly(bool value) {
    _isAudioOnly = value;
    notifyListeners();
  }

  /// Clear current video
  void clearVideo() {
    _currentVideo = null;
    _error = null;
    _url = '';
    _selectedQuality = '1080p';
    _selectedAudioQuality = '320kbps';
    _isAudioOnly = false;
    notifyListeners();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Retry fetching video
  Future<void> retry() async {
    if (_url.isNotEmpty) {
      await fetchVideo(_url);
    }
  }
}