import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'logo_widget.dart';

/// Split auth layout used by login and signup (Indeed/LinkedIn style).
class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
    this.onBack,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: Row(
        children: <Widget>[
          if (wide) Expanded(child: _BrandPanel(onBack: onBack)),
          Expanded(
            flex: wide ? 1 : 2,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (!wide)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Row(
                              children: <Widget>[
                                if (onBack != null)
                                  IconButton(
                                    onPressed: onBack,
                                    icon: const Icon(Icons.arrow_back),
                                  ),
                                const LogoWidget(size: 36),
                                const SizedBox(width: 10),
                                const Text(
                                  'Job For All',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.indigo,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.5,
                              ),
                        ),
                        const SizedBox(height: 28),
                        child,
                        if (footer != null) ...<Widget>[
                          const SizedBox(height: 20),
                          footer!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.authGradient),
      child: Stack(
        children: <Widget>[
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  const Spacer(),
                  const LogoWidget(size: 56, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    'Job For All',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ethiopia\'s marketplace for verified talent, '
                    'local payments, and USSD-friendly hiring.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _Highlight(icon: Icons.verified_user_outlined, text: 'Verified profiles'),
                  const SizedBox(height: 12),
                  _Highlight(icon: Icons.dialpad_outlined, text: 'USSD job access'),
                  const SizedBox(height: 12),
                  _Highlight(icon: Icons.security_outlined, text: 'Secure local payments'),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: AppColors.amber, size: 22),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.95),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
