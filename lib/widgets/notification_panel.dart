import 'package:flutter/material.dart';

import '../services/notification_service.dart';

/// Dropdown-style notification list with modern styling.
class NotificationPanel extends StatefulWidget {
  const NotificationPanel({super.key, this.onNotificationsChanged});

  final VoidCallback? onNotificationsChanged;

  @override
  State<NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<NotificationPanel> {
  late Future<List<UserNotification>> _future;

  @override
  void initState() {
    super.initState();
    _future = NotificationService.instance.fetchMyNotifications();
  }

  void _refresh() {
    setState(() {
      _future = NotificationService.instance.fetchMyNotifications();
    });
    widget.onNotificationsChanged?.call();
  }

  Future<void> _markAllRead() async {
    await NotificationService.instance.markAllRead();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF4C63FF);

    return FutureBuilder<List<UserNotification>>(
      future: _future,
      builder:
          (
            BuildContext context,
            AsyncSnapshot<List<UserNotification>> snapshot,
          ) {
            final List<UserNotification> notifications =
                snapshot.data ?? <UserNotification>[];
            final int unreadCount = notifications
                .where((UserNotification notification) => !notification.isRead)
                .length;
            final bool isLoading =
                snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData;

            return Material(
              elevation: 12,
              shadowColor: Colors.black26,
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              child: Container(
                width: 380,
                constraints: const BoxConstraints(maxHeight: 440),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.06),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.notifications_active_outlined,
                              color: accent,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Notifications',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  unreadCount == 0
                                      ? 'You are all caught up'
                                      : '$unreadCount unread',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: notifications.isEmpty
                                ? null
                                : _markAllRead,
                            child: const Text('Mark all read'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (notifications.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 24,
                        ),
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No notifications yet',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Job matches and updates will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: notifications.length,
                          separatorBuilder: (BuildContext context, int index) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (BuildContext context, int index) {
                            final UserNotification notification =
                                notifications[index];

                            return _NotificationTile(
                              notification: notification,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification});

  final UserNotification notification;

  @override
  Widget build(BuildContext context) {
    const Color accent = Color(0xFF4C63FF);
    final bool unread = !notification.isRead;

    return Material(
      color: unread ? accent.withValues(alpha: 0.04) : Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: unread
                    ? accent.withValues(alpha: 0.12)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                unread ? Icons.auto_awesome : Icons.notifications_none_outlined,
                color: unread ? accent : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: unread
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (unread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: TextStyle(
                      color: Colors.grey[700],
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatDate(notification.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final DateTime local = value.toLocal();
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${local.year}-${twoDigits(local.month)}-${twoDigits(local.day)}';
  }
}
