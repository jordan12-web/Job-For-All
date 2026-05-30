import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/job.dart';
import '../utils/debug_logger.dart';

/// Service for fetching and managing jobs from Supabase 'public.jobs' table
class JobService {
  JobService._();

  static final JobService instance = JobService._();

  static const String jobsTable = 'jobs';

  SupabaseClient get _client => Supabase.instance.client;

  /// Fetch all approved jobs from the database
  /// Returns a list of Job objects with status = 'Approved'
  Future<List<Job>> fetchApprovedJobs() async {
    try {
      DebugLogger.step('Fetching approved jobs from $jobsTable');

      final List<dynamic> data = await _client
          .from(jobsTable)
          .select()
          .eq('status', 'Approved')
          .order('created_at', ascending: false);

      DebugLogger.info('Fetched ${data.length} approved jobs');

      final List<Job> jobs = (data as List<dynamic>)
          .map((dynamic item) => Job.fromMap(item as Map<String, dynamic>))
          .toList();

      DebugLogger.success('Successfully parsed jobs. Count: ${jobs.length}');
      return jobs;
    } on PostgrestException catch (e) {
      DebugLogger.error('PostgrestException: ${e.message} | code: ${e.code}');
      throw Exception('Failed to fetch jobs: ${e.message}');
    } catch (e) {
      DebugLogger.error('Unexpected error fetching jobs: $e');
      throw Exception('Failed to fetch jobs: ${e.toString()}');
    }
  }

  /// Fetch a single job by ID
  Future<Job?> fetchJobById(String jobId) async {
    try {
      DebugLogger.step('Fetching job: $jobId');

      final Map<String, dynamic>? data = await _client
          .from(jobsTable)
          .select()
          .eq('id', jobId)
          .maybeSingle();

      if (data == null) {
        DebugLogger.warning('Job not found: $jobId');
        return null;
      }

      final Job job = Job.fromMap(data);
      DebugLogger.success('Fetched job: ${job.title}');
      return job;
    } on PostgrestException catch (e) {
      DebugLogger.error('PostgrestException: ${e.message}');
      throw Exception('Failed to fetch job: ${e.message}');
    } catch (e) {
      DebugLogger.error('Unexpected error fetching job: $e');
      throw Exception('Failed to fetch job: ${e.toString()}');
    }
  }

  /// Fetch jobs by employer ID
  Future<List<Job>> fetchJobsByEmployer(String employerId) async {
    try {
      DebugLogger.step('Fetching jobs for employer: $employerId');

      final List<dynamic> data = await _client
          .from(jobsTable)
          .select()
          .eq('employer_id', employerId)
          .order('created_at', ascending: false);

      DebugLogger.info('Fetched ${data.length} jobs for employer');

      final List<Job> jobs = (data as List<dynamic>)
          .map((dynamic item) => Job.fromMap(item as Map<String, dynamic>))
          .toList();

      DebugLogger.success('Successfully parsed employer jobs. Count: ${jobs.length}');
      return jobs;
    } on PostgrestException catch (e) {
      DebugLogger.error('PostgrestException: ${e.message}');
      throw Exception('Failed to fetch employer jobs: ${e.message}');
    } catch (e) {
      DebugLogger.error('Unexpected error fetching employer jobs: $e');
      throw Exception('Failed to fetch employer jobs: ${e.toString()}');
    }
  }

  /// Search approved jobs by keyword (title, description, requirements, company, location)
  Future<List<Job>> searchJobs(String keyword) async {
    if (keyword.trim().isEmpty) {
      return fetchApprovedJobs();
    }

    try {
      DebugLogger.step('Searching jobs with keyword: $keyword');

      // First fetch all approved jobs, then filter locally
      // (Supabase full-text search requires additional setup)
      final List<Job> jobs = await fetchApprovedJobs();

      final String lowerKeyword = keyword.toLowerCase();
      final List<Job> filtered = jobs
          .where((Job job) =>
              job.title.toLowerCase().contains(lowerKeyword) ||
              job.description.toLowerCase().contains(lowerKeyword) ||
              job.requirements.toLowerCase().contains(lowerKeyword) ||
              (job.company?.toLowerCase().contains(lowerKeyword) ?? false) ||
              (job.location?.toLowerCase().contains(lowerKeyword) ?? false))
          .toList();

      DebugLogger.success('Search returned ${filtered.length} jobs');
      return filtered;
    } catch (e) {
      DebugLogger.error('Error searching jobs: $e');
      rethrow;
    }
  }

  /// Filter approved jobs by location and type
  Future<List<Job>> filterJobs({
    String? location,
    String? type,
  }) async {
    try {
      DebugLogger.step('Filtering jobs - location: $location, type: $type');

      final List<Job> jobs = await fetchApprovedJobs();

      final List<Job> filtered = jobs.where((Job job) {
        final bool matchesLocation =
            location == null || location == 'All' || job.location == location;
        final bool matchesType =
            type == null || type == 'All' || job.type == type;
        return matchesLocation && matchesType;
      }).toList();

      DebugLogger.success('Filter returned ${filtered.length} jobs');
      return filtered;
    } catch (e) {
      DebugLogger.error('Error filtering jobs: $e');
      rethrow;
    }
  }
}
