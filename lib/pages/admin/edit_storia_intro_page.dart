import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../models/storia_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import 'admin_widgets.dart';

/// Form per modificare titolo, sottotitolo, testo introduttivo e foto di
/// copertina della pagina "Storia di Gubbio".
class EditStoriaIntroPage extends StatefulWidget {
  final StoriaIntro intro;

  const EditStoriaIntroPage({super.key, required this.intro});

  @override
  State<EditStoriaIntroPage> createState() => _EditStoriaIntroPageState();
}

class _EditStoriaIntroPageState extends State<EditStoriaIntroPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titolo;
  late final TextEditingController _sottotitolo;
  late final TextEditingController _testo;

  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titolo = TextEditingController(text: widget.intro.titolo);
    _sottotitolo = TextEditingController(text: widget.intro.sottotitolo);
    _testo = TextEditingController(text: widget.intro.testo);
  }

  @override
  void dispose() {
    _titolo.dispose();
    _sottotitolo.dispose();
    _testo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? imageUrl = widget.intro.imageUrl;
      if (_imageBytes != null) {
        imageUrl = await ContentService.uploadImage(
          _imageBytes!,
          folder: 'storia',
          fileName: _imageName ?? 'copertina.jpg',
        );
      }

      await ContentService.saveStoriaIntro(
        titolo: _titolo.text.trim(),
        sottotitolo: _sottotitolo.text.trim(),
        testo: _testo.text.trim(),
        imageUrl: imageUrl,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagina aggiornata!'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      // Se la tabella non esiste ancora, spiega cosa fare invece del solo errore tecnico.
      final missingTable = e.toString().contains('storia_pagina');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(missingTable
              ? 'Manca la tabella "storia_pagina": esegui lo script '
                  'supabase_storia_pagina_setup.sql nel SQL Editor di Supabase.'
              : 'Errore: $e'),
          backgroundColor: const Color(0xFFB71C1C),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.avorio,
      appBar: AppBar(title: const Text('Modifica introduzione')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Foto di copertina (opzionale)',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.bluNotte.withOpacity(0.7))),
            const SizedBox(height: 8),
            ImagePickerField(
              initialImageUrl: widget.intro.imageUrl,
              onChanged: (bytes, name) {
                _imageBytes = bytes;
                _imageName = name;
              },
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titolo,
              textCapitalization: TextCapitalization.sentences,
              decoration: adminInputDecoration('Titolo', icon: Icons.title),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci il titolo' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _sottotitolo,
              textCapitalization: TextCapitalization.sentences,
              decoration: adminInputDecoration('Sottotitolo',
                  icon: Icons.subtitles_outlined),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _testo,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
              decoration: adminInputDecoration('Testo introduttivo',
                  icon: Icons.notes),
            ),
            const SizedBox(height: 24),
            AdminSaveButton(
              loading: _saving,
              onPressed: _save,
              label: 'SALVA MODIFICHE',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
