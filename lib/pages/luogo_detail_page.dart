import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/luogo_model.dart';
import '../models/restaurant_model.dart';
import '../theme/app_colors.dart';
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
          : luogo.tipo == LuogoTipo.parcheggio
              ? _ParcheggioLink(title: luogo.linkTitle, url: luogo.linkUrl)
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

/// Titolo e link facoltativi di un parcheggio: se mancano entrambi non si vede
/// nulla; solo il titolo è un semplice testo; con il link il titolo diventa un
/// pulsante (senza titolo si mostra l'indirizzo del sito).
class _ParcheggioLink extends StatelessWidget {
  final String? title;
  final String? url;
  const _ParcheggioLink({this.title, this.url});

  Uri? get _uri {
    var u = (url ?? '').trim();
    if (u.isEmpty) return null;
    if (!u.startsWith('http://') && !u.startsWith('https://')) u = 'https://$u';
    return Uri.tryParse(u);
  }

  @override
  Widget build(BuildContext context) {
    final t = (title ?? '').trim();
    final uri = _uri;
    if (t.isEmpty && uri == null) return const SizedBox.shrink();

    if (uri == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 8),
        child: Text(
          t,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () =>
              launchUrl(uri, mode: LaunchMode.externalApplication),
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: Text(t.isNotEmpty ? t : uri.host),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.rossoGubbio,
            side: const BorderSide(color: AppColors.rossoGubbio),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
