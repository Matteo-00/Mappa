import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'login_page.dart';

/// Schermata di registrazione semplificata
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _cognomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _cognomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Funzione di registrazione
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final langService = context.read<LanguageService>();
    final l10n = AppLocalizations.of(langService.currentLanguageCode);

    // Controllo conferma password
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.passwordsDontMatch),
          backgroundColor: const Color(0xFFB71C1C),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;
    final nome = _nomeController.text.trim();
    final cognome = _cognomeController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Registrazione con Supabase Auth (include metadata per il trigger)
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'nome': nome,
          'cognome': cognome,
        },
      );

      final user = response.user;
      if (user == null) {
        throw 'Registrazione fallita';
      }

      // Salvataggio dati utente nella tabella utenti (fallback se il trigger non funziona)
      try {
        await supabase.from('utenti').insert({
          'id': user.id,
          'nome': nome,
          'cognome': cognome,
          'email': email,
        });
      } catch (insertError) {
        // Se l'inserimento fallisce (es. trigger già creato), ignora l'errore
        print('Insert skipped (trigger might have handled it): $insertError');
      }

      if (!mounted) return;

      // Successo - torna al login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.registrationSuccess),
          backgroundColor: const Color(0xFF4CAF50),
        ),
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      
      setState(() => _isLoading = false);
      
      // Gestione errori specifici
      String errorMessage = l10n.registrationError;
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('429') || errorString.contains('too many')) {
        errorMessage = l10n.tooManyAttempts;
      } else if (errorString.contains('email') && errorString.contains('already')) {
        errorMessage = l10n.emailAlreadyInUse;
      } else if (errorString.contains('weak password')) {
        errorMessage = l10n.weakPassword;
      } else if (errorString.contains('invalid email')) {
        errorMessage = l10n.invalidEmail;
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = l10n.connectionError;
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
    final langService = context.watch<LanguageService>();
    final l10n = AppLocalizations.of(langService.currentLanguageCode);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF424242)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Selettore lingua
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              initialValue: langService.currentLanguageCode,
              onSelected: (String code) {
                langService.setLanguage(code);
              },
              offset: const Offset(0, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  value: 'it',
                  child: Row(
                    children: [
                      const Text('🇮🇹', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      const Text('Italiano'),
                      if (langService.currentLanguageCode == 'it') ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check, size: 16, color: Color(0xFFB13B2E)),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'en',
                  child: Row(
                    children: [
                      const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      const Text('English'),
                      if (langService.currentLanguageCode == 'en') ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.check, size: 16, color: Color(0xFFB13B2E)),
                      ],
                    ],
                  ),
                ),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      langService.currentLanguageCode == 'it' ? '🇮🇹' : '🇬🇧',
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[700]),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  // Logo identico al login
                  SizedBox(
                    width: 400,
                    height: 400,
                    child: Image.asset(
                      'assets/geo/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // const SizedBox(height: 0),
                  // Text(
                  //   'Registra il tuo account',
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w400,
                  //     color: Colors.grey[600],
                  //     letterSpacing: 0.5,
                  //   ),
                  // ),
                ],
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 380, left: 24, right: 24, bottom: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // Nome e Cognome in riga
                      Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nomeController,
                                cursorColor: Colors.black,
                                decoration: InputDecoration(
                              labelText: l10n.firstName,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E1DB),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E1DB),
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C),
                                  width: 1,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey[600],
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.enterFirstName;
                              }
                              return null;
                            },
                          ),
                        ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _cognomeController,
                                cursorColor: Colors.black,
                                decoration: InputDecoration(
                              labelText: l10n.lastName,
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E1DB),
                                  width: 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE5E1DB),
                                  width: 1,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFB71C1C),
                                  width: 1,
                                ),
                              ),
                              prefixIcon: Icon(
                                Icons.person_outline,
                                color: Colors.grey[600],
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.enterLastName;
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                      const SizedBox(height: 16),

                      // Email
                      Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                        labelText: l10n.email,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E1DB),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E1DB),
                            width: 1,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFB71C1C),
                            width: 1,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.email_outlined,
                          color: Colors.grey[600],
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.enterEmail;
                        }
                        if (!value.contains('@')) {
                          return l10n.invalidEmail;
                        }
                        return null;
                      },
                    ),
                  ),

                      const SizedBox(height: 16),

                      // Password
                      Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                        labelText: l10n.password,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E1DB),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E1DB),
                            width: 1,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFB71C1C),
                            width: 1,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[600],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.enterPassword;
                        }
                        if (value.length < 6) {
                          return l10n.passwordMinLength;
                        }
                        return null;
                      },
                    ),
                  ),

                      const SizedBox(height: 16),

                      // Conferma Password
                      Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E1DB),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E1DB),
                            width: 1,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFB71C1C),
                            width: 1,
                          ),
                        ),
                        prefixIcon: Icon(
                          Icons.lock_outline,
                          color: Colors.grey[600],
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.confirmPasswordText;
                        }
                        if (value != _passwordController.text) {
                          return l10n.passwordsDontMatch;
                        }
                        return null;
                      },
                    ),
                  ),

                      const SizedBox(height: 32),

                      // Pulsante Registrati
                      Container(
                        constraints: const BoxConstraints(maxWidth: 500),
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB13B2E),
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
                          : Text(
                              l10n.register,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),

                      const SizedBox(height: 24),

                      // Link per tornare al login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.haveAccount + ' ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.signIn,
                              style: const TextStyle(
                                color: Color(0xFFB13B2E),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
