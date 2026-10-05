import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lingue statiche supportate dall'app (testi UI + contenuti dal database).
const List<String> kSupportedLanguageCodes = ['it', 'en', 'de', 'fr'];

/// Servizio globale per la gestione della lingua corrente dell'app.
///
/// È l'unica sorgente di verità per la lingua selezionata: viene usato sia
/// per i testi statici (`AppLocalizations`) sia per decidere quale
/// traduzione dei contenuti dinamici (`content_translations`) leggere dal
/// database.
class LanguageService extends ChangeNotifier {
  Locale _currentLocale = const Locale('it'); // Italiano di default

  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageCode => _currentLocale.languageCode;
  
  bool get isItalian => _currentLocale.languageCode == 'it';
  bool get isEnglish => _currentLocale.languageCode == 'en';
  bool get isGerman => _currentLocale.languageCode == 'de';
  bool get isFrench => _currentLocale.languageCode == 'fr';

  LanguageService() {
    _loadSavedLanguage();
  }

  /// Carica la lingua salvata
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString('language') ?? 'it';
      _currentLocale = Locale(
        kSupportedLanguageCodes.contains(savedLang) ? savedLang : 'it',
      );
      notifyListeners();
    } catch (e) {
      // Default italiano
    }
  }

  /// Cambia la lingua corrente e la rende persistente tra i riavvii dell'app.
  Future<void> setLanguage(String languageCode) async {
    if (!kSupportedLanguageCodes.contains(languageCode)) return;
    
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
}
