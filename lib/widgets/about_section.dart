import 'package:flutter/material.dart';

/// About section explaining JOB FOR ALL's mission, features, and differentiators.
/// Highlights key value propositions: USSD access, credential verification, local payments.
class AboutSection extends StatelessWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 48 : 64,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Section title
          Text(
            'About Job For All',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),

          // Section subtitle
          Text(
            'Bridging the gap between Ethiopian talent and opportunity',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 40),

          // Mission statement
          Padding(
            padding: EdgeInsets.only(
              bottom: isMobile ? 40 : 0,
              right: isMobile ? 0 : 48,
            ),
            child: Text(
              'Job For All is a trusted, locally-focused job marketplace designed for Ethiopia. '
              'We connect job seekers with verified employers, providing a secure and accessible platform '
              'that works for everyone—regardless of internet connectivity.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6,
                    color: Colors.grey[700],
                  ),
            ),
          ),
          const SizedBox(height: 40),

          // Key differentiators
          Wrap(
            spacing: 24,
            runSpacing: 24,
            children: <Widget>[
              _DifferentiatorCard(
                icon: Icons.dialpad_outlined,
                title: 'USSD Access',
                description: 'Search jobs and apply using USSD—no app or data required.',
              ),
              _DifferentiatorCard(
                icon: Icons.verified_user_outlined,
                title: 'Verified Credentials',
                description: 'Every job seeker and employer is verified for trust and safety.',
              ),
              _DifferentiatorCard(
                icon: Icons.attach_money_outlined,
                title: 'Local Payments',
                description: 'Secure transactions using local payment methods (M-Pesa, bank transfer).',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A reusable card widget for displaying differentiators with icon and description.
class _DifferentiatorCard extends StatelessWidget {
  const _DifferentiatorCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    final double cardWidth = isMobile ? double.infinity : 300;

    return SizedBox(
      width: cardWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}
