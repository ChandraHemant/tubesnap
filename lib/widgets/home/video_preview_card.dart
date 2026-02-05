import 'package:flutter/material.dart';
import 'package:tubesnap/core/utils/responsive.dart';
import 'package:tubesnap/l10n/app_localizations.dart';

class VideoPreviewCard extends StatelessWidget {
  final String title;
  final String channelName;
  final String duration;
  final String views;
  final String? thumbnailUrl;

  const VideoPreviewCard({
    super.key,
    required this.title,
    required this.channelName,
    required this.duration,
    required this.views,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(responsive.rs(16)),
        child: responsive.isMobile
            ? _buildMobileLayout(theme, responsive, context)
            : _buildDesktopLayout(theme, responsive, context),
      ),
    );
  }

  Widget _buildMobileLayout(ThemeData theme, Responsive responsive, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        _buildThumbnail(theme, responsive),
        SizedBox(width: responsive.rs(16)),

        // Info
        Expanded(child: _buildVideoInfo(theme, responsive, context)),
      ],
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, Responsive responsive, BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large Thumbnail
        _buildThumbnail(theme, responsive, width: 200, height: 120),
        SizedBox(width: responsive.rs(20)),

        // Info
        Expanded(child: _buildVideoInfo(theme, responsive, context)),

        // Actions
        Column(
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.bookmark_border_rounded, color: theme.colorScheme.primary),
              tooltip: 'Save',
            ),
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.share_rounded, color: theme.colorScheme.onSurface.withOpacity(0.5)),
              tooltip: 'Share',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThumbnail(ThemeData theme, Responsive responsive, {double? width, double? height}) {
    return Container(
      width: responsive.rs(width ?? 120),
      height: responsive.rs(height ?? 80),
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
        children: [
          // Placeholder or Image
          if (thumbnailUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(responsive.rs(12)),
              child: Image.network(
                thumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => _buildPlaceholder(theme, responsive),
              ),
            )
          else
            _buildPlaceholder(theme, responsive),

          // Play Icon
          Center(
            child: Container(
              padding: EdgeInsets.all(responsive.rs(8)),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: responsive.iconSize(mobile: 24),
              ),
            ),
          ),

          // Duration Badge
          Positioned(
            bottom: responsive.rs(6),
            right: responsive.rs(6),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.rs(6),
                vertical: responsive.rs(3),
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(responsive.rs(4)),
              ),
              child: Text(
                duration,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.sp(10),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme, Responsive responsive) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(responsive.rs(12)),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.3),
            theme.colorScheme.secondary.withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.video_library_rounded,
          color: theme.colorScheme.primary.withOpacity(0.5),
          size: responsive.iconSize(mobile: 32),
        ),
      ),
    );
  }

  Widget _buildVideoInfo(ThemeData theme, Responsive responsive, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          title,
          style: TextStyle(
            fontSize: responsive.sp(14),
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: responsive.rs(6)),

        // Channel Name
        Row(
          children: [
            Icon(
              Icons.account_circle_rounded,
              size: responsive.iconSize(mobile: 16),
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
            SizedBox(width: responsive.rs(4)),
            Expanded(
              child: Text(
                channelName,
                style: TextStyle(
                  fontSize: responsive.sp(12),
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.rs(10)),

        // Stats Row
        Wrap(
          spacing: responsive.rs(8),
          runSpacing: responsive.rs(6),
          children: [
            _buildInfoChip(
              theme,
              responsive,
              Icons.access_time_rounded,
              duration,
            ),
            _buildInfoChip(
              theme,
              responsive,
              Icons.visibility_rounded,
              '$views ${context.tr("home.views")}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoChip(ThemeData theme, Responsive responsive, IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.rs(10),
        vertical: responsive.rs(5),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(responsive.rs(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: responsive.rs(14),
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: responsive.rs(6)),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.sp(12),
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}