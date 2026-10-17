import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/geo.dart';

/// Modello per un ristorante
class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final LatLng coordinates;
  final String? imageUrl;
  final String? phoneNumber;
  final String? website;
  final List<String> cuisineTypes;
  /// Valutazione da 1 a 5 (media TripAdvisor/Google Maps), impostata dal master.
  final double? rating;

  const RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.coordinates,
    this.imageUrl,
    this.phoneNumber,
    this.website,
    this.cuisineTypes = const [],
    this.rating,
  });

  /// Crea un ristorante dai dati di Supabase
  factory RestaurantModel.fromJson(Map<String, dynamic> json) {
    return RestaurantModel(
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
      rating: (json['rating'] as num?)?.toDouble(),
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
      'rating': rating,
    };
  }

  /// Distanza in metri, in linea d'aria, da una posizione (Haversine).
  double calculateDistance(LatLng currentPosition) =>
      distanceMeters(currentPosition, coordinates);

  /// Distanza formattata per la visualizzazione ("350 m", "1,4 km").
  String formatDistance(LatLng currentPosition) =>
      formatDistanceMeters(calculateDistance(currentPosition));
}
