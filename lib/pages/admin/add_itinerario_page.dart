import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/itinerario_model.dart';
import '../../models/storia_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import 'admin_widgets.dart';
import 'storia_picker_sheet.dart';

/// Form per aggiungere o modificare un itinerario con le sue tappe.
///
/// Ogni tappa ha: titolo, descrizione, durata, posizione (coordinate) e una
/// sezione "Approfondimento" (testo lungo, curiosità e collegamenti a uno o più
/// contenuti di Storia di Gubbio). Tutto si può modificare anche dopo.
class AddItinerarioPage extends StatefulWidget {
  /// Itinerario esistente da modificare (null = nuovo inserimento).
  final ItinerarioModel? editItinerario;

  /// Tappa da mostrare subito (la pagina scorre fin lì e apre l'approfondimento).
  final int? initialStopIndex;

  const AddItinerarioPage({
    super.key,
    this.editItinerario,
    this.initialStopIndex,
  });

  @override
  State<AddItinerarioPage> createState() => _AddItinerarioPageState();
}

class _TappaControllers {
  final nome = TextEditingController();
  final descrizione = TextEditingController();
  final durata = TextEditingController();
  final lat = TextEditingController();
  final lng = TextEditingController();
  final approfondimento = TextEditingController();
  final curiosita = TextEditingController();

  /// Contenuti di Storia di Gubbio collegati (id).
  List<String> storiaIds = [];

  /// Serve a scorrere fino a questa tappa quando c'è un errore da correggere.
  final GlobalKey key = GlobalKey();

  /// True se la tappa ha almeno un campo compilato (oltre al titolo).
  bool get hasOtherContent =>
      descrizione.text.trim().isNotEmpty ||
      durata.text.trim().isNotEmpty ||
      lat.text.trim().isNotEmpty ||
      lng.text.trim().isNotEmpty ||
      approfondimento.text.trim().isNotEmpty ||
      curiosita.text.trim().isNotEmpty ||
      storiaIds.isNotEmpty;

  _TappaControllers();

  factory _TappaControllers.from(ItinerarioTappa t) {
    final c = _TappaControllers();
    c.nome.text = t.nome;
    c.descrizione.text = t.descrizione;
    c.durata.text = t.durata;
    c.lat.text = t.latitudine?.toString() ?? '';
    c.lng.text = t.longitudine?.toString() ?? '';
    c.approfondimento.text = t.approfondimento;
    c.curiosita.text = t.curiosita;
    c.storiaIds = [...t.storiaIds];
    return c;
  }

  /// True se la sezione "Approfondimento" ha già dei contenuti.
  bool get hasApprofondimento =>
      approfondimento.text.trim().isNotEmpty ||
      curiosita.text.trim().isNotEmpty ||
      storiaIds.isNotEmpty;

  void dispose() {
    nome.dispose();
    descrizione.dispose();
    durata.dispose();
    lat.dispose();
    lng.dispose();
    approfondimento.dispose();
    curiosita.dispose();
  }
}

class _AddItinerarioPageState extends State<AddItinerarioPage> {
  final _formKey = GlobalKey<FormState>();
  final _titolo = TextEditingController();
  final _sottotitolo = TextEditingController();
  final _descrizione = TextEditingController();
  final _durata = TextEditingController();
  final _difficolta = TextEditingController();
  final _tema = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  final List<_TappaControllers> _tappe = [_TappaControllers()];

  /// Tutti i contenuti di Storia di Gubbio (per i collegamenti delle tappe).
  List<StoriaContenuto> _storia = [];

  Uint8List? _imageBytes;
  String? _imageName;
  String? _existingImageUrl;
  bool _saving = false;

  bool get _isEditing => widget.editItinerario != null;

  @override
  void initState() {
    super.initState();
    final it = widget.editItinerario;
    if (it != null) {
      _titolo.text = it.titolo;
      _sottotitolo.text = it.sottotitolo;
      _descrizione.text = it.descrizione;
      _durata.text = it.durata;
      _difficolta.text = it.difficolta;
      _tema.text = it.tema;
      _lat.text = it.latitudine?.toString() ?? '';
      _lng.text = it.longitudine?.toString() ?? '';
      _existingImageUrl = it.imageUrl;
      if (it.tappe.isNotEmpty) {
        _tappe.clear();
        for (final t in it.tappe) {
          _tappe.add(_TappaControllers.from(t));
        }
      }
    }
    _loadStoria();
    _goToInitialStop();
  }

