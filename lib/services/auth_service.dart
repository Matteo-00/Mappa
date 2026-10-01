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

  /// True se l'utente collegato è un amministratore
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Login con Supabase - chiamato dopo signInWithPassword
  void loginWithSupabase(Map<String, dynamic> userData) {
    _currentUser = UserModel.fromJson(userData);
    _isAuthenticated = true;
    
    // Tutti gli utenti partono come turisti
    _userMode = UserMode.turista;
    
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

  /// Cancella il profilo utente (riga nella tabella 'utenti') e termina la sessione.
  /// Nota: la rimozione definitiva dell'account di autenticazione Supabase
  /// richiede una funzione server-side con service role key (non deve mai
  /// essere inclusa nell'app), da implementare lato backend.
  Future<void> deleteAccount() async {
    final supabase = Supabase.instance.client;
    final userId = _currentUser?.id;
    if (userId != null) {
      await supabase.from('utenti').delete().eq('id', userId);
    }
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
