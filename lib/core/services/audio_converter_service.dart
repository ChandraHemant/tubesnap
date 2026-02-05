import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';

/// Audio Converter Service - Converts audio files to MP3 format
/// Uses ffmpeg_kit_flutter_new for audio conversion
class AudioConverterService {
  static final AudioConverterService _instance = AudioConverterService._internal();
  factory AudioConverterService() => _instance;
  AudioConverterService._internal();

  /// Convert audio file to MP3 format
  ///
  /// [inputPath] - Path to the input audio file (webm, m4a, etc.)
  /// [outputPath] - Path where the MP3 file will be saved
  /// [bitrateKbps] - Target bitrate in kbps (default: 192)
  /// [onProgress] - Callback for conversion progress (0.0 to 1.0)
  ///
  /// Returns true if conversion was successful, false otherwise
  Future<bool> convertToMp3({
    required String inputPath,
    required String outputPath,
    int bitrateKbps = 192,
    void Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('AudioConverterService: Starting MP3 conversion');
      debugPrint('  Input: $inputPath');
      debugPrint('  Output: $outputPath');
      debugPrint('  Bitrate: ${bitrateKbps}kbps');

      // Verify input file exists
      final inputFile = File(inputPath);
      if (!await inputFile.exists()) {
        debugPrint('AudioConverterService: ✗ Input file does not exist');
        return false;
      }

      final inputSize = await inputFile.length();
      debugPrint('  Input file size: $inputSize bytes');

      // Ensure output directory exists
      final outputFile = File(outputPath);
      if (!await outputFile.parent.exists()) {
        await outputFile.parent.create(recursive: true);
      }

      // Delete existing output file if it exists
      if (await outputFile.exists()) {
        await outputFile.delete();
      }

      // Build FFmpeg command
      // -i: input file
      // -vn: no video (audio only)
      // -acodec libmp3lame: use LAME MP3 encoder
      // -ab: audio bitrate
      // -ar: audio sample rate (44100 Hz is standard for MP3)
      // -ac: audio channels (2 for stereo)
      // -y: overwrite output file without asking
      final command = '-i "$inputPath" -vn -acodec libmp3lame -ab ${bitrateKbps}k -ar 44100 -ac 2 -y "$outputPath"';

      debugPrint('AudioConverterService: Executing FFmpeg command');
      debugPrint('  Command: $command');

      // Get input file duration for progress calculation
      int? totalDuration;
      try {
        final probeSession = await FFmpegKit.execute('-i "$inputPath" 2>&1');
        final probeOutput = await probeSession.getOutput();
        if (probeOutput != null) {
          // Parse duration from FFmpeg output: "Duration: 00:03:45.67"
          final durationMatch = RegExp(r'Duration:\s*(\d+):(\d+):(\d+)\.(\d+)').firstMatch(probeOutput);
          if (durationMatch != null) {
            final hours = int.parse(durationMatch.group(1)!);
            final minutes = int.parse(durationMatch.group(2)!);
            final seconds = int.parse(durationMatch.group(3)!);
            final centis = int.parse(durationMatch.group(4)!);
            totalDuration = (hours * 3600 + minutes * 60 + seconds) * 1000 + centis * 10;
            debugPrint('  Total duration: ${totalDuration}ms');
          }
        }
      } catch (e) {
        debugPrint('  Warning: Could not get duration: $e');
      }

      // Enable statistics callback for progress reporting
      if (onProgress != null && totalDuration != null && totalDuration > 0) {
        FFmpegKitConfig.enableStatisticsCallback((Statistics statistics) {
          final time = statistics.getTime();
          if (time > 0 && totalDuration != null && totalDuration! > 0) {
            final progress = (time / totalDuration!).clamp(0.0, 1.0);
            onProgress(progress);
          }
        });
      }

      // Execute FFmpeg command
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      // Clear the statistics callback
      FFmpegKitConfig.enableStatisticsCallback(null);

      if (ReturnCode.isSuccess(returnCode)) {
        // Verify output file was created
        if (await outputFile.exists()) {
          final outputSize = await outputFile.length();
          debugPrint('AudioConverterService: ✓ Conversion successful');
          debugPrint('  Output file size: $outputSize bytes');

          // Clean up temp input file
          try {
            if (await inputFile.exists()) {
              await inputFile.delete();
              debugPrint('  Cleaned up temp input file');
            }
          } catch (e) {
            debugPrint('  Warning: Could not delete temp file: $e');
          }

          // Report 100% progress
          if (onProgress != null) {
            onProgress(1.0);
          }

          return true;
        } else {
          debugPrint('AudioConverterService: ✗ Output file was not created');
          return false;
        }
      } else if (ReturnCode.isCancel(returnCode)) {
        debugPrint('AudioConverterService: Conversion was cancelled');
        return false;
      } else {
        final output = await session.getOutput();
        debugPrint('AudioConverterService: ✗ Conversion failed');
        debugPrint('  Return code: $returnCode');
        debugPrint('  Output: $output');
        return false;
      }
    } catch (e, st) {
      debugPrint('AudioConverterService: ✗ Exception during conversion: $e');
      debugPrint('Stack trace: $st');
      return false;
    }
  }

  /// Check if FFmpeg is available
  Future<bool> isFFmpegAvailable() async {
    try {
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      debugPrint('AudioConverterService: FFmpeg not available: $e');
      return false;
    }
  }

  /// Get FFmpeg version
  Future<String?> getFFmpegVersion() async {
    try {
      final session = await FFmpegKit.execute('-version');
      final output = await session.getOutput();
      if (output != null) {
        // Extract version from first line
        final firstLine = output.split('\n').first;
        return firstLine;
      }
    } catch (e) {
      debugPrint('AudioConverterService: Could not get FFmpeg version: $e');
    }
    return null;
  }

  /// Cancel all running FFmpeg sessions
  Future<void> cancelAll() async {
    try {
      await FFmpegKit.cancel();
      debugPrint('AudioConverterService: Cancelled all FFmpeg sessions');
    } catch (e) {
      debugPrint('AudioConverterService: Error cancelling sessions: $e');
    }
  }
}
