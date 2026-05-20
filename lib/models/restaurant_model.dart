import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Modello per un ristorante
class RestaurantModel {
  final String id;
  final String name;
  final String description;
  final String address;
  final LatLng coordinates;
  final String? imageUrl;
  final double? rating;
  final String? phoneNumber;
  final String? website;
  final List<String> cuisineTypes;
  final String priceRange; // €, ££, €€€
  final bool hasDiscount; // Promozione 5%
  
  const RestaurantModel({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.coordinates,
    this.imageUrl,
    this.rating,
    this.phoneNumber,
    this.website,
    this.cuisineTypes = const [],
    this.priceRange = '€€',
    this.hasDiscount = false,
  });
  
  /// Calcola la distanza da una posizione (in metri)
  double calculateDistance(LatLng currentPosition) {
    // Calcolo approssimativo usando formula di Haversine
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
