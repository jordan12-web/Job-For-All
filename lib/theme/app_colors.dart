import 'package:flutter/material.dart';

/// "Trust & Professionalism" design system palette.
///
/// Navy Blue for structure, Sky Blue for accents, clean off-white surfaces.
abstract final class AppColors {
  // ── Brand tokens ─────────────────────────────────────────
  /// Navy Blue — headlines, structure, primary text
  static const Color navy = Color(0xFF1A1A40);

  /// Sky Blue — accents, primary actions, focus rings
  static const Color sky = Color(0xFF00A8E8);

  /// Off-white — page background
  static const Color background = Color(0xFFF8F9FA);

  // ── Semantic aliases (used throughout the app) ───────────
  static const Color primary = navy;
  static const Color tertiary = sky;
  static const Color secondary = Color(0xFF5A5A7A);

  // ── Surfaces ─────────────────────────────────────────────
  static const Color surface = background;
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE2E4EA);
  static const Color borderFocus = sky;

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary = navy;
  static const Color textSecondary = secondary;
  static const Color textHint = Color(0xFF9A9AB0);

  // ── Semantic ─────────────────────────────────────────────
  static const Color success = Color(0xFF0E9F6E);
  static const Color warning = Color(0xFFB7791F);
  static const Color error = Color(0xFFC23B33);

  // ── Tints ────────────────────────────────────────────────
  static const Color skyLight = Color(0xFFE6F7FD);
  static const Color navyLight = Color(0xFFE8E8F0);

  // ── Backwards-compatible aliases ─────────────────────────
  static const Color navyMid = navy;
  static const Color skyDark = Color(0xFF0088C2);
  static const Color indigo = navy;
  static const Color indigoDark = navy;
  static const Color indigoDarker = navy;
  static const Color amber = sky;
  static const Color amberSoft = skyLight;

  static const LinearGradient navyGradient = LinearGradient(
    colors: <Color>[navy, navy],
  );
  static const LinearGradient skyGradient = LinearGradient(
    colors: <Color>[sky, sky],
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: <Color>[background, background],
  );
  static const LinearGradient footerGradient = LinearGradient(
    colors: <Color>[navy, navy],
  );
  static const LinearGradient authGradient = LinearGradient(
    colors: <Color>[navy, navy],
  );
}
