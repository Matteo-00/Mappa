import 'package:flutter/material.dart';
import '../models/itinerario_model.dart';

/// Itinerari consigliati (contenuti provvisori di esempio).
const List<ItinerarioModel> itinerariConsigliati = [
  ItinerarioModel(
    id: 'gubbio_medievale',
    titolo: 'Gubbio Medievale',
    sottotitolo: 'Tra vicoli, torri e palazzi del Trecento',
    descrizione:
        'Un percorso a piedi nel cuore del centro storico, alla scoperta '
        'dell\'epoca d\'oro del libero comune. Dalle piazze monumentali ai '
        'vicoli in pietra, un viaggio nella Gubbio medievale meglio conservata '
        'd\'Italia.',
    durata: 'Mezza giornata',
    difficolta: 'Facile',
    tema: 'Cultura e storia',
    icona: Icons.location_city_outlined,
    immagineLabel: 'Gubbio Medievale',
    tappe: [
      ItinerarioTappa(
        nome: 'Piazza Grande',
        descrizione:
            'Il punto di partenza ideale: una gigantesca terrazza sospesa con '
            'vista sulla valle, cuore della vita pubblica cittadina.',
        durata: '30 min',
      ),
      ItinerarioTappa(
        nome: 'Palazzo dei Consoli',
        descrizione:
            'Una delle più grandi architetture pubbliche del Medioevo italiano, '
            'oggi sede del Museo Civico e delle Tavole Eugubine.',
        durata: '1 h',
      ),
      ItinerarioTappa(
        nome: 'Via dei Consoli',
        descrizione:
            'La suggestiva via principale del centro storico, tra botteghe '
            'artigiane e le celebri "porte del morto".',
        durata: '40 min',
      ),
      ItinerarioTappa(
        nome: 'Duomo di Gubbio',
        descrizione:
            'La cattedrale medievale con la sua facciata sobria e l\'elegante '
            'interno a navata unica.',
        durata: '30 min',
      ),
    ],
  ),
  ItinerarioModel(
    id: 'panorami_natura',
    titolo: 'Panorami e Natura',
    sottotitolo: 'Dal Monte Ingino ai grandi belvedere',
    descrizione:
        'Un itinerario pensato per chi ama i grandi panorami e l\'aria aperta. '
        'Si sale verso il Monte Ingino con la storica funivia per godere di una '
        'vista spettacolare su Gubbio e sull\'intera vallata umbra.',
    durata: 'Mezza giornata',
    difficolta: 'Media',
    tema: 'Natura e panorami',
    icona: Icons.landscape_outlined,
    immagineLabel: 'Panorami e Natura',
    tappe: [
      ItinerarioTappa(
        nome: 'Funivia Colle Eletto',
        descrizione:
            'La caratteristica funivia a "cesti" che collega la città alla cima '
            'del Monte Ingino, con un panorama mozzafiato durante la salita.',
        durata: '20 min',
      ),
      ItinerarioTappa(
        nome: 'Basilica di Sant\'Ubaldo',
        descrizione:
            'Il santuario che domina Gubbio dall\'alto, dove sono custoditi i '
            'tre Ceri e il corpo del santo patrono.',
        durata: '45 min',
      ),
      ItinerarioTappa(
        nome: 'Belvedere del Monte Ingino',
        descrizione:
            'Uno dei punti panoramici più spettacolari dell\'Umbria, perfetto '
            'per ammirare il tramonto sulla città.',
        durata: '30 min',
      ),
      ItinerarioTappa(
        nome: 'Parco della Vittorina',
        descrizione:
            'Un\'area verde ai piedi della città, legata alla tradizione '
            'francescana, ideale per una passeggiata rilassante.',
        durata: '40 min',
      ),
    ],
  ),
  ItinerarioModel(
    id: 'sapori_gubbio',
    titolo: 'Sapori di Gubbio',
    sottotitolo: 'Un viaggio nel gusto tra tradizione e tipicità',
    descrizione:
        'Un percorso dedicato ai sapori autentici del territorio eugubino, tra '
        'prodotti tipici, botteghe storiche e cucina tradizionale umbra. Un '
        'itinerario per scoprire Gubbio anche a tavola.',
    durata: '2 – 3 ore',
    difficolta: 'Facile',
    tema: 'Enogastronomia',
    icona: Icons.restaurant_outlined,
    immagineLabel: 'Sapori di Gubbio',
    tappe: [
      ItinerarioTappa(
        nome: 'Botteghe del centro storico',
        descrizione:
            'Tra le vie del centro si trovano botteghe e negozi dove assaggiare '
            'e acquistare i prodotti tipici del territorio.',
        durata: '45 min',
      ),
      ItinerarioTappa(
        nome: 'Il tartufo di Gubbio',
        descrizione:
            'Uno dei prodotti simbolo della zona, protagonista di molti piatti '
            'della tradizione locale.',
        durata: '30 min',
      ),
      ItinerarioTappa(
        nome: 'Cucina tradizionale umbra',
        descrizione:
            'Una sosta in una trattoria tipica per gustare i sapori autentici '
            'della cucina eugubina, dai primi ai secondi di carne.',
        durata: '1 h',
      ),
      ItinerarioTappa(
        nome: 'Dolci e tradizione',
        descrizione:
            'Per concludere in dolcezza, i dolci tipici legati alle feste e '
            'alle tradizioni cittadine.',
        durata: '20 min',
      ),
    ],
  ),
];
