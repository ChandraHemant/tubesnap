import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';

class FreeFeaturesBanner extends StatelessWidget {
  final VoidCallback? onLearnMore;

  const FreeFeaturesBanner({super.key, this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.rs(20)),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
            theme.colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(responsive.rs(24)),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Icon
              Container(
                padding: EdgeInsets.all(responsive.rs(12)),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(responsive.rs(14)),
                ),
                child: Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: responsive.iconSize(mobile: 28, desktop: 32),
                ),
              ),
              SizedBox(width: responsive.rs(14)),

              // Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.tr('free.title'),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: responsive.sp(18),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: responsive.rs(8)),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.rs(10),
                            vertical: responsive.rs(4),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(responsive.rs(8)),
                          ),
                          child: Text(
                            '100% FREE',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontSize: responsive.sp(10),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.rs(4)),
                    Text(
                      context.tr('free.subtitle'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: responsive.sp(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.rs(16)),

          // Features Grid
          Wrap(
            spacing: responsive.rs(8),
            runSpacing: responsive.rs(8),
            children: [
              _buildFeatureChip(
                responsive,
                Icons.high_quality_rounded,
                context.tr('free.feature_4k'),
              ),
              _buildFeatureChip(
                responsive,
                Icons.all_inclusive_rounded,
                context.tr('free.feature_unlimited'),
              ),
              _buildFeatureChip(
                responsive,
                Icons.block_rounded,
                context.tr('free.feature_no_ads'),
              ),
              _buildFeatureChip(
                responsive,
                Icons.audiotrack_rounded,
                context.tr('free.feature_audio'),
              ),
              _buildFeatureChip(
                responsive,
                Icons.download_rounded,
                context.tr('free.feature_batch'),
              ),
              _buildFeatureChip(
                responsive,
                Icons.speed_rounded,
                context.tr('free.feature_fast'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(Responsive responsive, IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.rs(10),
        vertical: responsive.rs(6),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(responsive.rs(10)),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: responsive.rs(14),
          ),
          SizedBox(width: responsive.rs(6)),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.sp(11),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact version for smaller spaces
class FreeFeaturesBannerCompact extends StatelessWidget {
  const FreeFeaturesBannerCompact({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.rs(16),
        vertical: responsive.rs(12),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.secondary,
            theme.colorScheme.secondary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(responsive.rs(14)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_rounded,
            color: Colors.white,
            size: responsive.iconSize(mobile: 20),
          ),
          SizedBox(width: responsive.rs(10)),
          Expanded(
            child: Text(
              context.tr('free.compact_message'),
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.sp(12),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Features list for settings or about page
class FreeFeaturesList extends StatelessWidget {
  const FreeFeaturesList({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    final features = [
      (Icons.high_quality_rounded, context.tr('free.list_4k'), context.tr('free.list_4k_desc')),
      (Icons.all_inclusive_rounded, context.tr('free.list_unlimited'), context.tr('free.list_unlimited_desc')),
      (Icons.block_rounded, context.tr('free.list_no_ads'), context.tr('free.list_no_ads_desc')),
      (Icons.audiotrack_rounded, context.tr('free.list_audio'), context.tr('free.list_audio_desc')),
      (Icons.download_rounded, context.tr('free.list_batch'), context.tr('free.list_batch_desc')),
      (Icons.speed_rounded, context.tr('free.list_fast'), context.tr('free.list_fast_desc')),
      (Icons.folder_rounded, context.tr('free.list_organize'), context.tr('free.list_organize_desc')),
      (Icons.dark_mode_rounded, context.tr('free.list_themes'), context.tr('free.list_themes_desc')),
    ];

    return Card(
      child: Padding(
        padding: responsive.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(responsive.rs(10)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(responsive.rs(12)),
                  ),
                  child: Icon(
                    Icons.star_rounded,
                    color: Colors.white,
                    size: responsive.iconSize(mobile: 22),
                  ),
                ),
                SizedBox(width: responsive.rs(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('free.all_features'),
                        style: TextStyle(
                          fontSize: responsive.sp(16),
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        context.tr('free.no_hidden_costs'),
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
            ),
            SizedBox(height: responsive.rs(20)),

            // Features List
            ...features.map((feature) => Padding(
              padding: EdgeInsets.only(bottom: responsive.rs(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(responsive.rs(8)),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(responsive.rs(10)),
                    ),
                    child: Icon(
                      feature.$1,
                      color: theme.colorScheme.primary,
                      size: responsive.iconSize(mobile: 18),
                    ),
                  ),
                  SizedBox(width: responsive.rs(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature.$2,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: responsive.sp(14),
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: responsive.rs(2)),
                        Text(
                          feature.$3,
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle_rounded,
                    color: theme.colorScheme.secondary,
                    size: responsive.iconSize(mobile: 20),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}