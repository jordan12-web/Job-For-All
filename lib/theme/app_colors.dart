import 'package:flutter/material.dart';

/// Brand palette — Navy/Sky Blue "Trust & Professionalism" theme.
abstract final class AppColors {
  // ── Primary palette ──────────────────────────────────────
  /// Navy blue — primary structure colour
  static const Color navy     = Color(0xFF1A1A40);
  static const Color navyMid  = Color(0xFF252560);
  static const Color navyLight = Color(0xFF2E2E7A);

  /// Sky blue — accent / interactive colour
  static const Color sky      = Color(0xFF00A8E8);
  static const Color skyDark  = Color(0xFF0086BB);
  static const Color skyLight = Color(0xFFE6F7FD);

  // ── Neutrals ─────────────────────────────────────────────
  static const Color surface      = Color(0xFFF8F9FA);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color border       = Color(0xFFE2E8F0);
  static const Color borderFocus  = Color(0xFF00A8E8);

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0D0D2B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint      = Color(0xFF94A3B8);

  // ── Semantic ─────────────────────────────────────────────
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color error   = Color(0xFFDC2626);

  // ── Gradients ─────────────────────────────────────────────
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[navy, navyMid, navyLight],
  );

  static const LinearGradient skyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[sky, skyDark],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[surfaceWhite, Color(0xFFF0F9FF), skyLight],
  );

  static const LinearGradient footerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[navy, navyMid, navyLight],
  );

  // ── Backwards-compatible aliases (used in existing widgets) ──
  /// Kept so no existing widget referencing AppColors.indigo breaks.
  static const Color indigo       = navy;
  static const Color indigoDark   = navyMid;
  static const Color indigoDarker = Color(0xFF12122E);
  static const Color amber        = Color(0xFFF59E0B);
  static const Color amberSoft    = Color(0xFFFFF7ED);

  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[navy, navyMid, sky],
  );
}