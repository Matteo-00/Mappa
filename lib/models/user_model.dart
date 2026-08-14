/// Modello utente dalla tabella utenti di Supabase
class UserModel {
  final String id;
  final String nome;
  final String cognome;
  final String email;
  final DateTime? dataNascita;
  final String ruolo;

  const UserModel({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.email,
    this.dataNascita,
    this.ruolo = 'utente',
  });

  /// True se l'utente è un amministratore
  bool get isAdmin => ruolo == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      cognome: json['cognome'] as String,
      email: json['email'] as String,
      dataNascita: json['data_nascita'] != null
          ? DateTime.parse(json['data_nascita'] as String)
          : null,
      ruolo: (json['ruolo'] as String?) ?? 'utente',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'email': email,
      'data_nascita': dataNascita?.toIso8601String(),
      'ruolo': ruolo,
    };
  }

  String get nomeCompleto => '$nome $cognome';
}
