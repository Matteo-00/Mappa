import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servizio per la gestione della lingua dell'app
class LanguageService extends ChangeNotifier {
  Locale _currentLocale = const Locale('it'); // Italiano di default

  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageCode => _currentLocale.languageCode;
  
  bool get isItalian => _currentLocale.languageCode == 'it';
  bool get isEnglish => _currentLocale.languageCode == 'en';

  LanguageService() {
    _loadSavedLanguage();
  }

  /// Carica la lingua salvata
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language') ?? 'it';
      _currentLocale = Locale(savedLang);
      notifyListeners();
    } catch (e) {
      // Default italiano
    }
  }

  /// Cambia la lingua
  Future<void> setLanguage(String languageCode) async {
    if (languageCode != 'it' && languageCode != 'en') return;
    
    _currentLocale = Locale(languageCode);
    notifyListeners();
    
    // Salva la preferenza
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
    } catch (e) {
      // Ignore
    }
  }

  /// Toggle tra italiano e inglese
  Future<void> toggleLanguage() async {
    final newLang = _currentLocale.languageCode == 'it' ? 'en' : 'it';
    await setLanguage(newLang);
  }
}
