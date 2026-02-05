class AppStrings {
  // App Info
  static const String appName = 'TubeSnap';
  static const String appTagline = 'Fast Video Downloader';
  static const String appTaglineHi = 'तेज़ वीडियो डाउनलोडर';

  // Placeholders
  static const String urlPlaceholder = 'https://youtube.com/watch?v=...';
  static const String searchPlaceholder = 'Search downloads...';

  // YouTube URL Patterns
  static const String youtubePattern = r'(youtube\.com|youtu\.be)';
  static const String videoIdPattern = r'[a-zA-Z0-9_-]{11}';

  // Error Messages
  static const String errorInvalidUrl = 'Please enter a valid YouTube URL';
  static const String errorNoInternet = 'No internet connection';
  static const String errorDownloadFailed = 'Download failed. Please try again';
  static const String errorFetchFailed = 'Failed to fetch video info';
  static const String errorStoragePermission = 'Storage permission required';
  static const String errorNoStorage = 'Not enough storage space';

  // Success Messages
  static const String successDownloadComplete = 'Download completed successfully!';
  static const String successCopied = 'Copied to clipboard';
  static const String successCacheCleared = 'Cache cleared successfully';
  static const String successHistoryCleared = 'History cleared successfully';

  // Confirmation Messages
  static const String confirmClearCache = 'Are you sure you want to clear the cache?';
  static const String confirmClearHistory = 'Are you sure you want to clear download history?';
  static const String confirmCancelDownload = 'Are you sure you want to cancel this download?';
  static const String confirmDeleteDownload = 'Are you sure you want to delete this download?';

  // Feature Labels (ALL FREE)
  static const String featureUnlimitedDownloads = 'Unlimited Downloads';
  static const String featureAllQualities = 'All Qualities (4K, 2K, 1080p...)';
  static const String featureBatchDownload = 'Batch Download';
  static const String featureBackgroundDownload = 'Background Download';
  static const String featureAudioExtract = 'Audio Extraction';
  static const String featureNoAds = 'No Ads - 100% Free';

  // Social Links
  static const String websiteUrl = 'https://tubesnap.app';
  static const String privacyUrl = 'https://tubesnap.app/privacy';
  static const String termsUrl = 'https://tubesnap.app/terms';
  static const String supportEmail = 'support@tubesnap.app';
  static const String githubUrl = 'https://github.com/tubesnap';
}