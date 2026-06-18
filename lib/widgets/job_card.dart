import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Displays a single job listing.
///
/// Polish phase additions:
/// - Hover elevation lift via [_HoverCard]
/// - Sky-blue accent border when [isMatched]
/// - Subtle shadow on hover
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
    required this.onApply,
    this.isMatched = false,
    this.companyLogo,
  });

  final Map<String, String> job;
  final VoidCallback onTap;
  final VoidCallback onApply;
  final bool isMatched;
  final Widget? companyLogo;

  String _shortDescription(String description) {
    if (description.length <= 120) {
      return description;
    }
    return '${description.substring(0, 117)}...';
  }

  @override
  Widget build(BuildContext context) {
    final String title       = job['title']       ?? 'Untitled Job';
    final String company     = job['company']     ?? 'Unknown Company';
    final String location    = job['location']    ?? 'Unknown Location';
    final String type        = job['type']        ?? 'Unspecified';
    final String description = job['description'] ?? '';

    return _HoverCard(
      onTap: onTap,
      borderColor: isMatched ? AppColors.sky : Colors.transparent,
      borderWidth: isMatched ? 2 : 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (companyLogo != null) ...<Widget>[
                  companyLogo!,
                  const SizedBox(width: 14),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                ),
                const SizedBox(width: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: <Widget>[
                    if (isMatched)
                      Chip(
                        avatar: const Icon(
                          Icons.auto_awesome,
                          size: 14,
                          color: AppColors.navy,
                        ),
                        label: const Text('Recommended'),
                      ),
                    Chip(label: Text(type)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$company · $location',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              _shortDescription(description),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: onApply,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card wrapper that lifts on hover.
/// Stateful so it can track hover state locally.
class _HoverCard extends StatefulWidget {
  const _HoverCard({
    required this.child,
    required this.onTap,
    this.borderColor = Colors.transparent,
    this.borderWidth = 0,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color borderColor;
  final double borderWidth;

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hovered ? AppColors.sky : widget.borderColor,
          width: _hovered ? 1.5 : widget.borderWidth,
        ),
        boxShadow: _hovered
            ? <BoxShadow>[
                BoxShadow(
                  color:       AppColors.navy.withValues(alpha: 0.08),
                  blurRadius:  16,
                  spreadRadius: 0,
                  offset:      const Offset(0, 6),
                ),
              ]
            : <BoxShadow>[
                BoxShadow(
                  color:      Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset:     const Offset(0, 2),
                ),
              ],
      ),
      child: MouseRegion(
        onEnter:  (_) => setState(() => _hovered = true),
        onExit:   (_) => setState(() => _hovered = false),
        cursor:   SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}