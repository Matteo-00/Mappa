import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Email e password salvate sul telefono quando l'utente spunta "Ricorda
/// password" al login. Si conservano nell'archivio sicuro del dispositivo
/// (cifrato, protetto dal blocco schermo), non nelle preferenze normali.
class SavedLogin {
  final String email;
  final String password;
  const SavedLogin(this.email, this.password);
}

class SavedLoginService {
  SavedLoginService._();

  static const _storage = FlutterSecureStorage();
  static const _emailKey = 'saved_login_email';
  static const _passwordKey = 'saved_login_password';

  /// Le credenziali ricordate, o null se non ce ne sono.
  static Future<SavedLogin?> load() async {
    try {
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);
      if (email == null || email.isEmpty || password == null || password.isEmpty) {
        return null;
      }
      return SavedLogin(email, password);
    } catch (e) {
      debugPrint('SavedLoginService.load: $e');
      return null;
    }
  }

  static Future<void> save(String email, String password) async {
    try {
      await _storage.write(key: _emailKey, value: email);
      await _storage.write(key: _passwordKey, value: password);
    } catch (e) {
      debugPrint('SavedLoginService.save: $e');
    }
  }

  /// Dimentica le credenziali (casella "Ricorda password" tolta).
  static Future<void> clear() async {
    try {
      await _storage.delete(key: _emailKey);
      await _storage.delete(key: _passwordKey);
    } catch (e) {
      debugPrint('SavedLoginService.clear: $e');
    }
  }
}
