import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'logo_widget.dart';

/// Premium hero section with brand logo, value props, and dual CTAs.
class PremiumHeroSection extends StatelessWidget {
  const PremiumHeroSection({
    super.key,
    required this.onBrowseJobs,
    required this.onGetStarted,
  });

  final VoidCallback onBrowseJobs;
  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 768;
    final double headlineSize = isMobile ? 32 : 48;

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 60,
        isMobile ? 40 : 56,
        isMobile ? 20 : 60,
        isMobile ? 48 : 80,
      ),
      child: isMobile
          ? _buildMobileLayout(headlineSize)
          : _buildDesktopLayout(headlineSize),
    );
  }

  Widget _buildDesktopLayout(double headlineSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(child: _buildContentSection(headlineSize, false)),
        const SizedBox(width: 64),
        Expanded(child: _buildVisualSection(false)),
      ],
    );
  }

  Widget _buildMobileLayout(double headlineSize) {
    return Column(
      children: <Widget>[
        _buildContentSection(headlineSize, true),
        const SizedBox(height: 40),
        _buildVisualSection(true),
      ],
    );
  }

  Widget _buildContentSection(double headlineSize, bool isMobile) {
    final TextStyle headlineStyle = TextStyle(
      fontSize: headlineSize,
      fontWeight: FontWeight.bold,
      height: 1.15,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF4C63FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Text(
            'Ethiopia\'s trusted job marketplace',
            style: TextStyle(
              color: Color(0xFF4C63FF),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 20),
        RichText(
          text: TextSpan(
            style: headlineStyle.copyWith(color: const Color(0xFF1A1A1A)),
            children: <TextSpan>[
              const TextSpan(text: 'The Talent Your Work '),
              TextSpan(
                text: 'Deserves',
                style: headlineStyle.copyWith(color: const Color(0xFFFFA500)),
              ),
              const TextSpan(text: '. All in '),
              TextSpan(
                text: 'One Platform',
                style: headlineStyle.copyWith(color: const Color(0xFF4C63FF)),
              ),
              const TextSpan(text: '.'),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Connect with skilled professionals ready to deliver. From quick tasks to complex projects, '
          'find the right people to move your business forward — verified, secure, and built for Ethiopia.',
          style: TextStyle(
            fontSize: isMobile ? 15 : 16,
            color: Colors.grey[600],
            height: 1.6,
          ),
        ),
        const SizedBox(height: 28),
        _buildValueProp(
          icon: Icons.verified_user,
          title: 'Verified Job Seekers',
          subtitle: 'Credential-checked profiles you can trust',
        ),
        const SizedBox(height: 10),
        _buildValueProp(
          icon: Icons.security,
          title: 'Secure USSD Payments',
          subtitle: 'Pay safely with local mobile money',
        ),
        const SizedBox(height: 10),
        _buildValueProp(
          icon: Icons.dialpad_outlined,
          title: 'Works Without Data',
          subtitle: 'Browse and apply via USSD from any phone',
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: <Widget>[
            ElevatedButton(
              onPressed: onBrowseJobs,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA500),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.search, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Browse Jobs',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onGetStarted,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF4C63FF), width: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                'Get Started Free',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4C63FF),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            _TrustTag(
              icon: Icons.verified_user_outlined,
              label: 'Verified talent',
            ),
            _TrustTag(icon: Icons.dialpad_outlined, label: 'USSD ready'),
            _TrustTag(icon: Icons.payments_outlined, label: 'Local payments'),
          ],
        ),
      ],
    );
  }

  Widget _buildVisualSection(bool isMobile) {
    final double outerSize = isMobile ? 240 : 320;
    final double logoSize = isMobile ? 72 : 96;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: outerSize,
            height: outerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[
                  const Color(0xFF4C63FF).withValues(alpha: 0.12),
                  const Color(0xFFFFA500).withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
          Container(
            width: outerSize * 0.72,
            height: outerSize * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.indigo.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                LogoWidget(size: logoSize),
                const SizedBox(height: 16),
                const Text(
                  'Job For All',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C63FF),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Find your perfect match',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: isMobile ? 8 : 16,
            right: isMobile ? 8 : 24,
            child: _FloatingBadge(
              icon: Icons.verified,
              label: 'Verified',
              color: const Color(0xFF4C63FF),
            ),
          ),
          Positioned(
            bottom: isMobile ? 12 : 20,
            left: isMobile ? 0 : 12,
            child: _FloatingBadge(
              icon: Icons.payments_outlined,
              label: 'USSD Pay',
              color: const Color(0xFFFFA500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueProp({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF4C63FF).withValues(alpha: 0.1),
          ),
          child: Icon(icon, color: const Color(0xFF4C63FF), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustTag extends StatelessWidget {
  const _TrustTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: AppColors.indigo),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingBadge extends StatelessWidget {
  const _FloatingBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
