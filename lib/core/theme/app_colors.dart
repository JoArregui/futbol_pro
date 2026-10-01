import 'package:flutter/material.dart';

/// Paleta premium deportiva — estilo EA FC / Nike.
/// Verde lima eléctrico sobre negro carbón, con acentos glass.
class AppColors {
  AppColors._();

  // Base oscura
  static const bg = Color(0xFF0B0F0C);
  static const bg2 = Color(0xFF121814);
  static const surface = Color(0xFF161D18);
  static const surface2 = Color(0xFF1E2620);
  static const card = Color(0xFF182019);

  // Acento principal
  static const lime = Color(0xFFC6F135); // verde lima eléctrico
  static const limeDark = Color(0xFF9BC81A);
  static const neon = Color(0xFFD4FF3F);
  static const field = Color(0xFF1DB954); // verde campo
  static const gold = Color(0xFFFFC93C);

  // Texto
  static const text = Color(0xFFF2F5ED);
  static const textDim = Color(0xFF9AA69B);
  static const muted = Color(0xFF6B766C);

  // Estados
  static const danger = Color(0xFFFF5A5A);
  static const info = Color(0xFF4CC9F0);
  static const warning = Color(0xFFFFB020);
  static const success = Color(0xFF2ECC71);

  // Claros (modo light premium)
  static const lightBg = Color(0xFFF4F6F0);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF10160F);

  static const gradientHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A2E0A), Color(0xFF0B0F0C), Color(0xFF12300F)],
  );

  static const gradientLime = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neon, lime, limeDark],
  );

  static const gradientCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2A1D), Color(0xFF121814)],
  );
}
