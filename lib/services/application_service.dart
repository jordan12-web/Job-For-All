import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/application.dart';
import '../utils/debug_logger.dart';

/// Result wrapper returned by [ApplicationService.apply].
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

  // ── Seeker methods ─────────────────────────────────────────────────────────

  /// Submits a job application for the currently logged-in seeker.
  /// Handles the UNIQUE(job_id, seeker_id) constraint gracefully.
  Future<ApplyResult> apply({
    required String jobId,
    String? cvUrl,
  }) async {
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
        'job_id':    jobId,
        'seeker_id': seekerId,
        'status':    'pending',
        if (cvUrl != null && cvUrl.isNotEmpty) 'cv_url': cvUrl,
      });

      DebugLogger.success('Application inserted: jobId=$jobId');
      return const ApplyResult(
        status: ApplyStatus.success,
        message: 'Application submitted successfully!',
      );
    } on PostgrestException catch (e) {
      DebugLogger.error('apply PostgrestException: ${e.message} | ${e.code}');
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
      DebugLogger.error('apply unexpected error: $e');
      return const ApplyResult(
        status: ApplyStatus.error,
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  /// Returns true if the current seeker has already applied to [jobId].
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

  /// Returns all applications submitted by the current seeker,
  /// with the job title joined in.
  Future<List<Application>> fetchMyApplications() async {
    final String? seekerId = _client.auth.currentSession?.user.id;
    if (seekerId == null || seekerId.isEmpty) {
      return <Application>[];
    }
    try {
      final List<dynamic> data = await _client
          .from(_table)
          .select('*, jobs(title)')
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

  // ── Employer methods ───────────────────────────────────────────────────────

  /// Fetches all applications for every job posted by [employerId].
  ///
  /// Uses a nested join:
  ///   applications → jobs (to filter by employer_id and get title)
  ///   applications → users (to get seeker name and email)
  ///
  /// Returns newest applications first.
  Future<List<Application>> fetchApplicationsForEmployer(
    String employerId,
  ) async {
    if (employerId.isEmpty) {
      DebugLogger.warning('fetchApplicationsForEmployer: empty employerId');
      return <Application>[];
    }

    DebugLogger.step(
      'fetchApplicationsForEmployer: employerId=$employerId',
    );

    try {
      // Select application columns + join jobs (filter + title) + join users
      // Use jobs!inner to enforce the employer_id filter at the DB level.
      // The join syntax jobs!applications_job_id_fkey ensures PostgREST
      // uses the correct FK path when multiple FKs exist.
      final List<dynamic> data = await _client
          .from(_table)
          .select('*, jobs!inner(id, title, employer_id), users(name, email)')
          .eq('jobs.employer_id', employerId)
          .order('created_at', ascending: false);

      DebugLogger.info('fetchApplicationsForEmployer: ${data.length} rows');

      return data
          .map((dynamic item) =>
              Application.fromMap(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      DebugLogger.error(
        'fetchApplicationsForEmployer failed: ${e.message} | ${e.code}',
      );
      throw Exception('Failed to fetch applications: ${e.message}');
    } catch (e) {
      DebugLogger.error('fetchApplicationsForEmployer unexpected error: $e');
      throw Exception('Failed to fetch applications: $e');
    }
  }

  /// Returns the number of applications submitted for a single [jobId].
  /// Used by the Recruitment Hub's "My Postings" list to show an
  /// applicant counter next to each job without fetching full rows.
  Future<int> countApplicationsForJob(String jobId) async {
    if (jobId.isEmpty) {
      return 0;
    }
    try {
      final List<dynamic> data = await _client
          .from(_table)
          .select('id')
          .eq('job_id', jobId);
      return data.length;
    } on PostgrestException catch (e) {
      DebugLogger.error('countApplicationsForJob failed: ${e.message}');
      return 0;
    }
  }

  /// Returns applicant counts for multiple jobs in one round trip.
  /// More efficient than calling [countApplicationsForJob] in a loop
  /// when rendering a full "My Postings" list.
  Future<Map<String, int>> countApplicationsForJobs(
    List<String> jobIds,
  ) async {
    if (jobIds.isEmpty) {
      return <String, int>{};
    }
    try {
      final List<dynamic> data = await _client
          .from(_table)
          .select('job_id')
          .inFilter('job_id', jobIds);

      final Map<String, int> counts = <String, int>{
        for (final String id in jobIds) id: 0,
      };
      for (final dynamic row in data) {
        final String jobId = (row as Map<String, dynamic>)['job_id'] as String;
        counts[jobId] = (counts[jobId] ?? 0) + 1;
      }
      return counts;
    } on PostgrestException catch (e) {
      DebugLogger.error('countApplicationsForJobs failed: ${e.message}');
      return <String, int>{for (final String id in jobIds) id: 0};
    }
  }

  /// Updates an application's status to 'accepted' or 'rejected'.
  ///
  /// Only the employer who owns the job can do this (enforced by RLS).
  /// Returns true on success, false on failure.
  Future<bool> updateApplicationStatus({
    required String applicationId,
    required String status,
  }) async {
    if (!<String>{'accepted', 'rejected'}.contains(status)) {
      DebugLogger.error(
        'updateApplicationStatus: invalid status "$status"',
      );
      return false;
    }

    DebugLogger.step(
      'updateApplicationStatus: id=$applicationId status=$status',
    );

    try {
      await _client
          .from(_table)
          .update(<String, dynamic>{'status': status})
          .eq('id', applicationId);

      DebugLogger.success(
        'Application $applicationId updated to "$status"',
      );
      return true;
    } on PostgrestException catch (e) {
      DebugLogger.error(
        'updateApplicationStatus failed: ${e.message} | ${e.code}',
      );
      return false;
    } catch (e) {
      DebugLogger.error('updateApplicationStatus unexpected error: $e');
      return false;
    }
  }
}