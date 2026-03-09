import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/welcome_carousel_dialog.dart';
import 'unified_home_page.dart';
import 'register_page.dart';

/// Schermata di Login con stile Visit Gubbio
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Login con Supabase Auth
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw 'Login fallito';
      }

      // Recupera dati utente dalla tabella utenti
      final userData = await supabase
          .from('utenti')
          .select()
          .eq('id', user.id)
          .single();

      if (!mounted) return;

      // Aggiorna AuthService con i dati utente
      final authService = context.read<AuthService>();
      authService.loginWithSupabase(userData);

      // Mostra dialog di benvenuto, poi naviga alla home
      if (!mounted) return;
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WelcomeCarouselDialog(
          onComplete: () {
            Navigator.of(context).pop();
          },
        ),
      );
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UnifiedHomePage()),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Gestione errori specifici
      String errorMessage = 'Errore durante il login';
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid') && (errorString.contains('email') || errorString.contains('password') || errorString.contains('credentials'))) {
        errorMessage = 'Email o password non corretti';
      } else if (errorString.contains('429') || errorString.contains('too many')) {
        errorMessage = 'Troppi tentativi! Attendi qualche minuto e riprova.';
      } else if (errorString.contains('email not confirmed')) {
        errorMessage = 'Email non confermata. Controlla la tua casella di posta.';
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = 'Errore di connessione. Controlla la tua rete.';
      } else if (errorString.contains('user not found')) {
        errorMessage = 'Account non trovato. Registrati prima.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.vgAncientParchment,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo/Icona stilizzata medievale
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: AppTheme.vgCardGradient,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.vgBronze.withOpacity(0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.vgStoneGray.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_city,
                      size: 70,
                      color: AppTheme.vgBronze,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Titolo principale
                  const Text(
                    'VISIT GUBBIO',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.vgDarkSlate,
                      letterSpacing: 2.0,
                      fontFamily: 'serif',
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'La città medievale dell\'Umbria',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.vgStoneGray,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Campo Email
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.vgDarkSlate),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: AppTheme.vgStoneGray),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.vgStoneGray.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.vgBronze,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: AppTheme.vgBronze,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Inserisci email';
                        }
                        if (!value.contains('@')) {
                          return 'Email non valida';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Campo Password
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppTheme.vgDarkSlate),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: AppTheme.vgStoneGray),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppTheme.vgStoneGray.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppTheme.vgBronze,
                            width: 2,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: AppTheme.vgBronze,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppTheme.vgStoneGray,
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
                          return 'Inserisci password';
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Pulsante Login
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.vgBronze,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        shadowColor: AppTheme.vgStoneGray.withOpacity(0.4),
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
                              'ACCEDI',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Link registrazione
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Non hai un account? ',
                        style: TextStyle(
                          color: AppTheme.vgStoneGray,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RegisterPage()),
                          );
                        },
                        child: const Text(
                          'Registrati',
                          style: TextStyle(
                            color: AppTheme.vgBronze,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info configurazione Supabase (per sviluppo)
                  if (false) // Cambia a true per vedere le info di configurazione
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(top: 16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configurazione Supabase',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[800],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ricorda di inserire URL e ANON_KEY in main.dart',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
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
}
