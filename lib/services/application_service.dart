import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application.dart';
import '../utils/debug_logger.dart';

/// Result wrapper returned by [ApplicationService.apply].
/// Keeps the calling widget simple — it just checks [status].
enum ApplyStatus {
  success,
  alreadyApplied,
  notLoggedIn,
  error,
}

class ApplyResult {
  const ApplyResult({required this.status, this.message});

  final ApplyStatus status;
  final String? message;

  bool get isSuccess => status == ApplyStatus.success;
}

/// Handles all reads and writes to `public.applications`.
class ApplicationService {
  ApplicationService._();

  static final ApplicationService instance = ApplicationService._();

  static const String _table = 'applications';

  SupabaseClient get _client => Supabase.instance.client;

  /// Submits a job application for the currently logged-in seeker.
  ///
  /// Returns [ApplyStatus.success] on insert.
  /// Returns [ApplyStatus.alreadyApplied] if the UNIQUE(job_id, seeker_id)
  /// constraint fires (Postgres error code 23505).
  /// Returns [ApplyStatus.notLoggedIn] if no active session exists.
  /// Returns [ApplyStatus.error] for any other failure.
  Future<ApplyResult> apply({
    required String jobId,
    String? cvUrl,
  }) async {
    // ── Guard: must be logged in ─────────────────────────────
    final String? seekerId = _client.auth.currentSession?.user.id;

    if (seekerId == null || seekerId.isEmpty) {
      DebugLogger.warning('ApplicationService.apply: no active session');
      return const ApplyResult(
        status: ApplyStatus.notLoggedIn,
        message: 'You must be signed in to apply.',
      );
    }

    DebugLogger.step(
      'ApplicationService.apply: seekerId=$seekerId jobId=$jobId',
    );

    try {
      await _client.from(_table).insert(<String, dynamic>{
        'job_id': jobId,
        'seeker_id': seekerId,
        'status': 'pending',
        if (cvUrl != null && cvUrl.isNotEmpty) 'cv_url': cvUrl,
      });

      DebugLogger.success(
        'Application submitted: seekerId=$seekerId jobId=$jobId',
      );

      return const ApplyResult(
        status: ApplyStatus.success,
        message: 'Application submitted successfully!',
      );
    } on PostgrestException catch (e) {
      DebugLogger.error(
        'PostgrestException in apply: ${e.message} | code: ${e.code}',
      );

      // Postgres unique violation — seeker already applied to this job
      if (e.code == '23505') {
        return const ApplyResult(
          status: ApplyStatus.alreadyApplied,
          message: 'You have already applied for this job.',
        );
      }

      return ApplyResult(
        status: ApplyStatus.error,
        message: 'Could not submit application: ${e.message}',
      );
    } catch (e) {
      DebugLogger.error('Unexpected error in apply: $e');
      return const ApplyResult(
        status: ApplyStatus.error,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Returns true if the current seeker has already applied to [jobId].
  /// Used to disable the Apply button pre-emptively.
  Future<bool> hasApplied({required String jobId}) async {
    final String? seekerId = _client.auth.currentSession?.user.id;
    if (seekerId == null || seekerId.isEmpty) {
      return false;
    }

    try {
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select('id')
          .eq('job_id', jobId)
          .eq('seeker_id', seekerId)
          .maybeSingle();

      return row != null;
    } catch (e) {
      DebugLogger.error('hasApplied check failed: $e');
      return false;
    }
  }

  /// Fetches all applications for the currently logged-in seeker.
  Future<List<Application>> fetchMyApplications() async {
    final String? seekerId = _client.auth.currentSession?.user.id;
    if (seekerId == null || seekerId.isEmpty) {
      return <Application>[];
    }

    try {
      final List<dynamic> data = await _client
          .from(_table)
          .select()
          .eq('seeker_id', seekerId)
          .order('created_at', ascending: false);

      return data
          .map((dynamic item) =>
              Application.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      DebugLogger.error('fetchMyApplications failed: ${e.message}');
      return <Application>[];
    }
  }
}