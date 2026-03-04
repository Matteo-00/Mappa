import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

/// Schermata di registrazione con opzione Ceraiolo
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _etaController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCeraiolo = false;
  String? _ceroScelto;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _ceriDisponibili = [
    'Sant\'Ubaldo',
    'Sant\'Antonio Abate',
    'San Giorgio',
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _etaController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Validazione password robusta
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Inserisci una password';
    }
    if (value.length < 8) {
      return 'Minimo 8 caratteri';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Richiesta 1 maiuscola';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Richiesto 1 numero';
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Richiesto 1 carattere speciale';
    }
    return null;
  }

  /// Funzione di registrazione
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    // Controllo conferma password
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le password non coincidono'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }

    // Se è ceraiolo, controllo che abbia scelto un cero
    if (_isCeraiolo && _ceroScelto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seleziona il tuo Cero'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;
    final nome = _nomeController.text.trim();
    final cognome = _cognomeController.text.trim();
    final eta = int.tryParse(_etaController.text.trim());
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (eta == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Età non valida'),
          backgroundColor: Color(0xFFB71C1C),
        ),
      );
      return;
    }

    try {
      // Registrazione con Supabase Auth
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw 'Registrazione fallita';
      }

      // Salvataggio dati utente nella tabella utenti
      await supabase.from('utenti').insert({
        'id': user.id,
        'nome': nome,
        'cognome': cognome,
        'eta': eta,
        'is_ceraiolo': _isCeraiolo,
        'cero': _isCeraiolo ? _ceroScelto : null,
      });

      if (!mounted) return;

      // Successo - torna al login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrazione completata! Effettua il login.'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      // Gestione errori specifici
      String errorMessage = 'Errore durante la registrazione';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('429') || errorString.contains('too many')) {
        errorMessage = 'Troppe richieste! Attendi 5-10 minuti e riprova.\n'
            'Supabase ha limiti di rate per prevenire spam.';
      } else if (errorString.contains('email') && errorString.contains('already')) {
        errorMessage = 'Email già registrata. Prova ad effettuare il login.';
      } else if (errorString.contains('weak password')) {
        errorMessage = 'Password troppo debole. Usa almeno 8 caratteri con maiuscole, numeri e caratteri speciali.';
      } else if (errorString.contains('invalid email')) {
        errorMessage = 'Email non valida. Controlla il formato.';
      } else if (errorString.contains('42501') || errorString.contains('row-level security') || errorString.contains('violates row')) {
        errorMessage = '⚠️ ERRORE CONFIGURAZIONE SUPABASE\n\n'
            '1. Dashboard → Authentication → Settings\n'
            '2. DISABILITA "Enable email confirmations"\n'
            '3. Salva e riprova\n\n'
            'Se l\'errore persiste, verifica le Policy RLS.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Errore di connessione. Controlla la tua rete.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: const Color(0xFFB71C1C),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Titolo
                  Text(
                    'Registrazione',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea il tuo account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Nome
                  _buildTextField(
                    controller: _nomeController,
                    label: 'Nome',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci il nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Cognome
                  _buildTextField(
                    controller: _cognomeController,
                    label: 'Cognome',
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci il cognome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Età
                  _buildTextField(
                    controller: _etaController,
                    label: 'Età',
                    icon: Icons.calendar_today_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci l\'età';
                      }
                      final eta = int.tryParse(value);
                      if (eta == null || eta < 1 || eta > 120) {
                        return 'Età non valida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Inserisci l\'email';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Email non valida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Conferma Password
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Conferma Password',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Conferma la password';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(
                            () => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Checkbox Ceraiolo
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _isCeraiolo,
                              activeColor: const Color(0xFFB71C1C),
                              onChanged: (value) {
                                setState(() {
                                  _isCeraiolo = value ?? false;
                                  if (!_isCeraiolo) {
                                    _ceroScelto = null;
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Text(
                                'Sei un Ceraiolo?',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_isCeraiolo) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _ceroScelto,
                            decoration: InputDecoration(
                              labelText: 'Scegli il tuo Cero',
                              filled: true,
                              fillColor: Colors.grey[50],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C),
                                  width: 2,
                                ),
                              ),
                            ),
                            items: _ceriDisponibili.map((cero) {
                              return DropdownMenuItem(
                                value: cero,
                                child: Text(cero),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _ceroScelto = value);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Pulsante Registrati
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Registrati',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Link al login
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                    },
                    child: Text(
                      'Hai già un account? Accedi',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    String? Function(String?)? validator,
    Widget? suffixIcon,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFFB71C1C),
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.orange[700]!,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.orange[700]!,
              width: 2,
            ),
          ),
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          suffixIcon: suffixIcon,
        ),
        validator: validator,
      ),
    );
  }
}
