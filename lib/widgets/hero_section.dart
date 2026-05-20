import 'package:flutter/material.dart';

/// Hero section displaying headline, subtext, and primary CTA buttons.
/// Designed to be the first impression on the landing page.
class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.onBrowseJobs,
    required this.onGetStarted,
  });

  final VoidCallback onBrowseJobs;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24 : 48,
          vertical: isMobile ? 48 : 80,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            // Headline
            Text(
              'Find Your Perfect Job in Ethiopia',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: isMobile ? 32 : 56,
                  ),
            ),
            const SizedBox(height: 24),

            // Subtext
            Text(
              'A trusted job marketplace connecting Ethiopian talent with '
              'employers. Verified credentials, local payments, and USSD access.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: isMobile ? 16 : 18,
                  ),
            ),
            const SizedBox(height: 48),

            // CTA Buttons
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: <Widget>[
                // Browse Jobs button
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: onBrowseJobs,
                    child: const Text(
                      'Browse Jobs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // Get Started button
                SizedBox(
                  width: isMobile ? double.infinity : 200,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: onGetStarted,
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
