import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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

/// Header premium riutilizzabile con pulsante Home a sinistra,
/// titolo centrato e azione opzionale a destra.
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
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(
          children: [
            const HomeButton(),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'serif',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bluNotte,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: Center(child: trailing ?? const SizedBox.shrink()),
            ),
          ],
        ),
      ),
    );
  }
}
