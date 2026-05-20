import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Loading screen elegante per transizione Festa dei Ceri
/// Durata: 2 secondi
class FestaCeriLoadingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const FestaCeriLoadingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<FestaCeriLoadingScreen> createState() => _FestaCeriLoadingScreenState();
}

class _FestaCeriLoadingScreenState extends State<FestaCeriLoadingScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _controller.forward();
    
    // Dopo 2 secondi chiude
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.fcDeepRed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: const BoxDecoration(
              gradient: AppTheme.fcHeaderGradient,
            ),
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icona celebrazione
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.celebration,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Titolo
                      const Text(
                        'FESTA DEI CERI',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                          fontFamily: 'serif',
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Sottotitolo
                      Text(
                        'Una tradizione millenaria',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.5,
                        ),
                      ),
                      
                      const SizedBox(height: 48),
                      
                      // Indicatore di caricamento elegante
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
