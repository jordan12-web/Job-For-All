import 'package:flutter/material.dart';

class RoleUtils {
  RoleUtils._();

  static const String jobSeeker = 'Job Seeker';
  static const String employer = 'Employer';
  static const String admin = 'Admin';

  /// Roles available on public signup (Admin is internal only).
  static const List<String> publicSignupRoles = <String>[jobSeeker, employer];

  /// Demo admin account for platform staff (not on public signup).
  static const String adminDemoEmail = 'admin@jobforall.et';
  static const String adminDemoPassword = 'Admin2026!';

  static final Map<String, Map<String, String>> userProfiles =
      <String, Map<String, String>>{};

  static String currentRole = jobSeeker;
  static String? currentUserEmail;

  /// Seeds internal admin and other demo accounts at app start.
  static void ensureDemoAccounts() {
    userProfiles.putIfAbsent(
      adminDemoEmail,
      () => <String, String>{
        'email': adminDemoEmail,
        'password': adminDemoPassword,
        'role': admin,
      },
    );
  }

  static void registerUser({
    required String email,
    required String password,
    required String role,
  }) {
    if (role == admin) {
      throw ArgumentError('Admin accounts cannot be created via public signup.');
    }
    if (!publicSignupRoles.contains(role)) {
      throw ArgumentError('Invalid role for public signup.');
    }

    userProfiles[email.toLowerCase()] = <String, String>{
      'email': email.toLowerCase(),
      'password': password,
      'role': role,
    };
    currentUserEmail = email.toLowerCase();
    currentRole = role;
  }

  static bool loginUser({required String email, required String password}) {
    ensureDemoAccounts();

    final Map<String, String>? profile = userProfiles[email.toLowerCase()];
    if (profile == null || profile['password'] != password) {
      return false;
    }

    currentUserEmail = profile['email'];
    currentRole = profile['role'] ?? jobSeeker;
    return true;
  }

  static bool isJobSeeker([String? role]) => (role ?? currentRole) == jobSeeker;
  static bool isEmployer([String? role]) => (role ?? currentRole) == employer;
  static bool isAdmin([String? role]) => (role ?? currentRole) == admin;

  static List<RoleNavItem> navItemsForRole(String role) {
    if (isAdmin(role)) {
      return const <RoleNavItem>[
        RoleNavItem(key: 'home', label: 'Home', icon: Icons.home_outlined),
        RoleNavItem(
          key: 'admin',
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
        ),
        RoleNavItem(
          key: 'moderation',
          label: 'Moderation',
          icon: Icons.admin_panel_settings_outlined,
        ),
      ];
    }

    if (isEmployer(role)) {
      return const <RoleNavItem>[
        RoleNavItem(key: 'home', label: 'Home', icon: Icons.home_outlined),
        RoleNavItem(key: 'jobs', label: 'Jobs', icon: Icons.work_outline),
        RoleNavItem(key: 'postJob', label: 'Post Job', icon: Icons.post_add),
        RoleNavItem(
          key: 'applicants',
          label: 'Applicants',
          icon: Icons.groups_outlined,
        ),
        RoleNavItem(
          key: 'profile',
          label: 'Profile',
          icon: Icons.business_outlined,
        ),
        RoleNavItem(
          key: 'payments',
          label: 'Payments',
          icon: Icons.payments_outlined,
        ),
      ];
    }

    return const <RoleNavItem>[
      RoleNavItem(key: 'home', label: 'Home', icon: Icons.home_outlined),
      RoleNavItem(key: 'jobs', label: 'Jobs', icon: Icons.work_outline),
      RoleNavItem(key: 'profile', label: 'Profile', icon: Icons.person_outline),
      RoleNavItem(
        key: 'notifications',
        label: 'Notifications',
        icon: Icons.notifications_outlined,
      ),
      RoleNavItem(key: 'ussd', label: 'USSD', icon: Icons.dialpad_outlined),
    ];
  }
}

class RoleNavItem {
  const RoleNavItem({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}
