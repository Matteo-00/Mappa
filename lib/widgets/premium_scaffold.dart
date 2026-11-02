import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/route_observer.dart';

/// True se la schermata ha senso con la freccia "indietro": cioè si è aperta
/// da un'altra schermata (es. un ristorante dalla lista, la mappa da un
/// ristorante). Se si è aperta direttamente dalla home (menu, icona profilo)
/// "indietro" e "home" sono la stessa cosa e basta la casina.
bool showBackButton(BuildContext context) {
  final route = ModalRoute.of(context);
  if (route == null || !Navigator.of(context).canPop()) return false;
  final index = navStackObserver.indexOf(route);
  return index < 0 ? true : index >= 2;
}

/// I pulsanti in alto a sinistra: la casina sempre, la freccia "indietro" solo
/// quando la schermata si è aperta dentro un'altra ([showBackButton]).
class NavButtons extends StatelessWidget {
  final bool light;
  const NavButtons({super.key, this.light = false});

  /// Larghezza occupata dai pulsanti (serve a chi li mette in una AppBar).
  static double widthFor(BuildContext context) =>
      showBackButton(context) ? 104 : 48;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBackButton(context)) ...[
          BackCircleButton(light: light),
          const SizedBox(width: 8),
        ],
        HomeButton(light: light),
      ],
    );
  }
}

/// Pulsante universale "Home" in alto a sinistra.
/// Riporta sempre alla home (prima route dello stack).
class HomeButton extends StatelessWidget {
  final bool light;
  const HomeButton({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: light ? Colors.white.withOpacity(0.92) : Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.home_rounded, color: AppColors.rossoGubbio, size: 25),
        ),
      ),
    );
  }
}

/// Pulsante "Indietro" (freccia): torna alla schermata precedente, per esempio
/// dalla mappa alla tappa o al luogo da cui si era partiti. Accanto a [HomeButton].
class BackCircleButton extends StatelessWidget {
  final bool light;
  const BackCircleButton({super.key, this.light = false});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: light ? Colors.white.withOpacity(0.92) : Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black.withOpacity(0.25),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).maybePop(),
        child: const SizedBox(
          width: 48,
          height: 48,
          child: Icon(Icons.arrow_back_rounded,
              color: AppColors.rossoGubbio, size: 25),
        ),
      ),
    );
  }
}

/// Header premium riutilizzabile: a sinistra la freccia "indietro" (quando c'è
/// una pagina da cui si arriva) e il pulsante Home, poi il titolo e, a destra,
/// un'azione opzionale.
/// Va inserito come primo figlio del body (gestisce già la SafeArea).
class PremiumHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const PremiumHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final canGoBack = showBackButton(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            if (canGoBack) ...[
              const BackCircleButton(),
              const SizedBox(width: 8),
            ],
            const HomeButton(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: canGoBack ? 21 : 24,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: AppColors.bluNotte,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
            if (trailing != null)
              SizedBox(
                width: 48,
                height: 48,
                child: Center(child: trailing),
              ),
          ],
        ),
      ),
    );
  }
}
