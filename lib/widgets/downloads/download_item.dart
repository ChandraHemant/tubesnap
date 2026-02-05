import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../../models/download_model.dart';
import '../../l10n/app_localizations.dart';

class DownloadItem extends StatelessWidget {
  final DownloadTask task;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final VoidCallback? onDelete;
  final VoidCallback? onOpen;
  final VoidCallback? onShare;

  const DownloadItem({
    super.key,
    required this.task,
    this.onPause,
    this.onResume,
    this.onCancel,
    this.onRetry,
    this.onDelete,
    this.onOpen,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Card(
      margin: EdgeInsets.only(bottom: responsive.rs(12)),
      child: Padding(
        padding: EdgeInsets.all(responsive.rs(16)),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail with Status
                _buildThumbnail(theme, responsive),
                SizedBox(width: responsive.rs(16)),

                // Info
                Expanded(
                  child: _buildInfo(theme, responsive, context),
                ),

                // Actions Menu
                _buildActionsMenu(theme, responsive, context),
              ],
            ),

            // Progress Bar (for active downloads)
            if (task.isActive || task.status == DownloadStatus.paused) ...[
              SizedBox(height: responsive.rs(12)),
              _buildProgressBar(theme, responsive),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme, Responsive responsive) {
    return Stack(
      children: [
        // Thumbnail
        Container(
          width: responsive.rs(70),
          height: responsive.rs(70),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsive.rs(14)),
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary.withOpacity(0.2),
                theme.colorScheme.secondary.withOpacity(0.2),
              ],
            ),
            image: task.thumbnailUrl.isNotEmpty
                ? DecorationImage(
              image: NetworkImage(task.thumbnailUrl),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: task.thumbnailUrl.isEmpty
              ? Icon(
            Icons.video_library_rounded,
            color: theme.colorScheme.primary.withOpacity(0.5),
            size: responsive.iconSize(mobile: 28),
          )
              : null,
        ),

        // Status Overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(responsive.rs(14)),
              color: Colors.black.withOpacity(0.3),
            ),
            child: Center(
              child: _buildStatusIcon(theme, responsive),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(ThemeData theme, Responsive responsive) {
    IconData icon;
    Color color;
    bool showProgress = false;

    switch (task.status) {
      case DownloadStatus.queued:
        icon = Icons.hourglass_top_rounded;
        color = Colors.white;
        break;
      case DownloadStatus.downloading:
        showProgress = true;
        icon = Icons.downloading_rounded;
        color = theme.colorScheme.primary;
        break;
      case DownloadStatus.paused:
        icon = Icons.pause_rounded;
        color = Colors.amber;
        break;
      case DownloadStatus.completed:
        icon = Icons.check_circle_rounded;
        color = theme.colorScheme.secondary;
        break;
      case DownloadStatus.failed:
        icon = Icons.error_rounded;
        color = theme.colorScheme.error;
        break;
      case DownloadStatus.cancelled:
        icon = Icons.cancel_rounded;
        color = Colors.grey;
        break;
    }

    if (showProgress) {
      return Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: responsive.rs(36),
            height: responsive.rs(36),
            child: CircularProgressIndicator(
              value: task.progress,
              strokeWidth: 3,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          Text(
            '${task.progressPercent}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.sp(10),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Icon(
      icon,
      color: color,
      size: responsive.iconSize(mobile: 28),
    );
  }

  Widget _buildInfo(ThemeData theme, Responsive responsive, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: responsive.sp(14),
            color: theme.colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: responsive.rs(8)),

        // Info Chips
        Wrap(
          spacing: responsive.rs(8),
          runSpacing: responsive.rs(6),
          children: [
            _buildInfoChip(
              theme,
              responsive,
              Icons.high_quality_rounded,
              task.quality,
            ),
            _buildInfoChip(
              theme,
              responsive,
              Icons.storage_rounded,
              task.formattedSize,
            ),
            if (task.status == DownloadStatus.downloading && task.speed != null)
              _buildInfoChip(
                theme,
                responsive,
                Icons.speed_rounded,
                task.speed!,
                isHighlighted: true,
              ),
          ],
        ),

        // Status Message
        if (task.status == DownloadStatus.failed && task.errorMessage != null) ...[
          SizedBox(height: responsive.rs(6)),
          Text(
            task.errorMessage!,
            style: TextStyle(
              color: theme.colorScheme.error,
              fontSize: responsive.sp(11),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(
      ThemeData theme,
      Responsive responsive,
      IconData icon,
      String label, {
        bool isHighlighted = false,
      }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.rs(8),
        vertical: responsive.rs(4),
      ),
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.secondary.withOpacity(0.1)
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(responsive.rs(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: responsive.rs(12),
            color: isHighlighted ? theme.colorScheme.secondary : theme.colorScheme.primary,
          ),
          SizedBox(width: responsive.rs(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.sp(11),
              color: isHighlighted ? theme.colorScheme.secondary : theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(ThemeData theme, Responsive responsive) {
    return Column(
      children: [
        // Progress Info Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              task.status == DownloadStatus.paused ? 'Paused' : 'Downloading...',
              style: TextStyle(
                fontSize: responsive.sp(12),
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            if (task.eta != null)
              Text(
                'ETA: ${task.eta}',
                style: TextStyle(
                  fontSize: responsive.sp(12),
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        SizedBox(height: responsive.rs(8)),

        // Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(responsive.rs(6)),
          child: LinearProgressIndicator(
            value: task.progress,
            backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
            valueColor: AlwaysStoppedAnimation(
              task.status == DownloadStatus.paused
                  ? Colors.amber
                  : theme.colorScheme.primary,
            ),
            minHeight: responsive.rs(6),
          ),
        ),
      ],
    );
  }

  Widget _buildActionsMenu(ThemeData theme, Responsive responsive, BuildContext context) {
    return PopupMenuButton(
      icon: Icon(
        Icons.more_vert_rounded,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.rs(14)),
      ),
      itemBuilder: (context) => [
        // Active download actions
        if (task.status == DownloadStatus.downloading)
          _buildMenuItem(
            context,
            responsive,
            Icons.pause_rounded,
            context.tr('downloads.pause'),
            onPause,
          ),

        if (task.status == DownloadStatus.paused)
          _buildMenuItem(
            context,
            responsive,
            Icons.play_arrow_rounded,
            context.tr('downloads.resume'),
            onResume,
          ),

        if (task.isActive)
          _buildMenuItem(
            context,
            responsive,
            Icons.close_rounded,
            context.tr('downloads.cancel'),
            onCancel,
          ),

        // Completed download actions
        if (task.status == DownloadStatus.completed) ...[
          _buildMenuItem(
            context,
            responsive,
            Icons.play_circle_rounded,
            context.tr('downloads.open'),
            onOpen,
          ),
          _buildMenuItem(
            context,
            responsive,
            Icons.share_rounded,
            context.tr('downloads.share'),
            onShare,
          ),
        ],

        // Failed download actions
        if (task.status == DownloadStatus.failed)
          _buildMenuItem(
            context,
            responsive,
            Icons.refresh_rounded,
            context.tr('downloads.retry'),
            onRetry,
          ),

        // Delete action (always available)
        _buildMenuItem(
          context,
          responsive,
          Icons.delete_rounded,
          context.tr('downloads.delete'),
          onDelete,
          isDestructive: true,
        ),
      ],
    );
  }

  PopupMenuItem _buildMenuItem(
      BuildContext context,
      Responsive responsive,
      IconData icon,
      String label,
      VoidCallback? onTap, {
        bool isDestructive = false,
      }) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return PopupMenuItem(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: responsive.iconSize(mobile: 20), color: color),
          SizedBox(width: responsive.rs(12)),
          Text(label, style: TextStyle(color: color)),
        ],
      ),
    );
  }
}