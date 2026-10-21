import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

/// Valutazione da 0 a 5 in "cresce" (il pane tipico di Gubbio) al posto delle
/// stelle: 5 cresce valgono come 5 stelle. Le icone si riempiono in
/// proporzione, decimali compresi: 4.5 = quattro cresce piene e mezza crescia,
/// 4.3 = quattro piene e un terzo della quinta.
class RatingIcons extends StatelessWidget {
  final double rating;

  /// Altezza di ogni crescia (la larghezza segue le proporzioni dell'immagine).
  final double size;

  const RatingIcons({super.key, required this.rating, this.size = 15});

  @override
  Widget build(BuildContext context) {
    final value = rating.clamp(0.0, 5.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (value - i).clamp(0.0, 1.0);
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? size * 0.12 : 0),
          child: _PartialCrescia(size: size, fill: fill),
        );
      }),
    );
  }
}

/// Crescia "vuota" (grigia) con sopra quella dorata tagliata alla frazione
/// [fill] da sinistra.
class _PartialCrescia extends StatelessWidget {
  final double size;
  final double fill;

  const _PartialCrescia({required this.size, required this.fill});

  @override
  Widget build(BuildContext context) {
    if (fill >= 1) return CresciaIcon(size: size);
    final empty = CresciaIcon(size: size, filled: false);
    if (fill <= 0) return empty;
    return Stack(
      children: [
        empty,
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: fill,
            child: CresciaIcon(size: size),
          ),
        ),
      ],
    );
  }
}

/// L'icona della crescia (assets/crescia.png). Vuota = grigia e trasparente,
/// come una stella non colorata.
class CresciaIcon extends StatelessWidget {
  static const String asset = 'assets/crescia.png';

  /// Larghezza / altezza dell'immagine.
  static const double aspectRatio = 300 / 208;

  final double size;
  final bool filled;

  const CresciaIcon({super.key, this.size = 15, this.filled = true});

  // Scala di grigi (pesi standard di luminanza).
  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      asset,
      width: size * aspectRatio,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );
    if (filled) return image;
    return Opacity(
      opacity: 0.35,
      child: ColorFiltered(colorFilter: _greyscale, child: image),
    );
  }
}

/// Cresce + voto numerico + pulsante "i" che spiega cosa sono le cresce e
/// come nasce la valutazione.
class RatingSummary extends StatelessWidget {
  final double rating;
  final double iconSize;
  final double fontSize;

  const RatingSummary({
    super.key,
    required this.rating,
    this.iconSize = 15,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingIcons(rating: rating, size: iconSize),
        SizedBox(width: iconSize * 0.35),
        Text(
          rating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
        // Area di tocco più ampia dell'icona, per non aprire per sbaglio
        // la card sotto.
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => showRatingInfo(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
            child: Icon(
              Icons.info_outline_rounded,
              size: fontSize + 4,
              color: AppColors.textMuted.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}

/// Finestra della "i": spiega le cresce (5 cresce = 5 stelle) e che il
/// punteggio si basa su dati certi da fonti affidabili.
void showRatingInfo(BuildContext context) {
  final l10n = AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const CresciaIcon(size: 26),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.t('ratingCresceTitle'))),
        ],
      ),
      content: SingleChildScrollView(
        child: Text('${l10n.t('ratingCresceInfo')}\n\n${l10n.t('ratingInfo')}'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
