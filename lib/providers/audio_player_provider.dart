import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AudioPlayerProvider extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  String? _currentAudioPath;
  String? _currentAudioTitle;
  String? _currentThumbnailUrl;
  bool _isInitialized = false;
  String? _errorMessage;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  String? get currentAudioPath => _currentAudioPath;
  String? get currentAudioTitle => _currentAudioTitle;
  String? get currentThumbnailUrl => _currentThumbnailUrl;
  bool get isInitialized => _isInitialized;
  bool get isPlaying => _audioPlayer.playing;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;

  AudioPlayerProvider() {
    _initializeAudioPlayer();
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();

      // Configure audio session for background playback
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Listen to playback state changes
      _audioPlayer.playerStateStream.listen((state) {
        notifyListeners();
      });

      _isInitialized = true;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to initialize audio player: $e';
      _isInitialized = false;
      notifyListeners();
    }
  }

  /// Load and play an audio file
  Future<void> loadAndPlayAudio({
    required String audioPath,
    required String audioTitle,
    String? thumbnailUrl,
  }) async {
    try {
      _currentAudioPath = audioPath;
      _currentAudioTitle = audioTitle;
      _currentThumbnailUrl = thumbnailUrl;
      _errorMessage = null;

      await _audioPlayer.setFilePath(audioPath);
      await _audioPlayer.play();

      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load audio: $e';
      notifyListeners();
    }
  }

  /// Play audio
  Future<void> play() async {
    try {
      await _audioPlayer.play();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to play audio: $e';
      notifyListeners();
    }
  }

  /// Pause audio
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to pause audio: $e';
      notifyListeners();
    }
  }

  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to seek: $e';
      notifyListeners();
    }
  }

  /// Stop playing and clear
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentAudioPath = null;
      _currentAudioTitle = null;
      _currentThumbnailUrl = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to stop audio: $e';
      notifyListeners();
    }
  }

  /// Set loop mode
  Future<void> setLoopMode(LoopMode loopMode) async {
    try {
      await _audioPlayer.setLoopMode(loopMode);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to set loop mode: $e';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
