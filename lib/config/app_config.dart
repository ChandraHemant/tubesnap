class AppConfig {
  // App Information
  static const String appName = 'TubeSnap';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String packageName = 'com.tubesnap.app';

  // API Configuration (if using backend)
  static const String baseUrl = 'https://api.tubesnap.com';
  static const int connectionTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000;

  // Download Configuration
  static const int maxConcurrentDownloads = 3;
  static const int maxRetryAttempts = 3;
  static const String defaultDownloadPath = '/TubeSnap';
  static const String defaultQuality = '1080p';

  // Supported Quality Options (ALL FREE)
  static const List<String> supportedQualities = [
    '2160p', // 4K - FREE
    '1440p', // 2K - FREE
    '1080p', // Full HD - FREE
    '720p',  // HD - FREE
    '480p',  // SD - FREE
    '360p',  // Low - FREE
    '240p',  // Very Low - FREE
    '144p',  // Lowest - FREE
  ];

  // Supported Audio Qualities (ALL FREE)
  static const List<String> supportedAudioQualities = [
    '320kbps', // High - FREE
    '256kbps', // Medium - FREE
    '128kbps', // Standard - FREE
    '64kbps',  // Low - FREE
  ];

  // File Extensions
  static const List<String> videoExtensions = ['mp4', 'webm', 'mkv'];
  static const List<String> audioExtensions = ['mp3', 'm4a', 'aac', 'opus'];

  // Supported Languages
  static const List<String> supportedLanguages = ['en', 'hi'];
  static const String defaultLanguage = 'en';

  // Cache Configuration
  static const int maxCacheSize = 500 * 1024 * 1024; // 500 MB
  static const int thumbnailCacheSize = 100 * 1024 * 1024; // 100 MB

  // UI Configuration
  static const int splashDuration = 2500; // milliseconds
  static const int animationDuration = 300; // milliseconds
  static const int toastDuration = 2000; // milliseconds
}