import 'package:flutter/material.dart';
import 'package:tubesnap/core/utils/responsive.dart';
import 'package:tubesnap/l10n/app_localizations.dart';

class QualitySelector extends StatelessWidget {
  final List<Map<String, dynamic>> qualities;
  final String selectedQuality;
  final ValueChanged<String> onQualitySelected;
  final bool isAudioOnly;
  final ValueChanged<bool>? onAudioOnlyChanged;

  const QualitySelector({
    super.key,
    required this.qualities,
    required this.selectedQuality,
    required this.onQualitySelected,
    this.isAudioOnly = false,
    this.onAudioOnlyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Card(
      child: Padding(
        padding: responsive.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(theme, responsive, context),
            SizedBox(height: responsive.rs(12)),

            // Audio/Video Toggle
            if (onAudioOnlyChanged != null) ...[
              _buildMediaToggle(theme, responsive, context),
              SizedBox(height: responsive.rs(16)),
            ],

            // Quality Options
            ...qualities.map((quality) {
              final isSelected = selectedQuality == quality['resolution'];
              return Padding(
                padding: EdgeInsets.only(bottom: responsive.rs(8)),
                child: _buildQualityOption(
                  theme: theme,
                  responsive: responsive,
                  quality: quality,
                  isSelected: isSelected,
                  context: context,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Responsive responsive, BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(responsive.rs(10)),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(responsive.rs(12)),
          ),
          child: Icon(
            Icons.high_quality_rounded,
            color: theme.colorScheme.secondary,
            size: responsive.iconSize(mobile: 22),
          ),
        ),
        SizedBox(width: responsive.rs(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('home.select_quality'),
                style: TextStyle(
                  fontSize: responsive.sp(16),
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'All qualities available - 100% FREE!',
                style: TextStyle(
                  fontSize: responsive.sp(12),
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMediaToggle(ThemeData theme, Responsive responsive, BuildContext context) {
    return Container(
      padding: EdgeInsets.all(responsive.rs(4)),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(responsive.rs(12)),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildToggleButton(
              theme: theme,
              responsive: responsive,
              icon: Icons.videocam_rounded,
              label: 'Video',
              isSelected: !isAudioOnly,
              onTap: () => onAudioOnlyChanged?.call(false),
            ),
          ),
          Expanded(
            child: _buildToggleButton(
              theme: theme,
              responsive: responsive,
              icon: Icons.audiotrack_rounded,
              label: 'Audio Only',
              isSelected: isAudioOnly,
              onTap: () => onAudioOnlyChanged?.call(true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required ThemeData theme,
    required Responsive responsive,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.rs(10)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.rs(16),
          vertical: responsive.rs(12),
        ),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(responsive.rs(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: responsive.iconSize(mobile: 18),
              color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
            ),
            SizedBox(width: responsive.rs(8)),
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.sp(13),
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption({
    required ThemeData theme,
    required Responsive responsive,
    required Map<String, dynamic> quality,
    required bool isSelected,
    required BuildContext context,
  }) {
    final isRecommended = quality['resolution'] == '1080p';

    return InkWell(
      onTap: () => onQualitySelected(quality['resolution']),
      borderRadius: BorderRadius.circular(responsive.rs(14)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(responsive.rs(14)),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : theme.colorScheme.background,
          borderRadius: BorderRadius.circular(responsive.rs(14)),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio Button
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: responsive.rs(22),
              height: responsive.rs(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
                  width: 2,
                ),
                color: isSelected ? theme.colorScheme.primary : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                Icons.check_rounded,
                size: responsive.rs(14),
                color: Colors.white,
              )
                  : null,
            ),
            SizedBox(width: responsive.rs(14)),

            // Quality Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        quality['resolution'],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: responsive.sp(15),
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (isRecommended) ...[
                        SizedBox(width: responsive.rs(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.rs(8),
                            vertical: responsive.rs(2),
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondary,
                            borderRadius: BorderRadius.circular(responsive.rs(6)),
                          ),
                          child: Text(
                            context.tr('quality.recommended'),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: responsive.sp(9),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: responsive.rs(2)),
                  Text(
                    context.tr(quality['label']),
                    style: TextStyle(
                      fontSize: responsive.sp(12),
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),

            // Size Badge
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.rs(12),
                vertical: responsive.rs(6),
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(responsive.rs(10)),
              ),
              child: Text(
                quality['size'],
                style: TextStyle(
                  fontSize: responsive.sp(12),
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}