  /// Se si arriva da "Modifica tappa", porta in vista quella tappa.
  void _goToInitialStop() {
    final i = widget.initialStopIndex;
    if (i == null || i < 0 || i >= _tappe.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _tappe[i].key.currentContext;
      if (!mounted || ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.05,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _loadStoria() async {
    final all = await ContentService.fetchStoriaContenuti();
    if (!mounted) return;
    setState(() => _storia = all);
  }

  @override
  void dispose() {
    _titolo.dispose();
    _sottotitolo.dispose();
    _descrizione.dispose();
    _durata.dispose();
    _difficolta.dispose();
    _tema.dispose();
    _lat.dispose();
    _lng.dispose();
    for (final t in _tappe) {
      t.dispose();
    }
    super.dispose();
  }

  /// Le coordinate sono facoltative, ma se ne compili una serve anche l'altra
  /// e il valore deve essere nell'intervallo valido.
  String? _coordinateError(
    String? value,
    String other,
    double limit, {
    required String missingLabel,
  }) {
    final v = (value ?? '').trim().replaceAll(',', '.');
    final o = other.trim();
    if (v.isEmpty) {
      return o.isEmpty ? null : 'Inserisci anche $missingLabel';
    }
    final n = double.tryParse(v);
    if (n == null || n < -limit || n > limit) {
      return 'Numero non valido (es. 43.3527)';
    }
    return null;
  }

  void _addTappa() => setState(() => _tappe.add(_TappaControllers()));

  void _removeTappa(int i) {
    setState(() {
      _tappe[i].dispose();
      _tappe.removeAt(i);
    });
  }

  void _moveTappa(int i, int delta) {
    final j = i + delta;
    if (j < 0 || j >= _tappe.length) return;
    setState(() {
      final t = _tappe.removeAt(i);
      _tappe.insert(j, t);
    });
  }

  /// Apre l'elenco degli eventi storici e salva la scelta sulla tappa.
  Future<void> _pickStoria(_TappaControllers t) async {
    if (_storia.isEmpty) {
      // Può essere ancora in caricamento o non esserci contenuti.
      await _loadStoria();
      if (_storia.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Non ci sono ancora contenuti nella Storia di Gubbio da collegare.'),
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    final result = await showStoriaPicker(
      context,
      all: _storia,
      selected: t.storiaIds,
    );
    if (result != null) setState(() => t.storiaIds = result);
  }

  /// Primo campo del form con un errore (in ordine di apparizione).
  FormFieldState<dynamic>? _firstErrorIn(BuildContext? root) {
    if (root == null) return null;
    FormFieldState<dynamic>? found;
    void visit(Element e) {
      if (found != null) return;
      if (e is StatefulElement) {
        final state = e.state;
        if (state is FormFieldState && state.hasError) {
          found = state;
          return;
        }
      }
      e.visitChildren(visit);
    }

    (root as Element).visitChildren(visit);
    return found;
  }

  /// Dice cosa non va e porta il campo sbagliato in vista: prima l'errore era
  /// solo un piccolo testo rosso, spesso fuori schermo, e il salvataggio
  /// sembrava non fare nulla.
  void _showFormProblem() {
    final bad = _firstErrorIn(_formKey.currentContext);
    var where = '';
    if (bad != null) {
      for (var i = 0; i < _tappe.length; i++) {
        if (_firstErrorIn(_tappe[i].key.currentContext) == bad) {
          where = 'Tappa ${i + 1}: ';
          break;
        }
      }
      Scrollable.ensureVisible(
        bad.context,
        alignment: 0.3,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            bad == null
                ? 'Controlla i campi evidenziati in rosso.'
                : '$where${bad.errorText ?? 'controlla questo campo'}',
          ),
          backgroundColor: const Color(0xFFB71C1C),
          duration: const Duration(seconds: 5),
        ),
      );
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) {
      _showFormProblem();
      return;
    }
    setState(() => _saving = true);

    try {
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        imageUrl = await ContentService.uploadImage(
          _imageBytes!,
          folder: 'itinerari',
          fileName: _imageName ?? 'foto.jpg',
        );
      }

      double? num(TextEditingController c) =>
          double.tryParse(c.text.trim().replaceAll(',', '.'));

      final tappe = _tappe
          .where((t) => t.nome.text.trim().isNotEmpty)
          .map((t) {
        final lat = num(t.lat);
        final lng = num(t.lng);
        final hasPos = lat != null && lng != null;
        return ItinerarioTappa(
          nome: t.nome.text.trim(),
          descrizione: t.descrizione.text.trim(),
          durata: t.durata.text.trim(),
          latitudine: hasPos ? lat : null,
          longitudine: hasPos ? lng : null,
          approfondimento: t.approfondimento.text.trim(),
          curiosita: t.curiosita.text.trim(),
          storiaIds: t.storiaIds,
        );
      }).toList();

      final itinerario = ItinerarioModel(
        id: widget.editItinerario?.id ?? '',
        titolo: _titolo.text.trim(),
        sottotitolo: _sottotitolo.text.trim(),
        descrizione: _descrizione.text.trim(),
        durata: _durata.text.trim(),
        difficolta: _difficolta.text.trim(),
        tema: _tema.text.trim(),
        immagineLabel: _titolo.text.trim(),
        imageUrl: imageUrl,
        tappe: tappe,
        latitudine: num(_lat),
        longitudine: num(_lng),
      );

      if (_isEditing) {
        await ContentService.updateItinerario(itinerario);
      } else {
        await ContentService.addItinerario(itinerario);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(
            '${_isEditing ? 'Itinerario aggiornato!' : 'Itinerario aggiunto!'} '
            '(${tappe.length == 1 ? '1 tappa salvata' : '${tappe.length} tappe salvate'})',
          ),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('latitudine') ||
                    e.toString().contains('longitudine')
                ? 'Mancano le colonne della posizione: esegui lo script '
                    'supabase_itinerari_posizione.sql nel SQL Editor di Supabase.'
                : 'Errore: $e',
          ),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      appBar: AppBar(
          title: Text(_isEditing ? 'Modifica Itinerario' : 'Aggiungi Itinerario')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ImagePickerField(
              initialImageUrl: _existingImageUrl,
              onChanged: (bytes, name) {
                _imageBytes = bytes;
                _imageName = name;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titolo,
              decoration: adminInputDecoration('Titolo', icon: Icons.route),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci il titolo' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sottotitolo,
              decoration:
                  adminInputDecoration('Sottotitolo', icon: Icons.subtitles_outlined),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descrizione,
              maxLines: 4,
              decoration: adminInputDecoration('Descrizione', icon: Icons.notes),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durata,
                    decoration: adminInputDecoration('Durata',
                        icon: Icons.timer_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _difficolta,
                    decoration: adminInputDecoration('Difficoltà',
                        icon: Icons.trending_up),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tema,
              decoration:
                  adminInputDecoration('Tema', icon: Icons.palette_outlined),
            ),
            const SizedBox(height: 18),
            Text(
              'Punto di partenza sulla mappa (facoltativo)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.bluNotte.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            _coordinatesRow(_lat, _lng),
            const SizedBox(height: 6),
            const Text(
              'Se lo lasci vuoto, sulla mappa l\'itinerario compare dalla prima '
              'tappa che ha le coordinate. Su Google Maps tieni premuto sul punto '
              'e copia le coordinate.',
              style: TextStyle(
                  fontSize: 12, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'TAPPE',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.bluNotte,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _addTappa,
                  icon: const Icon(Icons.add, color: AppColors.rossoGubbio),
                  label: const Text('Aggiungi tappa',
                      style: TextStyle(color: AppColors.rossoGubbio)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_tappe.length, (i) => _buildTappa(i)),
            const SizedBox(height: 24),
            AdminSaveButton(
              loading: _saving,
              onPressed: _save,
              label: _isEditing ? 'SALVA MODIFICHE' : 'SALVA',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Riga con latitudine e longitudine (i due campi si validano insieme).
  Widget _coordinatesRow(TextEditingController lat, TextEditingController lng) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: lat,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: adminInputDecoration('Latitudine'),
            validator: (v) => _coordinateError(v, lng.text, 90,
                missingLabel: 'la latitudine'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: lng,
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            decoration: adminInputDecoration('Longitudine'),
            validator: (v) => _coordinateError(v, lat.text, 180,
                missingLabel: 'la longitudine'),
          ),
        ),
      ],
    );
  }

  Widget _buildTappa(int i) {
    final t = _tappe[i];
    return Container(
      // La chiave lega lo stato (es. sezione aperta) alla tappa, anche se si riordina,
      // e permette di scorrere fino a lei in caso di errore.
      key: t.key,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E1DB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.rossoGubbio,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Tappa',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.bluNotte)),
              ),
              IconButton(
                tooltip: 'Sposta su',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_upward_rounded),
                color: AppColors.bluNotte,
                onPressed: i > 0 ? () => _moveTappa(i, -1) : null,
              ),
              IconButton(
                tooltip: 'Sposta giù',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_downward_rounded),
                color: AppColors.bluNotte,
                onPressed:
                    i < _tappe.length - 1 ? () => _moveTappa(i, 1) : null,
              ),
              if (_tappe.length > 1)
                IconButton(
                  tooltip: 'Elimina tappa',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.rossoGubbio),
                  onPressed: () => _removeTappa(i),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: t.nome,
            textCapitalization: TextCapitalization.sentences,
            decoration: adminInputDecoration('Titolo della tappa'),
            // Senza titolo la tappa non viene salvata: meglio dirlo subito.
            validator: (v) => ((v ?? '').trim().isEmpty && t.hasOtherContent)
                ? 'Inserisci il titolo della tappa'
                : null,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: t.descrizione,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: adminInputDecoration('Descrizione'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: t.durata,
            decoration: adminInputDecoration('Durata (es. 30 min)',
                icon: Icons.schedule),
          ),
          const SizedBox(height: 14),
          const Text(
            'Posizione della tappa',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
            ),
          ),
          const SizedBox(height: 6),
          _coordinatesRow(t.lat, t.lng),
          const SizedBox(height: 10),
          _buildApprofondimento(t),
        ],
      ),
    );
  }

  /// Sezione "Approfondimento": testo lungo, curiosità e collegamenti alla Storia.
  Widget _buildApprofondimento(_TappaControllers t) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.avorio,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Aperta da subito se la tappa ha già degli approfondimenti.
          initiallyExpanded: t.hasApprofondimento,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: const Icon(Icons.auto_stories_outlined,
              color: AppColors.rossoGubbio),
          title: const Text(
            'Approfondimento (pulsante "Approfondisci")',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.bluNotte,
            ),
          ),
          children: [
            TextFormField(
              controller: t.approfondimento,
              maxLines: 8,
              textCapitalization: TextCapitalization.sentences,
              decoration: adminInputDecoration(
                'Approfondimento (testo lungo)',
                icon: Icons.notes,
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: t.curiosita,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: adminInputDecoration(
                'Curiosità',
                icon: Icons.lightbulb_outline,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Eventi storici collegati',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.bluNotte,
              ),
            ),
            const SizedBox(height: 8),
            if (t.storiaIds.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in t.storiaIds)
                    InputChip(
                      label: Text(_storiaTitle(id)),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFE5E1DB)),
                      labelStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.bluNotte,
                      ),
                      deleteIconColor: AppColors.rossoGubbio,
                      onDeleted: () => setState(() => t.storiaIds.remove(id)),
                    ),
                ],
              )
            else
              const Text(
                'Nessun collegamento. Aggiungine uno per portare i visitatori '
                'direttamente a un pezzo della storia di Gubbio.',
                style: TextStyle(
                    fontSize: 12, height: 1.4, color: AppColors.textMuted),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _pickStoria(t),
              icon: const Icon(Icons.add_link),
              label: Text(t.storiaIds.isEmpty
                  ? 'Scegli evento storico'
                  : 'Modifica collegamenti'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rossoGubbio,
                side: const BorderSide(color: AppColors.rossoGubbio),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Titolo del contenuto storico collegato (se è stato eliminato lo segnala).
  String _storiaTitle(String id) {
    for (final c in _storia) {
      if (c.id == id) return c.title;
    }
    return _storia.isEmpty ? '...' : 'Contenuto non più presente';
  }
}
