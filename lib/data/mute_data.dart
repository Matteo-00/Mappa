import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/muta_model.dart';

/// Dati demo delle mute lungo il percorso
final List<MutaModel> muteData = [
  MutaModel(
    id: '1',
    name: 'Bargello',
    zone: 'Piazza Grande',
    info: 'Punto di partenza della corsa. Preparazione e organizzazione.',
    coordinates: LatLng(43.35190, 12.57730),
    capoMuta: 'Lorenzo Bartolini',
    capocorsa: 'Riccardo Montanari',
    esterniSinistra: [
      'Marco Rinaldi',
      'Paolo Ceccarelli',
      'Andrea Brunetti',
      'Matteo Guidi',
    ],
    esterniDestra: [
      'Simone Casagrande',
      'Davide Bellucci',
      'Filippo Santori',
      'Alessandro Pierini',
    ],
    interniPosteriori: [
      'Luca Bianchi',
      'Stefano Morelli',
    ],
  ),
  MutaModel(
    id: '2',
    name: 'Via dei Consoli',
    zone: 'Centro Storico',
    info: 'Prima tappa dopo la partenza. Coordinamento essenziale.',
    coordinates: LatLng(43.35105, 12.57975),
    capoMuta: 'Giovanni Rossi',
    capocorsa: 'Francesco Neri',
    esterniSinistra: [
      'Luca Ferri',
      'Andrea Galli',
      'Marco Verdi',
      'Paolo Baldi',
    ],
    esterniDestra: [
      'Stefano Conti',
      'Matteo Serra',
      'Diego Greco',
      'Alberto Monti',
    ],
    interniPosteriori: [
      'Roberto Marini',
      'Carlo Bianchi',
    ],
  ),
  MutaModel(
    id: '3',
    name: 'Via della Repubblica',
    zone: 'Ingresso Monte',
    info: 'Punto strategico prima della salita. Cambio di ritmo.',
    coordinates: LatLng(43.35000, 12.58230),
    capoMuta: 'Simone Vitali',
    capocorsa: 'Antonio Ricci',
    esterniSinistra: [
      'Fabio Costa',
      'Enrico Lombardi',
      'Pietro Fontana',
      'Nicola Esposito',
    ],
    esterniDestra: [
      'Michele Romano',
      'Alessio Colombo',
      'Daniele Rizzo',
      'Claudio Ferrara',
    ],
    interniPosteriori: [
      'Massimo Russo',
      'Giorgio Bruno',
    ],
  ),
  MutaModel(
    id: '4',
    name: 'Salita Monte Ingino',
    zone: 'Monte Ingino',
    info: 'Tratto impegnativo. Massima concentrazione richiesta.',
    coordinates: LatLng(43.34900, 12.58450),
    capoMuta: 'Davide Gentili',
    capocorsa: 'Lorenzo De Luca',
    esterniSinistra: [
      'Cristian Martini',
      'Emanuele Barbieri',
      'Riccardo Mancini',
      'Tommaso Santini',
    ],
    esterniDestra: [
      'Federico Marchetti',
      'Gabriele Galli',
      'Simone Pellegrini',
      'Jacopo Fabbri',
    ],
    interniPosteriori: [
      'Alessandro Caruso',
      'Manuel Bianco',
    ],
  ),
  MutaModel(
    id: '5',
    name: 'Arrivo Sant\'Ubaldo',
    zone: 'Basilica Sant\'Ubaldo',
    info: 'Punto di arrivo. Traguardo della tradizione.',
    coordinates: LatLng(43.34705, 12.58820),
    capoMuta: 'Marco Benedetti',
    capocorsa: 'Samuele Moretti',
    esterniSinistra: [
      'Leonardo Palma',
      'Mattia Villa',
      'Alessandro Testa',
      'Vincenzo Orlandi',
    ],
    esterniDestra: [
      'Filippo Guerra',
      'Giacomo Rinaldi',
      'Andrea Giordano',
      'Luca Silvestri',
    ],
    interniPosteriori: [
      'Davide Sanna',
      'Francesco Piras',
    ],
  ),
];
