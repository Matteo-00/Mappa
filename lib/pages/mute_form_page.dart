import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/muta_model.dart';
import '../data/mute_data.dart';

/// Pagina per creare o modificare una muta
class MuteFormPage extends StatefulWidget {
  final MutaModel? muta;

  const MuteFormPage({
    super.key,
    this.muta,
  });

  @override
  State<MuteFormPage> createState() => _MuteFormPageState();
}

class _MuteFormPageState extends State<MuteFormPage> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nomeController;
  late TextEditingController _zoneController;
  late TextEditingController _capoMutaController;
  late TextEditingController _capocorsaController;
  
  // Controllers per esterni sinistra
  late List<TextEditingController> _esterniSinistraControllers;
  
  // Controllers per esterni destra
  late List<TextEditingController> _esterniDestraControllers;
  
  // Controllers per interni posteriori
  late List<TextEditingController> _interniPosterioriControllers;
  
  late LatLng _selectedCoordinates;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.muta != null;
    
    // Inizializza i controllers
    _nomeController = TextEditingController(text: widget.muta?.name ?? '');
    _zoneController = TextEditingController(text: widget.muta?.zone ?? '');
    _capoMutaController = TextEditingController(text: widget.muta?.capoMuta ?? '');
    _capocorsaController = TextEditingController(text: widget.muta?.capocorsa ?? '');
    
    _esterniSinistraControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: widget.muta?.esterniSinistra[index] ?? '',
      ),
    );
    
    _esterniDestraControllers = List.generate(
      4,
      (index) => TextEditingController(
        text: widget.muta?.esterniDestra[index] ?? '',
      ),
    );
    
    _interniPosterioriControllers = List.generate(
      2,
      (index) => TextEditingController(
        text: widget.muta?.interniPosteriori[index] ?? '',
      ),
    );
    
    _selectedCoordinates = widget.muta?.coordinates ?? 
        const LatLng(43.35190, 12.57730); // Default: Piazza Grande
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _zoneController.dispose();
    _capoMutaController.dispose();
    _capocorsaController.dispose();
    for (var controller in _esterniSinistraControllers) {
      controller.dispose();
    }
    for (var controller in _esterniDestraControllers) {
      controller.dispose();
    }
    for (var controller in _interniPosterioriControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Modifica Muta' : 'Nuova Muta'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Informazioni generali
            _buildSectionHeader('Informazioni Generali'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nomeController,
              label: 'Nome Muta',
              icon: Icons.people,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Il nome è obbligatorio';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _zoneController,
              label: 'Zona/Località',
              icon: Icons.location_on_outlined,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La zona è obbligatoria';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _capoMutaController,
              label: 'Capo Muta',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Il capo muta è obbligatorio';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Capocorsa
            _buildSectionHeader('Capocorsa (Davanti)'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _capocorsaController,
              label: 'Capocorsa',
              icon: Icons.star,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Il capocorsa è obbligatorio';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 24),
            
            // Esterni Sinistra
            _buildSectionHeader('Esterni Sinistra (4 ceraioli)'),
            const SizedBox(height: 8),
            ..._esterniSinistraControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTextField(
                  controller: entry.value,
                  label: 'Esterno Sinistro ${entry.key + 1}',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obbligatorio';
                    }
                    return null;
                  },
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Esterni Destra
            _buildSectionHeader('Esterni Destra (4 ceraioli)'),
            const SizedBox(height: 8),
            ..._esterniDestraControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTextField(
                  controller: entry.value,
                  label: 'Esterno Destro ${entry.key + 1}',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obbligatorio';
                    }
                    return null;
                  },
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Interni Posteriori
            _buildSectionHeader('Interni Posteriori (2 ceraioli)'),
            const SizedBox(height: 8),
            ..._interniPosterioriControllers.asMap().entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildTextField(
                  controller: entry.value,
                  label: 'Interno Posteriore ${entry.key + 1}',
                  icon: Icons.person_outline,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Campo obbligatorio';
                    }
                    return null;
                  },
                ),
              );
            }).toList(),
            
            const SizedBox(height: 24),
            
            // Pulsante salva
            ElevatedButton(
              onPressed: _saveMuta,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isEditMode ? 'Salva Modifiche' : 'Crea Muta',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            if (_isEditMode) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _deleteMuta,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Elimina Muta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFFB71C1C),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 2),
        ),
      ),
      validator: validator,
    );
  }

  void _saveMuta() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Compila tutti i campi obbligatori'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final newMuta = MutaModel(
      id: widget.muta?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nomeController.text,
      zone: _zoneController.text,
      info: 'Muta configurata', // Info di default
      coordinates: _selectedCoordinates,
      capoMuta: _capoMutaController.text,
      capocorsa: _capocorsaController.text,
      esterniSinistra: _esterniSinistraControllers.map((c) => c.text).toList(),
      esterniDestra: _esterniDestraControllers.map((c) => c.text).toList(),
      interniPosteriori: _interniPosterioriControllers.map((c) => c.text).toList(),
    );

    if (_isEditMode) {
      // Modifica muta esistente
      final index = muteData.indexWhere((m) => m.id == widget.muta!.id);
      if (index != -1) {
        muteData[index] = newMuta;
      }
    } else {
      // Aggiungi nuova muta
      muteData.add(newMuta);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditMode ? 'Muta modificata con successo' : 'Muta creata con successo'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();
  }

  void _deleteMuta() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina Muta'),
        content: const Text('Sei sicuro di voler eliminare questa muta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () {
              muteData.removeWhere((m) => m.id == widget.muta!.id);
              Navigator.pop(context); // Chiudi dialog
              Navigator.pop(context); // Torna alla lista
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Muta eliminata'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text(
              'Elimina',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
