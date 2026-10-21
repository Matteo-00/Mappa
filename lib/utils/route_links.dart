import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

String _pt(LatLng p) => '${p.latitude},${p.longitude}';

/// Apre Google Maps con le indicazioni per raggiungere [destination].
/// [travelMode]: `walking` (a piedi) o `driving` (in auto).
Future<bool> openDirectionsTo(LatLng destination, String travelMode) async {
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': _pt(destination),
    'travelmode': travelMode,
  });
  return _open(uri);
}

/// Apre Google Maps con il **percorso completo** che attraversa tutte le tappe
/// nell'ordine dato (la prima è la partenza, l'ultima l'arrivo).
///
/// Google Maps accetta un numero limitato di tappe intermedie: se sono troppe
/// ne vengono usate al massimo 8, distribuite lungo il percorso.
Future<bool> openRouteThrough(
  List<LatLng> stops, {
  String travelMode = 'walking',
}) async {
  if (stops.length < 2) return false;

  var middle = stops.sublist(1, stops.length - 1);
  const maxWaypoints = 8;
  if (middle.length > maxWaypoints) {
    final step = middle.length / maxWaypoints;
    middle = [for (var i = 0; i < maxWaypoints; i++) middle[(i * step).floor()]];
  }

  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'origin': _pt(stops.first),
    'destination': _pt(stops.last),
    'travelmode': travelMode,
    if (middle.isNotEmpty) 'waypoints': middle.map(_pt).join('|'),
  });
  return _open(uri);
}

Future<bool> _open(Uri uri) async {
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}
