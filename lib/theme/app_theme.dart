// ignore_for_file: unnecessary_import
// The cupertino.dart import below is flagged as unnecessary by the
// local Flutter SDK's analyzer (material.dart re-exports
// CupertinoPageTransitionsBuilder in this version), but the production
// build pipeline (dart2js --release on Vercel CI) previously failed
// with "Method not found: CupertinoPageTransitionsBuilder" without this
// explicit import. Keeping it intentionally — see Sprint deploy notes.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Layout and interaction tokens exposed via [ThemeExtension].
@immutable
class AppLayoutTokens extends ThemeExtension<AppLayoutTokens> {
  const AppLayoutTokens({
    required this.pagePadding,
    required this.cardPadding,
    required this.fieldSpacing,
    required this.sectionSpacing,
    required this.cardRadius,
    required this.buttonRadius,
    required this.cardElevation,
    required this.cardElevationHovered,
    required this.transitionDuration,
  });

  final double pagePadding;
  final double cardPadding;
  final double fieldSpacing;
  final double sectionSpacing;
  final double cardRadius;
  final double buttonRadius;
  final double cardElevation;
  final double cardElevationHovered;
  final Duration transitionDuration;

  static const AppLayoutTokens defaults = AppLayoutTokens(
    pagePadding: 28,
    cardPadding: 28,
    fieldSpacing: 20,
    sectionSpacing: 32,
    cardRadius: 14,
    buttonRadius: 10,
    cardElevation: 1,
    cardElevationHovered: 6,
    transitionDuration: Duration(milliseconds: 120),
  );

  @override
  AppLayoutTokens copyWith({
    double? pagePadding,
    double? cardPadding,
    double? fieldSpacing,
    double? sectionSpacing,
    double? cardRadius,
    double? buttonRadius,
    double? cardElevation,
    double? cardElevationHovered,
    Duration? transitionDuration,
  }) {
    return AppLayoutTokens(
      pagePadding: pagePadding ?? this.pagePadding,
      cardPadding: cardPadding ?? this.cardPadding,
      fieldSpacing: fieldSpacing ?? this.fieldSpacing,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      cardElevation: cardElevation ?? this.cardElevation,
      cardElevationHovered: cardElevationHovered ?? this.cardElevationHovered,
      transitionDuration: transitionDuration ?? this.transitionDuration,
    );
  }

  @override
  AppLayoutTokens lerp(ThemeExtension<AppLayoutTokens>? other, double t) {
    if (other is! AppLayoutTokens) {
      return this;
    }
    return AppLayoutTokens(
      pagePadding: pagePadding,
      cardPadding: cardPadding,
      fieldSpacing: fieldSpacing,
      sectionSpacing: sectionSpacing,
      cardRadius: cardRadius,
      buttonRadius: buttonRadius,
      cardElevation: cardElevation,
      cardElevationHovered: cardElevationHovered,
      transitionDuration: transitionDuration,
    );
  }
}

/// Fast fade — feels instantaneous without jarring cuts.
class _FastFadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FastFadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}

/// "Trust & Professionalism" design system theme.
///
/// Navy Blue structure, Sky Blue accents, breathable spacing,
/// subtle hover elevation on interactive surfaces.
abstract final class AppTheme {
  static AppLayoutTokens layoutOf(BuildContext context) {
    return Theme.of(context).extension<AppLayoutTokens>() ??
        AppLayoutTokens.defaults;
  }

  static ThemeData build() {
    const ColorScheme colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.navy,
      onPrimary: Colors.white,
      secondary: AppColors.sky,
      onSecondary: Colors.white,
      tertiary: AppColors.sky,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: AppColors.surfaceWhite,
      onSurface: AppColors.navy,
    );

    const AppLayoutTokens layout = AppLayoutTokens.defaults;

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      extensions: const <ThemeExtension<dynamic>>[layout],

