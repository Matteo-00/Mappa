import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/itinerario_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import 'admin_widgets.dart';

/// Form per aggiungere o modificare un itinerario con le sue tappe.
class AddItinerarioPage extends StatefulWidget {
  /// Itinerario esistente da modificare (null = nuovo inserimento).
  final ItinerarioModel? editItinerario;

  const AddItinerarioPage({super.key, this.editItinerario});

  @override
  State<AddItinerarioPage> createState() => _AddItinerarioPageState();
}

class _TappaControllers {
  final nome = TextEditingController();
  final descrizione = TextEditingController();
  final durata = TextEditingController();

  void dispose() {
    nome.dispose();
    descrizione.dispose();
    durata.dispose();
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

  final List<_TappaControllers> _tappe = [_TappaControllers()];

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
      _existingImageUrl = it.imageUrl;
      if (it.tappe.isNotEmpty) {
        _tappe.clear();
        for (final t in it.tappe) {
          final c = _TappaControllers();
          c.nome.text = t.nome;
          c.descrizione.text = t.descrizione;
          c.durata.text = t.durata;
          _tappe.add(c);
        }
      }
    }
  }

  @override
  void dispose() {
    _titolo.dispose();
    _sottotitolo.dispose();
    _descrizione.dispose();
    _durata.dispose();
    _difficolta.dispose();
    _tema.dispose();
    for (final t in _tappe) {
      t.dispose();
    }
    super.dispose();
  }

  void _addTappa() => setState(() => _tappe.add(_TappaControllers()));

  void _removeTappa(int i) {
    setState(() {
      _tappe[i].dispose();
      _tappe.removeAt(i);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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

      final tappe = _tappe
          .where((t) => t.nome.text.trim().isNotEmpty)
          .map((t) => ItinerarioTappa(
                nome: t.nome.text.trim(),
                descrizione: t.descrizione.text.trim(),
                durata: t.durata.text.trim(),
              ))
          .toList();

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
              Text(_isEditing ? 'Itinerario aggiornato!' : 'Itinerario aggiunto!'),
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
      appBar: AppBar(title: Text(_isEditing ? 'Modifica Itinerario' : 'Aggiungi Itinerario')),
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

  Widget _buildTappa(int i) {
    final t = _tappe[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E1DB)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text('Tappa ${i + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppColors.bluNotte)),
              const Spacer(),
              if (_tappe.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: AppColors.rossoGubbio),
                  onPressed: () => _removeTappa(i),
                ),
            ],
          ),
          TextFormField(
            controller: t.nome,
            decoration: adminInputDecoration('Nome tappa'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: t.descrizione,
            maxLines: 2,
            decoration: adminInputDecoration('Descrizione'),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: t.durata,
            decoration: adminInputDecoration('Durata (es. 30 min)'),
          ),
        ],
      ),
    );
  }
}
