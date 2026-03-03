import 'package:flutter/foundation.dart';
import '../models/user_mode.dart';

/// Servizio di autenticazione
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  UserMode? _userMode;

  bool get isAuthenticated => _isAuthenticated;
  UserMode? get userMode => _userMode;

  /// Login con username e password
  /// Ritorna true se il login ha successo
  Future<bool> login(String username, String password) async {
    // Simula un delay per il login
    await Future.delayed(const Duration(milliseconds: 500));

    // Credenziali demo
    if (username.toLowerCase() == 'admin') {
      if (password == 'adminturista') {
        _isAuthenticated = true;
        _userMode = UserMode.turista;
        notifyListeners();
        return true;
      } else if (password == 'adminceraiolo') {
        _isAuthenticated = true;
        _userMode = UserMode.ceraiolo;
        notifyListeners();
        return true;
      }
    }

    return false;
  }

  /// Logout
  void logout() {
    _isAuthenticated = false;
    _userMode = null;
    notifyListeners();
  }
}
