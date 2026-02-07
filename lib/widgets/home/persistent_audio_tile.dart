import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/audio_player_provider.dart';
import '../../core/utils/responsive.dart';
import '../../screens/audio_player_screen.dart';

class PersistentAudioTile extends StatelessWidget {
  const PersistentAudioTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, audioProvider, child) {
        // Only show if audio is loaded
        if (!audioProvider.isInitialized || audioProvider.currentAudioPath == null || audioProvider.hasError) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final responsive = Responsive(context);

        return Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.rs(12))),
          elevation: 2,
          color: theme.colorScheme.surface,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(responsive.rs(12)),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Open the full audio player screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AudioPlayerScreen(
                        audioPath: audioProvider.currentAudioPath!,
                        audioTitle: audioProvider.currentAudioTitle ?? 'Playing',
                        thumbnailUrl: audioProvider.currentThumbnailUrl,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: responsive.rs(12), vertical: responsive.rs(10)),
                  child: Row(
                    children: [
                      // Thumbnail
                      Container(
                        width: responsive.rs(56),
                        height: responsive.rs(56),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(responsive.rs(8)),
                          color: theme.colorScheme.onSurface.withOpacity(0.05),
                        ),
                        child: audioProvider.currentThumbnailUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(responsive.rs(8)),
                                child: Image.network(
                                  audioProvider.currentThumbnailUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(Icons.music_note, size: responsive.rs(28));
                                  },
                                ),
                              )
                            : Icon(Icons.music_note, size: responsive.rs(28)),
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
                              style: TextStyle(fontSize: responsive.sp(14), fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: responsive.rs(6)),
                            Text(
                              audioProvider.isPlaying ? 'Playing' : 'Paused',
                              style: TextStyle(fontSize: responsive.sp(12), color: theme.colorScheme.onSurface.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),

                      // Play/Pause
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
                            icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            tooltip: playing ? 'Pause' : 'Play',
                          );
                        },
                      ),

                      // Stop button
                      IconButton(
                        onPressed: () {
                          audioProvider.stop();
                        },
                        icon: const Icon(Icons.stop_rounded),
                        tooltip: 'Stop',
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

