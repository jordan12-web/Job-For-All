import 'package:flutter/material.dart';

import 'app_colors.dart';

/// "Clinical" design system theme.
///
/// Hospital-grade legibility, single accent colour, flat surfaces,
/// 8px button radius, 12px card radius. No gradients.
abstract final class AppTheme {
  static ThemeData build() {
    const ColorScheme colorScheme = ColorScheme(
      brightness:  Brightness.light,
      primary:     AppColors.primary,
      onPrimary:   Colors.white,
      secondary:   AppColors.tertiary,
      onSecondary: Colors.white,
      error:       AppColors.error,
      onError:     Colors.white,
      surface:     AppColors.surfaceWhite,
      onSurface:   AppColors.primary,
    );

    return ThemeData(
      colorScheme:             colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3:            true,

      // ── Typography — IBM Plex Sans / IBM Plex Mono ────────
      // These ship as system-available fonts on most platforms when
      // referenced by family name; fallbacks ensure legibility even
      // if the exact font isn't present on the host OS/browser.
      fontFamily: 'IBM Plex Sans',
      fontFamilyFallback: const <String>[
        'Segoe UI',
        'Roboto',
        'Arial',
      ],
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor:    AppColors.primary,
        displayColor: AppColors.primary,
      ).copyWith(
        displayLarge:  const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineLarge: const TextStyle(fontWeight: FontWeight.w700),
        headlineMedium: const TextStyle(fontWeight: FontWeight.w600),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w600),
        titleLarge:    const TextStyle(fontWeight: FontWeight.w600),
        titleMedium:   const TextStyle(fontWeight: FontWeight.w600),
        // Labels use IBM Plex Mono for the "clinical" data-readout feel
        labelLarge: const TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
        ),
        labelMedium: const TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontWeight: FontWeight.w500,
          letterSpacing: 0.2,
          color: AppColors.secondary,
        ),
        labelSmall: const TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
          color: AppColors.secondary,
        ),
        bodyMedium: const TextStyle(color: AppColors.secondary),
        bodySmall:  const TextStyle(color: AppColors.secondary),
      ),

      // ── AppBar ──────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor:  AppColors.surfaceWhite,
        foregroundColor:  AppColors.primary,
        elevation:        0,
        centerTitle:      false,
        surfaceTintColor: Colors.transparent,
        shadowColor:      Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'IBM Plex Sans',
          fontSize:   18,
          fontWeight: FontWeight.w600,
          color:      AppColors.primary,
        ),
      ),

      // ── Card — 12px radius (lg token) ─────────────────────
      cardTheme: CardThemeData(
        color:            AppColors.surfaceWhite,
        elevation:        0,
        shadowColor:      Colors.black.withValues(alpha: 0.04),
        surfaceTintColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── FilledButton — 8px radius (md token), tertiary accent ──
      // Tertiary (#0E9F8E) is the ONLY accent in the system.
      // Hover = subtle elevation shift, NOT a colour change —
      // "no color changes or distracting flashes" per spec.
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.disabled)) {
              return AppColors.textHint;
            }
            return AppColors.tertiary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.10),
          ),
          elevation: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.hovered)) {
              return 3;
            }
            return 0;
          }),
          shadowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.18),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),

      // ── OutlinedButton — secondary actions, never the accent ────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          side: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.hovered)) {
              return const BorderSide(color: AppColors.primary, width: 1.5);
            }
            return const BorderSide(color: AppColors.border);
          }),
          overlayColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.04),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),

      // ── TextButton ───────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
          overlayColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.04),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),

      // ── Input / TextField ────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          color:      AppColors.secondary,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: const TextStyle(
          color:      AppColors.textHint,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        // Focus uses the tertiary accent — the one place a non-button
        // element is allowed to show it, since it signals the single
        // active input the user is interacting with.
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.tertiary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // ── Chip — flat, secondary-coloured metadata tag ──────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        labelStyle: const TextStyle(
          fontFamily: 'IBM Plex Mono',
          color:      AppColors.secondary,
          fontWeight: FontWeight.w500,
          fontSize:   12,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),

      // ── Divider ──────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color:     AppColors.border,
        thickness: 1,
        space:     1,
      ),

      // ── SnackBar ─────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior:         SnackBarBehavior.floating,
        backgroundColor:  AppColors.primary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // ── Page transitions — instant, clinical feel ─────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux:   FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.macOS:   CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}