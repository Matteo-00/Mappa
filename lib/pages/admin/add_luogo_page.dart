import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/luogo_model.dart';
import '../../models/storia_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rating_icons.dart';
import 'admin_widgets.dart';
import 'storia_picker_sheet.dart';

/// Form per aggiungere o modificare una chiesa, un museo, un negozio o un
/// parcheggio. Titolo, descrizione, indirizzo, posizione e foto per tutti;
/// in più telefono / sito / tag (non per i parcheggi), le stelle (solo
/// negozi) e i collegamenti a "Storia di Gubbio" (chiese e musei).
class AddLuogoPage extends StatefulWidget {
  final LuogoTipo tipo;

  /// Luogo esistente da modificare (null = nuovo inserimento).
  final LuogoModel? editLuogo;

  const AddLuogoPage({super.key, required this.tipo, this.editLuogo});

  @override
  State<AddLuogoPage> createState() => _AddLuogoPageState();
}

class _AddLuogoPageState extends State<AddLuogoPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _tags = TextEditingController();
  final _lat = TextEditingController(text: '43.3519');
  final _lng = TextEditingController(text: '12.5773');
  final _rating = TextEditingController();

  Uint8List? _imageBytes;
  String? _imageName;
  String? _existingImageUrl;
  bool _saving = false;

  List<String> _storiaIds = [];
  List<StoriaContenuto> _storia = [];

  LuogoTipo get _tipo => widget.tipo;
  bool get _isEditing => widget.editLuogo != null;

  /// Nome del tipo al singolare, per titoli e messaggi.
  String get _kindLabel {
    switch (_tipo) {
      case LuogoTipo.chiesa:
        return 'Chiesa';
      case LuogoTipo.museo:
        return 'Museo';
      case LuogoTipo.negozio:
        return 'Negozio';
      case LuogoTipo.parcheggio:
        return 'Parcheggio';
    }
  }

  /// "Chiesa aggiunta!" / "Museo aggiunto!"...
  String get _doneMessage {
    final fem = _tipo == LuogoTipo.chiesa;
    final suffix = fem ? 'a' : 'o';
    return _isEditing
        ? '$_kindLabel aggiornat$suffix!'
        : '$_kindLabel aggiunt$suffix!';
  }

  @override
  void initState() {
    super.initState();
    final l = widget.editLuogo;
    if (l != null) {
      _name.text = l.name;
      _description.text = l.description;
      _address.text = l.address;
      _phone.text = l.phoneNumber ?? '';
      _website.text = l.website ?? '';
      _tags.text = l.tags.join(', ');
      _lat.text = l.coordinates.latitude.toString();
      _lng.text = l.coordinates.longitude.toString();
      _existingImageUrl = l.imageUrl;
      _rating.text = _formatRating(l.rating);
      _storiaIds = [...l.storiaIds];
    }
    if (_tipo.hasStoria) _loadStoria();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _phone.dispose();
    _website.dispose();
    _tags.dispose();
    _lat.dispose();
    _lng.dispose();
    _rating.dispose();
    super.dispose();
  }

  Future<void> _loadStoria() async {
    final all = await ContentService.fetchStoriaContenuti();
    if (!mounted) return;
    setState(() => _storia = all);
  }

  List<String> _parseTags() => _tags.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  static String _formatRating(double? rating) {
    if (rating == null) return '';
    return rating == rating.roundToDouble()
        ? rating.toStringAsFixed(0)
        : rating.toStringAsFixed(1);
  }

  double? _parseRating() {
    final value = double.tryParse(_rating.text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0 || value > 5) return null;
    return (value * 10).round() / 10;
  }

  /// Le coordinate servono per mostrare il luogo sulla mappa e calcolare la
  /// distanza: devono essere due numeri validi.
  String? _coordinateError(String? value, double limit) {
    final n = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (n == null || n < -limit || n > limit) {
      return 'Numero non valido (es. 43.3527)';
    }
    return null;
  }

  Future<void> _pickStoria() async {
    if (_storia.isEmpty) {
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
      selected: _storiaIds,
    );
    if (result != null) setState(() => _storiaIds = result);
  }

  /// Titolo del contenuto storico collegato (se è stato eliminato lo segnala).
  String _storiaTitle(String id) {
    for (final c in _storia) {
      if (c.id == id) return c.title;
    }
    return _storia.isEmpty ? '…' : '(contenuto eliminato)';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Controlla i campi in rosso e riprova.'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }
    setState(() => _saving = true);

    try {
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        imageUrl = await ContentService.uploadImage(
          _imageBytes!,
          folder: 'luoghi/${_tipo.db}',
          fileName: _imageName ?? 'foto.jpg',
        );
      }

      final contacts = _tipo.hasContacts;
      final luogo = LuogoModel(
        id: widget.editLuogo?.id ?? '',
        tipo: _tipo,
        name: _name.text.trim(),
        description: _description.text.trim(),
        address: _address.text.trim(),
        coordinates: LatLng(
          double.parse(_lat.text.trim().replaceAll(',', '.')),
          double.parse(_lng.text.trim().replaceAll(',', '.')),
        ),
        imageUrl: imageUrl,
        phoneNumber: contacts && _phone.text.trim().isNotEmpty
            ? _phone.text.trim()
            : null,
        website: contacts && _website.text.trim().isNotEmpty
            ? _website.text.trim()
            : null,
        tags: contacts ? _parseTags() : const [],
        rating: _tipo.hasRating ? _parseRating() : null,
        storiaIds: _tipo.hasStoria ? _storiaIds : const [],
      );

      if (_isEditing) {
        await ContentService.updateLuogo(luogo);
      } else {
        await ContentService.addLuogo(luogo);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_doneMessage),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
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
    return Scaffold(
      backgroundColor: AppColors.avorio,
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifica $_kindLabel' : 'Aggiungi $_kindLabel'),
      ),
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
              controller: _name,
              decoration: adminInputDecoration('Titolo', icon: _tipo.icon),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci il titolo' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 5,
              decoration:
                  adminInputDecoration('Descrizione', icon: Icons.notes),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              decoration:
                  adminInputDecoration('Indirizzo', icon: Icons.place_outlined),
            ),
            if (_tipo.hasContacts) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _tags,
                decoration: adminInputDecoration(
                  'Tag (separati da virgola)',
                  icon: Icons.label_outline,
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: adminInputDecoration('Telefono',
                    icon: Icons.phone_outlined),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _website,
                keyboardType: TextInputType.url,
                decoration: adminInputDecoration('Sito web',
                    icon: Icons.language_outlined),
              ),
            ],
            if (_tipo.hasRating) ...[
              const SizedBox(height: 14),
              Text(
                'Valutazione in stelle',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.bluNotte.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 130,
                    child: TextFormField(
                      controller: _rating,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: adminInputDecoration('Voto su 5')
                          .copyWith(hintText: 'es. 4.3'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        return _parseRating() == null ? 'Da 0.1 a 5' : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _rating,
                        builder: (context, _, __) => FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RatingIcons(
                            rating: _parseRating() ?? 0,
                            size: 24,
                            kind: RatingKind.stelle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Scrivi un voto da 0 a 5, anche con i decimali. Lascia vuoto per nessuna valutazione.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.bluNotte.withOpacity(0.55),
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Posizione (per "Mostra sulla mappa" e la distanza)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.bluNotte.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: adminInputDecoration('Latitudine'),
                    validator: (v) => _coordinateError(v, 90),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: adminInputDecoration('Longitudine'),
                    validator: (v) => _coordinateError(v, 180),
                  ),
                ),
              ],
            ),
            if (_tipo.hasStoria) ...[
              const SizedBox(height: 20),
              const Text(
                'Momento storico (collegamenti a Storia di Gubbio)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                ),
              ),
              const SizedBox(height: 8),
              if (_storiaIds.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in _storiaIds)
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
                        onDeleted: () =>
                            setState(() => _storiaIds.remove(id)),
                      ),
                  ],
                )
              else
                const Text(
                  'Nessun collegamento (facoltativo). Aggiungine uno per portare '
                  'i visitatori direttamente a un pezzo della storia di Gubbio.',
                  style: TextStyle(
                      fontSize: 12, height: 1.4, color: AppColors.textMuted),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickStoria,
                icon: const Icon(Icons.add_link),
                label: Text(_storiaIds.isEmpty
                    ? 'Scegli momento storico'
                    : 'Modifica collegamenti'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rossoGubbio,
                  side: const BorderSide(color: AppColors.rossoGubbio),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
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
}
