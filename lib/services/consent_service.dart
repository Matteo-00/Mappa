import 'package:shared_preferences/shared_preferences.dart';

/// Gestisce la persistenza dei consensi dell'utente (privacy, ecc.).
/// La privacy va accettata una sola volta: il flag resta salvato sul dispositivo.
class ConsentService {
  static const String _privacyKey = 'privacy_accepted_v1';
  static const String _locationRationaleKey = 'location_rationale_shown_v1';

  /// True se l'utente ha già accettato l'informativa sulla privacy.
  static Future<bool> hasAcceptedPrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyKey) ?? false;
  }

  /// Salva l'accettazione della privacy.
  static Future<void> setPrivacyAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyKey, true);
  }

  /// True se abbiamo già mostrato almeno una volta la spiegazione sui permessi
  /// di posizione (per evitare di ripeterla inutilmente).
  static Future<bool> hasShownLocationRationale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_locationRationaleKey) ?? false;
  }

  static Future<void> setLocationRationaleShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_locationRationaleKey, true);
  }
}
