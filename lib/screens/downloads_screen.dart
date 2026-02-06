import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../providers/download_provider.dart';
import '../models/download_model.dart';
import 'video_player_screen.dart';
import 'audio_player_screen.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);
    final downloadProvider = Provider.of<DownloadProvider>(context);

    final activeDownloads = downloadProvider.activeDownloads;
    final failedDownloads = downloadProvider.failedDownloads;
    final completedDownloads = downloadProvider.completedDownloads;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: responsive.screenPadding,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.tr('downloads.title'),
                        style: TextStyle(
                          fontSize: responsive.sp(24),
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          // clear all completed
                          await downloadProvider.clearCompleted();
                        },
                        icon: Icon(
                          Icons.delete_sweep_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        tooltip: context.tr('downloads.clear_all'),
                      ),
                    ],
                  ),
                ),

                // Tab Bar
                Container(
                  margin: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(responsive.rs(12)),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(responsive.rs(10)),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorPadding: EdgeInsets.all(responsive.rs(4)),
                    labelColor: Colors.white,
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.sp(14),
                    ),
                    dividerColor: Colors.transparent,
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.downloading_rounded, size: responsive.rs(18)),
                            SizedBox(width: responsive.rs(8)),
                            Text(context.tr('downloads.active')),
                            if (activeDownloads.isNotEmpty) ...[
                              SizedBox(width: responsive.rs(6)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.rs(6),
                                  vertical: responsive.rs(2),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(responsive.rs(10)),
                                ),
                                child: Text(
                                  '${activeDownloads.length}',
                                  style: TextStyle(fontSize: responsive.sp(10)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: responsive.rs(18)),
                            SizedBox(width: responsive.rs(8)),
                            Text(context.tr('downloads.completed')),
                            if (completedDownloads.isNotEmpty) ...[
                              SizedBox(width: responsive.rs(6)),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.rs(6),
                                  vertical: responsive.rs(2),
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(responsive.rs(10)),
                                ),
                                child: Text(
                                  '${completedDownloads.length}',
                                  style: TextStyle(fontSize: responsive.sp(10)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.rs(16)),

                // Tab Views
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Active Downloads
                      activeDownloads.isEmpty
                          ? _buildEmptyState(theme, responsive)
                          : _buildActiveList(theme, responsive, activeDownloads),

                      // Completed Downloads
                      (completedDownloads.isEmpty && failedDownloads.isEmpty)
                          ? _buildEmptyState(theme, responsive)
                          : _buildCompletedList(theme, responsive, completedDownloads, failedDownloads),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Responsive responsive) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(responsive.rs(24)),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download_rounded,
              size: responsive.iconSize(mobile: 48, desktop: 64),
              color: theme.colorScheme.primary.withOpacity(0.5),
            ),
          ),
          SizedBox(height: responsive.rs(24)),
          Text(
            context.tr('downloads.no_downloads'),
            style: TextStyle(
              fontSize: responsive.sp(18),
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: responsive.rs(8)),
          Text(
            context.tr('downloads.no_downloads_desc'),
            style: TextStyle(
              fontSize: responsive.sp(14),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActiveList(ThemeData theme, Responsive responsive, List<DownloadTask> activeDownloads) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      itemCount: activeDownloads.length,
      itemBuilder: (context, index) {
        final item = activeDownloads[index];
        return _buildDownloadCard(
          theme: theme,
          responsive: responsive,
          title: item.title,
          quality: item.quality,
          size: item.formattedSize,
          progress: item.progress,
          status: item.statusLabel,
          isActive: item.isActive,
          onPauseResume: () async {
            if (item.status == DownloadStatus.paused) {
              Provider.of<DownloadProvider>(context, listen: false).resumeDownload(item.id);
            } else {
              Provider.of<DownloadProvider>(context, listen: false).pauseDownload(item.id);
            }
          },
          onCancel: () async {
            Provider.of<DownloadProvider>(context, listen: false).cancelDownload(item.id);
          },
        );
      },
    );
  }

  Widget _buildCompletedList(ThemeData theme, Responsive responsive, List<DownloadTask> completedDownloads, List<DownloadTask> failedDownloads) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalPadding),
      // We'll display completed items first, then failed items (if any)
      itemCount: completedDownloads.length + failedDownloads.length + (completedDownloads.isNotEmpty && failedDownloads.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        // If there are completed items, render them first
        if (index < completedDownloads.length) {
          final item = completedDownloads[index];
          return _buildDownloadCard(
            theme: theme,
            responsive: responsive,
            title: item.title,
            quality: item.quality,
            size: item.formattedSize,
            date: item.completedAt != null ? item.completedAt!.toLocal().toString().split(' ').first : null,
            status: item.statusLabel,
            isActive: false,
            onOpen: () async {
              await _openFile(item.filePath, context);
            },
            onShare: () async {
              await _shareFile(item.filePath, item.title, context);
            },
            onDelete: () async {
              await Provider.of<DownloadProvider>(context, listen: false).deleteDownload(item.id);
            },
          );
        }

        // If both lists exist, insert a separator header between completed and failed
        if (completedDownloads.isNotEmpty && failedDownloads.isNotEmpty && index == completedDownloads.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: responsive.rs(8)),
            child: Text(
              context.tr('downloads.failed'),
              style: TextStyle(
                fontSize: responsive.sp(13),
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.error,
              ),
            ),
          );
        }

        // Otherwise render failed items
        final failedIndex = index - completedDownloads.length - (completedDownloads.isNotEmpty && failedDownloads.isNotEmpty ? 1 : 0);
        final item = failedDownloads[failedIndex];
        return _buildDownloadCard(
          theme: theme,
          responsive: responsive,
          title: item.title,
          quality: item.quality,
          size: item.formattedSize,
          date: item.completedAt != null ? item.completedAt!.toLocal().toString().split(' ').first : null,
          status: item.statusLabel,
          isActive: false,
          onOpen: () {},
          onShare: () {},
          onDelete: () async {
            await Provider.of<DownloadProvider>(context, listen: false).deleteDownload(item.id);
          },
        );
      },
    );
  }

  Widget _buildDownloadCard({
    required ThemeData theme,
    required Responsive responsive,
    required String title,
    required String quality,
    required String size,
    double? progress,
    String? date,
    required String status,
    required bool isActive,
    VoidCallback? onPauseResume,
    VoidCallback? onCancel,
    VoidCallback? onOpen,
    VoidCallback? onShare,
    VoidCallback? onDelete,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: responsive.rs(12)),
      child: Padding(
        padding: EdgeInsets.all(responsive.rs(16)),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: responsive.rs(64),
              height: responsive.rs(64),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(responsive.rs(12)),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.2),
                    theme.colorScheme.secondary.withOpacity(0.2),
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isActive && progress != null)
                    SizedBox(
                      width: responsive.rs(40),
                      height: responsive.rs(40),
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        backgroundColor: theme.colorScheme.outline,
                        valueColor: AlwaysStoppedAnimation(
                          status.toLowerCase().contains('pause')
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.primary,
                        ),
                      ),
                    )
                  else
                    Icon(
                      Icons.check_circle_rounded,
                      color: theme.colorScheme.secondary,
                      size: responsive.iconSize(mobile: 32),
                    ),

                  if (isActive && progress != null)
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: responsive.sp(10),
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(width: responsive.rs(16)),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: responsive.sp(14),
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: responsive.rs(8)),
                  Wrap(
                    children: [
                      _buildInfoChip(theme, responsive, Icons.high_quality_rounded, quality),
                      SizedBox(width: responsive.rs(8)),
                      _buildInfoChip(theme, responsive, Icons.storage_rounded, size),
                      if (date != null) ...[
                        SizedBox(width: responsive.rs(8)),
                        _buildInfoChip(theme, responsive, Icons.calendar_today_rounded, date),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Actions
            PopupMenuButton(
              icon: Icon(
                Icons.more_vert_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(responsive.rs(12)),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'pause_resume':
                    if (onPauseResume != null) onPauseResume();
                    break;
                  case 'cancel':
                    if (onCancel != null) onCancel();
                    break;
                  case 'open':
                    if (onOpen != null) onOpen();
                    break;
                  case 'share':
                    if (onShare != null) onShare();
                    break;
                  case 'delete':
                    if (onDelete != null) onDelete();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (isActive) ...[
                  PopupMenuItem(value: 'pause_resume', child: Row(children: [Icon(status == 'Paused' ? Icons.play_arrow_rounded : Icons.pause_rounded, size: responsive.iconSize(mobile: 20)), SizedBox(width: responsive.rs(12)), Text(status == 'Paused' ? context.tr('downloads.resume') : context.tr('downloads.pause'))])),
                  PopupMenuItem(value: 'cancel', child: Row(children: [Icon(Icons.close_rounded, size: responsive.iconSize(mobile: 20)), SizedBox(width: responsive.rs(12)), Text(context.tr('downloads.cancel'))])),
                ] else ...[
                  PopupMenuItem(value: 'open', child: Row(children: [Icon(Icons.play_circle_rounded, size: responsive.iconSize(mobile: 20)), SizedBox(width: responsive.rs(12)), Text(context.tr('downloads.open'))])),
                  PopupMenuItem(value: 'share', child: Row(children: [Icon(Icons.share_rounded, size: responsive.iconSize(mobile: 20)), SizedBox(width: responsive.rs(12)), Text(context.tr('downloads.share'))])),
                ],
                PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_rounded, size: responsive.iconSize(mobile: 20), color: Colors.red), SizedBox(width: responsive.rs(12)), Text(context.tr('downloads.delete'), style: const TextStyle(color: Colors.red))])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, Responsive responsive, IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.rs(8),
        vertical: responsive.rs(4),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(responsive.rs(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: responsive.rs(12), color: theme.colorScheme.primary),
          SizedBox(width: responsive.rs(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.sp(11),
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Open downloaded file in appropriate in-app player
  Future<void> _openFile(String filePath, BuildContext context) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('downloads.file_not_found')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Determine file type from extension
      final extension = filePath.split('.').last.toLowerCase();
      final fileName = filePath.split('/').last.split('.').first;

      if (!context.mounted) return;

      // Open appropriate player based on file type
      if (extension == 'mp3' || extension == 'm4a' || extension == 'webm' && fileName.contains('audio')) {
        // Open audio player for audio files
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => AudioPlayerScreen(
              audioPath: filePath,
              audioTitle: fileName.replaceAll('_', ' '),
            ),
          ),
        );
      } else {
        // Open video player for video files
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => VideoPlayerScreen(
              videoPath: filePath,
              videoTitle: fileName.replaceAll('_', ' '),
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('downloads.error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Share downloaded file
  Future<void> _shareFile(String filePath, String title, BuildContext context) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('downloads.file_not_found')),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: title,
        subject: 'Share from TubeSnap',
      );

      if (result.status == ShareResultStatus.unavailable) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('downloads.share_unavailable')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${context.tr('downloads.error')}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}