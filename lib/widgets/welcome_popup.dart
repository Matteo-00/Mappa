import 'package:flutter/material.dart';
import '../models/event_model.dart';

/// Popup di benvenuto elegante da mostrare alla prima apertura dell'app
/// Card bianca con ombra, titolo, immagine e prossimo evento
class WelcomePopup extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onViewProgram;
  final EventModel? nextEvent;

  const WelcomePopup({
    super.key,
    required this.onClose,
    required this.onViewProgram,
    this.nextEvent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.4), // Overlay scuro
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Contenuto principale
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),
                  // Titolo principale
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Benvenuto\nalla Festa dei Ceri',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.3,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Sottotitolo rosso
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB22222).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Oggi, ${_formatDate()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFB22222),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Immagine segnaposto (folla con Ceri)
                  Container(
                    height: 180,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFEAEAEA),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.festival_rounded,
                            size: 60,
                            color: const Color(0xFFB22222).withOpacity(0.3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'I Ceri di Gubbio',
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF6B6B6B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Prossimo evento
                  if (nextEvent != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Prossimo evento:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B6B6B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        '15 Maggio – ${nextEvent!.time}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        nextEvent!.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B6B6B),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  // Pulsante rosso grande
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          onClose();
                          onViewProgram();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFB22222),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Vedi programma',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
              // Pulsante X in alto a destra
              Positioned(
                top: 16,
                right: 16,
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B6B6B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF6B6B6B),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Formatta la data corrente
  String _formatDate() {
    final now = DateTime.now();
    final months = [
      'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    return '${now.day} ${months[now.month - 1]}';
  }
}
