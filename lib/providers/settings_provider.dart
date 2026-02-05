import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

class SettingsProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();

  String _defaultQuality = '1080p';
  bool _wifiOnly = false;
  bool _notifications = true;
  String? _downloadPath;

  // Getters
  String get defaultQuality => _defaultQuality;
  bool get wifiOnly => _wifiOnly;
  bool get notifications => _notifications;
  String? get downloadPath => _downloadPath;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _defaultQuality = await _storage.getDefaultQuality();
    _wifiOnly = await _storage.getWifiOnly();
    _notifications = await _storage.getNotifications();
    _downloadPath = await _storage.getDownloadPath();
    notifyListeners();
  }

  Future<void> setDefaultQuality(String quality) async {
    _defaultQuality = quality;
    await _storage.setDefaultQuality(quality);
    notifyListeners();
  }

  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;
    await _storage.setWifiOnly(value);
    notifyListeners();
  }

  Future<void> setNotifications(bool value) async {
    _notifications = value;
    await _storage.setNotifications(value);
    notifyListeners();
  }

  Future<void> setDownloadPath(String path) async {
    _downloadPath = path;
    await _storage.setDownloadPath(path);
    notifyListeners();
  }

  Future<void> clearCache() async {
    await _storage.clearCache();
    notifyListeners();
  }

  Future<void> clearHistory() async {
    await _storage.clearDownloadHistory();
    notifyListeners();
  }

  Future<int> getCacheSize() async {
    return await _storage.getCacheSize();
  }

  Future<Map<String, int>> getStorageInfo() async {
    return await _storage.getStorageInfo();
  }
}