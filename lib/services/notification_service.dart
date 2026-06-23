import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/debug_logger.dart';

class UserNotification {
  const UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    return UserNotification(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'Notification',
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }
}

/// Persists employer-to-seeker notifications in `public.notifications`.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _table = 'notifications';

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<UserNotification>> fetchMyNotifications() async {
    final String? userId = _client.auth.currentSession?.user.id;
    if (userId == null || userId.isEmpty) {
      return <UserNotification>[];
    }

    try {
      final List<dynamic> data = await _client
          .from(_table)
          .select('id, title, message, type, is_read, created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return data
          .map(
            (dynamic item) =>
                UserNotification.fromMap(item as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      DebugLogger.error(
        'fetchMyNotifications failed: ${e.message} | ${e.code}',
      );
      return <UserNotification>[];
    } catch (e) {
      DebugLogger.error('fetchMyNotifications unexpected error: $e');
      return <UserNotification>[];
    }
  }

  Future<int> fetchUnreadCount() async {
    final List<UserNotification> notifications = await fetchMyNotifications();
    return notifications.where((UserNotification item) => !item.isRead).length;
  }

  Future<bool> markAllRead() async {
    final String? userId = _client.auth.currentSession?.user.id;
    if (userId == null || userId.isEmpty) {
      return false;
    }

    try {
      await _client
          .from(_table)
          .update(<String, dynamic>{'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      return true;
    } on PostgrestException catch (e) {
      DebugLogger.error('markAllRead failed: ${e.message} | ${e.code}');
      return false;
    } catch (e) {
      DebugLogger.error('markAllRead unexpected error: $e');
      return false;
    }
  }

  /// Notifies a job seeker they have been shortlisted for an interview.
  Future<bool> scheduleInterview({
    required String seekerId,
    required String applicationId,
    required String jobTitle,
    String? employerName,
  }) async {
    if (seekerId.isEmpty || applicationId.isEmpty) {
      DebugLogger.warning(
        'scheduleInterview: missing seekerId or applicationId',
      );
      return false;
    }

    final String company = employerName ?? 'An employer';
    final String message =
        '$company has shortlisted you for an interview regarding "$jobTitle". '
        'Please check your email for next steps.';

    DebugLogger.step(
      'NotificationService.scheduleInterview: seeker=$seekerId app=$applicationId',
    );

    try {
      await _client.from(_table).insert(<String, dynamic>{
        'user_id': seekerId,
        'type': 'interview_scheduled',
        'title': 'Interview Scheduled',
        'message': message,
        'is_read': false,
      });

      DebugLogger.success('Interview notification sent to seeker=$seekerId');
      return true;
    } on PostgrestException catch (e) {
      DebugLogger.error('scheduleInterview failed: ${e.message} | ${e.code}');
      return false;
    } catch (e) {
      DebugLogger.error('scheduleInterview unexpected error: $e');
      return false;
    }
  }
}
