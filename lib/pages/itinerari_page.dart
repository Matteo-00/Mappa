import 'package:flutter/material.dart';
import '../data/itinerari_data.dart';
import '../models/itinerario_model.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import 'itinerario_detail_page.dart';

/// Elenco degli itinerari consigliati per visitare Gubbio.
class ItinerariPage extends StatelessWidget {
  const ItinerariPage({super.key});

  void _openItinerario(BuildContext context, ItinerarioModel itinerario) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ItinerarioDetailPage(itinerario: itinerario),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          const PremiumHeader(title: 'Itinerari consigliati'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              children: [
                const Text(
                  'Percorsi selezionati per vivere Gubbio al meglio, in base al '
                  'tempo a disposizione e ai tuoi interessi.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 18),
                ...itinerariConsigliati.map(
                  (it) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildItinerarioCard(context, it),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarioCard(BuildContext context, ItinerarioModel it) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _openItinerario(context, it),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluNotte.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                    child: SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: itinerarioImagePlaceholder(
                        it.immagineLabel,
                        icon: it.icona,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.rossoGubbio,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        it.tema,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      it.titolo,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bluNotte,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      it.sottotitolo,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.rossoGubbio,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _metaChip(Icons.schedule, it.durata),
                        const SizedBox(width: 8),
                        _metaChip(Icons.terrain_outlined, it.difficolta),
                        const SizedBox(width: 8),
                        _metaChip(Icons.place_outlined, '${it.tappe.length} tappe'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.avorio,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.grigioChiaro),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.tortora),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: AppColors.bluNotte,
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder elegante per un'immagine di itinerario ancora da inserire.
Widget itinerarioImagePlaceholder(String label,
    {IconData icon = Icons.image_outlined}) {
  return DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.grigioChiaro,
          AppColors.tortora,
        ],
      ),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 38, color: Colors.white.withOpacity(0.85)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Immagine: $label',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.95),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
