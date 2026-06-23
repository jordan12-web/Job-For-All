import 'package:flutter/material.dart';

/// How It Works section displaying a simple 3-step flow:
/// Register → Apply → Get Hired
/// Uses visual cards to explain each step in the job-seeking journey.
class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 48 : 64,
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Section title
          Text(
            'How It Works',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),

          // Section subtitle
          Text(
            'Get hired in three simple steps',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 48),

          // Steps
          if (isMobile)
            // Mobile layout: stacked vertically
            Column(
              spacing: 24,
              children: <Widget>[
                _StepCard(
                  stepNumber: 1,
                  title: 'Create an Account',
                  description:
                      'Sign up as a job seeker or employer. Complete your profile with your skills, education, or company details.',
                  icon: Icons.person_add_outlined,
                ),
                _StepCard(
                  stepNumber: 2,
                  title: 'Browse & Apply',
                  description:
                      'Search for jobs that match your skills. Submit applications with just a few clicks.',
                  icon: Icons.search_outlined,
                ),
                _StepCard(
                  stepNumber: 3,
                  title: 'Get Hired',
                  description:
                      'Employers review your application. Connect, negotiate, and start your new role.',
                  icon: Icons.check_circle_outlined,
                ),
              ],
            )
          else
            // Desktop layout: horizontal with connecting lines
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _StepCard(
                    stepNumber: 1,
                    title: 'Create an Account',
                    description:
                        'Sign up as a job seeker or employer. Complete your profile with your skills, education, or company details.',
                    icon: Icons.person_add_outlined,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Text(
                    '→',
                    style: TextStyle(fontSize: 32, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: _StepCard(
                    stepNumber: 2,
                    title: 'Browse & Apply',
                    description:
                        'Search for jobs that match your skills. Submit applications with just a few clicks.',
                    icon: Icons.search_outlined,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32),
                  child: Text(
                    '→',
                    style: TextStyle(fontSize: 32, color: Colors.grey),
                  ),
                ),
                Expanded(
                  child: _StepCard(
                    stepNumber: 3,
                    title: 'Get Hired',
                    description:
                        'Employers review your application. Connect, negotiate, and start your new role.',
                    icon: Icons.check_circle_outlined,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Reusable card for displaying a single step in the flow.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  final int stepNumber;
  final String title;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Step number badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Center(
                child: Text(
                  stepNumber.toString(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Icon
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),

            // Title
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
