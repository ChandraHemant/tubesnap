import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/download_model.dart';

/// Storage Service - Handles local storage operations
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  // Keys
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguage = 'language';
  static const String _keyDefaultQuality = 'default_quality';
  static const String _keyDownloadPath = 'download_path';
  static const String _keyWifiOnly = 'wifi_only';
  static const String _keyNotifications = 'notifications';
  static const String _keyDownloadHistory = 'download_history';
  static const String _keyFirstLaunch = 'first_launch';

  /// Initialize storage
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ==================== Theme ====================

  Future<bool> getIsDarkMode() async {
    final p = await prefs;
    return p.getBool(_keyThemeMode) ?? true;
  }

  Future<void> setIsDarkMode(bool value) async {
    final p = await prefs;
    await p.setBool(_keyThemeMode, value);
  }

  // ==================== Language ====================

  Future<String> getLanguage() async {
    final p = await prefs;
    return p.getString(_keyLanguage) ?? 'en';
  }

  Future<void> setLanguage(String value) async {
    final p = await prefs;
    await p.setString(_keyLanguage, value);
  }

  // ==================== Download Settings ====================

  Future<String> getDefaultQuality() async {
    final p = await prefs;
    return p.getString(_keyDefaultQuality) ?? '1080p';
  }

  Future<void> setDefaultQuality(String value) async {
    final p = await prefs;
    await p.setString(_keyDefaultQuality, value);
  }

  Future<String?> getDownloadPath() async {
    final p = await prefs;
    return p.getString(_keyDownloadPath);
  }

  Future<void> setDownloadPath(String value) async {
    final p = await prefs;
    await p.setString(_keyDownloadPath, value);
  }

  Future<bool> getWifiOnly() async {
    final p = await prefs;
    return p.getBool(_keyWifiOnly) ?? false;
  }

  Future<void> setWifiOnly(bool value) async {
    final p = await prefs;
    await p.setBool(_keyWifiOnly, value);
  }

  Future<bool> getNotifications() async {
    final p = await prefs;
    return p.getBool(_keyNotifications) ?? true;
  }

  Future<void> setNotifications(bool value) async {
    final p = await prefs;
    await p.setBool(_keyNotifications, value);
  }

  // ==================== Download History ====================

  Future<List<DownloadTask>> getDownloadHistory() async {
    final p = await prefs;
    final jsonString = p.getString(_keyDownloadHistory);
    if (jsonString == null) return [];

    try {
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((e) => DownloadTask.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveDownloadHistory(List<DownloadTask> history) async {
    final p = await prefs;
    final jsonString = json.encode(history.map((e) => e.toJson()).toList());
    await p.setString(_keyDownloadHistory, jsonString);
  }

  Future<void> addToDownloadHistory(DownloadTask task) async {
    final history = await getDownloadHistory();
    history.insert(0, task);
    // Keep only last 100 downloads
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }
    await saveDownloadHistory(history);
  }

  Future<void> removeFromDownloadHistory(String taskId) async {
    final history = await getDownloadHistory();
    history.removeWhere((task) => task.id == taskId);
    await saveDownloadHistory(history);
  }

  Future<void> clearDownloadHistory() async {
    final p = await prefs;
    await p.remove(_keyDownloadHistory);
  }

  // ==================== First Launch ====================

  Future<bool> isFirstLaunch() async {
    final p = await prefs;
    return p.getBool(_keyFirstLaunch) ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    final p = await prefs;
    await p.setBool(_keyFirstLaunch, false);
  }

  // ==================== Cache Management ====================

  Future<int> getCacheSize() async {
    int totalSize = 0;

    try {
      final cacheDir = await getTemporaryDirectory();
      totalSize = await _getDirectorySize(cacheDir);
    } catch (e) {
      // Handle error
    }

    return totalSize;
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;

    try {
      if (await dir.exists()) {
        await for (var entity in dir.list(recursive: true, followLinks: false)) {
          if (entity is File) {
            size += await entity.length();
          }
        }
      }
    } catch (e) {
      // Handle error
    }

    return size;
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
        await cacheDir.create();
      }
    } catch (e) {
      // Handle error
    }
  }

  // ==================== Storage Info ====================

  Future<Map<String, int>> getStorageInfo() async {
    int usedSpace = 0;
    int freeSpace = 0;

    try {
      final downloadDir = Directory('/storage/emulated/0/Download/TubeSnap');
      if (await downloadDir.exists()) {
        usedSpace = await _getDirectorySize(downloadDir);
      }

      // Get free space (platform specific)
      // This is a simplified version
      freeSpace = 10 * 1024 * 1024 * 1024; // 10 GB default
    } catch (e) {
      // Handle error
    }

    return {
      'used': usedSpace,
      'free': freeSpace,
    };
  }

  // ==================== Clear All Data ====================

  Future<void> clearAllData() async {
    final p = await prefs;
    await p.clear();
    await clearCache();
  }
}