import 'package:flutter/material.dart';

import '../models/bar_model.dart';
import '../models/restaurant_model.dart';
import 'restaurant_detail_page.dart';

/// Dettaglio di un bar: mostra le stesse informazioni di un ristorante
/// (immagine, tag, descrizione, contatti, indirizzo), senza prezzo/stelle/sconto.
class BarDetailPage extends StatelessWidget {
  final BarModel bar;

  const BarDetailPage({super.key, required this.bar});

  @override
  Widget build(BuildContext context) {
    return RestaurantDetailPage(
      restaurant: RestaurantModel(
        id: bar.id,
        name: bar.name,
        description: bar.description,
        address: bar.address,
        coordinates: bar.coordinates,
        imageUrl: bar.imageUrl,
        phoneNumber: bar.phoneNumber,
        website: bar.website,
        cuisineTypes: bar.cuisineTypes,
      ),
    );
  }
}
