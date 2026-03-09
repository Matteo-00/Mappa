import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Provider per gestire la modalità dell'app (Visit Gubbio / Festa dei Ceri)
class ThemeProvider extends ChangeNotifier {
  AppMode _currentMode = AppMode.visitGubbio;
  bool _isTransitioning = false;
  
  AppMode get currentMode => _currentMode;
  bool get isTransitioning => _isTransitioning;
  bool get isVisitGubbio => _currentMode == AppMode.visitGubbio;
  bool get isFestaDeiCeri => _currentMode == AppMode.festaDeiCeri;
  
  /// Ottieni il tema corrente
  ThemeData get currentTheme {
    return _currentMode == AppMode.visitGubbio
        ? AppTheme.getVisitGubbioTheme()
        : AppTheme.getFestaDeiCeriTheme();
  }
  
  /// Cambia modalità con animazione
  Future<void> changeMode(AppMode newMode) async {
    if (_currentMode == newMode) return;
    
    _isTransitioning = true;
    notifyListeners();
    
    // Attendi un breve momento per l'animazione di transizione
    await Future.delayed(const Duration(milliseconds: 300));
    
    _currentMode = newMode;
    notifyListeners();
    
    // Fine transizione
    await Future.delayed(const Duration(milliseconds: 500));
    _isTransitioning = false;
    notifyListeners();
  }
  
  /// Passa a Visit Gubbio
  Future<void> switchToVisitGubbio() async {
    await changeMode(AppMode.visitGubbio);
  }
  
  /// Passa a Festa dei Ceri (con loading screen)
  Future<void> switchToFestaDeiCeri() async {
    await changeMode(AppMode.festaDeiCeri);
  }
  
  /// Ottieni il titolo dell'app basato sulla modalità
  String getAppTitle() {
    return _currentMode == AppMode.visitGubbio 
        ? 'VISIT GUBBIO' 
        : 'FESTA DEI CERI';
  }
}
