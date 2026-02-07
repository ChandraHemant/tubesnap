/// Settings Screen
/// Developer: Hemant Kumar Chandra
///
/// A comprehensive settings screen for managing app preferences including
/// theme, language, download settings, notifications, storage management,
/// and app information.
library settings_screen;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:url_launcher/url_launcher.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/settings_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'downloads_player_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Future<PackageInfo> _packageInfo;
  late Future<Map<String, int>> _storageInfo;
  late Future<int> _cacheSize;

  @override
  void initState() {
    super.initState();
    _packageInfo = PackageInfo.fromPlatform();
    final settingsProvider = context.read<SettingsProvider>();
    _storageInfo = settingsProvider.getStorageInfo();
    _cacheSize = settingsProvider.getCacheSize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

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

                  // Downloaded Media Sections (Music & Videos)
                  _buildDownloadedMediaSection(theme, responsive, settingsProvider),
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
                            activeThumbColor: theme.colorScheme.primary,
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
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
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
                          subtitle: settingsProvider.downloadPath ?? '/storage/emulated/0/Download/TubeSnap',
                          onTap: () => _showLocationPicker(context, settingsProvider),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),

                        // Default Quality
                        _SettingsTile(
                          icon: Icons.high_quality_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: context.tr('settings.default_quality'),
                          subtitle: _getQualityLabel(settingsProvider.defaultQuality),
                          onTap: () => _showQualityPicker(context, theme, responsive, settingsProvider),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),

                        // WiFi Only
                        _SettingsTile(
                          icon: Icons.wifi_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          title: context.tr('settings.wifi_only'),
                          subtitle: context.tr('settings.wifi_only_desc'),
                          trailing: Switch.adaptive(
                            value: settingsProvider.wifiOnly,
                            onChanged: (value) => settingsProvider.setWifiOnly(value),
                            activeThumbColor: theme.colorScheme.primary,
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
                        value: settingsProvider.notifications,
                        onChanged: (value) => settingsProvider.setNotifications(value),
                        activeThumbColor: theme.colorScheme.primary,
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
                        FutureBuilder<Map<String, int>>(
                          future: _storageInfo,
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Padding(
                                padding: EdgeInsets.all(responsive.rs(16)),
                                child: const CircularProgressIndicator(),
                              );
                            }

                            final used = snapshot.data!['used'] ?? 0;
                            final free = snapshot.data!['free'] ?? 0;
                            final total = used + free;
                            final percentage = total > 0 ? used / total : 0.0;

                            final usedGB = (used / (1024 * 1024 * 1024)).toStringAsFixed(1);
                            final freeGB = (free / (1024 * 1024 * 1024)).toStringAsFixed(1);

                            return Padding(
                              padding: EdgeInsets.all(responsive.rs(16)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Used: $usedGB GB',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Free: $freeGB GB',
                                        style: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: responsive.rs(12)),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(responsive.rs(8)),
                                    child: LinearProgressIndicator(
                                      value: percentage.clamp(0.0, 1.0),
                                      backgroundColor: theme.colorScheme.outline,
                                      valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                                      minHeight: responsive.rs(8),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline),

                        // Clear Cache
                        FutureBuilder<int>(
                          future: _cacheSize,
                          builder: (context, snapshot) {
                            final cacheSizeMB = snapshot.hasData
                                ? (snapshot.data! / (1024 * 1024)).toStringAsFixed(1)
                                : 'Calculating...';

                            return _SettingsTile(
                              icon: Icons.cleaning_services_rounded,
                              iconColor: const Color(0xFF06B6D4),
                              title: context.tr('settings.clear_cache'),
                              subtitle: '$cacheSizeMB MB',
                              onTap: () => _showClearCacheDialog(context, theme, responsive, settingsProvider),
                            );
                          },
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),

                        // Clear History
                        _SettingsTile(
                          icon: Icons.history_rounded,
                          iconColor: const Color(0xFFEC4899),
                          title: context.tr('settings.clear_history'),
                          subtitle: context.tr('settings.clear_history_desc'),
                          onTap: () => _showClearHistoryDialog(context, theme, responsive, settingsProvider),
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
                          onTap: () => _launchPlayStore(),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),
                        _SettingsTile(
                          icon: Icons.share_rounded,
                          iconColor: const Color(0xFF10B981),
                          title: context.tr('settings.share_app'),
                          onTap: () => _shareApp(),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),
                        _SettingsTile(
                          icon: Icons.privacy_tip_rounded,
                          iconColor: const Color(0xFF6366F1),
                          title: context.tr('settings.privacy_policy'),
                          onTap: () => _launchURL('https://tubesnap.example.com/privacy'),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),
                        _SettingsTile(
                          icon: Icons.description_rounded,
                          iconColor: const Color(0xFF8B5CF6),
                          title: context.tr('settings.terms_of_service'),
                          onTap: () => _launchURL('https://tubesnap.example.com/terms'),
                        ),
                        Divider(height: 1, color: theme.colorScheme.outline, indent: 70),
                        FutureBuilder<PackageInfo>(
                          future: _packageInfo,
                          builder: (context, snapshot) {
                            final version = snapshot.hasData ? snapshot.data!.version : '1.0.0';
                            final buildNumber = snapshot.hasData ? snapshot.data!.buildNumber : '1';

                            return _SettingsTile(
                              icon: Icons.info_outline_rounded,
                              iconColor: const Color(0xFF64748B),
                              title: context.tr('settings.version'),
                              subtitle: '$version (Build $buildNumber)',
                            );
                          },
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
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        SizedBox(height: responsive.rs(4)),
                        Text(
                          'Developer: Hemant Kumar Chandra',
                          style: TextStyle(
                            fontSize: responsive.sp(11),
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: responsive.rs(16)),

                        // Social Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(
                              theme,
                              responsive,
                              Icons.language,
                              () => _launchURL('https://tubesnap.example.com'),
                            ),
                            SizedBox(width: responsive.rs(12)),
                            _buildSocialButton(
                              theme,
                              responsive,
                              Icons.mail_rounded,
                              () => _launchEmail('support@tubesnap.example.com'),
                            ),
                            SizedBox(width: responsive.rs(12)),
                            _buildSocialButton(
                              theme,
                              responsive,
                              Icons.code_rounded,
                              () => _launchURL('https://github.com/tubesnap'),
                            ),
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
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context, SettingsProvider settingsProvider) {
    // Simple path selector dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('settings.download_location')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('/storage/emulated/0/Download/TubeSnap'),
              onTap: () {
                settingsProvider.setDownloadPath('/storage/emulated/0/Download/TubeSnap');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('/storage/emulated/0/DCIM/TubeSnap'),
              onTap: () {
                settingsProvider.setDownloadPath('/storage/emulated/0/DCIM/TubeSnap');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getQualityLabel(String quality) {
    final qualityMap = {
      '2160p': '2160p - 4K',
      '1440p': '1440p - 2K',
      '1080p': '1080p - Full HD',
      '720p': '720p - HD',
      '480p': '480p - SD',
    };
    return qualityMap[quality] ?? quality;
  }

  void _showQualityPicker(BuildContext context, ThemeData theme, Responsive responsive, SettingsProvider settingsProvider) {
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
            ...[
              ('2160p', '2160p - 4K'),
              ('1440p', '1440p - 2K'),
              ('1080p', '1080p - Full HD'),
              ('720p', '720p - HD'),
              ('480p', '480p - SD'),
            ].map((item) {
              final isSelected = settingsProvider.defaultQuality == item.$1;
              return ListTile(
                title: Text(item.$2),
                leading: Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                onTap: () {
                  settingsProvider.setDefaultQuality(item.$1);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            SizedBox(height: responsive.rs(16)),
          ],
        ),
      ),
    );
  }

  void _showClearCacheDialog(BuildContext context, ThemeData theme, Responsive responsive, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.rs(20))),
        title: Text(context.tr('settings.clear_cache')),
        content: const Text('Are you sure you want to clear the cache? This will free up storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('common.cancel')),
          ),
          ElevatedButton(
            onPressed: () {
              settingsProvider.clearCache();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('Cache cleared successfully')),
              );
              setState(() {
                _cacheSize = settingsProvider.getCacheSize();
              });
            },
            child: Text(context.tr('common.confirm')),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context, ThemeData theme, Responsive responsive, SettingsProvider settingsProvider) {
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
            onPressed: () {
              settingsProvider.clearHistory();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: const Text('History cleared successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(context.tr('common.delete')),
          ),
        ],
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  Future<void> _shareApp() async {
    // Use SharePlus.instance.share with ShareParams to follow the newer API
    final params = share_plus.ShareParams(
      text: 'Check out TubeSnap - The best YouTube video downloader! Download it now from the Play Store.',
      subject: 'TubeSnap - Fast YouTube Downloader',
    );
    await share_plus.SharePlus.instance.share(params);
  }

  Future<void> _launchPlayStore() async {
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.tubesnap.app';
    await _launchURL(playStoreUrl);
  }

  Widget _buildDownloadedMediaSection(ThemeData theme, Responsive responsive, SettingsProvider settingsProvider) {
    final downloadPath = settingsProvider.downloadPath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Downloaded Media',
          style: TextStyle(fontSize: responsive.sp(16), fontWeight: FontWeight.w700, color: theme.colorScheme.onSurface),
        ),
        SizedBox(height: responsive.rs(12)),

        // Single Player Tile - opens combined downloads player screen
        Card(
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: responsive.rs(16), vertical: responsive.rs(12)),
            leading: Container(
              padding: EdgeInsets.all(responsive.rs(10)),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(responsive.rs(12)),
              ),
              child: Icon(Icons.play_circle_fill_rounded, color: Theme.of(context).colorScheme.primary, size: responsive.iconSize(mobile: 26)),
            ),
            title: Text('Player', style: TextStyle(fontSize: responsive.sp(14), fontWeight: FontWeight.w700)),
            subtitle: Text(downloadPath ?? '/storage/emulated/0/Download/TubeSnap', style: TextStyle(fontSize: responsive.sp(12))),
            trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => DownloadsPlayerScreen()));
            },
          ),
        ),

        SizedBox(height: responsive.rs(12)),

        // ...existing code (rest of settings page continues) ...
      ],
    );
  }
}

/// Settings Tile Widget
///
/// A reusable widget for displaying individual settings tiles with
/// an icon, title, subtitle, and optional trailing widget.
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
                color: iconColor.withValues(alpha: 0.1),
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
          ],
        ),
      ),
    );
  }
}
