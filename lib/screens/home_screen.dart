import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/utils/responsive.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../providers/video_provider.dart';
import '../providers/download_provider.dart';
import '../widgets/home/free_features_banner.dart';
import '../widgets/home/video_preview_card.dart';
import '../models/quality_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
            child: Consumer2<VideoProvider, DownloadProvider>(
              builder: (context, videoProvider, downloadProvider, child) {
                return SingleChildScrollView(
                  padding: responsive.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme, responsive),
                      SizedBox(height: responsive.rs(24)),

                      // FREE Features Banner (No Premium!)
                      const FreeFeaturesBanner(),
                      SizedBox(height: responsive.rs(24)),

                      // URL Input Section
                      _buildUrlInputSection(theme, responsive, videoProvider),
                      SizedBox(height: responsive.rs(20)),

                      // Video Preview & Quality Selector
                      if (videoProvider.hasVideo) ...[
                        VideoPreviewCard(
                          title: videoProvider.currentVideo!.title,
                          channelName: videoProvider.currentVideo!.channelName,
                          duration: videoProvider.currentVideo!.formattedDuration,
                          views: videoProvider.currentVideo!.formattedViews,
                          thumbnailUrl: videoProvider.currentVideo!.thumbnailUrl,
                        ),
                        SizedBox(height: responsive.rs(20)),

                        _buildQualitySection(theme, responsive, videoProvider),
                        SizedBox(height: responsive.rs(20)),

                        _buildDownloadSection(theme, responsive, videoProvider, downloadProvider),
                        SizedBox(height: responsive.rs(32)),
                      ],

                      // Error Message
                      if (videoProvider.hasError)
                        _buildErrorCard(theme, responsive, videoProvider),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Responsive responsive) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final langProvider = Provider.of<LanguageProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Logo & Title
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              ).createShader(bounds),
              child: Text(
                context.tr('app_name'),
                style: TextStyle(
                  fontSize: responsive.sp(28),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            Text(
              context.tr('tagline'),
              style: TextStyle(
                fontSize: responsive.sp(14),
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),

        // Action Buttons
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(responsive.rs(16)),
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Language Toggle
              IconButton(
                onPressed: () => langProvider.toggleLanguage(),
                icon: Text(
                  langProvider.isHindi ? '🇺🇸' : '🇮🇳',
                  style: TextStyle(fontSize: responsive.sp(20)),
                ),
                tooltip: context.tr('settings.language'),
              ),

              // Theme Toggle
              IconButton(
                onPressed: () => themeProvider.toggleTheme(),
                icon: Icon(
                  themeProvider.isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: theme.colorScheme.primary,
                ),
                tooltip: context.tr('settings.dark_mode'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUrlInputSection(ThemeData theme, Responsive responsive, VideoProvider videoProvider) {
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
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(responsive.rs(12)),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color: theme.colorScheme.primary,
                    size: responsive.iconSize(mobile: 22),
                  ),
                ),
                SizedBox(width: responsive.rs(12)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('home.paste_link'),
                        style: TextStyle(
                          fontSize: responsive.sp(16),
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'YouTube, Shorts, Playlists',
                        style: TextStyle(
                          fontSize: responsive.sp(12),
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.rs(16)),

            // URL Input
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.circular(responsive.rs(16)),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      enabled: !videoProvider.isLoading,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: responsive.sp(14),
                      ),
                      decoration: InputDecoration(
                        hintText: context.tr('home.enter_url'),
                        hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(responsive.rs(16)),
                        prefixIcon: Icon(
                          Icons.play_circle_outline_rounded,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      onSubmitted: (_) => _fetchVideo(videoProvider),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: videoProvider.isLoading ? null : () async {
                      final data = await Clipboard.getData('text/plain');
                      if (data?.text != null) {
                        _urlController.text = data!.text!;
                      }
                    },
                    icon: Icon(Icons.content_paste_rounded, size: responsive.rs(16)),
                    label: Text(context.tr('home.paste_clipboard'), style: TextStyle(fontSize: responsive.sp(12))),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.primary),
                  ),
                  SizedBox(width: responsive.rs(8)),
                ],
              ),
            ),
            SizedBox(height: responsive.rs(16)),

            // Fetch Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: videoProvider.isLoading ? null : () => _fetchVideo(videoProvider),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: responsive.rs(16)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(responsive.rs(16)),
                  ),
                ),
                child: videoProvider.isLoading
                    ? SizedBox(
                  height: responsive.rs(22),
                  width: responsive.rs(22),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8)),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_rounded, size: responsive.iconSize(mobile: 22)),
                    SizedBox(width: responsive.rs(8)),
                    Text(
                      context.tr('home.fetch_video'),
                      style: TextStyle(fontSize: responsive.sp(16), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: responsive.rs(12)),

            // All FREE indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_rounded, color: theme.colorScheme.secondary, size: responsive.rs(14)),
                SizedBox(width: responsive.rs(6)),
                Text(
                  context.tr('home.all_free'),
                  style: TextStyle(
                    fontSize: responsive.sp(11),
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQualitySection(ThemeData theme, Responsive responsive, VideoProvider videoProvider) {
    final qualities = videoProvider.isAudioOnly
        ? videoProvider.currentVideo!.audioQualities
        : videoProvider.currentVideo!.qualities;

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
                        'All qualities FREE!',
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
            SizedBox(height: responsive.rs(12)),

            // Video/Audio Toggle
            _buildMediaToggle(theme, responsive, videoProvider),
            SizedBox(height: responsive.rs(16)),

            // Quality Options
            if (videoProvider.isAudioOnly)
              // Use fixed MP3 quality options (32-320 kbps)
              ...videoProvider.audioQualityOptions.map((q) => _buildAudioQualityTile(theme, responsive, videoProvider, q))
            else
              ...videoProvider.currentVideo!.qualities.map((q) => _buildVideoQualityTile(theme, responsive, videoProvider, q)),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaToggle(ThemeData theme, Responsive responsive, VideoProvider videoProvider) {
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
            child: _buildToggleBtn(theme, responsive, Icons.videocam_rounded, context.tr('quality.video_mode'), !videoProvider.isAudioOnly, () => videoProvider.setAudioOnly(false)),
          ),
          Expanded(
            child: _buildToggleBtn(theme, responsive, Icons.audiotrack_rounded, context.tr('quality.audio_mode'), videoProvider.isAudioOnly, () => videoProvider.setAudioOnly(true)),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(ThemeData theme, Responsive responsive, IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.rs(10)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: responsive.rs(16), vertical: responsive.rs(12)),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(responsive.rs(10)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: responsive.rs(18), color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6)),
            SizedBox(width: responsive.rs(8)),
            Text(label, style: TextStyle(fontSize: responsive.sp(13), fontWeight: FontWeight.w600, color: isSelected ? Colors.white : theme.colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoQualityTile(ThemeData theme, Responsive responsive, VideoProvider videoProvider, QualityOption q) {
    final isSelected = videoProvider.selectedQuality == q.resolution;
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.rs(8)),
      child: InkWell(
        onTap: () => videoProvider.setQuality(q.resolution),
        borderRadius: BorderRadius.circular(responsive.rs(12)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(responsive.rs(14)),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.background,
            borderRadius: BorderRadius.circular(responsive.rs(12)),
            border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              _buildRadio(theme, responsive, isSelected),
              SizedBox(width: responsive.rs(12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.resolution, style: TextStyle(fontWeight: FontWeight.w700, fontSize: responsive.sp(15), color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
                    Text(q.label, style: TextStyle(fontSize: responsive.sp(12), color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: responsive.rs(10), vertical: responsive.rs(5)),
                decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(responsive.rs(8))),
                child: Text(q.formattedSize, style: TextStyle(fontSize: responsive.sp(12), fontWeight: FontWeight.w700, color: theme.colorScheme.secondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioQualityTile(ThemeData theme, Responsive responsive, VideoProvider videoProvider, AudioQualityOption q) {
    final isSelected = videoProvider.selectedAudioQuality == q.bitrate;
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.rs(8)),
      child: InkWell(
        onTap: () => videoProvider.setAudioQuality(q.bitrate),
        borderRadius: BorderRadius.circular(responsive.rs(12)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(responsive.rs(14)),
          decoration: BoxDecoration(
            color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.background,
            borderRadius: BorderRadius.circular(responsive.rs(12)),
            border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline, width: isSelected ? 2 : 1),
          ),
          child: Row(
            children: [
              _buildRadio(theme, responsive, isSelected),
              SizedBox(width: responsive.rs(12)),
              Icon(Icons.audiotrack_rounded, color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5), size: responsive.rs(20)),
              SizedBox(width: responsive.rs(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(q.bitrate, style: TextStyle(fontWeight: FontWeight.w700, fontSize: responsive.sp(15), color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
                    Text(q.label, style: TextStyle(fontSize: responsive.sp(12), color: theme.colorScheme.onSurface.withOpacity(0.6))),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: responsive.rs(10), vertical: responsive.rs(5)),
                decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(responsive.rs(8))),
                child: Text(q.formattedSize, style: TextStyle(fontSize: responsive.sp(12), fontWeight: FontWeight.w700, color: theme.colorScheme.secondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadio(ThemeData theme, Responsive responsive, bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: responsive.rs(22),
      height: responsive.rs(22),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline, width: 2),
        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
      ),
      child: isSelected ? Icon(Icons.check_rounded, size: responsive.rs(14), color: Colors.white) : null,
    );
  }

  Widget _buildDownloadSection(ThemeData theme, Responsive responsive, VideoProvider videoProvider, DownloadProvider downloadProvider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _startDownload(videoProvider, downloadProvider),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.secondary,
          padding: EdgeInsets.symmetric(vertical: responsive.rs(18)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(responsive.rs(16))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.download_rounded, size: responsive.iconSize(mobile: 22)),
            SizedBox(width: responsive.rs(8)),
            Text(
              '${context.tr('home.download_now')} (${videoProvider.isAudioOnly ? videoProvider.selectedAudioQuality : videoProvider.selectedQuality})',
              style: TextStyle(fontSize: responsive.sp(16), fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, Responsive responsive, VideoProvider videoProvider) {
    return Card(
      color: theme.colorScheme.error.withOpacity(0.1),
      child: Padding(
        padding: responsive.cardPadding,
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
            SizedBox(width: responsive.rs(12)),
            Expanded(child: Text(videoProvider.error!, style: TextStyle(color: theme.colorScheme.error))),
            IconButton(
              onPressed: () => videoProvider.clearError(),
              icon: Icon(Icons.close_rounded, color: theme.colorScheme.error),
            ),
          ],
        ),
      ),
    );
  }

  void _fetchVideo(VideoProvider videoProvider) {
    if (_urlController.text.isNotEmpty) {
      videoProvider.fetchVideo(_urlController.text.trim());
    }
  }

  void _startDownload(VideoProvider videoProvider, DownloadProvider downloadProvider) {
    if (videoProvider.currentVideo == null) return;

    if (videoProvider.isAudioOnly) {
      downloadProvider.startAudioDownload(
        video: videoProvider.currentVideo!,
        quality: videoProvider.selectedAudioQualityOption!,
      );
    } else {
      downloadProvider.startDownload(
        video: videoProvider.currentVideo!,
        quality: videoProvider.selectedQualityOption!,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download started!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}