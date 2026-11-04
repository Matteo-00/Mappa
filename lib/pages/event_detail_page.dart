import '../widgets/distance_label.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/event_model.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../widgets/premium_scaffold.dart';
import 'map_page.dart';
import 'package:url_launcher/url_launcher.dart';
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
          PremiumHeader(title: l10n.eventHeaderTitle),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Immagine grande in alto
                  _buildEventImage(),

                  // Contenuto dettagli
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Orario con icona
                        _buildTimeSection(),
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

                        // Informazioni storiche (non per gli eventi del
                        // Comune: concerti, mostre... non hanno un testo storico)
                        if (!event.isFromComune) ...[
                          _buildHistoricalSection(l10n),
                          const SizedBox(height: 24),
                        ],

                        // Curiosità (se disponibili)
                        _buildCuriositySection(l10n),
                        const SizedBox(height: 24),

                        // Luogo
                        _buildLocationSection(context, l10n),
                        const SizedBox(height: 24),
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

  /// Immagine evento (segnaposto)
  Widget _buildEventImage() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.tortora.withOpacity(0.4),
            AppColors.avorio,
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.festival_outlined,
              size: 72,
              color: AppColors.rossoGubbio.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              event.category.trim().isNotEmpty ? event.category : 'Gubbio',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sezione orario
  Widget _buildTimeSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.rossoGubbio.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.access_time_rounded,
            color: AppColors.rossoGubbio,
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            event.time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.rossoGubbio,
            ),
          ),
        ],
      ),
    );
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

  /// Sezione informazioni storiche
  Widget _buildHistoricalSection(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.bluNotte.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.rossoGubbio.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.rossoGubbio,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.historicalContextLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getHistoricalContext(event.id),
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Sezione curiosità
  Widget _buildCuriositySection(AppLocalizations l10n) {
    final curiosities = _getCuriosities(event.id);
    if (curiosities.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.rossoGubbio.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.rossoGubbio.withOpacity(0.18),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.rossoGubbio.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.rossoGubbio,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.didYouKnowLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...curiosities.map((curiosity) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.rossoGubbio,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        curiosity,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
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
                color: AppColors.bluNotte.withOpacity(0.05),
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

  /// Restituisce il contesto storico per un evento
  String _getHistoricalContext(String eventId) {
    final contexts = {
      'evt_1': 'La tradizione dei tamburi che svegliano i Capitani risale al Medioevo, '
          'quando era necessario radunare i ceraioli prima dell\'alba per prepararsi alla lunga giornata di celebrazioni.',
      'evt_2': 'Il Campanone del Palazzo dei Consoli, con il suo suono inconfondibile, '
          'risuona per tutta Gubbio annunciando ufficialmente l\'inizio della Festa dei Ceri.',
      'evt_4': 'La Messa dei Ceraioli nel Duomo è un momento di raccoglimento e spiritualità '
          'che precede l\'energica celebrazione della giornata.',
      'evt_6': 'L\'Alzata dei Ceri è il momento culminante della mattinata: i tre Ceri, '
          'alti 4 metri e pesanti circa 280 kg ciascuno, vengono issati sulle spalle dei ceraioli '
          'tra il boato della folla in Piazza Grande.',
      'evt_8': 'La Corsa dei Ceri è il momento più atteso: una sfida secolare dove i tre Ceri '
          'vengono portati di corsa dal centro storico fino alla Basilica di Sant\'Ubaldo sul Monte Ingino. '
          'Non è una gara di velocità, ma un atto di devozione e orgoglio.',
    };
    return contexts[eventId] ?? 
        'Un evento importante della tradizione eugubina che si tramanda di generazione in generazione.';
  }

  /// Restituisce curiosità per un evento
  List<String> _getCuriosities(String eventId) {
    final curiositiesMap = {
      'evt_6': [
        'Ogni Cero pesa circa 280 kg ed è alto oltre 4 metri',
        'I tre Ceri rappresentano i Santi Ubaldo, Giorgio e Antonio',
        'L\'ordine dei Ceri non cambia mai: Sant\'Ubaldo arriva sempre per primo',
      ],
      'evt_8': [
        'La corsa dura circa 30 minuti',
        'I ceraioli percorrono oltre 4 km in salita',
        'La festa ha origini medievali e risale al XII secolo',
      ],
    };
    return curiositiesMap[eventId] ?? [];
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
