import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/itinerario_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import 'admin_widgets.dart';

/// Form per aggiungere un itinerario con le sue tappe.
class AddItinerarioPage extends StatefulWidget {
  const AddItinerarioPage({super.key});

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
  bool _saving = false;

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
      String? imageUrl;
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

      await ContentService.addItinerario(ItinerarioModel(
        id: '',
        titolo: _titolo.text.trim(),
        sottotitolo: _sottotitolo.text.trim(),
        descrizione: _descrizione.text.trim(),
        durata: _durata.text.trim(),
        difficolta: _difficolta.text.trim(),
        tema: _tema.text.trim(),
        immagineLabel: _titolo.text.trim(),
        imageUrl: imageUrl,
        tappe: tappe,
      ));

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Itinerario aggiunto!'),
          backgroundColor: Color(0xFF4CAF50),
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
      appBar: AppBar(title: const Text('Aggiungi Itinerario')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ImagePickerField(
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
            AdminSaveButton(loading: _saving, onPressed: _save),
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
