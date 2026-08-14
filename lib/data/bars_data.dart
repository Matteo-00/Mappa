import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/bar_model.dart';

/// Dati dei bar e caffetterie a Gubbio
List<BarModel> getGubbioBars() {
  return [
    const BarModel(
      id: 'bar_1',
      name: 'Caffè del Centro',
      description:
          'Bar storico nel cuore di Gubbio. Ottimo caffè e pasticceria artigianale.',
      address: 'Piazza Grande, 06024 Gubbio PG',
      coordinates: LatLng(43.3517, 12.5766),
      phoneNumber: '+39 075 927 1122',
      cuisineTypes: ['Caffè', 'Pasticceria'],
    ),
    const BarModel(
      id: 'bar_2',
      name: 'Bar San Francesco',
      description:
          'Bar moderno con terrazza panoramica. Perfetto per aperitivi e cocktail.',
      address: 'Via Cairoli, 15, 06024 Gubbio PG',
      coordinates: LatLng(43.3512, 12.5788),
      phoneNumber: '+39 075 922 3344',
      cuisineTypes: ['Aperitivi', 'Cocktail'],
    ),
    const BarModel(
      id: 'bar_3',
      name: 'Caffetteria dei Ceri',
      description:
          'Caffetteria tradizionale con specialità locali. Ambiente familiare.',
      address: 'Corso Garibaldi, 32, 06024 Gubbio PG',
      coordinates: LatLng(43.3524, 12.5758),
      phoneNumber: '+39 075 927 5566',
      cuisineTypes: ['Caffè', 'Colazioni'],
    ),
    const BarModel(
      id: 'bar_4',
      name: 'Gran Caffè Ducale',
      description:
          'Elegante caffè con dehors sulla piazza. Colazioni e brunch di qualità.',
      address: 'Via dei Consoli, 40, 06024 Gubbio PG',
      coordinates: LatLng(43.3510, 12.5792),
      phoneNumber: '+39 075 927 7788',
      cuisineTypes: ['Colazioni', 'Brunch'],
    ),
    const BarModel(
      id: 'bar_5',
      name: 'Bar Tabacchi Ingino',
      description:
          'Punto di ritrovo del quartiere. Caffè espresso e snack veloci.',
      address: 'Via della Repubblica, 78, 06024 Gubbio PG',
      coordinates: LatLng(43.3528, 12.5752),
      phoneNumber: '+39 075 922 9900',
      cuisineTypes: ['Caffè', 'Snack'],
    ),
    const BarModel(
      id: 'bar_6',
      name: 'Wine Bar Il Bargello',
      description:
          'Enoteca e wine bar con selezione di vini umbri e taglieri locali.',
      address: 'Largo del Bargello, 8, 06024 Gubbio PG',
      coordinates: LatLng(43.3506, 12.5779),
      phoneNumber: '+39 075 927 4433',
      cuisineTypes: ['Enoteca', 'Vini'],
    ),
  ];
}
