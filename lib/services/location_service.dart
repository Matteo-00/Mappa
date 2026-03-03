import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

/// Servizio per la gestione della geolocalizzazione
class LocationService {
  /// Richiede i permessi di localizzazione
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Ottiene la posizione corrente dell'utente
  Future<LatLng?> getCurrentLocation() async {
    try {
      // Verifica se i permessi sono stati concessi
      final hasPermission = await Permission.location.isGranted;
      if (!hasPermission) {
        final granted = await requestLocationPermission();
        if (!granted) return null;
      }

      // Ottiene la posizione
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      return null;
    }
  }

  /// Calcola la distanza in metri tra due coordinate
  double calculateDistance(LatLng from, LatLng to) {
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );
  }

  /// Formatta la distanza in modo leggibile
  String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }
}
