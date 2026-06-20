import 'package:flutter/material.dart';

/// "Clinical" design system palette.
///
/// Hospital-grade legibility, extreme clarity, single-action focus.
/// Flat colours only — no gradients, no alternate accents.
abstract final class AppColors {
  // ── Clinical tokens ──────────────────────────────────────
  /// Background / neutral surface
  static const Color background = Color(0xFFF1F5F7);

  /// Primary — headlines and body text
  static const Color primary = Color(0xFF0F2A3B);

  /// Secondary — metadata, borders, supporting text
  static const Color secondary = Color(0xFF4F6B7C);

  /// Tertiary — THE ONLY action accent colour in the entire app.
  /// Reserve for exactly one primary action per screen
  /// (e.g. Apply, Save, Approve). Do not use for decoration.
  static const Color tertiary = Color(0xFF0E9F8E);

  // ── Neutrals ─────────────────────────────────────────────
  static const Color surface      = Color(0xFFF1F5F7);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color border       = Color(0xFFD7E0E5);
  static const Color borderFocus  = tertiary;

  // ── Text ─────────────────────────────────────────────────
  static const Color textPrimary   = primary;
  static const Color textSecondary = secondary;
  static const Color textHint      = Color(0xFF8FA3AD);

  // ── Semantic (flat, no gradients) ─────────────────────────
  static const Color success = Color(0xFF0E9F8E); // reuses tertiary tone
  static const Color warning = Color(0xFFB7791F);
  static const Color error   = Color(0xFFC23B33);

  // ── Backwards-compatible aliases ──────────────────────────
  // Kept so existing widgets referencing the old Navy/Sky palette
  // continue to compile without modification. All resolve to the
  // new Clinical tokens — no gradients, flat colour only.
  static const Color navy        = primary;
  static const Color navyMid     = primary;
  static const Color navyLight   = primary;
  static const Color sky         = tertiary;
  static const Color skyDark     = tertiary;
  static const Color skyLight    = Color(0xFFE3F4F2);
  static const Color indigo      = primary;
  static const Color indigoDark  = primary;
  static const Color indigoDarker = primary;
  static const Color amber       = tertiary;
  static const Color amberSoft   = Color(0xFFE3F4F2);

  // Gradients are explicitly forbidden by the Clinical system.
  // These are kept as flat single-colour "gradients" (start == end)
  // purely so any remaining widget reference still compiles —
  // they render as flat fills, not gradients.
  static const LinearGradient navyGradient = LinearGradient(
    colors: <Color>[primary, primary],
  );
  static const LinearGradient skyGradient = LinearGradient(
    colors: <Color>[tertiary, tertiary],
  );
  static const LinearGradient heroGradient = LinearGradient(
    colors: <Color>[background, background],
  );
  static const LinearGradient footerGradient = LinearGradient(
    colors: <Color>[primary, primary],
  );
  static const LinearGradient authGradient = LinearGradient(
    colors: <Color>[primary, primary],
  );
}