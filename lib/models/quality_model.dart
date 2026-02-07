class QualityOption {
  final String resolution;
  final String label;
  final String labelHi;
  final int fileSize; // in bytes
  final String extension;
  final String downloadUrl;
  final int bitrate; // in kbps
  final int fps;
  final String codec;

  QualityOption({
    required this.resolution,
    required this.label,
    required this.labelHi,
    required this.fileSize,
    this.extension = 'mp4',
    this.downloadUrl = '',
    this.bitrate = 0,
    this.fps = 30,
    this.codec = 'h264',
  });

  /// Get formatted file size
  String get formattedSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) return '${(fileSize / (1024 * 1024)).toStringAsFixed(0)} MB';
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// All available qualities - ALL FREE!
  static List<QualityOption> get allQualities => [
    QualityOption(
      resolution: 'MAX',
      label: 'Maximum Quality (No Compression)',
      labelHi: 'अधिकतम गुणवत्ता (कोई संपीड़न नहीं)',
      fileSize: 2000 * 1024 * 1024, // 2 GB (estimate for highest quality)
      bitrate: 25000,
      fps: 60,
      codec: 'vp9',
    ),
    QualityOption(
      resolution: '2160p',
      label: '4K Ultra HD',
      labelHi: '4K अल्ट्रा HD',
      fileSize: 850 * 1024 * 1024, // 850 MB
      bitrate: 20000,
      fps: 60,
      codec: 'vp9',
    ),
    QualityOption(
      resolution: '1440p',
      label: '2K QHD',
      labelHi: '2K QHD',
      fileSize: 450 * 1024 * 1024, // 450 MB
      bitrate: 12000,
      fps: 60,
      codec: 'vp9',
    ),
    QualityOption(
      resolution: '1080p',
      label: 'Full HD',
      labelHi: 'फुल HD',
      fileSize: 250 * 1024 * 1024, // 250 MB
      bitrate: 8000,
      fps: 60,
    ),
    QualityOption(
      resolution: '720p',
      label: 'HD Ready',
      labelHi: 'HD रेडी',
      fileSize: 120 * 1024 * 1024, // 120 MB
      bitrate: 5000,
      fps: 30,
    ),
    QualityOption(
      resolution: '480p',
      label: 'Standard',
      labelHi: 'स्टैंडर्ड',
      fileSize: 65 * 1024 * 1024, // 65 MB
      bitrate: 2500,
      fps: 30,
    ),
    QualityOption(
      resolution: '360p',
      label: 'Low',
      labelHi: 'कम',
      fileSize: 35 * 1024 * 1024, // 35 MB
      bitrate: 1000,
      fps: 30,
    ),
    QualityOption(
      resolution: '240p',
      label: 'Very Low',
      labelHi: 'बहुत कम',
      fileSize: 20 * 1024 * 1024, // 20 MB
      bitrate: 500,
      fps: 30,
    ),
    QualityOption(
      resolution: '144p',
      label: 'Lowest',
      labelHi: 'न्यूनतम',
      fileSize: 10 * 1024 * 1024, // 10 MB
      bitrate: 250,
      fps: 30,
    ),
  ];

  factory QualityOption.fromJson(Map<String, dynamic> json) {
    return QualityOption(
      resolution: json['resolution'] ?? '',
      label: json['label'] ?? '',
      labelHi: json['labelHi'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      extension: json['extension'] ?? 'mp4',
      downloadUrl: json['downloadUrl'] ?? '',
      bitrate: json['bitrate'] ?? 0,
      fps: json['fps'] ?? 30,
      codec: json['codec'] ?? 'h264',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'resolution': resolution,
      'label': label,
      'labelHi': labelHi,
      'fileSize': fileSize,
      'extension': extension,
      'downloadUrl': downloadUrl,
      'bitrate': bitrate,
      'fps': fps,
      'codec': codec,
    };
  }
}

/// Audio Quality Option - ALL FREE!
class AudioQualityOption {
  final String bitrate;
  final String label;
  final String labelHi;
  final int fileSize;
  final String extension;
  final String downloadUrl;
  final int bitrateKbps; // Numeric bitrate for MP3 conversion

  AudioQualityOption({
    required this.bitrate,
    required this.label,
    required this.labelHi,
    required this.fileSize,
    this.extension = 'mp3',
    this.downloadUrl = '',
    this.bitrateKbps = 128,
  });

  String get formattedSize {
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Standard MP3 quality options for audio conversion
  static List<AudioQualityOption> get allQualities => [
    AudioQualityOption(
      bitrate: '320kbps',
      label: 'Highest Quality',
      labelHi: 'उच्चतम गुणवत्ता',
      fileSize: 12 * 1024 * 1024,
      bitrateKbps: 320,
    ),
    AudioQualityOption(
      bitrate: '256kbps',
      label: 'High Quality',
      labelHi: 'उच्च गुणवत्ता',
      fileSize: 10 * 1024 * 1024,
      bitrateKbps: 256,
    ),
    AudioQualityOption(
      bitrate: '192kbps',
      label: 'Good Quality',
      labelHi: 'अच्छी गुणवत्ता',
      fileSize: 8 * 1024 * 1024,
      bitrateKbps: 192,
    ),
    AudioQualityOption(
      bitrate: '128kbps',
      label: 'Standard',
      labelHi: 'स्टैंडर्ड',
      fileSize: 6 * 1024 * 1024,
      bitrateKbps: 128,
    ),
    AudioQualityOption(
      bitrate: '64kbps',
      label: 'Low Quality',
      labelHi: 'कम गुणवत्ता',
      fileSize: 3 * 1024 * 1024,
      bitrateKbps: 64,
    ),
    AudioQualityOption(
      bitrate: '32kbps',
      label: 'Lowest Quality',
      labelHi: 'न्यूनतम गुणवत्ता',
      fileSize: 2 * 1024 * 1024,
      bitrateKbps: 32,
    ),
  ];

  factory AudioQualityOption.fromJson(Map<String, dynamic> json) {
    return AudioQualityOption(
      bitrate: json['bitrate'] ?? '',
      label: json['label'] ?? '',
      labelHi: json['labelHi'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      extension: json['extension'] ?? 'mp3',
      downloadUrl: json['downloadUrl'] ?? '',
      bitrateKbps: json['bitrateKbps'] ?? 128,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bitrate': bitrate,
      'label': label,
      'labelHi': labelHi,
      'fileSize': fileSize,
      'extension': extension,
      'downloadUrl': downloadUrl,
      'bitrateKbps': bitrateKbps,
    };
  }
}