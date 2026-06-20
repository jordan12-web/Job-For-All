import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/employer_profile.dart';
import '../utils/debug_logger.dart';

/// Service for all reads/writes to `public.employers`.
///
/// Kept separate from JobService and ApplicationService to preserve
/// modularity — the Subscription Hub and Pricing/Payment pages depend
/// only on this service and pricing_plan.dart, never on job logic.
class EmployerService {
  EmployerService._();

  static final EmployerService instance = EmployerService._();

  static const String _table = 'employers';

  SupabaseClient get _client => Supabase.instance.client;

  /// Fetches the employer profile for the currently signed-in user.
  /// Returns null if no row exists yet (shouldn't normally happen —
  /// the signup trigger creates one — but handled defensively).
  Future<EmployerProfile?> fetchMyProfile() async {
    final String? employerId = _client.auth.currentSession?.user.id;
    if (employerId == null || employerId.isEmpty) {
      DebugLogger.warning('fetchMyProfile: no active session');
      return null;
    }

    try {
      DebugLogger.step('fetchMyProfile: employerId=$employerId');
      final Map<String, dynamic>? row = await _client
          .from(_table)
          .select()
          .eq('id', employerId)
          .maybeSingle();

      if (row == null) {
        DebugLogger.warning('fetchMyProfile: no row for $employerId');
        return null;
      }

      return EmployerProfile.fromMap(row);
    } on PostgrestException catch (e) {
      DebugLogger.error('fetchMyProfile: ${e.message}');
      throw Exception('Failed to load employer profile: ${e.message}');
    }
  }

  /// Updates the employer's company info AND business registration number.
  ///
  /// IMPORTANT: per the verification workflow, saving a registration
  /// number always resets `is_verified` to false. This signals to the
  /// Admin that a (re-)verification request is pending. There is no
  /// client-side way to set is_verified — only the Admin can do that
  /// via [setVerified], which is enforced by RLS (employers_update_admin).
  Future<EmployerProfile> updateProfile({
    required String companyName,
    required String contactInfo,
    String? businessRegistrationNumber,
  }) async {
    final String? employerId = _client.auth.currentSession?.user.id;
    if (employerId == null || employerId.isEmpty) {
      throw Exception('You must be signed in to update your profile.');
    }

    DebugLogger.step('updateProfile: employerId=$employerId');

    try {
      final List<dynamic> result = await _client
          .from(_table)
          .update(<String, dynamic>{
            'company_name': companyName.trim(),
            'contact_info': contactInfo.trim(),
            'business_registration_number':
                (businessRegistrationNumber ?? '').trim().isEmpty
                ? null
                : businessRegistrationNumber!.trim(),
            // Any profile save (re-)triggers verification review.
            // This is intentional: a changed registration number should
            // always be re-checked by an admin before being trusted.
            'is_verified': false,
          })
          .eq('id', employerId)
          .select();

      if (result.isEmpty) {
        throw Exception('Update returned no data.');
      }

      final EmployerProfile profile = EmployerProfile.fromMap(
        result.first as Map<String, dynamic>,
      );
      DebugLogger.success('updateProfile: saved, is_verified reset to false');
      return profile;
    } on PostgrestException catch (e) {
      DebugLogger.error('updateProfile: ${e.message} | ${e.code}');
      throw Exception('Failed to save profile: ${e.message}');
    }
  }

  /// Updates only the subscription plan — called after a successful
  /// payment in the gatekeeper flow. Does NOT touch is_verified.
  Future<bool> setSubscriptionPlan(String planId) async {
    final String? employerId = _client.auth.currentSession?.user.id;
    if (employerId == null || employerId.isEmpty) {
      DebugLogger.error('setSubscriptionPlan: no active session');
      return false;
    }

    try {
      await _client
          .from(_table)
          .update(<String, dynamic>{'subscription_plan': planId})
          .eq('id', employerId);
      DebugLogger.success('setSubscriptionPlan: $employerId → $planId');
      return true;
    } on PostgrestException catch (e) {
      DebugLogger.error('setSubscriptionPlan: ${e.message}');
      return false;
    }
  }

  // ── Admin methods ─────────────────────────────────────────────────────────

  /// Fetches all employers with a non-empty registration number that
  /// are still unverified — the Admin's verification queue.
  /// RLS policy employers_select_admin enforces admin-only access.
  Future<List<EmployerProfile>> fetchPendingVerifications() async {
    try {
      DebugLogger.step('fetchPendingVerifications');
      final List<dynamic> data = await _client
          .from(_table)
          .select('*, users(name, email)')
          .eq('is_verified', false)
          .not('business_registration_number', 'is', null)
          .order('created_at', ascending: false);

      return data
          .map(
            (dynamic i) => EmployerProfile.fromMap(i as Map<String, dynamic>),
          )
          .toList();
    } on PostgrestException catch (e) {
      DebugLogger.error('fetchPendingVerifications: ${e.message}');
      throw Exception('Failed to fetch verification queue: ${e.message}');
    }
  }

  /// Admin action: marks an employer as verified.
  /// RLS policy employers_update_admin enforces admin-only access.
  Future<bool> setVerified({
    required String employerId,
    required bool verified,
  }) async {
    try {
      await _client
          .from(_table)
          .update(<String, dynamic>{'is_verified': verified})
          .eq('id', employerId);
      DebugLogger.success('setVerified: $employerId → $verified');
      return true;
    } on PostgrestException catch (e) {
      DebugLogger.error('setVerified: ${e.message}');
      return false;
    }
  }
}
