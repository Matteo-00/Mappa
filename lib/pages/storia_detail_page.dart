import 'package:flutter/material.dart';
import '../models/storia_model.dart';
import '../theme/app_colors.dart';

/// Pagina editoriale dedicata a un singolo capitolo della storia di Gubbio.
class StoriaDetailPage extends StatelessWidget {
  final StoriaCapitolo capitolo;

  const StoriaDetailPage({super.key, required this.capitolo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: CustomScrollView(
        slivers: [
          _buildHero(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEpocaBadge(),
                  const SizedBox(height: 16),
                  Text(
                    capitolo.titolo,
                    style: const TextStyle(
                      fontFamily: 'serif',
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                      color: AppColors.bluNotte,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    capitolo.sottotitolo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.rossoGubbio,
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Introduzione in evidenza
                  Container(
                    padding: const EdgeInsets.only(left: 16),
                    decoration: const BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.tortora,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      capitolo.introduzione,
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.55,
                        fontStyle: FontStyle.italic,
                        color: AppColors.bluNotte.withOpacity(0.85),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Sezioni
                  for (final sezione in capitolo.sezioni)
                    _buildSezione(sezione),

                  // Curiosità
                  if (capitolo.curiosita != null) ...[
                    const SizedBox(height: 8),
                    _buildCuriosita(capitolo.curiosita!),
                  ],

                  // Cosa vede oggi il visitatore
                  if (capitolo.cosaVedeOggi != null) ...[
                    const SizedBox(height: 20),
                    _buildCosaVedeOggi(capitolo.cosaVedeOggi!),
                  ],

                  const SizedBox(height: 32),
                  _buildBackToIndex(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------- Hero collassabile
  Widget _buildHero(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.bluNotte,
      foregroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: _circleButton(
          icon: Icons.arrow_back_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _imagePlaceholder(capitolo.immagineHeroLabel, icon: capitolo.icona),
            // Overlay per leggibilità
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22000000),
                    Color(0x66000000),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 22,
              bottom: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.rossoGubbio,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Capitolo ${capitolo.numero}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEpocaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.tortora.withOpacity(0.22),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(capitolo.icona, size: 16, color: AppColors.rossoGubbio),
          const SizedBox(width: 8),
          Text(
            capitolo.epoca,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSezione(StoriaSezione sezione) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sezione.sottotitolo != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.rossoGubbio,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sezione.sottotitolo!,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bluNotte,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (sezione.conImmagine) ...[
          _imageCard(sezione.immagineLabel ?? 'Immagine'),
          const SizedBox(height: 16),
        ],
        Text(
          sezione.testo,
          style: const TextStyle(
            fontSize: 15.5,
            height: 1.65,
            color: AppColors.bluNotte,
          ),
        ),
        const SizedBox(height: 26),
      ],
    );
  }

  Widget _buildCuriosita(String testo) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.rossoGubbio.withOpacity(0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.rossoGubbio.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.lightbulb_outline_rounded,
                  color: AppColors.rossoGubbio, size: 22),
              SizedBox(width: 10),
              Text(
                'Curiosità',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.rossoGubbio,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            testo,
            style: const TextStyle(
              fontSize: 15,
              height: 1.6,
              color: AppColors.bluNotte,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCosaVedeOggi(String testo) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bluNotte,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.visibility_outlined,
                  color: AppColors.tortora, size: 22),
              SizedBox(width: 10),
              Text(
                'Cosa vede oggi il visitatore',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            testo,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackToIndex(BuildContext context) {
    return Center(
      child: OutlinedButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.list_alt_rounded, size: 20),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.rossoGubbio,
          side: const BorderSide(color: AppColors.rossoGubbio),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        label: const Text(
          'Torna all\'indice',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // -------------------------------------------------- Helpers immagini
  Widget _imageCard(String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: _imagePlaceholder(label),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.black.withOpacity(0.28),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Placeholder elegante per un'immagine ancora da inserire.
Widget _imagePlaceholder(String label, {IconData icon = Icons.image_outlined}) {
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
          Icon(icon, size: 40, color: Colors.white.withOpacity(0.85)),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Immagine: $label',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.95),
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
