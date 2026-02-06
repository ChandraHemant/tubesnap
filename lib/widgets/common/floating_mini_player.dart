import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/audio_player_provider.dart';
import '../../core/utils/responsive.dart';

class FloatingMiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const FloatingMiniPlayer({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        // Only show if audio is loaded and playing
        if (!audioProvider.isInitialized ||
            audioProvider.currentAudioPath == null ||
            audioProvider.hasError) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final responsive = Responsive(context);

        return Container(
          margin: EdgeInsets.all(responsive.rs(8)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.9),
                theme.colorScheme.secondary.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(responsive.rs(12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(responsive.rs(12)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: EdgeInsets.all(responsive.rs(12)),
                  child: Row(
                    children: [
                      // Thumbnail or icon
                      Container(
                        width: responsive.rs(48),
                        height: responsive.rs(48),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(responsive.rs(8)),
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: audioProvider.currentThumbnailUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(responsive.rs(8)),
                                child: Image.network(
                                  audioProvider.currentThumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.music_note,
                                      color: Colors.white,
                                      size: responsive.rs(24),
                                    );
                                  },
                                ),
                              )
                            : Icon(
                                Icons.music_note,
                                color: Colors.white,
                                size: responsive.rs(24),
                              ),
                      ),
                      SizedBox(width: responsive.rs(12)),

                      // Title and status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              audioProvider.currentAudioTitle ?? 'Playing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: responsive.sp(14),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: responsive.rs(4)),
                            Text(
                              audioProvider.isPlaying ? 'Playing in background' : 'Paused',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: responsive.sp(12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: responsive.rs(12)),

                      // Play/Pause button
                      StreamBuilder<PlayerState>(
                        stream: audioProvider.audioPlayer.playerStateStream,
                        builder: (context, snapshot) {
                          final playerState = snapshot.data;
                          final playing = playerState?.playing ?? false;

                          return IconButton(
                            onPressed: () {
                              if (playing) {
                                audioProvider.pause();
                              } else {
                                audioProvider.play();
                              }
                            },
                            icon: Icon(
                              playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: responsive.rs(24),
                            ),
                            constraints: BoxConstraints(
                              minWidth: responsive.rs(40),
                              minHeight: responsive.rs(40),
                            ),
                            padding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
