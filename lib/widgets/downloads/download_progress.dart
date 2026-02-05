import 'package:flutter/material.dart';
import 'package:tubesnap/core/utils/responsive.dart';
import 'package:tubesnap/l10n/app_localizations.dart';

class DownloadProgressCard extends StatelessWidget {
  final double progress;
  final String? speed;
  final String? eta;
  final String? downloaded;
  final String? total;
  final VoidCallback? onCancel;

  const DownloadProgressCard({
    super.key,
    required this.progress,
    this.speed,
    this.eta,
    this.downloaded,
    this.total,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Card(
      child: Padding(
        padding: responsive.cardPadding,
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.downloading_rounded,
                      color: theme.colorScheme.primary,
                      size: responsive.iconSize(mobile: 20),
                    ),
                    SizedBox(width: responsive.rs(8)),
                    Text(
                      context.tr('home.downloading'),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: responsive.sp(18),
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.rs(16)),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(responsive.rs(10)),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.outline.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                minHeight: responsive.rs(10),
              ),
            ),
            SizedBox(height: responsive.rs(12)),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (speed != null)
                  _buildStatItem(theme, responsive, Icons.speed_rounded, speed!),
                if (downloaded != null && total != null)
                  _buildStatItem(theme, responsive, Icons.storage_rounded, '$downloaded / $total'),
                if (eta != null)
                  _buildStatItem(theme, responsive, Icons.timer_rounded, eta!),
              ],
            ),

            // Cancel Button
            if (onCancel != null) ...[
              SizedBox(height: responsive.rs(12)),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: Icon(Icons.close_rounded, size: responsive.iconSize(mobile: 18)),
                  label: Text(context.tr('downloads.cancel')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                    padding: EdgeInsets.symmetric(vertical: responsive.rs(12)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(responsive.rs(12)),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, Responsive responsive, IconData icon, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: responsive.iconSize(mobile: 14),
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        SizedBox(width: responsive.rs(4)),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.sp(12),
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}