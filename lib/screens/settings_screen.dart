import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
            child: SingleChildScrollView(
              padding: responsive.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    context.tr('settings.title'),
                    style: TextStyle(
                      fontSize: responsive.sp(24),
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: responsive.rs(24)),

                  // Appearance Section
                  _buildSectionHeader(
                    theme: theme,
                    responsive: responsive,
                    icon: Icons.palette_rounded,
                    title: context.tr('settings.appearance'),
                  ),
                  SizedBox(height: responsive.rs(12)),
                  Card(
                    child: Column(
                      children: [
                        // Dark Mode
                        _SettingsTile(
                          icon: Icons.dark_mode_rounded,
                          iconColor: const Color(0xFF6366F1),
                          title: context.tr('settings.dark_mode'),
                          subtitle: context.tr('settings.dark_mode_desc'),
                          trailing: Switch.adaptive(
                            value: themeProvider.isDark,
                            onChanged: (_) => themeProvider.toggleTheme(),
                            activeColor: theme.colorScheme.primary,
                          ),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),

                        // Language
                        _SettingsTile(
                          icon: Icons.language_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: context.tr('settings.language'),
                          subtitle: context.tr('settings.language_desc'),
                          trailing: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.rs(12),
                              vertical: responsive.rs(6),
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(responsive.rs(8)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: langProvider.languageCode,
                                isDense: true,
                                borderRadius: BorderRadius.circular(responsive.rs(12)),
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: responsive.sp(14),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'en',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('🇺🇸', style: TextStyle(fontSize: responsive.sp(16))),
                                        SizedBox(width: responsive.rs(8)),
                                        Text(context.tr('settings.english')),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'hi',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('🇮🇳', style: TextStyle(fontSize: responsive.sp(16))),
                                        SizedBox(width: responsive.rs(8)),
                                        Text(context.tr('settings.hindi')),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    langProvider.setLanguage(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.rs(24)),

                  // Downloads Section
                  _buildSectionHeader(
                    theme: theme,
                    responsive: responsive,
                    icon: Icons.download_rounded,
                    title: context.tr('settings.downloads_section'),
                  ),
                  SizedBox(height: responsive.rs(12)),
                  Card(
                    child: Column(
                      children: [
                        // Download Location
                        _SettingsTile(
                          icon: Icons.folder_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: context.tr('settings.download_location'),
                          subtitle: '/storage/emulated/0/TubeSnap',
                          onTap: () => _showLocationPicker(context),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),

                        // Default Quality
                        _SettingsTile(
                          icon: Icons.high_quality_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: context.tr('settings.default_quality'),
                          subtitle: '1080p - Full HD',
                          onTap: () => _showQualityPicker(context, theme, responsive),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),

                        // WiFi Only
                        _SettingsTile(
                          icon: Icons.wifi_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          title: context.tr('settings.wifi_only'),
                          subtitle: context.tr('settings.wifi_only_desc'),
                          trailing: Switch.adaptive(
                            value: true,
                            onChanged: (_) {},
                            activeColor: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.rs(24)),

                  // Notifications Section
                  _buildSectionHeader(
                    theme: theme,
                    responsive: responsive,
                    icon: Icons.notifications_rounded,
                    title: context.tr('settings.notifications'),
                  ),
                  SizedBox(height: responsive.rs(12)),
                  Card(
                    child: _SettingsTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: context.tr('settings.notify_complete'),
                      subtitle: context.tr('settings.notify_complete_desc'),
                      trailing: Switch.adaptive(
                        value: true,
                        onChanged: (_) {},
                        activeColor: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  SizedBox(height: responsive.rs(24)),

                  // Storage Section
                  _buildSectionHeader(
                    theme: theme,
                    responsive: responsive,
                    icon: Icons.storage_rounded,
                    title: context.tr('settings.storage'),
                  ),
                  SizedBox(height: responsive.rs(12)),
                  Card(
                    child: Column(
                      children: [
                        // Storage Usage
                        Padding(
                          padding: EdgeInsets.all(responsive.rs(16)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Used: 2.4 GB',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  Text(
                                    'Free: 12.6 GB',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: responsive.rs(12)),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(responsive.rs(8)),
                                child: LinearProgressIndicator(
                                  value: 0.16,
                                  backgroundColor: theme.colorScheme.outline,
                                  valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                                  minHeight: responsive.rs(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline),

                        // Clear Cache
                        _SettingsTile(
                          icon: Icons.cleaning_services_rounded,
                          iconColor: const Color(0xFF06B6D4),
                          title: context.tr('settings.clear_cache'),
                          subtitle: '128 MB',
                          onTap: () => _showClearCacheDialog(context, theme, responsive),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),

                        // Clear History
                        _SettingsTile(
                          icon: Icons.history_rounded,
                          iconColor: const Color(0xFFEC4899),
                          title: context.tr('settings.clear_history'),
                          subtitle: context.tr('settings.clear_history_desc'),
                          onTap: () => _showClearHistoryDialog(context, theme, responsive),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.rs(24)),

                  // About Section
                  _buildSectionHeader(
                    theme: theme,
                    responsive: responsive,
                    icon: Icons.info_rounded,
                    title: context.tr('settings.about'),
                  ),
                  SizedBox(height: responsive.rs(12)),
                  Card(
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.star_rounded,
                          iconColor: const Color(0xFFF59E0B),
                          title: context.tr('settings.rate_app'),
                          onTap: () {},
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),
                        _SettingsTile(
                          icon: Icons.share_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: context.tr('settings.share_app'),
                          onTap: () {},
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),
                        _SettingsTile(
                          icon: Icons.privacy_tip_rounded,
                          iconColor: const Color(0xFF6366F1),
                          title: context.tr('settings.privacy_policy'),
                          onTap: () {},
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),
                        _SettingsTile(
                          icon: Icons.description_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: context.tr('settings.terms_of_service'),
                          onTap: () {},
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFF64748B),
                          title: context.tr('settings.version'),
                          subtitle: '1.0.0 (Build 1)',
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.rs(32)),

                  // App Logo & Social
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(responsive.rs(16)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.secondary,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(responsive.rs(20)),
                          ),
                          child: Icon(
                            Icons.play_circle_filled_rounded,
                            color: Colors.white,
                            size: responsive.iconSize(mobile: 40),
                          ),
                        ),
                        SizedBox(height: responsive.rs(12)),
                        Text(
                          'TubeSnap',
                          style: TextStyle(
                            fontSize: responsive.sp(18),
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: responsive.rs(4)),
                        Text(
                          'Made with ❤️ in India',
                          style: TextStyle(
                            fontSize: responsive.sp(12),
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        SizedBox(height: responsive.rs(16)),

                        // Social Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(theme, responsive, Icons.language, () {}),
                            SizedBox(width: responsive.rs(12)),
                            _buildSocialButton(theme, responsive, Icons.mail_rounded, () {}),
                            SizedBox(width: responsive.rs(12)),
                            _buildSocialButton(theme, responsive, Icons.code_rounded, () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.rs(32)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required ThemeData theme,
    required Responsive responsive,
    required IconData icon,
    required String title,
  }) {
    return Row(
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
    );
  }

  Widget _buildSocialButton(ThemeData theme, Responsive responsive, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.rs(12)),
      child: Container(
        padding: EdgeInsets.all(responsive.rs(12)),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(responsive.rs(12)),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Icon(
          icon,
          size: responsive.iconSize(mobile: 20),
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    // Implement folder picker
  }

  void _showQualityPicker(BuildContext context, ThemeData theme, Responsive responsive) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(responsive.rs(24))),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(responsive.rs(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('settings.default_quality'),
              style: TextStyle(
                fontSize: responsive.sp(18),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: responsive.rs(16)),
            ...['2160p - 4K', '1440p - 2K', '1080p - Full HD', '720p - HD', '480p - SD'].map(
                  (quality) => ListTile(
                title: Text(quality),
                leading: Radio(
                  value: quality,
                  groupValue: '1080p - Full HD',
                  onChanged: (_) => Navigator.pop(context),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ),
            SizedBox(height: responsive.rs(16)),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, ThemeData theme, Responsive responsive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.rs(20))),
        title: Text(context.tr('settings.clear_cache')),
        content: const Text('Are you sure you want to clear the cache? This will free up 128 MB of storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common.confirm')),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, ThemeData theme, Responsive responsive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.rs(20))),
        title: Text(context.tr('settings.clear_history')),
        content: Text(context.tr('settings.clear_history_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('common.delete')),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Settings Tile Widget
// ============================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(responsive.rs(16)),
        child: Row(
          children: [
            // Icon
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
                    ),
                  ],
                ],
              ),
            ),

            // Trailing
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
    );
  }
}