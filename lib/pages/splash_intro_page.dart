import 'package:flutter/material.dart';

import 'login_page.dart';

/// ============================================================
/// VISIT GUBBIO — Intro cinematografica
/// ------------------------------------------------------------
/// Sequenza premium, minimal e fluida che precede il Login:
///  1. Schermata bianca pulita
///  2. Delicato watermark del castello (quasi trasparente)
///  3. Il logo si rivela dall'alto verso il basso con una
///     maschera a gradiente morbido: prima il castello, poi
///     "Visit Gubbio", infine "SCOPRI. VIVI. RICORDA."
///  4. Leggero fade-in + scale + drift verso l'alto
///  5. Dissolvenza elegante e passaggio automatico al Login
///
/// Tutto è realizzato con le sole API native di Flutter
/// (nessuna libreria aggiuntiva) e un unico AnimationController.
/// ============================================================
class SplashIntroPage extends StatefulWidget {
  const SplashIntroPage({super.key});

  @override
  State<SplashIntroPage> createState() => _SplashIntroPageState();
}

class _SplashIntroPageState extends State<SplashIntroPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Watermark del castello sullo sfondo
  late final Animation<double> _watermarkOpacity;
  late final Animation<double> _watermarkScale;

  // Logo principale
  late final Animation<double> _logoReveal; // maschera a gradiente (0 -> 1)
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoDrift; // spostamento verticale

  // Dissolvenza finale dell'intera intro
  late final Animation<double> _exitOpacity;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4300),
    );

    _watermarkOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.08, 0.45, curve: Curves.easeOutCubic),
    );

    _watermarkScale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.08, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    _logoReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.20, 0.72, curve: Curves.easeInOutCubic),
    );

    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.55, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _logoDrift = Tween<double>(begin: 14.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.18, 0.80, curve: Curves.easeOutCubic),
      ),
    );

    _exitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.88, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _goToLogin();
      }
    });

    _controller.forward();
  }

  void _goToLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 550),
        pageBuilder: (_, __, ___) => const LoginPage(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortestSide = size.shortestSide;

    // Dimensioni responsive
    final logoWidth = (shortestSide * 0.86).clamp(280.0, 520.0);
    final watermarkWidth = (shortestSide * 1.30).clamp(420.0, 860.0);

    // Leggermente sopra il centro, come il logo nella schermata di Login
    const verticalAlign = Alignment(0.0, -0.30);

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Opacity(
            opacity: _exitOpacity.value,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ---------- Watermark castello (sfondo delicato) ----------
                Align(
                  alignment: verticalAlign,
                  child: Opacity(
                    opacity: _watermarkOpacity.value * 0.07,
                    child: Transform.scale(
                      scale: _watermarkScale.value,
                      child: Transform.translate(
                        offset: const Offset(0, -24),
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: 0.60,
                            child: Image.asset(
                              'assets/geo/logo.png',
                              width: watermarkWidth,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ---------- Logo principale con reveal a gradiente ----------
                Align(
                  alignment: verticalAlign,
                  child: Transform.translate(
                    offset: Offset(0, _logoDrift.value),
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Opacity(
                        opacity: _logoOpacity.value,
                        child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (rect) {
                            final r = _logoReveal.value;
                            const feather = 0.16;
                            final s1 = (r - feather).clamp(0.0, 1.0);
                            final s2 = r.clamp(0.0, 1.0);
                            return LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: const [
                                Colors.white,
                                Colors.white,
                                Colors.transparent,
                                Colors.transparent,
                              ],
                              stops: [0.0, s1, s2, 1.0],
                            ).createShader(rect);
                          },
                          child: Image.asset(
                            'assets/geo/logo.png',
                            width: logoWidth,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
