/// Posizioni ufficiali sulla barella (11 ruoli totali)
class BarellaCeraioli {
  // Stanga Sinistra (4 ceraioli)
  final CeraioloInfo stangaSinistraPuntaAvanti;
  final CeraioloInfo stangaSinistraCeppoAvanti;
  final CeraioloInfo stangaSinistraCeppoDietro;
  final CeraioloInfo stangaSinistraPuntaDietro;

  // Stanga Destra (4 ceraioli)
  final CeraioloInfo stangaDestraPuntaAvanti;
  final CeraioloInfo stangaDestraCeppoAvanti;
  final CeraioloInfo stangaDestraCeppoDietro;
  final CeraioloInfo stangaDestraPuntaDietro;

  // Centro (3 ceraioli)
  final CeraioloInfo centroCapo10;
  final CeraioloInfo centroCapo5;
  final CeraioloInfo centroBarelone;

  const BarellaCeraioli({
    required this.stangaSinistraPuntaAvanti,
    required this.stangaSinistraCeppoAvanti,
    required this.stangaSinistraCeppoDietro,
    required this.stangaSinistraPuntaDietro,
    required this.stangaDestraPuntaAvanti,
    required this.stangaDestraCeppoAvanti,
    required this.stangaDestraCeppoDietro,
    required this.stangaDestraPuntaDietro,
    required this.centroCapo10,
    required this.centroCapo5,
    required this.centroBarelone,
  });

  /// Ritorna tutti gli 11 ceraioli
  List<CeraioloInfo> getAllCeraioli() {
    return [
      stangaSinistraPuntaAvanti,
      stangaSinistraCeppoAvanti,
      stangaSinistraCeppoDietro,
      stangaSinistraPuntaDietro,
      stangaDestraPuntaAvanti,
      stangaDestraCeppoAvanti,
      stangaDestraCeppoDietro,
      stangaDestraPuntaDietro,
      centroCapo10,
      centroCapo5,
      centroBarelone,
    ];
  }
}

/// Informazioni su un ceraiolo in una posizione specifica
class CeraioloInfo {
  final String ruolo;
  final String nome;
  final String cognome;

  const CeraioloInfo({
    required this.ruolo,
    required this.nome,
    required this.cognome,
  });

  String get nomeCompleto => '$nome $cognome';
  String get displayText => '$ruolo – $nome $cognome';
}

/// Dati esempio per la barella (da sostituire con dati reali da Supabase)
const barellaEsempio = BarellaCeraioli(
  stangaSinistraPuntaAvanti: CeraioloInfo(
    ruolo: 'Punta Avanti SX',
    nome: 'Marco',
    cognome: 'Rossi',
  ),
  stangaSinistraCeppoAvanti: CeraioloInfo(
    ruolo: 'Ceppo Avanti SX',
    nome: 'Luca',
    cognome: 'Bianchi',
  ),
  stangaSinistraCeppoDietro: CeraioloInfo(
    ruolo: 'Ceppo Dietro SX',
    nome: 'Andrea',
    cognome: 'Verdi',
  ),
  stangaSinistraPuntaDietro: CeraioloInfo(
    ruolo: 'Punta Dietro SX',
    nome: 'Paolo',
    cognome: 'Neri',
  ),
  stangaDestraPuntaAvanti: CeraioloInfo(
    ruolo: 'Punta Avanti DX',
    nome: 'Giovanni',
    cognome: 'Gialli',
  ),
  stangaDestraCeppoAvanti: CeraioloInfo(
    ruolo: 'Ceppo Avanti DX',
    nome: 'Francesco',
    cognome: 'Viola',
  ),
  stangaDestraCeppoDietro: CeraioloInfo(
    ruolo: 'Ceppo Dietro DX',
    nome: 'Alessandro',
    cognome: 'Marroni',
  ),
  stangaDestraPuntaDietro: CeraioloInfo(
    ruolo: 'Punta Dietro DX',
    nome: 'Matteo',
    cognome: 'Azzurri',
  ),
  centroCapo10: CeraioloInfo(
    ruolo: 'Capo 10',
    nome: 'Roberto',
    cognome: 'Grigi',
  ),
  centroCapo5: CeraioloInfo(
    ruolo: 'Capo 5',
    nome: 'Stefano',
    cognome: 'Arancioni',
  ),
  centroBarelone: CeraioloInfo(
    ruolo: 'Barelone',
    nome: 'Antonio',
    cognome: 'Rosa',
  ),
);
