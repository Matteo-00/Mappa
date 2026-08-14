import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import 'consent_service.dart';

/// Servizio per la gestione della geolocalizzazione
class LocationService {
  /// Richiede i permessi di localizzazione
  Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();
    return status.isGranted;
  }

  /// Flusso completo con spiegazione all'utente.
  /// - Se già concesso: ritorna true senza disturbare l'utente.
  /// - Se non ancora chiesto: mostra una spiegazione e poi la richiesta di sistema.
  /// - Se negato permanentemente: propone di aprire le impostazioni.
  /// Ritorna true solo se il permesso è concesso.
  Future<bool> ensureLocationPermission(BuildContext context) async {
    var status = await Permission.location.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      final open = await _showDialog(
        context,
        title: 'Posizione disattivata',
        message:
            'Hai negato il permesso di posizione. Per vedere dove ti trovi sulla '
            'mappa, attivalo dalle impostazioni del telefono.',
        confirmLabel: 'Apri impostazioni',
      );
      if (open == true) {
        await openAppSettings();
      }
      return false;
    }

    // Prima richiesta: mostra la spiegazione una sola volta.
    final alreadyShown = await ConsentService.hasShownLocationRationale();
    if (!alreadyShown) {
      if (!context.mounted) return false;
      final proceed = await _showDialog(
        context,
        title: 'Attivare la posizione?',
        message:
            'Visit Gubbio usa la tua posizione solo per mostrarti dove ti trovi '
            'sulla mappa e i luoghi vicini. Non la salviamo sui nostri server.',
        confirmLabel: 'Consenti',
      );
      await ConsentService.setLocationRationaleShown();
      if (proceed != true) return false;
    }

    status = await Permission.location.request();
    return status.isGranted;
  }

  Future<bool?> _showDialog(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non ora'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
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
