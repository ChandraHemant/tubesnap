import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

class LanguageProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  Locale _locale = const Locale('en');

  LanguageProvider() {
    _loadLanguage();
  }

  Locale get locale => _locale;
  bool get isHindi => _locale.languageCode == 'hi';
  bool get isEnglish => _locale.languageCode == 'en';
  String get languageCode => _locale.languageCode;
  String get languageName => isHindi ? 'हिंदी' : 'English';

  Future<void> _loadLanguage() async {
    final code = await _storage.getLanguage();
    _locale = Locale(code);
    notifyListeners();
  }

  Future<void> toggleLanguage() async {
    _locale = _locale.languageCode == 'en' ? const Locale('hi') : const Locale('en');
    await _storage.setLanguage(_locale.languageCode);
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    _locale = Locale(code);
    await _storage.setLanguage(code);
    notifyListeners();
  }
}