import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/debug_logger.dart';

/// Persists employer-to-seeker notifications in `public.notifications`.
class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _table = 'notifications';

  SupabaseClient get _client => Supabase.instance.client;

  /// Notifies a job seeker they have been shortlisted for an interview.
  Future<bool> scheduleInterview({
    required String seekerId,
    required String applicationId,
    required String jobTitle,
    String? employerName,
  }) async {
    if (seekerId.isEmpty || applicationId.isEmpty) {
      DebugLogger.warning('scheduleInterview: missing seekerId or applicationId');
      return false;
    }

    final String? employerId = _client.auth.currentSession?.user.id;
    final String company = employerName ?? 'An employer';
    final String message =
        '$company has shortlisted you for an interview regarding "$jobTitle". '
        'Please check your email for next steps.';

    DebugLogger.step(
      'NotificationService.scheduleInterview: seeker=$seekerId app=$applicationId',
    );

    try {
      await _client.from(_table).insert(<String, dynamic>{
        'user_id':        seekerId,
        'application_id': applicationId,
        'type':           'interview_scheduled',
        'title':          'Interview Scheduled',
        'message':        message,
        'read':           false,
        'created_by':     ?employerId,
      });

      DebugLogger.success('Interview notification sent to seeker=$seekerId');
      return true;
    } on PostgrestException catch (e) {
      DebugLogger.error(
        'scheduleInterview failed: ${e.message} | ${e.code}',
      );
      return false;
    } catch (e) {
      DebugLogger.error('scheduleInterview unexpected error: $e');
      return false;
    }
  }
}
