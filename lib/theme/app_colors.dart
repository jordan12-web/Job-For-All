import 'package:flutter/material.dart';

/// Brand palette — Indigo primary, Amber accent.
abstract final class AppColors {
  static const Color indigo = Color(0xFF4C63FF);
  static const Color indigoDark = Color(0xFF2D3A8C);
  static const Color indigoDarker = Color(0xFF1A2247);
  static const Color amber = Color(0xFFFFA500);
  static const Color amberSoft = Color(0xFFFFF3E0);
  static const Color surface = Color(0xFFF8F9FC);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static const LinearGradient footerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[indigoDarker, indigoDark, indigo],
  );

  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[indigo, Color(0xFF5B7BFF), Color(0xFF7C8FE8)],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Colors.white, Color(0xFFF5F7FF), amberSoft],
  );
}
