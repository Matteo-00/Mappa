import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';
import 'app_filter_chip.dart';

/// Pulsante a pillola "Filtri" che apre un pannello con tutti i filtri
/// raggruppati. Se ci sono filtri attivi mostra un numerino rosso.
///
/// Sostituisce le lunghe file di chip a scorrimento orizzontale: occupa una
/// sola riga e i filtri si scelgono comodamente nel pannello.
class FilterPillButton extends StatelessWidget {
  final int activeCount;
  final VoidCallback onTap;

  /// Sopra una mappa o una foto: ombra più marcata.
  final bool floating;

  const FilterPillButton({
    super.key,
    required this.activeCount,
    required this.onTap,
    this.floating = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.read<LanguageService>().currentLanguageCode);
    final active = activeCount > 0;
    return Material(
      color: Colors.white,
      elevation: floating ? 4 : 1.5,
      shadowColor: Colors.black.withOpacity(floating ? 0.22 : 0.12),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 9, 12, 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.tune_rounded,
                  size: 19, color: AppColors.rossoGubbio),
              const SizedBox(width: 7),
              Text(
                l10n.t('filtersButton'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.bluNotte,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 7),
                Container(
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.rossoGubbio,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$activeCount',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 2),
              const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: AppColors.tortora),
            ],
          ),
        ),
      ),
    );
  }
}

/// Titoletto di un gruppo di filtri nel pannello (icona + testo).
class FilterGroupTitle extends StatelessWidget {
  final IconData icon;
  final String text;

  const FilterGroupTitle({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 18, 0, 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.rossoGubbio),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: AppColors.bluNotte,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Un gruppo di chip che vanno a capo (nessuno scorrimento laterale).
class FilterChipsWrap extends StatelessWidget {
  final List<AppFilterChip> chips;

  const FilterChipsWrap({super.key, required this.chips});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: chips);
  }
}

/// Apre il pannello dei filtri dal basso.
///
/// [content] costruisce le sezioni; riceve [rebuild] da chiamare dopo ogni
/// cambio, così il pannello si ridisegna subito (i filtri si applicano in
/// tempo reale, dietro al pannello). [onReset] azzera tutti i filtri.
Future<void> showFilterSheet(
  BuildContext context, {
  required String title,
  required List<Widget> Function(BuildContext context, VoidCallback rebuild)
      content,
  required VoidCallback onReset,
  required bool Function() hasActiveFilters,
  Widget? header,
}) {
  final l10n = AppLocalizations.of(
      context.read<LanguageService>().currentLanguageCode);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.avorio,
    barrierColor: Colors.black.withOpacity(0.25),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setSheet) {
          void rebuild() => setSheet(() {});
          final maxHeight = MediaQuery.of(ctx).size.height * 0.82;
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grigioChiaro,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 14, 12, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded,
                            color: AppColors.rossoGubbio),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppColors.bluNotte,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded,
                              color: AppColors.tortora),
                        ),
                      ],
                    ),
                  ),
                  if (header != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
                      child: header,
                    ),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: content(ctx, rebuild),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: hasActiveFilters()
                                ? () {
                                    onReset();
                                    rebuild();
                                  }
                                : null,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.rossoGubbio,
                              side: BorderSide(
                                color: hasActiveFilters()
                                    ? AppColors.rossoGubbio
                                    : AppColors.grigioChiaro,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              l10n.t('fltReset'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.rossoGubbio,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(
                              l10n.t('filtersDone'),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
