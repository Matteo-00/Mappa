import 'package:flutter/material.dart';
import 'dart:async';
import '../theme/app_theme.dart';

/// Dialog di benvenuto con carosello di 4 pagine
/// Appare dopo il login e prima della schermata principale
class WelcomeCarouselDialog extends StatefulWidget {
  final VoidCallback onComplete;
  
  const WelcomeCarouselDialog({
    super.key,
    required this.onComplete,
  });

  @override
  State<WelcomeCarouselDialog> createState() => _WelcomeCarouselDialogState();
}

class _WelcomeCarouselDialogState extends State<WelcomeCarouselDialog> 
    with SingleTickerProviderStateMixin {
  
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  final List<_CarouselPage> _pages = [
    const _CarouselPage(
      imagePath: 'assets/carousel/gubbio_panorama.jpg',
      title: 'Benvenuto su VISIT GUBBIO',
      description: 'Scopri Gubbio come non l\'hai mai vista.\n\n'
          'Questa applicazione ti accompagna tra eventi, tradizioni, '
          'ristoranti e luoghi imperdibili della città.\n\n'
          'Lasciati guidare tra le vie medievali e vivi l\'atmosfera unica '
          'di una delle città più affascinanti dell\'Umbria.',
    ),
    const _CarouselPage(
      imagePath: 'assets/carousel/eventi_gubbio.jpg',
      title: 'Eventi e tradizioni',
      description: 'Consulta la sezione Eventi per scoprire cosa succede in città.\n\n'
          'Concerti, manifestazioni, appuntamenti culturali e momenti speciali '
          'della tradizione eugubina.\n\n'
          'Aprendo un evento potrai vedere tutti i dettagli e raggiungerlo '
          'facilmente sulla mappa.',
    ),
    const _CarouselPage(
      imagePath: 'assets/carousel/ristorante_gubbio.jpg',
      title: 'Ristoranti convenzionati',
      description: 'Scopri i ristoranti affiliati all\'app.\n\n'
          'Nella sezione Ristoranti puoi trovare i locali più vicini a te '
          'e visualizzarli direttamente sulla mappa.\n\n'
          'Prenotando tramite l\'app potrai accedere a promozioni dedicate.\n\n'
          'Ad esempio: 5% di sconto fino a 50€ nei ristoranti aderenti.',
    ),
    const _CarouselPage(
      imagePath: 'assets/carousel/ceri_corsa.jpg',
      title: 'La Festa dei Ceri',
      description: 'Vivi da vicino una delle tradizioni più spettacolari d\'Italia.\n\n'
          'All\'interno dell\'app trovi una sezione dedicata alla Festa dei Ceri '
          'con il percorso della corsa, il programma ufficiale e le informazioni '
          'principali per seguire l\'evento.\n\n'
          'Un\'esperienza unica nel cuore di Gubbio.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Setup animazione di apertura
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
    
    // Avvia auto-scroll
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        // Torna alla prima pagina
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }
  
  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.5),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 700,
              ),
              decoration: BoxDecoration(
                color: AppTheme.vgAncientParchment,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Carosello pagine
                    Expanded(
                      child: GestureDetector(
                        onHorizontalDragStart: (_) => _stopAutoScroll(),
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) {
                            setState(() => _currentPage = index);
                          },
                          itemCount: _pages.length,
                          itemBuilder: (context, index) {
                            return _buildPage(_pages[index]);
                          },
                        ),
                      ),
                    ),
                    
                    // Indicatori pagina
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _pages.length,
                          (index) => _buildPageIndicator(index),
                        ),
                      ),
                    ),
                    
                    // Pulsante principale
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            _animationController.reverse().then((_) {
                              widget.onComplete();
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.vgBronze,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shadowColor: AppTheme.vgStoneGray.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'INIZIA L\'ESPERIENZA',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPage(_CarouselPage page) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Immagine (o placeholder)
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.vgWarmStone,
                  AppTheme.vgStoneGray,
                ],
              ),
            ),
            child: page.imagePath != null
                ? Image.asset(
                    page.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder(page.title);
                    },
                  )
                : _buildImagePlaceholder(page.title),
          ),
          
          // Contenuto testuale
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Titolo
                Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.vgDarkSlate,
                    height: 1.3,
                    letterSpacing: -0.5,
                    fontFamily: 'serif',
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Descrizione
                Text(
                  page.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: AppTheme.vgStoneGray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImagePlaceholder(String title) {
    IconData icon = Icons.location_city;
    
    if (title.contains('Eventi')) {
      icon = Icons.event;
    } else if (title.contains('Ristoranti')) {
      icon = Icons.restaurant;
    } else if (title.contains('Ceri')) {
      icon = Icons.celebration;
    }
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: AppTheme.vgBronze.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title.split('\n').first,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.vgBronze.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPageIndicator(int index) {
    final isActive = index == _currentPage;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.vgBronze : AppTheme.vgStoneGray.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

/// Classe per rappresentare una pagina del carosello
class _CarouselPage {
  final String? imagePath;
  final String title;
  final String description;
  
  const _CarouselPage({
    this.imagePath,
    required this.title,
    required this.description,
  });
}
