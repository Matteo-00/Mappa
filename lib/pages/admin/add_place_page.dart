import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/bar_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import 'admin_widgets.dart';

/// Form per aggiungere o modificare un ristorante o un bar (stessi campi).
class AddPlacePage extends StatefulWidget {
  /// Se true gestisce un bar, altrimenti un ristorante.
  final bool isBar;

  /// Ristorante esistente da modificare (null = nuovo inserimento).
  final RestaurantModel? editRestaurant;

  /// Bar esistente da modificare (null = nuovo inserimento).
  final BarModel? editBar;

  const AddPlacePage({
    super.key,
    required this.isBar,
    this.editRestaurant,
    this.editBar,
  });

  @override
  State<AddPlacePage> createState() => _AddPlacePageState();
}

class _AddPlacePageState extends State<AddPlacePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _tags = TextEditingController();
  final _lat = TextEditingController(text: '43.3519');
  final _lng = TextEditingController(text: '12.5773');

  Uint8List? _imageBytes;
  String? _imageName;
  String? _existingImageUrl;
  bool _saving = false;
  int _rating = 0;

  bool get _isEditing => widget.editRestaurant != null || widget.editBar != null;

  String get _titleLabel {
    if (_isEditing) return widget.isBar ? 'Modifica Bar' : 'Modifica Ristorante';
    return widget.isBar ? 'Aggiungi Bar' : 'Aggiungi Ristorante';
  }

  @override
  void initState() {
    super.initState();
    if (widget.editRestaurant != null) {
      final r = widget.editRestaurant!;
      _name.text = r.name;
      _description.text = r.description;
      _address.text = r.address;
      _phone.text = r.phoneNumber ?? '';
      _website.text = r.website ?? '';
      _tags.text = r.cuisineTypes.join(', ');
      _lat.text = r.coordinates.latitude.toString();
      _lng.text = r.coordinates.longitude.toString();
      _existingImageUrl = r.imageUrl;
      _rating = r.rating?.round() ?? 0;
    } else if (widget.editBar != null) {
      final b = widget.editBar!;
      _name.text = b.name;
      _description.text = b.description;
      _address.text = b.address;
      _phone.text = b.phoneNumber ?? '';
      _website.text = b.website ?? '';
      _tags.text = b.cuisineTypes.join(', ');
      _lat.text = b.coordinates.latitude.toString();
      _lng.text = b.coordinates.longitude.toString();
      _existingImageUrl = b.imageUrl;
      _rating = b.rating?.round() ?? 0;
    }
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
    super.dispose();
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
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        imageUrl = await ContentService.uploadImage(
          _imageBytes!,
          folder: widget.isBar ? 'bar' : 'ristoranti',
          fileName: _imageName ?? 'foto.jpg',
        );
      }

      final coordinates = LatLng(
        double.tryParse(_lat.text.replaceAll(',', '.')) ?? 43.3519,
        double.tryParse(_lng.text.replaceAll(',', '.')) ?? 12.5773,
      );

      if (widget.isBar) {
        final bar = BarModel(
          id: widget.editBar?.id ?? '',
          name: _name.text.trim(),
          description: _description.text.trim(),
          address: _address.text.trim(),
          coordinates: coordinates,
          imageUrl: imageUrl,
          phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          website: _website.text.trim().isEmpty ? null : _website.text.trim(),
          cuisineTypes: _parseTags(),
          rating: _rating > 0 ? _rating.toDouble() : null,
        );
        if (_isEditing) {
          await ContentService.updateBar(bar);
        } else {
          await ContentService.addBar(bar);
        }
      } else {
        final restaurant = RestaurantModel(
          id: widget.editRestaurant?.id ?? '',
          name: _name.text.trim(),
          description: _description.text.trim(),
          address: _address.text.trim(),
          coordinates: coordinates,
          imageUrl: imageUrl,
          phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          website: _website.text.trim().isEmpty ? null : _website.text.trim(),
          cuisineTypes: _parseTags(),
          rating: _rating > 0 ? _rating.toDouble() : null,
        );
        if (_isEditing) {
          await ContentService.updateRestaurant(restaurant);
        } else {
          await ContentService.addRestaurant(restaurant);
        }
      }

      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? (widget.isBar ? 'Bar aggiornato!' : 'Ristorante aggiornato!')
              : (widget.isBar ? 'Bar aggiunto!' : 'Ristorante aggiunto!')),
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
      appBar: AppBar(title: Text(_titleLabel)),
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
              decoration: adminInputDecoration('Nome', icon: Icons.storefront),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Inserisci il nome' : null,
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
              controller: _address,
              decoration:
                  adminInputDecoration('Indirizzo', icon: Icons.place_outlined),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tags,
              decoration: adminInputDecoration(
                'Tag (separati da virgola, es. Umbra, Italiana, Medievale)',
                icon: Icons.label_outline,
              ),
            ),
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
            Text(
              'Valutazione (media TripAdvisor / Google Maps)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.bluNotte.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() {
                    // Tocca di nuovo la stessa stella per azzerare la valutazione.
                    _rating = _rating == starValue ? 0 : starValue;
                  }),
                  icon: Icon(
                    starValue <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFF2A93B),
                    size: 32,
                  ),
                );
              }),
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
