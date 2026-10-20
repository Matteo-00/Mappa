import 'package:flutter/material.dart';

/// Osservatore delle pagine dell'app: permette a una schermata (es. la home
/// con il video) di sapere quando un'altra pagina le si apre sopra o viene
/// chiusa, per mettere in pausa / riprendere ciò che sta riproducendo.
/// Considera solo le pagine vere (non dialog né bottom sheet).
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();
