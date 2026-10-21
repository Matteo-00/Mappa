import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'admin/edit_itinerario_flow.dart';
import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../utils/route_links.dart';
import '../widgets/distance_label.dart';
import 'map_page.dart';
import 'tappa_detail_page.dart';
import '../models/itinerario_model.dart';
import '../theme/app_colors.dart';
import 'itinerari_page.dart' show itinerarioImagePlaceholder;

/// Pagina di dettaglio di un itinerario, con hero, informazioni e tappe.
///
/// Ogni tappa mostra titolo, descrizione, posizione e i pulsanti "Sulla mappa"
/// e "Approfondisci" (pagina con approfondimento, curiosità e collegamenti alla
/// storia di Gubbio).
///
/// L'amministratore vede una matita per modificare l'itinerario (e una per ogni
/// tappa): titoli, descrizioni, posizione, tappe, approfondimenti, tutto; al
/// salvataggio la pagina si aggiorna da sola.
class ItinerarioDetailPage extends StatefulWidget {
  final ItinerarioModel itinerario;

  const ItinerarioDetailPage({super.key, required this.itinerario});

  @override
  State<ItinerarioDetailPage> createState() => _ItinerarioDetailPageState();
}

class _ItinerarioDetailPageState extends State<ItinerarioDetailPage> {
  late ItinerarioModel _itinerario = widget.itinerario;

  Future<void> _edit(int? stopIndex) async {
    final updated =
        await editItinerarioFlow(context, _itinerario, stopIndex: stopIndex);
    if (updated != null && mounted) setState(() => _itinerario = updated);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthService>().isAdmin;
    return _ItinerarioDetailView(
      itinerario: _itinerario,
      onEdit: isAdmin ? _edit : null,
    );
  }
}

class _ItinerarioDetailView extends StatelessWidget {
  final ItinerarioModel itinerario;

  /// Solo admin: apre la modifica (null = tutto l'itinerario, altrimenti la tappa).
  final void Function(int? stopIndex)? onEdit;

  const _ItinerarioDetailView({required this.itinerario, this.onEdit});

  /// Apre la mappa sull'itinerario (con le tappe, se hanno la posizione) oppure
  /// su una singola tappa.
  void _openMap(BuildContext context, {int? stopIndex}) {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final position = stopIndex != null
        ? itinerario.tappe[stopIndex].position
        : itinerario.mapPosition;
    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              l10n.t(stopIndex != null ? 'tpNoPosition' : 'itNoPosition')),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapPage(
          focus: MapFocus(
            kind: MapKind.itinerary,
            id: itinerario.id,
            position: position,
            stopIndex: stopIndex,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    final stopsWithPosition = itinerario.tappeConPosizione;

    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.bluNotte,
            foregroundColor: Colors.white,
            actions: [
              if (onEdit != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Material(
                    color: Colors.black.withOpacity(0.28),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onEdit!(null),
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.edit_outlined,
                            color: Colors.white, size: 21),
                      ),
                    ),
                  ),
                ),
            ],
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Material(
                color: Colors.black.withOpacity(0.28),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (itinerario.imageUrl != null)
                    Image.network(
                      itinerario.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => itinerarioImagePlaceholder(
                        itinerario.immagineLabel,
                        icon: itinerario.icona,
                      ),
                    )
                  else
                    itinerarioImagePlaceholder(
                      itinerario.immagineLabel,
                      icon: itinerario.icona,
                    ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x22000000), Color(0x88000000)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.rossoGubbio,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            itinerario.tema.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          itinerario.titolo,
                          style: const TextStyle(
                            fontFamily: 'serif',
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info rapide
                  Row(
                    children: [
                      _infoBox(Icons.schedule, l10n.t('itDuration'),
                          itinerario.durata),
                      const SizedBox(width: 12),
                      _infoBox(Icons.terrain_outlined, l10n.t('itDifficulty'),
                          itinerario.difficolta),
                      const SizedBox(width: 12),
                      _infoBox(Icons.place_outlined, l10n.t('itStopsLabel'),
                          '${itinerario.tappe.length}'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _openMap(context),
                      icon: const Icon(Icons.map_outlined),
                      label: Text(l10n.t('showOnMapBtn')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.rossoGubbio,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  // Percorso completo: serve almeno partenza e arrivo.
                  if (stopsWithPosition.length >= 2) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => openRouteThrough(
                            [for (final t in stopsWithPosition) t.position!]),
                        icon: const Icon(Icons.directions_walk),
                        label: Text(l10n.t('tpFullRouteWalk')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.rossoGubbio,
                          side: const BorderSide(color: AppColors.rossoGubbio),
                          textStyle: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    itinerario.descrizione,
                    style: const TextStyle(
                      fontSize: 15.5,
                      height: 1.65,
                      color: AppColors.bluNotte,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    l10n.t('itDetailStops'),
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.bluNotte,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(itinerario.tappe.length, (i) {
                    final tappa = itinerario.tappe[i];
                    final isLast = i == itinerario.tappe.length - 1;
                    return _buildTappa(context, l10n, i, tappa, isLast);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.bluNotte.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.rossoGubbio, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.bluNotte,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTappa(
    BuildContext context,
    AppLocalizations l10n,
    int index,
    ItinerarioTappa tappa,
    bool isLast,
  ) {
    final numero = index + 1;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colonna numero + linea
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.rossoGubbio,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$numero',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.tortora.withOpacity(0.5),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Contenuto tappa
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bluNotte.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tappa.nome,
                            style: const TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bluNotte,
                            ),
                          ),
                        ),
                        if (onEdit != null)
                          IconButton(
                            tooltip: 'Modifica tappa',
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.edit_outlined,
                                size: 20, color: AppColors.bluNotte),
                            onPressed: () => onEdit!(index),
                          ),
                        if (tappa.durata.trim().isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.avorio,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule,
                                    size: 13, color: AppColors.tortora),
                                const SizedBox(width: 4),
                                Text(
                                  tappa.durata,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.bluNotte,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (tappa.descrizione.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        tappa.descrizione,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                    // Posizione della tappa: coordinate e distanza da te.
                    if (tappa.hasCoordinates) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.my_location,
                                  size: 14, color: AppColors.rossoGubbio),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '${tappa.latitudine!.toStringAsFixed(5)}, '
                                  '${tappa.longitudine!.toStringAsFixed(5)}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          DistanceLabel(target: tappa.position!, fontSize: 12),
                        ],
                      ),
                    ],
                    if (tappa.hasCoordinates || tappa.hasApprofondimento) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (tappa.hasCoordinates)
                            _smallButton(
                              icon: Icons.map_outlined,
                              label: l10n.t('tpOnMap'),
                              filled: false,
                              onTap: () => _openMap(context, stopIndex: index),
                            ),
                          if (tappa.hasApprofondimento)
                            _smallButton(
                              icon: Icons.auto_stories_outlined,
                              label: l10n.t('tpApprofondisci'),
                              filled: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TappaDetailPage(
                                    itinerario: itinerario,
                                    index: index,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallButton({
    required IconData icon,
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final style = filled
        ? ElevatedButton.styleFrom(
            backgroundColor: AppColors.rossoGubbio,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          )
        : OutlinedButton.styleFrom(
            foregroundColor: AppColors.rossoGubbio,
            side: const BorderSide(color: AppColors.rossoGubbio),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            textStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          );
    final iconWidget = Icon(icon, size: 18);
    return filled
        ? ElevatedButton.icon(
            onPressed: onTap, icon: iconWidget, label: Text(label), style: style)
        : OutlinedButton.icon(
            onPressed: onTap, icon: iconWidget, label: Text(label), style: style);
  }
}
