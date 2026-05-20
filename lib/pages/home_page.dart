import 'package:flutter/material.dart';

import '../data/mock_notification_store.dart';
import '../utils/role_utils.dart';
import '../widgets/notification_panel.dart';
import '../widgets/top_nav_bar.dart';
import 'admin_dashboard.dart';
import 'applicants_page.dart';
import 'employer_profile.dart';
import 'job_listing_page.dart';
import 'job_posting_page.dart';
import 'job_seeker_profile.dart';
import 'login_page.dart';
import 'payment_page.dart';
import 'ussd_simulation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onLogout});

  static const String routeName = '/home';

  final VoidCallback onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedTab = 0;

  List<RoleNavItem> get _navItems =>
      RoleUtils.navItemsForRole(RoleUtils.currentRole);

  void _logout(BuildContext context) {
    widget.onLogout();
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginPage.routeName,
      (Route<dynamic> route) => false,
    );
  }

  void _selectTabByKey(String key) {
    final int index = _navItems.indexWhere(
      (RoleNavItem item) => item.key == key,
    );
    if (index == -1) {
      return;
    }
    setState(() {
      _selectedTab = index;
    });
  }

  Widget _buildCurrentTab() {
    final List<RoleNavItem> items = _navItems;
    final RoleNavItem selectedItem =
        items[_selectedTab.clamp(0, items.length - 1)];

    return switch (selectedItem.key) {
      'home' => _DashboardTab(
        role: RoleUtils.currentRole,
        onSelectTab: _selectTabByKey,
      ),
      'jobs' => const JobListingPage(showAppBar: false),
      'profile' =>
        RoleUtils.isEmployer()
            ? const EmployerProfile()
            : const JobSeekerProfile(),
      'notifications' => _NotificationsTab(
        onMarkAllRead: () {
          setState(MockNotificationStore.markAllRead);
        },
      ),
      'ussd' => const UssdSimulationPage(showAppBar: false),
      'postJob' => const JobPostingPage(),
      'applicants' => const ApplicantsPage(showAppBar: false),
      'payments' => const PaymentPage(showAppBar: false),
      'admin' || 'moderation' => const AdminDashboard(showAppBar: false),
      _ => const JobListingPage(showAppBar: false),
    };
  }

  @override
  Widget build(BuildContext context) {
    final int maxIndex = _navItems.length - 1;
    if (_selectedTab > maxIndex) {
      _selectedTab = 0;
    }

    return Scaffold(
      body: Column(
        children: <Widget>[
          TopNavBar(
            selectedIndex: _selectedTab,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedTab = index;
              });
            },
            onLogout: () => _logout(context),
          ),
          Expanded(child: _buildCurrentTab()),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.role, required this.onSelectTab});

  final String role;
  final ValueChanged<String> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final List<_DashboardAction> actions = _actionsForRole();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$role Dashboard',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _descriptionForRole(),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final bool isWide = constraints.maxWidth >= 840;

                  if (!isWide) {
                    return Column(
                      children: actions
                          .map(
                            (_DashboardAction action) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _ActionCard(action: action),
                            ),
                          )
                          .toList(),
                    );
                  }

                  return GridView.count(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.45,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: actions
                        .map(
                          (_DashboardAction action) =>
                              _ActionCard(action: action),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _descriptionForRole() {
    if (RoleUtils.isAdmin(role)) {
      return 'Moderate job posts, verify profiles, and keep the platform trustworthy.';
    }
    if (RoleUtils.isEmployer(role)) {
      return 'Post jobs, review applicants, manage employer profile, and simulate paid promotions.';
    }
    return 'Browse recommended jobs, manage your seeker profile, and track matching notifications.';
  }

  List<_DashboardAction> _actionsForRole() {
    if (RoleUtils.isAdmin(role)) {
      return <_DashboardAction>[
        _DashboardAction(
          icon: Icons.dashboard_outlined,
          title: 'Admin Dashboard',
          subtitle: 'View moderation and verification tools.',
          onTap: () => onSelectTab('admin'),
        ),
        _DashboardAction(
          icon: Icons.admin_panel_settings,
          title: 'Moderation',
          subtitle: 'Approve, reject, or delete job posts.',
          onTap: () => onSelectTab('moderation'),
        ),
      ];
    }

    if (RoleUtils.isEmployer(role)) {
      return <_DashboardAction>[
        _DashboardAction(
          icon: Icons.post_add,
          title: 'Post a job',
          subtitle: 'Create a new listing for review.',
          onTap: () => onSelectTab('postJob'),
        ),
        _DashboardAction(
          icon: Icons.groups,
          title: 'Applicants',
          subtitle: 'Review submitted applications.',
          onTap: () => onSelectTab('applicants'),
        ),
        _DashboardAction(
          icon: Icons.payments_outlined,
          title: 'Payments',
          subtitle: 'Simulate featured jobs and subscriptions.',
          onTap: () => onSelectTab('payments'),
        ),
        _DashboardAction(
          icon: Icons.business,
          title: 'Employer Profile',
          subtitle: 'Maintain company information.',
          onTap: () => onSelectTab('profile'),
        ),
      ];
    }

    return <_DashboardAction>[
      _DashboardAction(
        icon: Icons.search,
        title: 'Browse jobs',
        subtitle: 'Search and filter open roles.',
        onTap: () => onSelectTab('jobs'),
      ),
      _DashboardAction(
        icon: Icons.person,
        title: 'Job Seeker Profile',
        subtitle: 'Update skills and recommendations.',
        onTap: () => onSelectTab('profile'),
      ),
      _DashboardAction(
        icon: Icons.notifications_outlined,
        title: 'Notifications',
        subtitle: 'Check matching job alerts.',
        onTap: () => onSelectTab('notifications'),
      ),
      _DashboardAction(
        icon: Icons.dialpad,
        title: 'USSD Simulation',
        subtitle: 'Test short-code job access flows.',
        onTap: () => onSelectTab('ussd'),
      ),
    ];
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab({required this.onMarkAllRead});

  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(child: NotificationPanel(onMarkAllRead: onMarkAllRead)),
    );
  }
}

class _DashboardAction {
  const _DashboardAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action});

  final _DashboardAction action;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                action.icon,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
              const SizedBox(height: 16),
              Text(
                action.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(action.subtitle),
            ],
          ),
        ),
      ),
    );
  }
}
