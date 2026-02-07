import 'dart:async';

import 'package:flutter/foundation.dart';
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
import '../widgets/home/persistent_audio_tile.dart';
import '../models/quality_model.dart';
import '../providers/share_intent_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  late AnimationController _animController;
  String? _lastProcessedSharedUrl;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final shareProvider = Provider.of<ShareIntentProvider>(context, listen: false);
        final videoProvider = Provider.of<VideoProvider>(context, listen: false);

        try {
          final last = shareProvider.lastSharedUrl;
          if (last != null && _lastProcessedSharedUrl != last) {
            _lastProcessedSharedUrl = last;
            if (kDebugMode) print('HomeScreen.initState: prefilling url from lastSharedUrl: $last');
            _urlController.text = last;
          }
        } catch (_) {}

        // Listener will check for pending shared urls and handle them once
        shareProvider.addListener(() {
          if (shareProvider.isPending && shareProvider.sharedUrl != null && _lastProcessedSharedUrl != shareProvider.sharedUrl) {
            if (kDebugMode) print('HomeScreen.shareListener: detected pending shared url: ${shareProvider.sharedUrl}');
            _lastProcessedSharedUrl = shareProvider.sharedUrl;
            // Use microtask to avoid modifying state during listener callback
            scheduleMicrotask(() {
              _handleSharedUrl(shareProvider.sharedUrl!, videoProvider, shareProvider);
            });
          } else {
            try {
              final last = shareProvider.lastSharedUrl;
              if (last != null && _lastProcessedSharedUrl != last) {
                if (kDebugMode) print('HomeScreen.shareListener: prefilling from lastSharedUrl: $last');
                _lastProcessedSharedUrl = last;
                _urlController.text = last;
              }
            } catch (_) {}
          }
        });
      } catch (e) {
        if (kDebugMode) print('HomeScreen.initState: failed to register share listener: $e');
      }
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _animController.dispose();

    super.dispose();
  }

  Future<void> _handleSharedUrl(String url, VideoProvider videoProvider, ShareIntentProvider shareProvider) async {
    if (kDebugMode) {
      print('HomeScreen._handleSharedUrl: received shared url: $url');
    }
    // Prefill the URL field and fetch the video details
    _urlController.text = url;
    shareProvider.setProcessing(true);
    try {
      if (kDebugMode) print('HomeScreen._handleSharedUrl: starting fetchVideo for $url');
      await videoProvider.fetchVideo(url);
      if (kDebugMode) print('HomeScreen._handleSharedUrl: fetchVideo completed for $url');
    } catch (e) {
      if (kDebugMode) print('HomeScreen._handleSharedUrl: fetchVideo failed for $url: $e');
    } finally {
      shareProvider.markAsProcessed();
      shareProvider.setProcessing(false);
      if (kDebugMode) print('HomeScreen._handleSharedUrl: shareProvider marked processed for $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = Responsive(context);
    final shareProvider = Provider.of<ShareIntentProvider>(context);
    final videoProvider = Provider.of<VideoProvider>(context, listen: false);

    // If there's a pending shared URL that we haven't processed yet, schedule a post-frame
    // callback to handle it once (avoid calling during build).
    if (shareProvider.isPending && shareProvider.sharedUrl != null && _lastProcessedSharedUrl != shareProvider.sharedUrl) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // double-check still pending
        if (shareProvider.isPending && shareProvider.sharedUrl != null && _lastProcessedSharedUrl != shareProvider.sharedUrl) {
          _lastProcessedSharedUrl = shareProvider.sharedUrl;
          _handleSharedUrl(shareProvider.sharedUrl!, videoProvider, shareProvider);
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: responsive.contentMaxWidth),
            child: Consumer2<VideoProvider, DownloadProvider>(
              builder: (context, videoProvider, downloadProvider, child) {
                // Make top area (header/banner/tile) fixed and rest scrollable
                return Padding(
                  padding: responsive.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(theme, responsive),
                      SizedBox(height: responsive.rs(24)),

                      // FREE Features Banner (No Premium!)
                      // const FreeFeaturesBanner(),
                      // SizedBox(height: responsive.rs(12)),

                      // Persistent Audio Tile fixed below banner
                      const PersistentAudioTile(),
                      SizedBox(height: responsive.rs(18)),

                      // Rest of the page scrolls
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                              SizedBox(height: responsive.rs(16)),
                            ],
                          ),
                        ),
                      ),
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

            // Dropdown selector which renders tile-like children
            _buildQualityDropdown(theme, responsive, videoProvider),
          ],
        ),
      ),
    );
  }

  // Build the dropdown that shows quality options. Each dropdown item uses the
  // same tile-like visuals (non-interactive) to match previous UI.
  Widget _buildQualityDropdown(ThemeData theme, Responsive responsive, VideoProvider videoProvider) {
    final isAudio = videoProvider.isAudioOnly;
    final options = isAudio ? videoProvider.audioQualityOptions : videoProvider.currentVideo!.qualities;
    final selectedValue = isAudio ? videoProvider.selectedAudioQuality : videoProvider.selectedQuality;

    // Small selector box that opens a bottom sheet with the full tile list.
    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) {
            final maxHeight = MediaQuery.of(ctx).size.height * 0.75;// allow up to 75% of screen
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.25,
              maxChildSize: 0.9,
              builder: (_, controller) {
                return Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(responsive.rs(16))),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  padding: EdgeInsets.all(responsive.rs(12)),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: EdgeInsets.only(bottom: responsive.rs(8)),
                        decoration: BoxDecoration(color: theme.colorScheme.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: responsive.rs(8)),
                        child: Row(
                          children: [
                            Expanded(child: Text(context.tr('home.select_quality'), style: TextStyle(fontSize: responsive.sp(16), fontWeight: FontWeight.w600))),
                            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Close')),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: controller,
                          itemCount: options.length,
                          itemBuilder: (c, i) {
                            final opt = options[i];
                            final key = isAudio ? (opt as dynamic).bitrate as String : (opt as dynamic).resolution as String;
                            final isSelected = key == selectedValue;
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: responsive.rs(6)),
                              child: InkWell(
                                onTap: () {
                                  if (isAudio) {
                                    videoProvider.setAudioQuality(key);
                                  } else {
                                    videoProvider.setQuality(key);
                                  }
                                  Navigator.of(ctx).pop();
                                },
                                child: _qualityTileWidget(theme, responsive, opt, isSelected: isSelected, isAudio: isAudio),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: responsive.rs(12), vertical: responsive.rs(14)),
        decoration: BoxDecoration(
          color: theme.colorScheme.background,
          borderRadius: BorderRadius.circular(responsive.rs(12)),
          border: Border.all(color: theme.colorScheme.outline),
        ),
        child: Row(
          children: [
            Expanded(child: Text(selectedValue, style: TextStyle(fontSize: responsive.sp(14), color: theme.colorScheme.onSurface))),
            Icon(Icons.arrow_drop_down_rounded, color: theme.colorScheme.onSurface),
          ],
        ),
      ),
    );
  }

  // Non-interactive tile used inside dropdown items so visual style remains the same
  Widget _qualityTileWidget(ThemeData theme, Responsive responsive, dynamic opt, {required bool isSelected, required bool isAudio}) {
    // opt may be QualityOption or AudioQualityOption
    final title = isAudio ? (opt.bitrate ?? '') : (opt.resolution ?? '');
    final subtitle = isAudio ? (opt.label ?? '') : (opt.label ?? '');
    final sizeText = opt.formattedSize ?? '';

    return Container(
      padding: EdgeInsets.all(responsive.rs(12)),
      decoration: BoxDecoration(
        color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : theme.colorScheme.surface,
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
                Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: responsive.sp(15), color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface)),
                SizedBox(height: responsive.rs(4)),
                Text(subtitle, style: TextStyle(fontSize: responsive.sp(12), color: theme.colorScheme.onSurface.withOpacity(0.6))),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: responsive.rs(10), vertical: responsive.rs(5)),
            decoration: BoxDecoration(color: theme.colorScheme.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(responsive.rs(8))),
            child: Text(sizeText, style: TextStyle(fontSize: responsive.sp(12), fontWeight: FontWeight.w700, color: theme.colorScheme.secondary)),
          ),
        ],
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

