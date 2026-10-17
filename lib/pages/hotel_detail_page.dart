import 'package:flutter/material.dart';

import '../models/hotel_model.dart';
import '../models/restaurant_model.dart';
import 'map_page.dart' show MapKind;
import 'restaurant_detail_page.dart';

/// Dettaglio di un hotel: stessa pagina di bar e ristoranti
/// (immagine, tag, descrizione, contatti, indirizzo, indicazioni).
class HotelDetailPage extends StatelessWidget {
  final HotelModel hotel;

  const HotelDetailPage({super.key, required this.hotel});

  @override
  Widget build(BuildContext context) {
    return RestaurantDetailPage(
      fallbackIcon: Icons.hotel,
      mapKind: MapKind.hotel,
      restaurant: RestaurantModel(
        id: hotel.id,
        name: hotel.name,
        description: hotel.description,
        address: hotel.address,
        coordinates: hotel.coordinates,
        imageUrl: hotel.imageUrl,
        phoneNumber: hotel.phoneNumber,
        website: hotel.website,
        cuisineTypes: hotel.cuisineTypes,
        rating: hotel.rating,
      ),
    );
  }
}
