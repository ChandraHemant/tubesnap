import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';

class PremiumBanner extends StatelessWidget {
  final VoidCallback? onUpgrade;

  const PremiumBanner({super.key, this.onUpgrade});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.rs(20)),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFD946EF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(responsive.rs(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(responsive.rs(14)),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(responsive.rs(16)),
            ),
            child: Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: responsive.iconSize(mobile: 32, desktop: 40),
            ),
          ),
          SizedBox(width: responsive.rs(16)),

          // Text Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      context.tr('premium.title'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.sp(18),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: responsive.rs(8)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.rs(8),
                        vertical: responsive.rs(2),
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(responsive.rs(6)),
                      ),
                      child: Text(
                        'PRO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsive.sp(10),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.rs(6)),

                // Features Row
                Wrap(
                  spacing: responsive.rs(8),
                  runSpacing: responsive.rs(4),
                  children: [
                    _buildFeatureChip(responsive, Icons.all_inclusive_rounded, context.tr('premium.feature_1')),
                    _buildFeatureChip(responsive, Icons.block_rounded, context.tr('premium.feature_2')),
                    _buildFeatureChip(responsive, Icons.hd_rounded, context.tr('premium.feature_3')),
                  ],
                ),
              ],
            ),
          ),

          // Upgrade Button (for desktop/tablet)
          if (!responsive.isMobile) ...[
            SizedBox(width: responsive.rs(16)),
            _buildUpgradeButton(context, responsive),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureChip(Responsive responsive, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: responsive.rs(12)),
        SizedBox(width: responsive.rs(4)),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: responsive.sp(11),
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeButton(BuildContext context, Responsive responsive) {
    return ElevatedButton(
      onPressed: onUpgrade ?? () => _showPremiumDialog(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6366F1),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.rs(20),
          vertical: responsive.rs(12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.rs(12)),
        ),
        elevation: 0,
      ),
      child: Text(
        context.tr('premium.upgrade'),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: responsive.sp(14),
        ),
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: responsive.hp(75),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(responsive.rs(32)),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: responsive.rs(12)),
              width: responsive.rs(40),
              height: responsive.rs(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.outline,
                borderRadius: BorderRadius.circular(responsive.rs(2)),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsive.rs(24)),
                child: Column(
                  children: [
                    // Premium Icon
                    Container(
                      padding: EdgeInsets.all(responsive.rs(20)),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFFD946EF)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        color: Colors.white,
                        size: responsive.iconSize(mobile: 48),
                      ),
                    ),
                    SizedBox(height: responsive.rs(20)),

                    Text(
                      context.tr('premium.title'),
                      style: TextStyle(
                        fontSize: responsive.sp(24),
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: responsive.rs(8)),
                    Text(
                      context.tr('premium.subtitle'),
                      style: TextStyle(
                        fontSize: responsive.sp(14),
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    SizedBox(height: responsive.rs(32)),

                    // Features List
                    ...[
                      (Icons.all_inclusive_rounded, context.tr('premium.feature_1')),
                      (Icons.block_rounded, context.tr('premium.feature_2')),
                      (Icons.hd_rounded, context.tr('premium.feature_3')),
                      (Icons.download_rounded, context.tr('premium.feature_4')),
                      (Icons.support_agent_rounded, context.tr('premium.feature_5')),
                    ].map((feature) => Padding(
                      padding: EdgeInsets.only(bottom: responsive.rs(12)),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(responsive.rs(8)),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              feature.$1,
                              color: theme.colorScheme.primary,
                              size: responsive.iconSize(mobile: 20),
                            ),
                          ),
                          SizedBox(width: responsive.rs(16)),
                          Text(
                            feature.$2,
                            style: TextStyle(
                              fontSize: responsive.sp(15),
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    )),
                    SizedBox(height: responsive.rs(24)),

                    // Pricing Options
                    Row(
                      children: [
                        Expanded(
                          child: _buildPriceCard(
                            context,
                            responsive,
                            theme,
                            context.tr('premium.monthly'),
                            '₹149',
                            '/mo',
                            false,
                          ),
                        ),
                        SizedBox(width: responsive.rs(12)),
                        Expanded(
                          child: _buildPriceCard(
                            context,
                            responsive,
                            theme,
                            context.tr('premium.yearly'),
                            '₹999',
                            '/yr',
                            true,
                            badge: '${context.tr("premium.save")} 44%',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.rs(24)),

                    // Upgrade Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: responsive.rs(18)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(responsive.rs(16)),
                          ),
                        ),
                        child: Text(
                          context.tr('premium.upgrade'),
                          style: TextStyle(
                            fontSize: responsive.sp(16),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.rs(12)),

                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(context.tr('premium.restore')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(
      BuildContext context,
      Responsive responsive,
      ThemeData theme,
      String title,
      String price,
      String period,
      bool isPopular, {
        String? badge,
      }) {
    return Container(
      padding: EdgeInsets.all(responsive.rs(16)),
      decoration: BoxDecoration(
        color: isPopular ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(responsive.rs(16)),
        border: Border.all(
          color: isPopular ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          if (badge != null) ...[
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.rs(8),
                vertical: responsive.rs(4),
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFD946EF)],
                ),
                borderRadius: BorderRadius.circular(responsive.rs(6)),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: responsive.sp(10),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(height: responsive.rs(8)),
          ],
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.sp(12),
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: responsive.rs(4)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: TextStyle(
                  fontSize: responsive.sp(24),
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(bottom: responsive.rs(4)),
                child: Text(
                  period,
                  style: TextStyle(
                    fontSize: responsive.sp(12),
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}