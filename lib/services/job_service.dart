import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/job.dart';
import '../utils/debug_logger.dart';

/// Service for all reads and writes to `public.jobs`.
class JobService {
  JobService._();

  static final JobService instance = JobService._();

  static const String jobsTable = 'jobs';

  SupabaseClient get _client => Supabase.instance.client;

  // ── Public / Seeker ────────────────────────────────────────────────────────

  /// Fetches all jobs with status = 'Approved', newest first.
  Future<List<Job>> fetchApprovedJobs() async {
    try {
      DebugLogger.step('fetchApprovedJobs');
      final List<dynamic> data = await _client
          .from(jobsTable)
          .select()
          .eq('status', 'Approved')
          .order('created_at', ascending: false);
      DebugLogger.success('fetchApprovedJobs: ${data.length} jobs');
      return data
          .map((dynamic i) => Job.fromMap(i as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      DebugLogger.error('fetchApprovedJobs: ${e.message}');
      throw Exception('Failed to fetch jobs: ${e.message}');
    } catch (e) {
      DebugLogger.error('fetchApprovedJobs unexpected: $e');
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  /// Fetches a single job by [jobId]. Returns null if not found.
  Future<Job?> fetchJobById(String jobId) async {
    try {
      DebugLogger.step('fetchJobById: $jobId');
      final Map<String, dynamic>? data = await _client
          .from(jobsTable)
          .select()
          .eq('id', jobId)
          .maybeSingle();
      if (data == null) {
        DebugLogger.warning('fetchJobById: not found $jobId');
        return null;
      }
      return Job.fromMap(data);
    } on PostgrestException catch (e) {
      DebugLogger.error('fetchJobById: ${e.message}');
      throw Exception('Failed to fetch job: ${e.message}');
    }
  }

  // ── Employer ───────────────────────────────────────────────────────────────

  /// Fetches all jobs posted by [employerId], newest first.
  Future<List<Job>> fetchJobsByEmployer(String employerId) async {
    try {
      DebugLogger.step('fetchJobsByEmployer: $employerId');
      final List<dynamic> data = await _client
          .from(jobsTable)
          .select()
          .eq('employer_id', employerId)
          .order('created_at', ascending: false);
      return data
          .map((dynamic i) => Job.fromMap(i as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      DebugLogger.error('fetchJobsByEmployer: ${e.message}');
      throw Exception('Failed to fetch employer jobs: ${e.message}');
    }
  }

  /// Inserts a new job into `public.jobs`.
  ///
  /// - `employer_id` is read from the active session — never from the UI.
  /// - `status` is always set to `'Pending'` regardless of input.
  Future<Job> createJob({
    required String title,
    required String company,
    required String location,
    required String type,
    required String description,
    required String requirements,
  }) async {
    final String? employerId = _client.auth.currentSession?.user.id;
    if (employerId == null || employerId.isEmpty) {
      throw Exception('You must be signed in to post a job.');
    }

    DebugLogger.step('createJob: employerId=$employerId title=$title');

    try {
      final List<dynamic> result = await _client
          .from(jobsTable)
          .insert(<String, dynamic>{
            'employer_id':  employerId,
            'title':        title.trim(),
            'company':      company.trim(),
            'location':     location.trim(),
            'type':         type,
            'description':  description.trim(),
            'requirements': requirements.trim(),
            'status':       'Pending',
          })
          .select();

      if (result.isEmpty) {
        throw Exception('Insert returned no data.');
      }

      final Job job = Job.fromMap(result.first as Map<String, dynamic>);
      DebugLogger.success('createJob: ${job.id} — ${job.title}');
      return job;
    } on PostgrestException catch (e) {
      DebugLogger.error('createJob: ${e.message} | ${e.code}');
      throw Exception('Failed to post job: ${e.message}');
    } catch (e) {
      DebugLogger.error('createJob unexpected: $e');
      rethrow;
    }
  }

  // ── Admin ──────────────────────────────────────────────────────────────────

  /// Fetches all jobs with status = 'Pending', newest first.
  /// Used by the Admin moderation dashboard.
  Future<List<Job>> fetchPendingJobs() async {
    try {
      DebugLogger.step('fetchPendingJobs');
      final List<dynamic> data = await _client
          .from(jobsTable)
          .select()
          .eq('status', 'Pending')
          .order('created_at', ascending: false);
      DebugLogger.success('fetchPendingJobs: ${data.length} jobs');
      return data
          .map((dynamic i) => Job.fromMap(i as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      DebugLogger.error('fetchPendingJobs: ${e.message}');
      throw Exception('Failed to fetch pending jobs: ${e.message}');
    } catch (e) {
      DebugLogger.error('fetchPendingJobs unexpected: $e');
      throw Exception('Failed to fetch pending jobs: $e');
    }
  }

  /// Updates a job's status to `'Approved'` or `'Rejected'`.
  /// Returns true on success, false on failure.
  /// RLS policy `jobs_update_admin` enforces admin-only access.
  Future<bool> updateJobStatus({
    required String jobId,
    required String status,
  }) async {
    if (!<String>{'Approved', 'Rejected'}.contains(status)) {
      DebugLogger.error('updateJobStatus: invalid status "$status"');
      return false;
    }

    DebugLogger.step('updateJobStatus: $jobId → $status');

    try {
      await _client
          .from(jobsTable)
          .update(<String, dynamic>{'status': status})
          .eq('id', jobId);

      DebugLogger.success('updateJobStatus: $jobId → $status');
      return true;
    } on PostgrestException catch (e) {
      DebugLogger.error('updateJobStatus: ${e.message} | ${e.code}');
      return false;
    } catch (e) {
      DebugLogger.error('updateJobStatus unexpected: $e');
      return false;
    }
  }

  // ── Search / Filter (client-side) ──────────────────────────────────────────

  Future<List<Job>> searchJobs(String keyword) async {
    if (keyword.trim().isEmpty) {
      return fetchApprovedJobs();
    }
    final List<Job> jobs = await fetchApprovedJobs();
    final String kw = keyword.toLowerCase();
    return jobs
        .where((Job j) =>
            j.title.toLowerCase().contains(kw) ||
            j.description.toLowerCase().contains(kw) ||
            j.requirements.toLowerCase().contains(kw) ||
            (j.company?.toLowerCase().contains(kw) ?? false) ||
            (j.location?.toLowerCase().contains(kw) ?? false))
        .toList();
  }

  Future<List<Job>> filterJobs({String? location, String? type}) async {
    final List<Job> jobs = await fetchApprovedJobs();
    return jobs.where((Job j) {
      final bool loc = location == null || location == 'All' || j.location == location;
      final bool typ = type == null || type == 'All' || j.type == type;
      return loc && typ;
    }).toList();
  }
}