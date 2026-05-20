import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'logo_widget.dart';

/// Footer with indigo gradient and working links.
class LandingFooter extends StatelessWidget {
  const LandingFooter({
    super.key,
    required this.onLinkTap,
  });

  final void Function(String link) onLinkTap;

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.sizeOf(context).width < 768;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.footerGradient),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 48,
        vertical: isMobile ? 40 : 56,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const LogoWidget(size: 32, color: Colors.white),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Job For All',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        'Hire with confidence. Work with trust.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 28,
                  children: <Widget>[
                    _FooterSection(
                      title: 'Company',
                      links: const <String>['About', 'Blog', 'Careers'],
                      onLinkTap: onLinkTap,
                    ),
                    _FooterSection(
                      title: 'Support',
                      links: const <String>[
                        'Help Center',
                        'Contact',
                        'Report Issue',
                      ],
                      onLinkTap: onLinkTap,
                    ),
                    _FooterSection(
                      title: 'Legal',
                      links: const <String>[
                        'Privacy Policy',
                        'Terms of Service',
                        'Cookie Policy',
                      ],
                      onLinkTap: onLinkTap,
                    ),
                    _SocialIcons(onLinkTap: onLinkTap),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 40,
                  children: <Widget>[
                    Expanded(
                      child: _FooterSection(
                        title: 'Company',
                        links: const <String>['About', 'Blog', 'Careers'],
                        onLinkTap: onLinkTap,
                      ),
                    ),
                    Expanded(
                      child: _FooterSection(
                        title: 'Support',
                        links: const <String>[
                          'Help Center',
                          'Contact',
                          'Report Issue',
                        ],
                        onLinkTap: onLinkTap,
                      ),
                    ),
                    Expanded(
                      child: _FooterSection(
                        title: 'Legal',
                        links: const <String>[
                          'Privacy Policy',
                          'Terms of Service',
                          'Cookie Policy',
                        ],
                        onLinkTap: onLinkTap,
                      ),
                    ),
                    Expanded(child: _SocialIcons(onLinkTap: onLinkTap)),
                  ],
                ),
              const SizedBox(height: 32),
              Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: <Widget>[
                  Text(
                    '© 2026 Job For All. All rights reserved.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    'Made for Ethiopia',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection({
    required this.title,
    required this.links,
    required this.onLinkTap,
  });

  final String title;
  final List<String> links;
  final void Function(String link) onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        ...links.map(
          (String link) => TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: Colors.white.withValues(alpha: 0.85),
            ),
            onPressed: () => onLinkTap(link),
            child: Text(link),
          ),
        ),
      ],
    );
  }
}

class _SocialIcons extends StatelessWidget {
  const _SocialIcons({required this.onLinkTap});

  final void Function(String link) onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: <Widget>[
        const Text(
          'Connect',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.mail_outline, color: Colors.white.withValues(alpha: 0.9)),
              onPressed: () => onLinkTap('Contact'),
              tooltip: 'Email',
            ),
            IconButton(
              icon: Icon(Icons.phone_outlined, color: Colors.white.withValues(alpha: 0.9)),
              onPressed: () => onLinkTap('Contact'),
              tooltip: 'Phone',
            ),
            IconButton(
              icon: Icon(Icons.help_outline, color: Colors.white.withValues(alpha: 0.9)),
              onPressed: () => onLinkTap('Help Center'),
              tooltip: 'Help',
            ),
          ],
        ),
      ],
    );
  }
}
