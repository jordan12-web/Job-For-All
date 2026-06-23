import 'package:flutter/material.dart';

import '../pages/login_page.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../utils/role_utils.dart';
import 'logo_widget.dart';
import 'notification_panel.dart';

/// App navigation bar for authenticated users and guest landing visitors.
class TopNavBar extends StatefulWidget {
  const TopNavBar({
    super.key,
    this.selectedIndex = 0,
    this.onDestinationSelected,
    this.onLogout,
    this.showLoginButton = false,
    this.isGuestMode = false,
    this.guestSelectedSection = 'home',
    this.onGuestNavigate,
    this.onSignIn,
    this.onRegister,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final VoidCallback? onLogout;
  final bool showLoginButton;

  /// Guest landing page mode — section scroll + auth actions.
  final bool isGuestMode;
  final String guestSelectedSection;
  final void Function(String section)? onGuestNavigate;
  final VoidCallback? onSignIn;
  final VoidCallback? onRegister;

  @override
  State<TopNavBar> createState() => _TopNavBarState();
}

class _TopNavBarState extends State<TopNavBar> {
  int _notificationRefreshKey = 0;
  OverlayEntry? _notificationOverlay;
  final LayerLink _notificationLayerLink = LayerLink();

  static const List<_GuestNavItem> _guestItems = <_GuestNavItem>[
    _GuestNavItem(key: 'home', label: 'Landing', icon: Icons.home_outlined),
    _GuestNavItem(key: 'jobs', label: 'Jobs', icon: Icons.work_outline),
    _GuestNavItem(key: 'about', label: 'About', icon: Icons.info_outline),
    _GuestNavItem(
      key: 'howItWorks',
      label: 'How It Works',
      icon: Icons.route_outlined,
    ),
    _GuestNavItem(key: 'profile', label: 'Profile', icon: Icons.person_outline),
  ];

  @override
  void dispose() {
    _removeNotificationOverlay();
    super.dispose();
  }

  void _toggleNotifications() {
    if (_notificationOverlay != null) {
      _removeNotificationOverlay();
      return;
    }
    _showNotificationOverlay();
  }

  void _refreshNotificationBadge() {
    setState(() {
      _notificationRefreshKey++;
    });
  }

  void _removeNotificationOverlay() {
    _notificationOverlay?.remove();
    _notificationOverlay = null;
  }

  void _showNotificationOverlay() {
    final OverlayState? overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    _notificationOverlay = OverlayEntry(
      builder: (BuildContext context) {
        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeNotificationOverlay,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _notificationLayerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 10),
              child: Material(
                color: Colors.transparent,
                child: NotificationPanel(
                  onNotificationsChanged: _refreshNotificationBadge,
                ),
              ),
            ),
          ],
        );
      },
    );

    overlay.insert(_notificationOverlay!);
  }

  void _handleGuestTap(String key) {
    widget.onGuestNavigate?.call(key);
  }

  /// Navigation fix: the logo always navigates somewhere, regardless of
  /// the current page or auth state.
  ///  - Guest mode: scrolls the landing page back to its home section
  ///    (existing behaviour, unchanged).
  ///  - Authenticated mode: selects the 'home' tab in HomePage's nav
  ///    rail/bar, returning the user to their role dashboard from
  ///    anywhere in the app — Recruitment Hub, Applicants, Profile, etc.
  VoidCallback? _resolveBrandTap() {
    if (widget.isGuestMode) {
      return () => _handleGuestTap('home');
    }
    if (widget.onDestinationSelected != null) {
      return () => widget.onDestinationSelected!(0); // index 0 = 'home'
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<RoleNavItem> roleItems = widget.isGuestMode
        ? const <RoleNavItem>[]
        : widget.showLoginButton
        ? const <RoleNavItem>[]
        : RoleUtils.navItemsForRole(RoleUtils.currentRole);

    return Material(
      color: Colors.white,
      elevation: widget.isGuestMode ? 0 : 2,
      shadowColor: Colors.black26,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          boxShadow: widget.isGuestMode
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 980;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (compact)
                          _buildCompactHeader(roleItems)
                        else
                          _buildDesktopHeader(roleItems),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(List<RoleNavItem> roleItems) {
    return Row(
      children: <Widget>[
        _BrandBlock(
          isGuest: widget.isGuestMode,
          onBrandTap: _resolveBrandTap(),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: widget.isGuestMode
              ? _buildGuestLinks(compact: false)
              : _buildRoleLinks(roleItems, compact: false),
        ),
        const SizedBox(width: 12),
        _buildTrailingActions(roleItems),
      ],
    );
  }

  Widget _buildCompactHeader(List<RoleNavItem> roleItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            _BrandBlock(
              isGuest: widget.isGuestMode,
              onBrandTap: _resolveBrandTap(),
            ),
            _buildTrailingActions(roleItems, compact: true),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: widget.isGuestMode
              ? _buildGuestLinks(compact: true)
              : _buildRoleLinks(roleItems, compact: true),
        ),
      ],
    );
  }

  Widget _buildGuestLinks({required bool compact}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _guestItems.map((_GuestNavItem item) {
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _NavLink(
            label: item.label,
            icon: item.icon,
            selected: widget.guestSelectedSection == item.key,
            compact: compact,
            onTap: () => _handleGuestTap(item.key),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRoleLinks(List<RoleNavItem> items, {required bool compact}) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int index = 0; index < items.length; index++)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _NavLink(
              label: items[index].label,
              icon: items[index].icon,
              selected: widget.selectedIndex == index,
              compact: compact,
              onTap: () => widget.onDestinationSelected?.call(index),
            ),
          ),
      ],
    );
  }

  Widget _buildTrailingActions(
    List<RoleNavItem> roleItems, {
    bool compact = false,
  }) {
    if (widget.isGuestMode) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (!compact)
            TextButton(
              onPressed: widget.onSignIn,
              child: const Text(
                'Sign In',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: widget.onRegister,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.amber,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Register'),
          ),
          if (compact) ...<Widget>[
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (String value) {
                if (value == 'signin') {
                  widget.onSignIn?.call();
                } else if (value == 'register') {
                  widget.onRegister?.call();
                } else if (value == 'browse') {
                  _handleGuestTap('browseJobs');
                } else {
                  _handleGuestTap(value);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'browse',
                  child: Text('Browse all jobs'),
                ),
                const PopupMenuItem<String>(
                  value: 'contact',
                  child: Text('Contact'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'signin',
                  child: Text('Sign In'),
                ),
                const PopupMenuItem<String>(
                  value: 'register',
                  child: Text('Register'),
                ),
              ],
            ),
          ],
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (RoleUtils.isJobSeeker())
          CompositedTransformTarget(
            link: _notificationLayerLink,
            child: _NotificationBell(
              refreshKey: _notificationRefreshKey,
              onPressed: _toggleNotifications,
            ),
          ),
        if (!widget.showLoginButton && roleItems.isNotEmpty)
          IconButton(
            tooltip: 'Logout',
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
          )
        else
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(LoginPage.routeName),
            child: const Text('Login'),
          ),
      ],
    );
  }
}

class _GuestNavItem {
  const _GuestNavItem({
    required this.key,
    required this.label,
    required this.icon,
  });

  final String key;
  final String label;
  final IconData icon;
}

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({required this.isGuest, this.onBrandTap});

  final bool isGuest;
  final VoidCallback? onBrandTap;

  @override
  Widget build(BuildContext context) {
    final Widget brand = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const LogoWidget(size: 32),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Job For All',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.indigo,
              ),
            ),
            Text(
              isGuest ? 'Find work. Hire talent.' : RoleUtils.currentRole,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );

    if (onBrandTap == null) {
      return brand;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onBrandTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: brand,
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.refreshKey, required this.onPressed});

  final int refreshKey;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      key: ValueKey<int>(refreshKey),
      future: NotificationService.instance.fetchUnreadCount(),
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        final int unreadCount = snapshot.data ?? 0;

        return Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            IconButton(
              tooltip: 'Notifications',
              onPressed: onPressed,
              icon: const Icon(Icons.notifications_outlined),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({
    required this.label,
    required this.icon,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color primary = AppColors.indigo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? primary : Colors.transparent),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: selected ? primary : Colors.black54, size: 20),
              if (!compact || selected) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? primary : Colors.black87,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
