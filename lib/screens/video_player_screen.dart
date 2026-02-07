import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import '../core/utils/responsive.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoPath;
  final String videoTitle;

  const VideoPlayerScreen({
    super.key,
    required this.videoPath,
    required this.videoTitle,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  String? _errorMessage;
  bool _showOverlay = false;
  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.videoPath);
      if (!await file.exists()) {
        setState(() {
          _errorMessage = 'Video file not found';
        });
        return;
      }

      _videoPlayerController = VideoPlayerController.file(file);
      await _videoPlayerController.initialize();

      // Auto-rotate based on video resolution: landscape if width >= height, portrait otherwise.
      try {
        final size = _videoPlayerController.value.size;
        if (size.width > 0 && size.height > 0) {
          if (size.width >= size.height) {
            // Lock to landscape for wide videos
            await SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          } else {
            // Lock to portrait for tall videos
            await SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          }
        }
      } catch (_) {
        // Ignore orientation errors and continue
      }

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        showControls: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 16),
                Text(
                  'Error: $errorMessage',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      );

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load video: $e';
      });
    }
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _overlayTimer?.cancel();
    // Restore all orientations when leaving so app can rotate normally again
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: isLandscape
          ? null
          : AppBar(
              backgroundColor: Colors.black,
              title: Text(
                widget.videoTitle,
                style: const TextStyle(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            ),
      body: Center(
        child: _errorMessage != null
            ? Padding(
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
              )
            : _isInitialized && _chewieController != null
                ? Stack(
                    children: [
                      // Player
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            // Toggle overlay title
                            setState(() {
                              _showOverlay = !_showOverlay;
                            });
                            // Auto hide after 3 seconds
                            _overlayTimer?.cancel();
                            if (_showOverlay) {
                              _overlayTimer = Timer(const Duration(seconds: 3), () {
                                if (mounted) setState(() => _showOverlay = false);
                              });
                            }
                          },
                          child: Chewie(controller: _chewieController!),
                        ),
                      ),

                      // Top overlay bar (only in landscape): title left, action buttons right
                      if (isLandscape)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: SafeArea(
                            child: AnimatedOpacity(
                              opacity: _showOverlay ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: Container(
                                color: Colors.black45,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    // Title on the left
                                    Expanded(
                                      child: Text(
                                        widget.videoTitle,
                                        style: TextStyle(color: Colors.white, fontSize: responsive.sp(16)),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Action buttons on the right
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          tooltip: 'Close',
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          icon: const Icon(Icons.close, color: Colors.white),
                                        ),
                                        IconButton(
                                          tooltip: 'Share',
                                          onPressed: () async {
                                            // Share the file path or title
                                            try {
                                              final params = share_plus.ShareParams(text: widget.videoPath, subject: widget.videoTitle);
                                              await share_plus.SharePlus.instance.share(params);
                                            } catch (_) {
                                              // ignore
                                            }
                                          },
                                          icon: const Icon(Icons.share, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  )
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
      ),
    );
  }
}
