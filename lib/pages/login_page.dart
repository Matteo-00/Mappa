import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'modern_home_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';

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

      // Naviga alla home
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ModernHomePage()),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      // Gestione errori specifici
      final langService = context.read<LanguageService>();
      final l10n = AppLocalizations.of(langService.currentLanguageCode);
      String errorMessage = l10n.loginError;
      
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('invalid') && (errorString.contains('email') || errorString.contains('password') || errorString.contains('credentials'))) {
        errorMessage = l10n.invalidCredentials;
      } else if (errorString.contains('429') || errorString.contains('too many')) {
        errorMessage = l10n.tooManyAttempts;
      } else if (errorString.contains('email not confirmed')) {
        errorMessage = l10n.emailNotConfirmed;
      } else if (errorString.contains('network') || errorString.contains('connection')) {
        errorMessage = l10n.connectionError;
      } else if (errorString.contains('user not found')) {
        errorMessage = l10n.userNotFound;
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
    final langService = context.watch<LanguageService>();
    final l10n = AppLocalizations.of(langService.currentLanguageCode);


    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: Stack(
          children: [
            // Contenuto principale
            Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 64),
                  // Logo ancora più grande
                  SizedBox(
                    width: 400,
                    height: 400,
                    child: Image.asset(
                      'assets/geo/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // const SizedBox(height: 4),
                  // Text(
                  //   'La più bella città medioevale',
                  //   style: TextStyle(
                  //     fontSize: 14,
                  //     fontWeight: FontWeight.w400,
                  //     color: Colors.brown,
                  //     fontFamily: 'Cinzel', // Font elegante stile antico, assicurati che sia nel progetto
                  //     letterSpacing: 2.0,
                  //     fontStyle: FontStyle.italic,
                  //     shadows: [
                  //       Shadow(
                  //         blurRadius: 2,
                  //         color: Colors.brown.shade200,
                  //         offset: Offset(1, 1),
                  //       ),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            // Form principale centrato
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 380, left: 24, right: 24, bottom: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // Campo Email
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
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

                      // Campo Password
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
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
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Password dimenticata
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            l10n.forgotPassword,
                            style: const TextStyle(
                              color: Color(0xFFB13B2E),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Pulsante Login
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB13B2E),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: const Color(0xFFB13B2E).withOpacity(0.3),
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
                                  l10n.login,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Divider
                      Container(
                        constraints: const BoxConstraints(maxWidth: 400),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: const Color(0xFFE5E1DB))),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                'o',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                            Expanded(child: Divider(color: const Color(0xFFE5E1DB))),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Link registrazione
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            l10n.noAccount + ' ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.register,
                              style: const TextStyle(
                                color: Color(0xFFB13B2E),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Selettore lingua in alto a destra
            Positioned(
              top: 16,
              right: 16,
              child: Container(
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
                  color: Colors.white,
                  offset: const Offset(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem(
                      value: 'it',
                      child: Row(
                        children: [
                          Text(
                            '🇮🇹',
                            style: TextStyle(fontSize: 20),
                          ),
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
                          Text(
                            '🇬🇧',
                            style: TextStyle(fontSize: 20),
                          ),
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
            ),
          ],
        ),
      ),
    );
  }
}
