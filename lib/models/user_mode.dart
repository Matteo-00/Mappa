/// Modalità utente dell'applicazione
enum UserMode {
  turista,
  ceraiolo,
}

/// Estensione per UserMode
extension UserModeExtension on UserMode {
  String get displayName {
    switch (this) {
      case UserMode.turista:
        return 'Turista';
      case UserMode.ceraiolo:
        return 'Ceraiolo';
    }
  }
}