      // ── Typography — Inter with clean fallbacks ───────────
      fontFamily: 'Inter',
      fontFamilyFallback: const <String>[
        'Segoe UI',
        'Roboto',
        'Helvetica Neue',
        'Arial',
      ],
      textTheme: ThemeData.light().textTheme
          .apply(
            bodyColor: AppColors.navy,
            displayColor: AppColors.navy,
            fontFamily: 'Inter',
          )
          .copyWith(
            displayLarge: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            displayMedium: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
            headlineLarge: const TextStyle(fontWeight: FontWeight.w700),
            headlineMedium: const TextStyle(fontWeight: FontWeight.w600),
            headlineSmall: const TextStyle(fontWeight: FontWeight.w600),
            titleLarge: const TextStyle(fontWeight: FontWeight.w600),
            titleMedium: const TextStyle(fontWeight: FontWeight.w600),
            labelLarge: const TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
            labelMedium: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              color: AppColors.secondary,
            ),
            labelSmall: const TextStyle(
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
              color: AppColors.secondary,
            ),
            bodyMedium: const TextStyle(color: AppColors.secondary),
            bodySmall: const TextStyle(color: AppColors.secondary),
          ),

      // ── AppBar ──────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        foregroundColor: AppColors.navy,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.navy,
        ),
      ),

      // ── Card ────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.surfaceWhite,
        elevation: layout.cardElevation,
        shadowColor: AppColors.navy.withValues(alpha: 0.06),
        surfaceTintColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(layout.cardRadius),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── FilledButton — Sky Blue accent, hover elevation ─
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((
            Set<WidgetState> s,
          ) {
            if (s.contains(WidgetState.disabled)) {
              return AppColors.textHint;
            }
            return AppColors.sky;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          overlayColor: WidgetStateProperty.all(
            Colors.white.withValues(alpha: 0.12),
          ),
          elevation: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.disabled)) {
              return 0;
            }
            if (s.contains(WidgetState.hovered) ||
                s.contains(WidgetState.pressed)) {
              return 4;
            }
            return 1;
          }),
          shadowColor: WidgetStateProperty.all(
            AppColors.sky.withValues(alpha: 0.35),
          ),
          minimumSize: WidgetStateProperty.all(const Size(0, 50)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(layout.buttonRadius),
            ),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          animationDuration: layout.transitionDuration,
        ),
      ),

      // ── OutlinedButton ──────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.navy),
          side: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.hovered)) {
              return const BorderSide(color: AppColors.sky, width: 1.5);
            }
            return const BorderSide(color: AppColors.border);
          }),
          overlayColor: WidgetStateProperty.all(
            AppColors.sky.withValues(alpha: 0.06),
          ),
          elevation: WidgetStateProperty.resolveWith((Set<WidgetState> s) {
            if (s.contains(WidgetState.hovered)) {
              return 2;
            }
            return 0;
          }),
          minimumSize: WidgetStateProperty.all(const Size(0, 50)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(layout.buttonRadius),
            ),
          ),
          animationDuration: layout.transitionDuration,
        ),
      ),

      // ── TextButton ──────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.navy),
          overlayColor: WidgetStateProperty.all(
            AppColors.sky.withValues(alpha: 0.06),
          ),
          animationDuration: layout.transitionDuration,
        ),
      ),

      // ── Input / TextField ───────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: const TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.w400,
        ),
        hintStyle: const TextStyle(
          color: AppColors.textHint,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(layout.buttonRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(layout.buttonRadius),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(layout.buttonRadius),
          borderSide: const BorderSide(color: AppColors.sky, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(layout.buttonRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(layout.buttonRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),

      // ── Chip ────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.navyLight,
        labelStyle: const TextStyle(
          color: AppColors.secondary,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── Divider ─────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(layout.buttonRadius),
        ),
      ),

      // ── Page transitions — fast fade for lightweight feel ─
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: _FastFadePageTransitionsBuilder(),
          TargetPlatform.iOS: _FastFadePageTransitionsBuilder(),
          TargetPlatform.linux: _FastFadePageTransitionsBuilder(),
          TargetPlatform.macOS: _FastFadePageTransitionsBuilder(),
          TargetPlatform.windows: _FastFadePageTransitionsBuilder(),
        },
      ),
    );
  }
}
