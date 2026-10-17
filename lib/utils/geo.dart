import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Distanza in metri, in linea d'aria, tra due punti (formula di Haversine).
double distanceMeters(LatLng a, LatLng b) {
  const earthRadius = 6371000.0;
  double rad(double deg) => deg * math.pi / 180.0;

  final dLat = rad(b.latitude - a.latitude);
  final dLon = rad(b.longitude - a.longitude);
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(a.latitude)) *
          math.cos(rad(b.latitude)) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadius * math.asin(math.min(1.0, math.sqrt(h)));
}

/// Distanza leggibile: "80 m", "350 m", "1,4 km", "12 km".
String formatDistanceMeters(double meters) {
  if (meters < 1000) {
    // Sotto il km arrotonda a 10 m (oltre i 100 m la precisione GPS non basta).
    final rounded = meters < 100 ? meters.round() : (meters / 10).round() * 10;
    return '$rounded m';
  }
  final km = meters / 1000;
  final text = km < 10 ? km.toStringAsFixed(1) : km.round().toString();
  return '${text.replaceAll('.', ',')} km';
}
