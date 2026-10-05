import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/storia_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import 'admin_widgets.dart';

const List<String> _storiaCategorie = [
  'chiesa',
  'palazzo',
  'piazza',
  'monumento',
  'natura',
];

/// Form per aggiungere o modificare un contenuto storico (monumento, chiesa,
/// palazzo...) della sezione "Storia di Gubbio". Pensato per essere usato
/// solo dagli ADMIN: niente modifiche a codice o file JSON, tutto da qui.
class AddStoriaContentPage extends StatefulWidget {
  final StoriaContenuto? editContenuto;

  const AddStoriaContentPage({super.key, this.editContenuto});

  @override
  State<AddStoriaContentPage> createState() => _AddStoriaContentPageState();
}

class _AddStoriaContentPageState extends State<AddStoriaContentPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _slug = TextEditingController();
  final _displayDate = TextEditingController();
  final _startYear = TextEditingController();
  final _endYear = TextEditingController();
  final _shortDescription = TextEditingController();
  final _fullDescription = TextEditingController();
  final _localStory = TextEditingController();
  final _curiosity = TextEditingController();
  final _tags = TextEditingController();
  final _sortOrder = TextEditingController(text: '0');
  final _lat = TextEditingController();
  final _lng = TextEditingController();

  List<StoriaEpoca> _epoche = [];
  String? _selectedEraId;
  String _selectedCategory = _storiaCategorie.first;
  bool _isPublished = true;
  bool _loadingEpoche = true;
  bool _saving = false;

  Uint8List? _coverBytes;
  String? _coverFileName;
  String? _existingCoverUrl;
  List<GalleryImageItem> _galleryItems = [];

  bool get _isEditing => widget.editContenuto != null;

  @override
  void initState() {
    super.initState();
    final c = widget.editContenuto;
    if (c != null) {
      _title.text = c.title;
      _slug.text = c.slug;
      _displayDate.text = c.displayDate;
      _startYear.text = c.startYear?.toString() ?? '';
      _endYear.text = c.endYear?.toString() ?? '';
      _shortDescription.text = c.shortDescription;
      _fullDescription.text = c.fullDescription;
      _localStory.text = c.localStory ?? '';
      _curiosity.text = c.curiosity ?? '';
      _tags.text = c.tags.join(', ');
      _sortOrder.text = c.sortOrder.toString();
      _lat.text = c.latitude?.toString() ?? '';
      _lng.text = c.longitude?.toString() ?? '';
      _selectedEraId = c.eraId;
      _selectedCategory =
          _storiaCategorie.contains(c.category) ? c.category : _storiaCategorie.first;
      _isPublished = c.isPublished;
      _existingCoverUrl = c.coverImage;
      _galleryItems = c.gallery.map((u) => GalleryImageItem(url: u)).toList();
    }
    _loadEpoche();
  }

  Future<void> _loadEpoche() async {
    final epoche = await ContentService.fetchStoriaEpoche();
    if (!mounted) return;
    setState(() {
      _epoche = epoche;
      _loadingEpoche = false;
      if (_selectedEraId == null && epoche.isNotEmpty) {
        _selectedEraId = epoche.first.id;
      }
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _slug.dispose();
    _displayDate.dispose();
    _startYear.dispose();
    _endYear.dispose();
    _shortDescription.dispose();
    _fullDescription.dispose();
    _localStory.dispose();
    _curiosity.dispose();
    _tags.dispose();
    _sortOrder.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  String _slugify(String text) {
    final lower = text.toLowerCase().trim();
    final withDashes = lower
        .replaceAll(RegExp(r"['’]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return withDashes;
  }

  List<String> _parseTags() => _tags.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? coverUrl = _existingCoverUrl;
      if (_coverBytes != null) {
        coverUrl = await ContentService.uploadImage(
          _coverBytes!,
          folder: 'storia',
          fileName: _coverFileName ?? 'foto.jpg',
        );
      }

      final galleryUrls = <String>[];
      for (final item in _galleryItems) {
        if (item.url != null) {
          galleryUrls.add(item.url!);
        } else if (item.bytes != null) {
          final url = await ContentService.uploadImage(
            item.bytes!,
            folder: 'storia',
            fileName: item.fileName ?? 'foto.jpg',
          );
          galleryUrls.add(url);
        }
      }

      final slug = _slug.text.trim().isEmpty
          ? _slugify(_title.text)
          : _slugify(_slug.text);

      final contenuto = StoriaContenuto(
        id: widget.editContenuto?.id ?? '',
        eraId: _selectedEraId,
        title: _title.text.trim(),
        slug: slug,
        category: _selectedCategory,
        displayDate: _displayDate.text.trim(),
        startYear: int.tryParse(_startYear.text.trim()),
        endYear: int.tryParse(_endYear.text.trim()),
        shortDescription: _shortDescription.text.trim(),
        fullDescription: _fullDescription.text.trim(),
        localStory: _localStory.text.trim().isEmpty ? null : _localStory.text.trim(),
        curiosity: _curiosity.text.trim().isEmpty ? null : _curiosity.text.trim(),
        tags: _parseTags(),
        coverImage: coverUrl,
        gallery: galleryUrls,
        sortOrder: int.tryParse(_sortOrder.text.trim()) ?? 0,
        isPublished: _isPublished,
        latitude: double.tryParse(_lat.text.trim().replaceAll(',', '.')),
        longitude: double.tryParse(_lng.text.trim().replaceAll(',', '.')),
      );

      if (_isEditing) {
        await ContentService.updateStoriaContenuto(contenuto);
      } else {
        await ContentService.addStoriaContenuto(contenuto);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Contenuto aggiornato!' : 'Contenuto aggiunto!'),
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
        title: Text(_isEditing ? 'Modifica contenuto storico' : 'Nuovo contenuto storico'),
      ),
      body: _loadingEpoche
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text('Foto principale',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.bluNotte.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  ImagePickerField(
                    initialImageUrl: _existingCoverUrl,
                    onChanged: (bytes, name) {
                      _coverBytes = bytes;
                      _coverFileName = name;
                    },
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _title,
                    decoration: adminInputDecoration('Titolo', icon: Icons.title),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Inserisci il titolo' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _slug,
                    decoration: adminInputDecoration(
                      'Slug (vuoto = generato dal titolo)',
                      icon: Icons.link,
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedEraId,
                    decoration: adminInputDecoration('Epoca', icon: Icons.schedule),
                    items: _epoche
                        .map((e) => DropdownMenuItem(value: e.id, child: Text(e.nome)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedEraId = v),
                    validator: (v) => v == null ? 'Seleziona un\'epoca' : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: adminInputDecoration('Categoria', icon: Icons.category_outlined),
                    items: _storiaCategorie
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c[0].toUpperCase() + c.substring(1)),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v ?? _selectedCategory),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _displayDate,
                    decoration: adminInputDecoration(
                      'Data da mostrare (es. "1332 – 1340")',
                      icon: Icons.calendar_today_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _startYear,
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          decoration: adminInputDecoration('Anno inizio (neg. = a.C.)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _endYear,
                          keyboardType: const TextInputType.numberWithOptions(signed: true),
                          decoration: adminInputDecoration('Anno fine'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _shortDescription,
                    maxLines: 2,
                    decoration: adminInputDecoration(
                      'Descrizione breve (per la card)',
                      icon: Icons.short_text,
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Inserisci una breve descrizione' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _fullDescription,
                    maxLines: 6,
                    decoration: adminInputDecoration(
                      'Storia (sezione "Storia" nel dettaglio)',
                      icon: Icons.history_edu_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _localStory,
                    maxLines: 8,
                    decoration: adminInputDecoration(
                      'Racconto da local (opzionale)',
                      icon: Icons.record_voice_over_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _curiosity,
                    maxLines: 3,
                    decoration: adminInputDecoration(
                      'Curiosità (opzionale)',
                      icon: Icons.lightbulb_outline,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _tags,
                    decoration: adminInputDecoration(
                      'Tag per la ricerca (separati da virgola)',
                      icon: Icons.label_outline,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text('Galleria foto (opzionale)',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.bluNotte.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  GalleryPickerField(
                    initialUrls: _galleryItems
                        .where((i) => i.url != null)
                        .map((i) => i.url!)
                        .toList(),
                    onChanged: (items) => _galleryItems = items,
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: _sortOrder,
                    keyboardType: TextInputType.number,
                    decoration: adminInputDecoration(
                      'Ordine nella timeline (numero, più basso = prima)',
                      icon: Icons.sort,
                    ),
                  ),                  const SizedBox(height: 18),
                  Text('Posizione (opzionale, per le indicazioni stradali)',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.bluNotte.withOpacity(0.7))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _lat,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: adminInputDecoration('Latitudine'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _lng,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: adminInputDecoration('Longitudine'),
                        ),
                      ),
                    ],
                  ),                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Pubblicato (visibile agli utenti)'),
                    value: _isPublished,
                    activeColor: AppColors.rossoGubbio,
                    onChanged: (v) => setState(() => _isPublished = v),
                  ),
                  const SizedBox(height: 20),
                  AdminSaveButton(loading: _saving, onPressed: _save),
                ],
              ),
            ),
    );
  }
}
