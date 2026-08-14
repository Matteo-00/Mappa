import 'package:flutter/material.dart';
import '../data/storia_data.dart';
import '../models/storia_model.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import 'storia_detail_page.dart';

/// Indice della sezione "Storia di Gubbio" — un piccolo museo digitale.
/// Introduzione scenografica, timeline del viaggio nel tempo e card
/// visive per ogni epoca.
class StoriaPage extends StatelessWidget {
  const StoriaPage({super.key});

  void _openCapitolo(BuildContext context, StoriaCapitolo capitolo) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StoriaDetailPage(capitolo: capitolo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          const PremiumHeader(title: 'Storia di Gubbio'),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildIntroHero(),
                const SizedBox(height: 24),
                _buildIntroText(),
                const SizedBox(height: 28),
                _buildTimeline(context),
                const SizedBox(height: 28),
                _buildSezioneTitolo(),
                const SizedBox(height: 16),
                ...List.generate(storiaCapitoli.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                    child: _buildEpocaCard(context, storiaCapitoli[i]),
                  );
                }),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Hero introduzione
  Widget _buildIntroHero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: SizedBox(
          height: 240,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _imagePlaceholderStoria('Panorama di Gubbio', icon: Icons.castle),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x11000000),
                      Color(0xCC16283D),
                    ],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.rossoGubbio,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        'MUSEO DIGITALE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      storiaIntroTitolo,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.05,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Oltre 2000 anni di storia',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildIntroText() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        storiaIntroTesto,
        style: const TextStyle(
          fontSize: 15.5,
          height: 1.65,
          color: AppColors.bluNotte,
        ),
      ),
    );
  }

  // -------------------------------------------------- Timeline del viaggio
  Widget _buildTimeline(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Il viaggio nel tempo',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Umbri → Romani → Medioevo → Comune → Rinascimento → Ceri → Oggi',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 108,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: storiaCapitoli.length,
            itemBuilder: (context, i) {
              final capitolo = storiaCapitoli[i];
              final isLast = i == storiaCapitoli.length - 1;
              return _buildTimelineNode(context, capitolo, isLast);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineNode(
      BuildContext context, StoriaCapitolo capitolo, bool isLast) {
    return GestureDetector(
      onTap: () => _openCapitolo(context, capitolo),
      child: SizedBox(
        width: 92,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.rossoGubbio.withOpacity(0.35),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.bluNotte.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(capitolo.icona,
                      color: AppColors.rossoGubbio, size: 22),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: AppColors.tortora.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              capitolo.epocaBreve,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.bluNotte,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------- Titolo sezione card
  Widget _buildSezioneTitolo() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        'Le epoche di Gubbio',
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.bluNotte,
        ),
      ),
    );
  }

  // -------------------------------------------------- Card epoca (compatta)
  Widget _buildEpocaCard(BuildContext context, StoriaCapitolo capitolo) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openCapitolo(context, capitolo),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluNotte.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // Miniatura con numero
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 78,
                      height: 78,
                      child: _imagePlaceholderStoriaCompact(capitolo.icona),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.rossoGubbio,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        capitolo.numero,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Testi
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      capitolo.epocaBreve.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.rossoGubbio,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      capitolo.titolo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bluNotte,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      capitolo.sottotitolo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.tortora, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Miniatura compatta per le card indice.
Widget _imagePlaceholderStoriaCompact(IconData icon) {
  return DecoratedBox(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.grigioChiaro, AppColors.tortora],
      ),
    ),
    child: Center(
      child: Icon(icon, size: 30, color: Colors.white.withOpacity(0.9)),
    ),
  );
}

/// Placeholder elegante per un'immagine ancora da inserire.
Widget _imagePlaceholderStoria(String label,
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
