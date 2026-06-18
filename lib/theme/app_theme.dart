import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData build() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary:    AppColors.navy,
      onPrimary:  Colors.white,
      secondary:  AppColors.sky,
      onSecondary: Colors.white,
      error:      AppColors.error,
      onError:    Colors.white,
      surface:    AppColors.surfaceWhite,
      onSurface:  AppColors.textPrimary,
    );

    return ThemeData(
      colorScheme:           colorScheme,
      scaffoldBackgroundColor: AppColors.surface,
      useMaterial3:          true,

      // ── Typography — Inter via system fallback ──────────
      // Inter ships as a system font on most modern browsers/OS.
      // Listing it first means it's used when available;
      // the remaining fonts are clean fallbacks.
      fontFamily: 'Inter',
      fontFamilyFallback: const <String>[
        'SF Pro Display',
        'Segoe UI',
        'Roboto',
        'Arial',
      ],
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor:    AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ).copyWith(
        displayLarge:  const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -1.0),
        displayMedium: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineLarge: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineMedium: const TextStyle(fontWeight: FontWeight.w600),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w600),
        titleLarge:    const TextStyle(fontWeight: FontWeight.w600),
        titleMedium:   const TextStyle(fontWeight: FontWeight.w500),
        labelLarge:    const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
      ),

      // ── AppBar ──────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor:    AppColors.surfaceWhite,
        foregroundColor:    AppColors.textPrimary,
        elevation:          0,
        centerTitle:        false,
        surfaceTintColor:   Colors.transparent,
        shadowColor:        Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily:  'Inter',
          fontSize:    18,
          fontWeight:  FontWeight.w600,
          color:       AppColors.textPrimary,
          letterSpacing: -0.2,
        ),
      ),

      // ── Card ────────────────────────────────────────────
      cardTheme: CardThemeData(
        color:             AppColors.surfaceWhite,
        elevation:         0,
        shadowColor:       Colors.black.withValues(alpha: 0.06),
        surfaceTintColor:  AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── FilledButton (primary CTA) ───────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.disabled)) {
              return AppColors.textHint;
            }
            if (s.contains(WidgetState.hovered)) {
              return AppColors.sky;          // hover → sky accent
            }
            return AppColors.navy;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.08),
          ),
          elevation: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.hovered)) {
              return 4;
            }
            return 0;
          }),
          shadowColor: WidgetStateProperty.all(
            AppColors.navy.withValues(alpha: 0.25),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),

      // ── OutlinedButton ───────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.hovered)) {
              return AppColors.sky;
            }
            return AppColors.navy;
          }),
          side: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.hovered)) {
              return const BorderSide(color: AppColors.sky, width: 1.5);
            }
            return const BorderSide(color: AppColors.navy);
          }),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),

      // ── TextButton ───────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.hovered)) {
              return AppColors.sky;
            }
            return AppColors.navy;
          }),
          animationDuration: const Duration(milliseconds: 150),
        ),
      ),

      // ── Input / TextField ────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled:         true,
        fillColor:      AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: const TextStyle(
          color:      AppColors.textSecondary,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: const TextStyle(
          color:      AppColors.textHint,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.sky, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // ── Chip ─────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:  AppColors.skyLight,
        labelStyle: const TextStyle(
          color:       AppColors.navy,
          fontWeight:  FontWeight.w500,
          fontSize:    13,
        ),
        side:            BorderSide.none,
        shape:           RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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
        behavior:        SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      // ── Page transitions — instant feel ──────────────────
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