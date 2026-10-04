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

  /// Cancella definitivamente l'account: profilo ('utenti') + utente di
  /// autenticazione Supabase, tramite l'Edge Function server-side
  /// 'delete-account' (vedi supabase/functions/delete-account), che usa la
  /// service role key senza mai esporla nell'app.
  Future<void> deleteAccount() async {
    final supabase = Supabase.instance.client;
    final userId = _currentUser?.id;

    try {
      await supabase.functions.invoke('delete-account');
    } catch (e) {
      // Fallback se la Edge Function non è ancora distribuita: elimina almeno
      // il profilo per non lasciare l'app in uno stato inconsistente. In
      // questo caso le credenziali di accesso restano attive su Supabase Auth
      // finché la funzione non viene distribuita.
      if (userId != null) {
        await supabase.from('utenti').delete().eq('id', userId);
      }
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
