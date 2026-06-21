import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class RoleUtils {
  RoleUtils._();

  static const String jobSeeker = 'Job Seeker';
  static const String employer = 'Employer';
  static const String admin = 'Admin';

  static const List<String> publicSignupRoles = <String>[jobSeeker, employer];

  static String currentRole = jobSeeker;
  static String? currentUserEmail;
  static String? currentUserId;
  static String? currentUserName;
  static String? currentDbRole;

  /// Tab to open when navigating to [HomePage] after login.
  static String? pendingInitialTabKey;

  static void setSession({required UserProfile profile}) {
    currentUserId = profile.id;
    currentUserEmail = profile.email;
    currentUserName = profile.name;
    currentDbRole = profile.role;
    currentRole = _displayRoleFromDb(profile.role);
    pendingInitialTabKey = _defaultTabForDbRole(profile.role);
  }

  static void clearSession() {
    currentUserId = null;
    currentUserEmail = null;
    currentUserName = null;
    currentDbRole = null;
    currentRole = jobSeeker;
    pendingInitialTabKey = null;
  }

  static String _displayRoleFromDb(String dbRole) {
    switch (dbRole) {
      case 'employer':
        return employer;
      case 'admin':
        return admin;
      case 'seeker':
      default:
        return jobSeeker;
    }
  }

  static String? _defaultTabForDbRole(String dbRole) {
    switch (dbRole) {
      case 'employer':
        return 'home';
      case 'admin':
        return 'admin';
      case 'seeker':
        return 'jobs';
      default:
        return null;
    }
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
        // Subscription is now part of the Profile tab's SubscriptionHub —
        // see EmployerProfile's TabBarView. No standalone Payments tab.
        RoleNavItem(
          key: 'profile',
          label: 'Profile',
          icon: Icons.business_outlined,
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