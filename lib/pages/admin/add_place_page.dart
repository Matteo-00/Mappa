import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/bar_model.dart';
import '../../models/hotel_model.dart';
import '../../models/restaurant_model.dart';
import '../../services/content_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/rating_icons.dart';
import 'admin_widgets.dart';

/// Form per aggiungere o modificare un ristorante, un bar o un hotel
/// (stessi campi).
class AddPlacePage extends StatefulWidget {
  /// Se true gestisce un bar.
  final bool isBar;

  /// Se true gestisce un hotel (se né [isBar] né [isHotel]: ristorante).
  final bool isHotel;

  /// Ristorante esistente da modificare (null = nuovo inserimento).
  final RestaurantModel? editRestaurant;

  /// Bar esistente da modificare (null = nuovo inserimento).
  final BarModel? editBar;

  /// Hotel esistente da modificare (null = nuovo inserimento).
  final HotelModel? editHotel;

  const AddPlacePage({
    super.key,
    required this.isBar,
    this.isHotel = false,
    this.editRestaurant,
    this.editBar,
    this.editHotel,
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
  /// Valutazione da 0 a 5 scritta a mano, decimali ammessi (es. 4.3).
  final _rating = TextEditingController();

  bool get _isEditing =>
      widget.editRestaurant != null ||
      widget.editBar != null ||
      widget.editHotel != null;

  /// Nome del tipo di luogo ("Bar", "Hotel", "Ristorante").
  String get _kindLabel => widget.isHotel
      ? 'Hotel'
      : (widget.isBar ? 'Bar' : 'Ristorante');

  String get _titleLabel =>
      _isEditing ? 'Modifica $_kindLabel' : 'Aggiungi $_kindLabel';

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
      _rating.text = _formatRating(r.rating);
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
      _rating.text = _formatRating(b.rating);
    } else if (widget.editHotel != null) {
      final h = widget.editHotel!;
      _name.text = h.name;
      _description.text = h.description;
      _address.text = h.address;
      _phone.text = h.phoneNumber ?? '';
      _website.text = h.website ?? '';
      _tags.text = h.cuisineTypes.join(', ');
      _lat.text = h.coordinates.latitude.toString();
      _lng.text = h.coordinates.longitude.toString();
      _existingImageUrl = h.imageUrl;
      _rating.text = _formatRating(h.rating);
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
    _rating.dispose();
    super.dispose();
  }

  List<String> _parseTags() => _tags.text
      .split(',')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  /// "4" per 4.0, "4.3" per 4.3, vuoto se manca.
  static String _formatRating(double? rating) {
    if (rating == null) return '';
    return rating == rating.roundToDouble()
        ? rating.toStringAsFixed(0)
        : rating.toStringAsFixed(1);
  }

  /// Valutazione scritta nel campo (accetta anche la virgola), arrotondata a
  /// un decimale. Null se il campo è vuoto o non valido.
  double? _parseRating() {
    final value = double.tryParse(_rating.text.trim().replaceAll(',', '.'));
    if (value == null || value <= 0 || value > 5) return null;
    return (value * 10).round() / 10;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      String? imageUrl = _existingImageUrl;
      if (_imageBytes != null) {
        imageUrl = await ContentService.uploadImage(
          _imageBytes!,
          folder: widget.isHotel ? 'hotel' : (widget.isBar ? 'bar' : 'ristoranti'),
          fileName: _imageName ?? 'foto.jpg',
        );
      }

      final coordinates = LatLng(
        double.tryParse(_lat.text.replaceAll(',', '.')) ?? 43.3519,
        double.tryParse(_lng.text.replaceAll(',', '.')) ?? 12.5773,
      );

      if (widget.isHotel) {
        final hotel = HotelModel(
          id: widget.editHotel?.id ?? '',
          name: _name.text.trim(),
          description: _description.text.trim(),
          address: _address.text.trim(),
          coordinates: coordinates,
          imageUrl: imageUrl,
          phoneNumber: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
          website: _website.text.trim().isEmpty ? null : _website.text.trim(),
          cuisineTypes: _parseTags(),
          rating: _parseRating(),
        );
        if (_isEditing) {
          await ContentService.updateHotel(hotel);
        } else {
          await ContentService.addHotel(hotel);
        }
      } else if (widget.isBar) {
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
          rating: _parseRating(),
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
          rating: _parseRating(),
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
              ? (widget.isHotel
                  ? 'Hotel aggiornato!'
                  : (widget.isBar ? 'Bar aggiornato!' : 'Ristorante aggiornato!'))
              : (widget.isHotel
                  ? 'Hotel aggiunto!'
                  : (widget.isBar ? 'Bar aggiunto!' : 'Ristorante aggiunto!'))),
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
                widget.isHotel
                    ? 'Tag (separati da virgola, es. 4 stelle, Spa, Parcheggio)'
                    : 'Tag (separati da virgola, es. Umbra, Italiana, Medievale)',
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
            // Valutazione in "cresce" su 5, con i decimali (es. 4.5 = quattro
            // cresce e mezza).
            Text(
              'Valutazione in cresce (media TripAdvisor / Google Maps)',
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
                      return _parseRating() == null
                          ? 'Da 0.1 a 5'
                          : null;
                    },
                  ),
                ),
                const SizedBox(width: 14),
                // Anteprima di come lo vedranno gli utenti.
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _rating,
                      builder: (context, value, child) {
                        final value = _parseRating();
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RatingIcons(rating: value ?? 0, size: 24),
                        );
                      },
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
