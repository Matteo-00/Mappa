import 'package:flutter/material.dart';

import '../models/luogo_model.dart';
import '../models/restaurant_model.dart';
import '../widgets/storia_links_section.dart';
import 'restaurant_detail_page.dart';

/// Dettaglio di una chiesa, un museo, un negozio o un parcheggio: stessa
/// pagina di bar, ristoranti e hotel (immagine, tag, descrizione, contatti,
/// indirizzo, "Mostra sulla mappa", indicazioni), più il "momento storico"
/// per chiese e musei e le stelle per i negozi.
class LuogoDetailPage extends StatelessWidget {
  final LuogoModel luogo;

  const LuogoDetailPage({super.key, required this.luogo});

  @override
  Widget build(BuildContext context) {
    return RestaurantDetailPage(
      fallbackIcon: luogo.tipo.icon,
      mapKind: luogo.tipo.db,
      extraSection: luogo.tipo.hasStoria
          ? StoriaLinksSection(storiaIds: luogo.storiaIds)
          : null,
      restaurant: RestaurantModel(
        id: luogo.id,
        name: luogo.name,
        description: luogo.description,
        address: luogo.address,
        coordinates: luogo.coordinates,
        imageUrl: luogo.imageUrl,
        phoneNumber: luogo.phoneNumber,
        website: luogo.website,
        cuisineTypes: luogo.tags,
        rating: luogo.rating,
      ),
    );
  }
}
