import 'package:flutter/material.dart';

/// A consistent button used across all pages in the app.
///
/// Hover states are handled by the theme's [FilledButtonThemeData]
/// and [OutlinedButtonThemeData] — no custom hover logic needed here.
/// This widget stays thin so future style changes go in [AppTheme].
class CommonButton extends StatelessWidget {
  const CommonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isFullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isPrimary;

  /// When true the button stretches to fill available width.
  final bool isFullWidth;

  @override
  Widget build(BuildContext context) {
    final Widget child = icon == null
        ? Text(label)
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(label),
            ],
          );

    final ButtonStyle? fullWidthStyle = isFullWidth
        ? ButtonStyle(
            minimumSize: WidgetStateProperty.all(
              const Size(double.infinity, 48),
            ),
          )
        : null;

    if (!isPrimary) {
      return OutlinedButton(
        onPressed: onPressed,
        style: fullWidthStyle,
        child: child,
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: fullWidthStyle,
      child: child,
    );
  }
}
