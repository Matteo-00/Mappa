import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_mode.dart';
import '../models/user_model.dart';

/// Servizio di autenticazione con Supabase
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  UserMode? _userMode;
  UserModel? _currentUser;

  bool get isAuthenticated => _isAuthenticated;
  UserMode? get userMode => _userMode;
  UserModel? get currentUser => _currentUser;

  /// Login con Supabase - chiamato dopo signInWithPassword
  void loginWithSupabase(Map<String, dynamic> userData) {
    _currentUser = UserModel.fromJson(userData);
    _isAuthenticated = true;
    
    // Determina UserMode in base a is_ceraiolo
    _userMode = _currentUser!.isCeraiolo ? UserMode.ceraiolo : UserMode.turista;
    
    notifyListeners();
  }

  /// Logout
  Future<void> logout() async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    
    _isAuthenticated = false;
    _userMode = null;
    _currentUser = null;
    notifyListeners();
  }

  /// Controlla se l'utente è già autenticato all'avvio
  Future<void> checkAuthStatus() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    
    if (user != null) {
      try {
        final userData = await supabase
            .from('utenti')
            .select()
            .eq('id', user.id)
            .single();
        
        loginWithSupabase(userData);
      } catch (e) {
        // Se fallisce, logout
        await logout();
      }
    }
  }
}
