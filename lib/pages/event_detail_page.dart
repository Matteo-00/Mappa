import '../widgets/distance_label.dart';
import '../widgets/full_photo.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import 'map_page.dart';
import '../widgets/favorite_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';

/// Pagina dettaglio evento con informazioni complete
class EventDetailPage extends StatelessWidget {
  final EventModel event;

  const EventDetailPage({
    super.key,
    required this.event,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(
        context.watch<LanguageService>().currentLanguageCode);
    return Scaffold(
      backgroundColor: AppColors.avorio,
      body: Column(
        children: [
          PremiumHeader(
            title: event.isNews ? l10n.t('newsTab') : l10n.eventHeaderTitle,
            trailing: ContentService.isRemoteId(event.id)
                ? FavoriteButton(kind: MapKind.event, id: event.id)
                : null,
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto dell'evento (la stessa della lista), se c'è
                  if ((event.imageUrl ?? '').isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: FullPhoto(
                        url: event.imageUrl!,
                        fallback: const ColoredBox(color: AppColors.grigioChiaro),
                      ),
                    ),

                  // Contenuto dettagli
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Data e orario
                        // Notizia: data di pubblicazione; evento: data e orario.
                        event.isNews
                            ? _buildPublishedSection(l10n)
                            : _buildTimeSection(l10n),
                        const SizedBox(height: 12),
                        _buildActions(l10n),
                        const SizedBox(height: 16),

                        // Solo admin: evento importato ancora da approvare
                        if (event.isDraft &&
                            context.watch<AuthService>().isAdmin) ...[
                          _DraftAdminBar(event: event),
                          const SizedBox(height: 16),
                        ],

                        // Titolo evento
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.bluNotte,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Descrizione completa
                        _buildDescriptionSection(l10n),
                        const SizedBox(height: 24),

                        // Fonte (eventi importati dal sito del Comune)
                        if (event.isFromComune) ...[
                          _buildSourceSection(l10n),
                          const SizedBox(height: 24),
                        ],

                        // Luogo (non per le notizie)
                        if (!event.isNews) ...[
                          _buildLocationSection(context, l10n),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Data ("Sabato 14 novembre 2026", oppure "4 nov – 24 nov" per gli
  /// eventi di più giorni) e orario ("21:00 – 23:00" o "Tutto il giorno").
  Widget _buildTimeSection(AppLocalizations l10n) {
    final s = event.startTime;
    final e = event.endTime;
    final days = l10n.list('weekdaysFull');
    final months = l10n.list('monthsFull');
    String cap(String v) =>
        v.isEmpty ? v : v[0].toUpperCase() + v.substring(1).toLowerCase();
    // Mesi con la maiuscola in inglese e tedesco, minuscola in italiano e
    // francese ("14 November" / "14 novembre").
    final upperMonths = l10n.languageCode == 'en' || l10n.languageCode == 'de';
    String month(int m) =>
        upperMonths ? cap(months[m - 1]) : months[m - 1].toLowerCase();
    String longDate(DateTime d) =>
        '${cap(days[d.weekday - 1])} ${d.day} ${month(d.month)} ${d.year}';
    String hm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    final sameDay = s.year == e.year && s.month == e.month && s.day == e.day;
    final allDay = s.hour == 0 && s.minute == 0 && e.hour == 23 && e.minute == 59;

    final dateText = sameDay || !e.isAfter(s)
        ? longDate(s)
        : '${s.day} ${month(s.month)} – ${e.day} ${month(e.month)} ${e.year}';
    final timeText = allDay
        ? l10n.t('evAllDay')
        : (sameDay && e.isAfter(s) ? '${hm(s)} – ${hm(e)}' : hm(s));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rossoGubbio.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_rounded,
              color: AppColors.rossoGubbio, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.bluNotte,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.rossoGubbio,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Notizia del Comune: "Pubblicata il 5 novembre 2026" e la categoria.
  Widget _buildPublishedSection(AppLocalizations l10n) {
    final d = event.startTime;
    final months = l10n.list('monthsFull');
    final upper = l10n.languageCode == 'en' || l10n.languageCode == 'de';
    final m = months[d.month - 1];
    final month = upper ? m[0] + m.substring(1).toLowerCase() : m.toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bluNotte.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.newspaper_outlined,
              color: AppColors.bluNotte, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.fmt('newsPublishedOn', {'date': '${d.day} $month ${d.year}'}),
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.bluNotte,
                  ),
                ),
                if (event.category.trim().isNotEmpty)
                  Text(
                    event.category,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.rossoGubbio,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// "Aggiungi al calendario" e "Condividi".
  Widget _buildActions(AppLocalizations l10n) {
    Widget button(IconData icon, String label, VoidCallback onTap) {
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 19),
          label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.rossoGubbio,
            side: const BorderSide(color: AppColors.rossoGubbio),
            padding: const EdgeInsets.symmetric(vertical: 12),
            textStyle:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        if (!event.isNews) ...[
          button(Icons.edit_calendar_outlined, l10n.t('evAddCalendar'),
              _addToCalendar),
          const SizedBox(width: 10),
        ],
        button(Icons.share_outlined, l10n.t('evShare'), () => _share(l10n)),
      ],
    );
  }

  /// Apre Google Calendar (app o sito) con l'evento già compilato: non
  /// servono permessi sul telefono.
  void _addToCalendar() {
    String utc(DateTime d) => d
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp(r'[-:]'), '')
        .replaceAll(RegExp(r'\.\d+'), '');
    final details = [
      if (event.description.trim().isNotEmpty) event.description.trim(),
      if (event.sourceUrl != null) event.sourceUrl!,
    ].join('\n\n');
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': event.title,
      'dates': '${utc(event.startTime)}/${utc(event.endTime)}',
      'details': details.length > 1500 ? details.substring(0, 1500) : details,
      'location': event.location.trim().isEmpty
          ? 'Gubbio'
          : '${event.location}, Gubbio',
    });
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _share(AppLocalizations l10n) {
    final s = event.startTime;
    final months = l10n.list('monthsFull');
    final date = '${s.day} ${months[s.month - 1].toLowerCase()} ${s.year}';
    final text = [
      event.title,
      [date, if (event.location.trim().isNotEmpty) event.location].join(' · '),
      if (event.sourceUrl != null) event.sourceUrl!,
      l10n.t('evShareFooter'),
    ].join('\n');
    SharePlus.instance.share(ShareParams(text: text, subject: event.title));
  }

  /// Sezione descrizione
  Widget _buildDescriptionSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.description,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          event.description.isNotEmpty
              ? event.description
              : l10n.defaultEventDescription,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textMuted,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  /// Fonte dell'evento con il link alla pagina originale del Comune.
  Widget _buildSourceSection(AppLocalizations l10n) {
    final url = event.sourceUrl ?? event.website;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.grigioChiaro),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_outlined,
                  size: 20, color: AppColors.bluNotte),
              const SizedBox(width: 8),
              Text(
                '${l10n.t('evSourceTitle')}: ${l10n.t('srcComune')}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l10n.t('evSourceText'),
            style: const TextStyle(
                fontSize: 13.5, height: 1.45, color: AppColors.textMuted),
          ),
          if (url != null && url.isNotEmpty) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(url),
                  mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new_rounded, size: 18),
              label: Text(l10n.t('evOpenSource')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rossoGubbio,
                side: const BorderSide(color: AppColors.rossoGubbio),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Sezione posizione
  Widget _buildLocationSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.positionLabel,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.bluNotte,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.bluNotte.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.rossoGubbio,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      event.location,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.bluNotte,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: DistanceLabel(
                  target: event.coordinates,
                  fontSize: 14,
                  suffix: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MapPage(
                          focus: MapFocus(
                            kind: MapKind.event,
                            id: event.id,
                            position: event.coordinates,
                          ),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_rounded, size: 20),
                  label: Text(l10n.viewOnMapLabel),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rossoGubbio,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Solo admin: avviso "da approvare" sulle bozze importate dal Comune, con
/// i pulsanti per pubblicarle o eliminarle.
class _DraftAdminBar extends StatefulWidget {
  final EventModel event;
  const _DraftAdminBar({required this.event});

  @override
  State<_DraftAdminBar> createState() => _DraftAdminBarState();
}

class _DraftAdminBarState extends State<_DraftAdminBar> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(done)));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Errore: $e'),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bozza importata dal sito del Comune',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFFE65100),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            e.datesToVerify
                ? 'Le date non erano scritte in modo chiaro: controllale (e '
                    'correggile con la matita nella lista eventi) prima di '
                    'pubblicare. Gli utenti non vedono questo evento.'
                : 'Controlla testo, date e foto. Gli utenti non vedono '
                    'questo evento finché non lo pubblichi.',
            style: const TextStyle(
                fontSize: 13, height: 1.4, color: AppColors.bluNotte),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => ContentService.deleteEvent(e.id),
                          'Evento eliminato'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFB71C1C),
                    side: const BorderSide(color: Color(0xFFB71C1C)),
                  ),
                  child: const Text('Elimina'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy
                      ? null
                      : () => _run(() => ContentService.publishEvent(e.id),
                          'Evento pubblicato'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rossoGubbio,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Pubblica'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
