import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/event_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import 'admin_widgets.dart';

/// Form per aggiungere un evento.
class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _category = TextEditingController(text: 'Eventi');
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _lat = TextEditingController(text: '43.3519');
  final _lng = TextEditingController(text: '12.5773');

  DateTime _date = DateTime.now();
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 12, minute: 0);

  Uint8List? _imageBytes;
  String? _imageName;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _category.dispose();
    _phone.dispose();
    _website.dispose();
    _lat.dispose();
    _lng.dispose();
    super.dispose();
  }

  DateTime _combine(TimeOfDay t) =>
      DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? imageUrl;
      if (_imageBytes != null) {
        imageUrl = await ContentService.uploadImage(
          _imageBytes!,
          folder: 'eventi',
          fileName: _imageName ?? 'foto.jpg',
        );
      }

      final start = _combine(_start);
      final end = _combine(_end);

      await ContentService.addEvent(EventModel(
        id: '',
        time: _fmtTime(_start),
        title: _title.text.trim(),
        description: _description.text.trim(),
        location: _location.text.trim(),
        coordinates: LatLng(
          double.tryParse(_lat.text.replaceAll(',', '.')) ?? 43.3519,
          double.tryParse(_lng.text.replaceAll(',', '.')) ?? 12.5773,
        ),
        startTime: start,
        endTime: end,
        imageUrl: imageUrl,
        category: _category.text.trim().isEmpty ? 'Eventi' : _category.text.trim(),
        phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        website: _website.text.trim().isEmpty ? null : _website.text.trim(),
      ));

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evento aggiunto!'),
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
      appBar: AppBar(title: const Text('Aggiungi Evento')),
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
              controller: _title,
              decoration: adminInputDecoration('Titolo', icon: Icons.event),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci il titolo' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              maxLines: 4,
              decoration:
                  adminInputDecoration('Descrizione', icon: Icons.notes),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _location,
              decoration:
                  adminInputDecoration('Luogo', icon: Icons.place_outlined),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _category,
              decoration:
                  adminInputDecoration('Categoria', icon: Icons.category_outlined),
            ),
            const SizedBox(height: 14),
            _buildDateTimeRow(),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration:
                  adminInputDecoration('Telefono', icon: Icons.phone_outlined),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _website,
              keyboardType: TextInputType.url,
              decoration: adminInputDecoration('Sito web',
                  icon: Icons.language_outlined),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _lat,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: adminInputDecoration('Latitudine'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lng,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: adminInputDecoration('Longitudine'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AdminSaveButton(loading: _saving, onPressed: _save),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeRow() {
    return Column(
      children: [
        _pickerTile(
          icon: Icons.calendar_today_outlined,
          label: 'Data',
          value:
              '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
          onTap: _pickDate,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _pickerTile(
                icon: Icons.schedule,
                label: 'Inizio',
                value: _fmtTime(_start),
                onTap: () => _pickTime(true),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _pickerTile(
                icon: Icons.schedule,
                label: 'Fine',
                value: _fmtTime(_end),
                onTap: () => _pickTime(false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pickerTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E1DB)),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.rossoGubbio, size: 20),
            const SizedBox(width: 10),
            Text('$label: ',
                style: const TextStyle(color: AppColors.textMuted)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.bluNotte)),
          ],
        ),
      ),
    );
  }
}
