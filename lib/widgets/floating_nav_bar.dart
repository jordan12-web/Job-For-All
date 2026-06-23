import 'package:flutter/material.dart';

import 'logo_widget.dart';

/// Floating navigation bar with modern, premium design
/// Features: Tabs for navigation, logo, and auth buttons
class FloatingNavBar extends StatefulWidget {
  final Function(String) onTabSelected;
  final String currentTab;
  final VoidCallback onRegisterPressed;
  final VoidCallback onSignInPressed;

  const FloatingNavBar({
    super.key,
    required this.onTabSelected,
    required this.currentTab,
    required this.onRegisterPressed,
    required this.onSignInPressed,
  });

  @override
  State<FloatingNavBar> createState() => _FloatingNavBarState();
}

class _FloatingNavBarState extends State<FloatingNavBar> {
  // Navigation tabs
  static const List<Map<String, String>> navTabs = [
    {'label': 'Home', 'route': 'home'},
    {'label': 'Explore Jobs', 'route': 'jobs'},
    {'label': 'About', 'route': 'about'},
    {'label': 'Contact', 'route': 'contact'},
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Positioned(
      top: 20,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: isMobile ? _buildMobileNav() : _buildDesktopNav(),
      ),
    );
  }

  /// Desktop navigation bar (horizontal layout)
  Widget _buildDesktopNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and brand
          GestureDetector(
            onTap: () => widget.onTabSelected('home'),
            child: Row(
              children: <Widget>[
                const LogoWidget(size: 32),
                const SizedBox(width: 10),
                const Text(
                  'Job For All',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4C63FF),
                  ),
                ),
              ],
            ),
          ),

          // Navigation tabs
          Row(
            children: navTabs.map((tab) {
              final isActive = widget.currentTab == tab['route'];
              return _buildNavTab(
                label: tab['label']!,
                isActive: isActive,
                onTap: () => widget.onTabSelected(tab['route']!),
              );
            }).toList(),
          ),

          // Auth buttons
          Row(
            children: [
              // Sign In (outline button)
              OutlinedButton(
                onPressed: widget.onSignInPressed,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF4C63FF), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                ),
                child: const Text(
                  'Sign In',
                  style: TextStyle(
                    color: Color(0xFF4C63FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Register (filled button)
              ElevatedButton(
                onPressed: widget.onRegisterPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA500), // Amber
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Mobile navigation bar (compact layout)
  Widget _buildMobileNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo (compact)
          GestureDetector(
            onTap: () => widget.onTabSelected('home'),
            child: const LogoWidget(size: 28),
          ),

          // Compact menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'register') {
                widget.onRegisterPressed();
              } else if (value == 'signin') {
                widget.onSignInPressed();
              } else {
                widget.onTabSelected(value);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                ...navTabs.map((tab) {
                  final isActive = widget.currentTab == tab['route'];
                  return PopupMenuItem<String>(
                    value: tab['route']!,
                    child: Row(
                      children: [
                        if (isActive)
                          const Icon(
                            Icons.check_circle,
                            color: Color(0xFF4C63FF),
                            size: 18,
                          ),
                        if (isActive) const SizedBox(width: 8),
                        Text(tab['label']!),
                      ],
                    ),
                  );
                }),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'signin',
                  child: Text('Sign In'),
                ),
                const PopupMenuItem<String>(
                  value: 'register',
                  child: Text('Register'),
                ),
              ];
            },
            child: const Icon(Icons.menu, color: Color(0xFF4C63FF), size: 24),
          ),
        ],
      ),
    );
  }

  /// Individual navigation tab
  Widget _buildNavTab({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF4C63FF) : Colors.grey[600],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 2,
                width: 30,
                decoration: BoxDecoration(
                  color: const Color(0xFF4C63FF),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
