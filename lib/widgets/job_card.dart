import 'package:flutter/material.dart';

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
    final String title = job['title'] ?? 'Untitled Job';
    final String company = job['company'] ?? 'Unknown Company';
    final String location = job['location'] ?? 'Unknown Location';
    final String type = job['type'] ?? 'Unspecified';
    final String description = job['description'] ?? '';

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isMatched
              ? Theme.of(context).colorScheme.secondary
              : Colors.transparent,
          width: isMatched ? 2 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                          avatar: const Icon(Icons.auto_awesome, size: 16),
                          label: const Text('Recommended'),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary.withValues(alpha: 0.25),
                          side: BorderSide.none,
                        ),
                      Chip(
                        label: Text(type),
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondary,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '$company - $location',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Text(_shortDescription(description)),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: onApply,
                  icon: const Icon(Icons.send),
                  label: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
