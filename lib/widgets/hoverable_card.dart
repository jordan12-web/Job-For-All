import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// Interactive card with subtle hover elevation.
/// All visual tokens come from [AppLayoutTokens] in [AppTheme].
class HoverableCard extends StatefulWidget {
  const HoverableCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  State<HoverableCard> createState() => _HoverableCardState();
}

class _HoverableCardState extends State<HoverableCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final AppLayoutTokens layout = AppTheme.layoutOf(context);
    final double elevation = _hovered
        ? layout.cardElevationHovered
        : layout.cardElevation;

    Widget content = AnimatedContainer(
      duration: layout.transitionDuration,
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(layout.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.navy.withValues(alpha: _hovered ? 0.10 : 0.04),
            blurRadius: _hovered ? 20 : 6,
            offset: Offset(0, _hovered ? 8 : 2),
          ),
        ],
      ),
      child: Padding(
        padding: widget.padding ?? EdgeInsets.all(layout.cardPadding),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: widget.onTap, child: content),
      );
    }

    return Material(
      color: Colors.transparent,
      elevation: elevation,
      shadowColor: AppColors.navy.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(layout.cardRadius),
      child: content,
    );
  }
}
