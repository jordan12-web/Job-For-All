import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/role_utils.dart';

/// Displays a single job listing using the "Clinical" design system.
///
/// Card token: white background, 24px padding, 12px radius.
/// Metadata (date/location) uses Secondary (#4F6B7C).
/// Tertiary (#0E9F8E) is reserved for the Apply button only —
/// no other element on this card uses the accent colour.
/// Hover = elevation shift only. No colour change, no flash.
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

  /// Recommended-job indicator. Rendered as a neutral label, NOT
  /// in the tertiary accent colour — Apply remains the only accent use.
  final bool isMatched;
  final Widget? companyLogo;

  String _shortDescription(String description) {
    if (description.length <= 140) {
      return description;
    }
    return '${description.substring(0, 137)}...';
  }

  @override
  Widget build(BuildContext context) {
    final String title = job['title'] ?? 'Untitled Job';
    final String company = job['company'] ?? 'Unknown Company';
    final String location = job['location'] ?? 'Unknown Location';
    final String type = job['type'] ?? 'Unspecified';
    final String description = job['description'] ?? '';
    final String postedDate = job['createdAt'] ?? job['date'] ?? '';

    return _ClinicalHoverCard(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(24), // Clinical card token: 24px
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header row: logo + title + type tag ─────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (companyLogo != null) ...<Widget>[
                  companyLogo!,
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        company,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _MetaTag(label: type),
              ],
            ),
            const SizedBox(height: 16),

            // ── Metadata row: location + date — Secondary colour ──
            Row(
              children: <Widget>[
                const Icon(
                  Icons.place_outlined,
                  size: 15,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(location, style: Theme.of(context).textTheme.labelMedium),
                if (postedDate.isNotEmpty) ...<Widget>[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 13,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    postedDate,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
                if (isMatched) ...<Widget>[
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.bookmark_border,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Recommended',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Description ───────────────────────────────────
            Text(
              _shortDescription(description),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.secondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),

            // ── The single accent action on this card ──────────
            // RBAC: employers never see an Apply action on job cards —
            // they post jobs, they don't apply to them.
            if (!RoleUtils.isEmployer())
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: onApply,
                  child: const Text('Apply'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Neutral, non-accent tag for job type (Full-time / Part-time).
/// Deliberately NOT using the tertiary colour — Apply is the only
/// accent element on the card per the Clinical single-action rule.
class _MetaTag extends StatelessWidget {
  const _MetaTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'IBM Plex Mono',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.secondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Clinical hover card — elevation shift ONLY.
/// No border colour change, no accent flash, no scale jump.
/// This is a deliberate constraint from the design system: hover
/// must read as "this is interactive" without drawing attention
/// away from the single accent action inside the card.
class _ClinicalHoverCard extends StatefulWidget {
  const _ClinicalHoverCard({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_ClinicalHoverCard> createState() => _ClinicalHoverCardState();
}

class _ClinicalHoverCardState extends State<_ClinicalHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(12), // Clinical card token: 12px
        border: Border.all(color: AppColors.border),
        boxShadow: _hovered
            ? <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ]
            : <BoxShadow>[
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(onTap: widget.onTap, child: widget.child),
      ),
    );
  }
}