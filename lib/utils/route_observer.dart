import 'package:flutter/material.dart';

/// Osservatore delle pagine dell'app: permette a una schermata (es. la home
/// con il video) di sapere quando un'altra pagina le si apre sopra o viene
/// chiusa, per mettere in pausa / riprendere ciò che sta riproducendo.
/// Considera solo le pagine vere (non dialog né bottom sheet).
final RouteObserver<PageRoute<dynamic>> appRouteObserver =
    RouteObserver<PageRoute<dynamic>>();

/// Tiene l'elenco delle schermate aperte (la prima è la home), per capire se
/// una schermata si è aperta direttamente sopra la home oppure dentro un'altra.
class NavStackObserver extends NavigatorObserver {
  final List<Route<dynamic>> _routes = [];

  /// Posizione della schermata nello stack: 0 = home, 1 = aperta direttamente
  /// dalla home (menu, icona profilo...), 2 o più = aperta da un'altra
  /// schermata. -1 se sconosciuta.
  int indexOf(Route<dynamic> route) => _routes.indexOf(route);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routes.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute == null) return;
    final i = oldRoute == null ? -1 : _routes.indexOf(oldRoute);
    if (i >= 0) {
      _routes[i] = newRoute;
    } else {
      _routes.add(newRoute);
    }
  }
}

final NavStackObserver navStackObserver = NavStackObserver();
