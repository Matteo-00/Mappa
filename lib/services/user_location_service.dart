import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../utils/geo.dart';
import 'location_service.dart';

/// Perché la posizione dell'utente non è disponibile.
enum LocationAvailability {
  /// Non ancora controllata.
  unknown,

  /// Posizione disponibile.
  available,

  /// Permesso non concesso (si può chiedere).
  permissionDenied,

  /// Permesso negato in modo permanente (serve passare dalle impostazioni).
  permissionDeniedForever,

  /// GPS / servizi di localizzazione spenti sul telefono.
  serviceDisabled,
}

/// Posizione dell'utente condivisa da tutta l'app: le schermate la leggono da
/// qui per calcolare le distanze, senza chiedere il permesso più volte.
///
/// - [refresh] aggiorna la posizione in silenzio (non mostra mai richieste).
/// - [enable] è l'azione dell'utente ("Abilita la posizione"): spiega,
///   chiede il permesso o apre le impostazioni, poi aggiorna.
class UserLocationService extends ChangeNotifier with WidgetsBindingObserver {
  UserLocationService._() {
    WidgetsBinding.instance.addObserver(this);
  }

  static final UserLocationService instance = UserLocationService._();

  final LocationService _locationService = LocationService();

  LatLng? _position;
  LocationAvailability _availability = LocationAvailability.unknown;
  bool _refreshing = false;

  LatLng? get position => _position;
  LocationAvailability get availability => _availability;

  /// True dopo il primo controllo (con esito positivo o negativo).
  bool get checked => _availability != LocationAvailability.unknown;

  /// Distanza in metri dalla posizione dell'utente (null se non disponibile).
  double? distanceTo(LatLng target) {
    final p = _position;
    return p == null ? null : distanceMeters(p, target);
  }

  /// Quando l'app torna in primo piano (es. dopo aver acceso il GPS o dato il
  /// permesso dalle impostazioni) la posizione viene ricalcolata.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  /// Aggiorna la posizione senza mostrare richieste all'utente.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        _set(null, LocationAvailability.permissionDenied);
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        _set(null, LocationAvailability.permissionDeniedForever);
        return;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        _set(null, LocationAvailability.serviceDisabled);
        return;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        // Fix GPS lento: ripiega sull'ultima posizione nota.
        pos = await Geolocator.getLastKnownPosition();
      }

      if (pos == null) {
        _set(null, LocationAvailability.serviceDisabled);
      } else {
        _set(LatLng(pos.latitude, pos.longitude), LocationAvailability.available);
      }
    } catch (_) {
      _set(null, LocationAvailability.serviceDisabled);
    } finally {
      _refreshing = false;
    }
  }

  /// Azione dell'utente: chiede il permesso (o apre le impostazioni) e
  /// poi aggiorna la posizione.
  Future<void> enable(BuildContext context) async {
    if (_availability == LocationAvailability.serviceDisabled) {
      await Geolocator.openLocationSettings();
      return; // al ritorno nell'app, didChangeAppLifecycleState richiama refresh()
    }
    final granted = await _locationService.ensureLocationPermission(context);
    if (granted) await refresh();
  }

  void _set(LatLng? position, LocationAvailability availability) {
    final changed = _position != position || _availability != availability;
    _position = position;
    _availability = availability;
    if (changed) notifyListeners();
  }
}

/// Distanza formattata dalla posizione dell'utente, o null se non disponibile.
String? formattedDistanceTo(LatLng target) {
  final d = UserLocationService.instance.distanceTo(target);
  return d == null ? null : formatDistanceMeters(d);
}
