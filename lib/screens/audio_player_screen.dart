import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:rxdart/rxdart.dart';
import '../core/utils/responsive.dart';

class AudioPlayerScreen extends StatefulWidget {
  final String audioPath;
  final String audioTitle;
  final String? thumbnailUrl;

  const AudioPlayerScreen({
    super.key,
    required this.audioPath,
    required this.audioTitle,
    this.thumbnailUrl,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen>
    with TickerProviderStateMixin {
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  String? _errorMessage;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.audioPath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Audio file not found';
        });
        return;
      }

      // Listen to player state to control rotation
      _audioPlayer.playerStateStream.listen((state) {
        if (state.playing) {
          _rotationController.repeat();
        } else {
          _rotationController.stop();
        }
      });

      // Set initialized to true BEFORE loading so UI shows immediately
      setState(() {
        _isInitialized = true;
      });

      await _audioPlayer.setFilePath(widget.audioPath);
      await _audioPlayer.play();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load audio: $e';
        _isInitialized = false;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        _audioPlayer.positionStream,
        _audioPlayer.bufferedPositionStream,
        _audioPlayer.durationStream,
        (position, bufferedPosition, duration) => PositionData(
          position,
          bufferedPosition,
          duration ?? Duration.zero,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.secondary.withOpacity(0.6),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
              child: _errorMessage != null
                  ? _buildErrorWidget(theme, responsive)
                  : _isInitialized
                      ? _buildPlayerWidget(theme, responsive)
                      : _buildLoadingWidget(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(ThemeData theme, Responsive responsive) {
    return Padding(
      padding: responsive.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: responsive.iconSize(mobile: 64, desktop: 96),
            color: Colors.red,
          ),
          SizedBox(height: responsive.rs(24)),
          Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.sp(16),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: responsive.rs(24)),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Go Back'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildPlayerWidget(ThemeData theme, Responsive responsive) {
    return Padding(
      padding: responsive.screenPadding,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Back button
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                  color: Colors.white,
                ),
              ],
            ),
        
            SizedBox(height: responsive.rs(24)),
        
            // Album Art / Rotating Disc
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: responsive.iconSize(mobile: 280, desktop: 400),
                height: responsive.iconSize(mobile: 280, desktop: 400),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                      theme.colorScheme.primary.withOpacity(0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Container(
                  margin: EdgeInsets.all(responsive.rs(40)),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.surface.withOpacity(0.9),
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    size: responsive.iconSize(mobile: 120, desktop: 180),
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
        
            SizedBox(height: responsive.rs(48)),
        
            // Title
            Text(
              widget.audioTitle,
              style: TextStyle(
                fontSize: responsive.sp(24),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        
            SizedBox(height: responsive.rs(12)),
        
            Text(
              'TubeSnap Audio',
              style: TextStyle(
                fontSize: responsive.sp(16),
                color: Colors.white.withOpacity(0.7),
              ),
            ),
        
            SizedBox(height: responsive.rs(48)),
        
            // Progress Bar
            StreamBuilder<PositionData>(
              stream: _positionDataStream,
              builder: (context, snapshot) {
                final positionData = snapshot.data;
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: responsive.rs(24)),
                  child: ProgressBar(
                    progress: positionData?.position ?? Duration.zero,
                    buffered: positionData?.bufferedPosition ?? Duration.zero,
                    total: positionData?.duration ?? Duration.zero,
                    onSeek: _audioPlayer.seek,
                    barHeight: 4,
                    thumbRadius: 8,
                    baseBarColor: Colors.white.withOpacity(0.3),
                    bufferedBarColor: Colors.white.withOpacity(0.5),
                    progressBarColor: Colors.white,
                    thumbColor: Colors.white,
                    timeLabelTextStyle: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: responsive.sp(14),
                    ),
                  ),
                );
              },
            ),
        
            SizedBox(height: responsive.rs(48)),
        
            // Playback Controls
            StreamBuilder<PlayerState>(
              stream: _audioPlayer.playerStateStream,
              builder: (context, snapshot) {
                final playerState = snapshot.data;
                final playing = playerState?.playing ?? false;
                final processingState = playerState?.processingState;
        
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Skip backward 10s
                    IconButton(
                      onPressed: () {
                        final newPosition = _audioPlayer.position - const Duration(seconds: 10);
                        _audioPlayer.seek(newPosition < Duration.zero ? Duration.zero : newPosition);
                      },
                      icon: const Icon(Icons.replay_10_rounded),
                      color: Colors.white,
                      iconSize: responsive.iconSize(mobile: 40),
                    ),
        
                    SizedBox(width: responsive.rs(24)),
        
                    // Play/Pause button
                    Container(
                      width: responsive.iconSize(mobile: 72),
                      height: responsive.iconSize(mobile: 72),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: processingState == ProcessingState.loading ||
                              processingState == ProcessingState.buffering
                          ? Padding(
                              padding: EdgeInsets.all(responsive.rs(20)),
                              child: CircularProgressIndicator(
                                color: theme.colorScheme.primary,
                                strokeWidth: 3,
                              ),
                            )
                          : IconButton(
                              onPressed: () {
                                if (playing) {
                                  _audioPlayer.pause();
                                } else {
                                  _audioPlayer.play();
                                }
                              },
                              icon: Icon(
                                playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: responsive.iconSize(mobile: 40),
                              ),
                              color: theme.colorScheme.primary,
                            ),
                    ),
        
                    SizedBox(width: responsive.rs(24)),
        
                    // Skip forward 10s
                    IconButton(
                      onPressed: () {
                        final duration = _audioPlayer.duration ?? Duration.zero;
                        final newPosition = _audioPlayer.position + const Duration(seconds: 10);
                        _audioPlayer.seek(newPosition > duration ? duration : newPosition);
                      },
                      icon: const Icon(Icons.forward_10_rounded),
                      color: Colors.white,
                      iconSize: responsive.iconSize(mobile: 40),
                    ),
                  ],
                );
              },
            ),
        
            SizedBox(height: responsive.rs(24)),
        
            // Loop button
            StreamBuilder<LoopMode>(
              stream: _audioPlayer.loopModeStream,
              builder: (context, snapshot) {
                final loopMode = snapshot.data ?? LoopMode.off;
                return IconButton(
                  onPressed: () {
                    _audioPlayer.setLoopMode(
                      loopMode == LoopMode.off ? LoopMode.one : LoopMode.off,
                    );
                  },
                  icon: Icon(
                    loopMode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  ),
                  color: loopMode == LoopMode.one ? theme.colorScheme.primary : Colors.white.withOpacity(0.5),
                  iconSize: responsive.iconSize(mobile: 28),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}
