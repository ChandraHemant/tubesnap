import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/responsive.dart';
import '../../l10n/app_localizations.dart';

class UrlInputCard extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onFetch;
  final bool isLoading;
  final String? error;

  const UrlInputCard({
    super.key,
    required this.controller,
    required this.onFetch,
    this.isLoading = false,
    this.error,
  });

  @override
  State<UrlInputCard> createState() => _UrlInputCardState();
}

class _UrlInputCardState extends State<UrlInputCard> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null && data!.text!.isNotEmpty) {
      widget.controller.text = data.text!;
      widget.controller.selection = TextSelection.fromPosition(
        TextPosition(offset: data.text!.length),
      );
    }
  }

  void _clearText() {
    widget.controller.clear();
  }

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
            _buildHeader(theme, responsive),
            SizedBox(height: responsive.rs(16)),

            // URL Input Field
            _buildInputField(theme, responsive),

            // Error Message
            if (widget.error != null) ...[
              SizedBox(height: responsive.rs(8)),
              _buildErrorMessage(theme, responsive),
            ],

            SizedBox(height: responsive.rs(16)),

            // Fetch Button
            _buildFetchButton(theme, responsive),

            SizedBox(height: responsive.rs(12)),

            // Supported Platforms Info
            _buildSupportedPlatforms(theme, responsive),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, Responsive responsive) {
    return Row(
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
    );
  }

  Widget _buildInputField(ThemeData theme, Responsive responsive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: BorderRadius.circular(responsive.rs(16)),
        border: Border.all(
          color: widget.error != null
              ? theme.colorScheme.error
              : theme.colorScheme.outline,
          width: widget.error != null ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Input Field
          Expanded(
            child: TextField(
              controller: widget.controller,
              enabled: !widget.isLoading,
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
                  size: responsive.iconSize(mobile: 22),
                ),
              ),
              onSubmitted: (_) => widget.onFetch(),
            ),
          ),

          // Clear Button (when text present)
          if (_hasText && !widget.isLoading)
            IconButton(
              onPressed: _clearText,
              icon: Icon(
                Icons.close_rounded,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                size: responsive.iconSize(mobile: 20),
              ),
              tooltip: 'Clear',
            ),

          // Paste Button
          Padding(
            padding: EdgeInsets.only(right: responsive.rs(8)),
            child: TextButton.icon(
              onPressed: widget.isLoading ? null : _pasteFromClipboard,
              icon: Icon(
                Icons.content_paste_rounded,
                size: responsive.iconSize(mobile: 16),
              ),
              label: Text(
                context.tr('home.paste_clipboard'),
                style: TextStyle(fontSize: responsive.sp(12)),
              ),
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.rs(12),
                  vertical: responsive.rs(8),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsive.rs(10)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme, Responsive responsive) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.rs(12),
        vertical: responsive.rs(8),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(responsive.rs(8)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: theme.colorScheme.error,
            size: responsive.iconSize(mobile: 16),
          ),
          SizedBox(width: responsive.rs(8)),
          Expanded(
            child: Text(
              widget.error!,
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: responsive.sp(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFetchButton(ThemeData theme, Responsive responsive) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.isLoading || !_hasText ? null : widget.onFetch,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: responsive.rs(16)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.rs(16)),
          ),
          elevation: 0,
          disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.5),
        ),
        child: widget.isLoading
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
              style: TextStyle(
                fontSize: responsive.sp(16),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportedPlatforms(ThemeData theme, Responsive responsive) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: theme.colorScheme.secondary,
          size: responsive.iconSize(mobile: 14),
        ),
        SizedBox(width: responsive.rs(6)),
        Text(
          'All Features Free • No Limits • No Ads',
          style: TextStyle(
            fontSize: responsive.sp(11),
            color: theme.colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}