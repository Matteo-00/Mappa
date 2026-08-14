import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modello per un bar / caffetteria
class BarModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final LatLng coordinates;
  final String? imageUrl;
  final String? phoneNumber;
  final String? website;
  final List<String> cuisineTypes;

  const BarModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.coordinates,
    this.imageUrl,
    this.phoneNumber,
    this.website,
    this.cuisineTypes = const [],
  });

  /// Crea un bar dai dati di Supabase
  factory BarModel.fromJson(Map<String, dynamic> json) {
    return BarModel(
      id: json['id'].toString(),
      name: (json['nome'] ?? '') as String,
      description: (json['descrizione'] ?? '') as String,
      address: (json['indirizzo'] ?? '') as String,
      coordinates: LatLng(
        (json['latitudine'] as num?)?.toDouble() ?? 43.3519,
        (json['longitudine'] as num?)?.toDouble() ?? 12.5773,
      ),
      imageUrl: json['image_url'] as String?,
      phoneNumber: json['telefono'] as String?,
      website: json['sito_web'] as String?,
      cuisineTypes:
          (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  /// Serializza per l'inserimento su Supabase
  Map<String, dynamic> toJson() {
    return {
      'nome': name,
      'descrizione': description,
      'indirizzo': address,
      'latitudine': coordinates.latitude,
      'longitudine': coordinates.longitude,
      'image_url': imageUrl,
      'telefono': phoneNumber,
      'sito_web': website,
      'tags': cuisineTypes,
    };
  }

  /// Calcola la distanza da una posizione (in metri)
  double calculateDistance(LatLng currentPosition) {
    const double earthRadius = 6371000; // metri

    double lat1 = currentPosition.latitude * 3.14159265359 / 180.0;
    double lat2 = coordinates.latitude * 3.14159265359 / 180.0;
    double lon1 = currentPosition.longitude * 3.14159265359 / 180.0;
    double lon2 = coordinates.longitude * 3.14159265359 / 180.0;

    double dLat = lat2 - lat1;
    double dLon = lon2 - lon1;

    double a = (dLat / 2.0) * (dLat / 2.0) +
        (dLon / 2.0) * (dLon / 2.0) * (lat1) * (lat2);
    double c = 2 * (a.isNegative ? -1 : 1) * (1 - a).abs();

    return earthRadius * c;
  }

  /// Formatta la distanza per visualizzazione
  String formatDistance(LatLng currentPosition) {
    final distance = calculateDistance(currentPosition);

    if (distance < 1000) {
      return '${distance.round()} m';
    } else {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
  }
}
