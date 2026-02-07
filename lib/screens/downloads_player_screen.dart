import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/utils/responsive.dart';
import '../providers/settings_provider.dart';
import 'audio_player_screen.dart';
import 'video_player_screen.dart';

class DownloadsPlayerScreen extends StatefulWidget {
  const DownloadsPlayerScreen({Key? key}) : super(key: key);

  @override
  State<DownloadsPlayerScreen> createState() => _DownloadsPlayerScreenState();
}

class _DownloadsPlayerScreenState extends State<DownloadsPlayerScreen> {
  late Future<List<FileSystemEntity>> _filesFuture;

  static const List<String> _audioExtensions = ['.mp3', '.m4a', '.aac', '.wav', '.ogg', '.flac'];
  static const List<String> _videoExtensions = ['.mp4', '.mkv', '.webm', '.mov', '.avi'];

  @override
  void initState() {
    super.initState();
    _refreshFiles();
  }

  void _refreshFiles() {
    final downloadPath = context.read<SettingsProvider>().downloadPath;
    _filesFuture = _listMediaFilesCombined(downloadPath);
  }

  Future<List<FileSystemEntity>> _listMediaFilesCombined(String? folderPath) async {
    if (folderPath == null || folderPath.isEmpty) return [];
    try {
      final dir = Directory(folderPath);
      if (!await dir.exists()) return [];
      final children = await dir.list().toList();
      final files = children.where((e) {
        if (e is! File) return false;
        final p = e.path.toLowerCase();
        return _audioExtensions.any((ext) => p.endsWith(ext)) || _videoExtensions.any((ext) => p.endsWith(ext));
      }).toList();
      files.sort((a, b) {
        final af = File(a.path);
        final bf = File(b.path);
        final at = af.lastModifiedSync();
        final bt = bf.lastModifiedSync();
        return bt.compareTo(at);
      });
      return files;
    } catch (_) {
      return [];
    }
  }

  bool _isAudio(String path) => _audioExtensions.any((ext) => path.toLowerCase().endsWith(ext));
  bool _isVideo(String path) => _videoExtensions.any((ext) => path.toLowerCase().endsWith(ext));

  String _basename(String path) => path.split(Platform.pathSeparator).last;

  String _filesizeString(FileSystemEntity entity) {
    try {
      final f = File(entity.path);
      final bytes = f.lengthSync();
      if (bytes < 1024) return '$bytes B';
      final kb = bytes / 1024;
      if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
      final mb = kb / 1024;
      return '${mb.toStringAsFixed(1)} MB';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final downloadPath = settingsProvider.downloadPath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloaded Media'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              setState(() {
                _refreshFiles();
              });
            },
          )
        ],
      ),
      body: Padding(
        padding: responsive.screenPadding,
        child: Column(
          children: [
            if (downloadPath == null || downloadPath.isEmpty) ...[
              SizedBox(height: responsive.rs(24)),
              Text('Download location not set.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
              SizedBox(height: responsive.rs(12)),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Open Settings'),
              ),
            ] else ...[
              Expanded(
                child: FutureBuilder<List<FileSystemEntity>>(
                  future: _filesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final files = snapshot.data ?? [];
                    if (files.isEmpty) {
                      return Center(
                        child: Text('No downloaded media found in the selected download folder.', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      );
                    }

                    return ListView.separated(
                      itemCount: files.length,
                      separatorBuilder: (_, __) => Divider(color: theme.colorScheme.outline),
                      itemBuilder: (context, index) {
                        final f = files[index];
                        final name = _basename(f.path);
                        final size = _filesizeString(f);
                        final isAudio = _isAudio(f.path);
                        final icon = isAudio ? Icons.audiotrack_rounded : Icons.videocam_rounded;

                        return ListTile(
                          leading: Icon(icon, color: theme.colorScheme.primary),
                          title: Text(name),
                          subtitle: Text(size),
                          onTap: () {
                            if (isAudio) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => AudioPlayerScreen(audioPath: f.path, audioTitle: name)));
                            } else if (_isVideo(f.path)) {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoPlayerScreen(videoPath: f.path, videoTitle: name)));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Unsupported file format')));
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
