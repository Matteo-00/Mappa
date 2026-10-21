import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/storia_model.dart';
import '../pages/storia_detail_page.dart';
import '../services/content_service.dart';
import '../services/language_service.dart';
import '../theme/app_colors.dart';

/// "Momento storico": i contenuti di Storia di Gubbio collegati a un luogo
/// (chiesa o museo). Toccandone uno si apre direttamente la sua pagina.
///
/// Non mostra nulla (nemmeno il titolo) se non ci sono contenuti da mostrare,
/// ad esempio perché quelli collegati sono stati eliminati.
class StoriaLinksSection extends StatefulWidget {
  final List<String> storiaIds;

  const StoriaLinksSection({super.key, required this.storiaIds});

  @override
  State<StoriaLinksSection> createState() => _StoriaLinksSectionState();
}

class _StoriaLinksSectionState extends State<StoriaLinksSection> {
  List<StoriaContenuto> _storia = [];
  List<StoriaEpoca> _epoche = [];
  bool _loading = true;
  String? _loadedLanguageCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final code = context.watch<LanguageService>().currentLanguageCode;
    if (_loadedLanguageCode != null && _loadedLanguageCode != code) _load();
  }

  Future<void> _load() async {
    final code = context.read<LanguageService>().currentLanguageCode;
    _loadedLanguageCode = code;
    if (widget.storiaIds.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final storia = await ContentService.fetchStoriaByIds(widget.storiaIds,
        languageCode: code);
    final epoche = await ContentService.fetchStoriaEpoche(languageCode: code);
    if (!mounted) return;
    setState(() {
      _storia = storia;
      _epoche = epoche;
      _loading = false;
    });
  }

  StoriaEpoca? _epocaOf(StoriaContenuto c) {
    for (final e in _epoche) {
      if (e.id == c.eraId) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.storiaIds.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);

    if (!_loading && _storia.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: AppColors.grigioChiaro),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.history_edu_outlined,
                  size: 22, color: AppColors.rossoGubbio),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.t('luogoHistoricMoment'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.bluNotte,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: AppColors.rossoGubbio),
              ),
            )
          else
            for (final c in _storia)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _card(context, c, l10n),
              ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, StoriaContenuto c, AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.avorio,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoriaDetailPage(contenuto: c, epoca: _epocaOf(c)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: c.coverImage != null
                        ? Image.network(
                            c.coverImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (c.displayDate.isNotEmpty)
                        Text(
                          c.displayDate.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.rossoGubbio,
                          ),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        c.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: AppColors.bluNotte,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.t('stReadStory'),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.rossoGubbio,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.tortora),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.grigioChiaro, AppColors.tortora],
          ),
        ),
        child: Center(
          child: Icon(Icons.castle_outlined, color: Colors.white, size: 26),
        ),
      );
}
