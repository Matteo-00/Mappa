import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

/// Il "simbolo" con cui si legge una valutazione: al posto delle stelle ogni
/// tipo di luogo ha la sua icona tipica di Gubbio.
enum RatingKind {
  /// Ristoranti: la crescia (il pane tipico).
  crescia,

  /// Bar: la bottiglia di Amaro Matto, l'amaro nato a Gubbio.
  amaro,

  /// Hotel: il Palazzo dei Consoli, il simbolo della città.
  palazzo,

  /// Negozi: le classiche stelle (non hanno un simbolo della città).
  stelle,
}

extension RatingKindInfo on RatingKind {
  String get asset {
    switch (this) {
      case RatingKind.crescia:
        return 'assets/crescia.png';
      case RatingKind.amaro:
        return 'assets/rating/amaro.png';
      case RatingKind.palazzo:
        return 'assets/rating/palazzo.png';
      case RatingKind.stelle:
        return ''; // disegnata con un'icona, non con un'immagine
    }
  }

  /// Larghezza / altezza dell'immagine.
  double get aspectRatio {
    switch (this) {
      case RatingKind.crescia:
        return 300 / 208;
      case RatingKind.amaro:
        return 79 / 200;
      case RatingKind.palazzo:
        return 193 / 200;
      case RatingKind.stelle:
        return 1;
    }
  }

  /// Altezza rispetto a `size`: la bottiglia è stretta e alta, quindi si
  /// ingrandisce un po' per restare leggibile accanto alle altre icone.
  double get heightFactor {
    switch (this) {
      case RatingKind.crescia:
        return 1.0;
      case RatingKind.amaro:
        return 1.35;
      case RatingKind.palazzo:
        return 1.05;
      case RatingKind.stelle:
        return 1.1;
    }
  }

  String get titleKey {
    switch (this) {
      case RatingKind.crescia:
        return 'ratingCresceTitle';
      case RatingKind.amaro:
        return 'ratingAmaroTitle';
      case RatingKind.palazzo:
        return 'ratingPalazzoTitle';
      case RatingKind.stelle:
        return 'ratingStelleTitle';
    }
  }

  String get infoKey {
    switch (this) {
      case RatingKind.crescia:
        return 'ratingCresceInfo';
      case RatingKind.amaro:
        return 'ratingAmaroInfo';
      case RatingKind.palazzo:
        return 'ratingPalazzoInfo';
      case RatingKind.stelle:
        return 'ratingStelleInfo';
    }
  }
}

/// Valutazione da 0 a 5 con le icone del luogo ([kind]) al posto delle stelle:
/// 5 icone valgono come 5 stelle. Le icone si riempiono in proporzione, decimali
/// compresi: 4.5 = quattro icone piene e mezza, 4.3 = quattro piene e un terzo
/// della quinta.
class RatingIcons extends StatelessWidget {
  final double rating;

  /// Altezza di riferimento di ogni icona (la larghezza segue le proporzioni
  /// dell'immagine).
  final double size;
  final RatingKind kind;

  const RatingIcons({
    super.key,
    required this.rating,
    this.size = 15,
    this.kind = RatingKind.crescia,
  });

  @override
  Widget build(BuildContext context) {
    final value = rating.clamp(0.0, 5.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final fill = (value - i).clamp(0.0, 1.0);
        return Padding(
          padding: EdgeInsets.only(right: i < 4 ? size * 0.12 : 0),
          child: _PartialIcon(kind: kind, size: size, fill: fill),
        );
      }),
    );
  }
}

/// Icona "vuota" (grigia) con sopra quella a colori tagliata alla frazione
/// [fill] da sinistra.
class _PartialIcon extends StatelessWidget {
  final RatingKind kind;
  final double size;
  final double fill;

  const _PartialIcon({
    required this.kind,
    required this.size,
    required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    if (fill >= 1) return RatingIcon(kind: kind, size: size);
    final empty = RatingIcon(kind: kind, size: size, filled: false);
    if (fill <= 0) return empty;
    return Stack(
      children: [
        empty,
        ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: fill,
            child: RatingIcon(kind: kind, size: size),
          ),
        ),
      ],
    );
  }
}

/// Una singola icona di valutazione. Vuota = grigia e trasparente, come una
/// stella non colorata.
class RatingIcon extends StatelessWidget {
  final RatingKind kind;
  final double size;
  final bool filled;

  const RatingIcon({
    super.key,
    this.kind = RatingKind.crescia,
    this.size = 15,
    this.filled = true,
  });

  // Scala di grigi (pesi standard di luminanza).
  static const ColorFilter _greyscale = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final height = size * kind.heightFactor;
    if (kind == RatingKind.stelle) {
      final star = Icon(Icons.star_rounded,
          size: height, color: const Color(0xFFF5A623));
      return filled
          ? star
          : Opacity(
              opacity: 0.35,
              child: ColorFiltered(colorFilter: _greyscale, child: star),
            );
    }
    final image = Image.asset(
      kind.asset,
      width: height * kind.aspectRatio,
      height: height,
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

/// L'icona della crescia (assets/crescia.png): scorciatoia per
/// `RatingIcon(kind: RatingKind.crescia)`.
class CresciaIcon extends StatelessWidget {
  static const String asset = 'assets/crescia.png';

  /// Larghezza / altezza dell'immagine.
  static const double aspectRatio = 300 / 208;

  final double size;
  final bool filled;

  const CresciaIcon({super.key, this.size = 15, this.filled = true});

  @override
  Widget build(BuildContext context) =>
      RatingIcon(kind: RatingKind.crescia, size: size, filled: filled);
}

/// Icone + voto numerico + pulsante "i" che spiega cosa sono le icone e come
/// nasce la valutazione.
class RatingSummary extends StatelessWidget {
  final double rating;
  final RatingKind kind;
  final double iconSize;
  final double fontSize;

  const RatingSummary({
    super.key,
    required this.rating,
    this.kind = RatingKind.crescia,
    this.iconSize = 15,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingIcons(rating: rating, size: iconSize, kind: kind),
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
          onTap: () => showRatingInfo(context, kind),
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

/// Finestra della "i": spiega le icone (5 icone = 5 stelle), racconta qualcosa
/// su ciò che rappresentano (la crescia, l'Amaro Matto, il Palazzo dei
/// Consoli) e che il punteggio si basa su dati certi da fonti affidabili.
void showRatingInfo(
  BuildContext context, [
  RatingKind kind = RatingKind.crescia,
]) {
  final l10n = AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          RatingIcon(kind: kind, size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text(l10n.t(kind.titleKey))),
        ],
      ),
      content: SingleChildScrollView(
        child: Text('${l10n.t(kind.infoKey)}\n\n${l10n.t('ratingInfo')}'),
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
