/// Modello utente dalla tabella utenti di Supabase
class UserModel {
  final String id;
  final String nome;
  final String cognome;
  final int eta;
  final bool isCeraiolo;
  final String? cero;

  const UserModel({
    required this.id,
    required this.nome,
    required this.cognome,
    required this.eta,
    required this.isCeraiolo,
    this.cero,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      nome: json['nome'] as String,
      cognome: json['cognome'] as String,
      eta: json['eta'] as int,
      isCeraiolo: json['is_ceraiolo'] as bool,
      cero: json['cero'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'cognome': cognome,
      'eta': eta,
      'is_ceraiolo': isCeraiolo,
      'cero': cero,
    };
  }

  String get nomeCompleto => '$nome $cognome';
}
