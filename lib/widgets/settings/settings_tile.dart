import 'package:flutter/material.dart';
import 'package:tubesnap/core/utils/responsive.dart';

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.all(responsive.rs(16)),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(responsive.rs(10)),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(responsive.rs(12)),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: responsive.iconSize(mobile: 20),
                  ),
                ),
                SizedBox(width: responsive.rs(16)),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: responsive.sp(15),
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: responsive.rs(2)),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing Widget
                if (trailing != null)
                  trailing!
                else if (onTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: theme.colorScheme.outline,
            indent: responsive.rs(70),
          ),
      ],
    );
  }
}

/// Settings Section Header
class SettingsSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;

  const SettingsSectionHeader({
    super.key,
    required this.icon,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Padding(
      padding: EdgeInsets.only(
        left: responsive.rs(4),
        bottom: responsive.rs(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: responsive.iconSize(mobile: 18),
            color: theme.colorScheme.primary,
          ),
          SizedBox(width: responsive.rs(8)),
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.sp(14),
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}