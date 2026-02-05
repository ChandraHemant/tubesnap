import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Helpers {
  // Private constructor to prevent instantiation
  Helpers._();

  /// Format file size from bytes to human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Format duration from seconds to HH:MM:SS or MM:SS
  static String formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Format view count to human readable (e.g., 1.2M, 500K)
  static String formatViewCount(int count) {
    if (count < 1000) return count.toString();
    if (count < 1000000) return '${(count / 1000).toStringAsFixed(1)}K';
    if (count < 1000000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    return '${(count / 1000000000).toStringAsFixed(1)}B';
  }

  /// Validate YouTube URL
  static bool isValidYouTubeUrl(String url) {
    final patterns = [
      RegExp(r'^(https?://)?(www\.)?youtube\.com/watch\?v=[\w-]+'),
      RegExp(r'^(https?://)?(www\.)?youtu\.be/[\w-]+'),
      RegExp(r'^(https?://)?(www\.)?youtube\.com/shorts/[\w-]+'),
      RegExp(r'^(https?://)?(m\.)?youtube\.com/watch\?v=[\w-]+'),
    ];
    return patterns.any((pattern) => pattern.hasMatch(url));
  }

  /// Extract video ID from YouTube URL
  static String? extractVideoId(String url) {
    final patterns = [
      RegExp(r'youtube\.com/watch\?v=([\w-]+)'),
      RegExp(r'youtu\.be/([\w-]+)'),
      RegExp(r'youtube\.com/shorts/([\w-]+)'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(url);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// Get thumbnail URL from video ID
  static String getThumbnailUrl(String videoId, {String quality = 'maxresdefault'}) {
    // Quality options: default, mqdefault, hqdefault, sddefault, maxresdefault
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  /// Copy text to clipboard
  static Future<void> copyToClipboard(String text, {BuildContext? context}) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context != null && context.mounted) {
      showSnackBar(context, 'Copied to clipboard');
    }
  }

  /// Get text from clipboard
  static Future<String?> getFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    return data?.text;
  }

  /// Show snackbar
  static void showSnackBar(
      BuildContext context,
      String message, {
        Duration duration = const Duration(seconds: 2),
        SnackBarAction? action,
        Color? backgroundColor,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show loading dialog
  static void showLoadingDialog(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message),
            ],
          ],
        ),
      ),
    );
  }

  /// Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Show confirmation dialog
  static Future<bool> showConfirmDialog(
      BuildContext context, {
        required String title,
        required String message,
        String confirmText = 'Confirm',
        String cancelText = 'Cancel',
        Color? confirmColor,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Get relative time string
  static String getRelativeTime(DateTime dateTime, {bool isHindi = false}) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return isHindi ? 'अभी' : 'Just now';
    }
    if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return isHindi ? '$mins मिनट पहले' : '$mins minutes ago';
    }
    if (difference.inHours < 24) {
      final hours = difference.inHours;
      return isHindi ? '$hours घंटे पहले' : '$hours hours ago';
    }
    if (difference.inDays < 7) {
      final days = difference.inDays;
      return isHindi ? '$days दिन पहले' : '$days days ago';
    }
    if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return isHindi ? '$weeks सप्ताह पहले' : '$weeks weeks ago';
    }
    if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return isHindi ? '$months महीने पहले' : '$months months ago';
    }
    final years = (difference.inDays / 365).floor();
    return isHindi ? '$years साल पहले' : '$years years ago';
  }
}
