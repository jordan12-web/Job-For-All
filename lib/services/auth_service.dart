import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../pages/admin_dashboard.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../utils/debug_logger.dart';
import '../utils/role_utils.dart';

/// Result wrapper for auth operations.
class AuthResult {
  const AuthResult({
    required this.success,
    this.profile,
    this.message,
    this.routeName,
    this.routeArguments,
    this.needsEmailConfirmation = false,
  });

  final bool success;
  final UserProfile? profile;
  final String? message;
  final String? routeName;
  final Object? routeArguments;
  final bool needsEmailConfirmation;

  factory AuthResult.failure(String message) {
    return AuthResult(success: false, message: message);
  }

  factory AuthResult.success({
    required UserProfile profile,
    required String routeName,
    Object? routeArguments,
    String? message,
    bool needsEmailConfirmation = false,
  }) {
    return AuthResult(
      success: true,
      profile: profile,
      routeName: routeName,
      routeArguments: routeArguments,
      message: message,
      needsEmailConfirmation: needsEmailConfirmation,
    );
  }
}

/// Supabase authentication and `users` table integration.
///
/// A DB trigger inserts into `users` on auth signup (default role: seeker).
/// This service updates name and the user-selected role after signup.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const String usersTable = 'users';
  static const Set<String> allowedSignupRoles = <String>{'seeker', 'employer'};

  SupabaseClient get _client => Supabase.instance.client;

  static Future<void> initialize() async {
    DebugLogger.step('Loading .env file...');
    await dotenv.load(fileName: '.env');
    DebugLogger.success('.env loaded');

    final String? url = dotenv.env['SUPABASE_URL'];
    final String? anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty || anonKey == null || anonKey.isEmpty) {
      DebugLogger.error('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
      throw Exception(
        'Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env',
      );
    }

    DebugLogger.info('SUPABASE_URL: $url');
    DebugLogger.info('SUPABASE_ANON_KEY: ${anonKey.substring(0, 20)}...');
    
    DebugLogger.step('Initializing Supabase client...');
    await Supabase.initialize(url: url, anonKey: anonKey);
    DebugLogger.success('Supabase client initialized');
  }

  bool get isAuthenticated => _client.auth.currentSession != null;

  Future<UserProfile?> tryRestoreSession() async {
    DebugLogger.step('Attempting to restore session...');
    
    final Session? session = _client.auth.currentSession;
    if (session == null) {
      DebugLogger.warning('No active session found');
      RoleUtils.clearSession();
      return null;
    }

    final User user = session.user;
    if (user.id.isEmpty) {
      DebugLogger.warning('Session user ID is empty');
      RoleUtils.clearSession();
      return null;
    }

    DebugLogger.info('Session found for user: ${user.id}');
    
    final UserProfile? profile = await _fetchUserProfile(user.id);
    if (profile == null) {
      DebugLogger.error('Profile not found for user: ${user.id}');
      await signOut();
      return null;
    }

    DebugLogger.success('Profile restored: ${profile.email} (role: ${profile.role})');
    RoleUtils.setSession(profile: profile);
    return profile;
  }

  String dbRoleFromDisplay(String displayRole) {
    if (displayRole == RoleUtils.employer) {
      return 'employer';
    }
    return 'seeker';
  }

  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String name,
    required String displayRole,
  }) async {
    final String trimmedEmail = email.trim().toLowerCase();
    final String trimmedName = name.trim();
    final String dbRole = dbRoleFromDisplay(displayRole);

    DebugLogger.step('Starting signup for: $trimmedEmail (role: $dbRole)');

    if (!allowedSignupRoles.contains(dbRole)) {
      DebugLogger.warning('Invalid role attempted: $dbRole');
      return AuthResult.failure(
        'Invalid role. Only job seekers and employers can register.',
      );
    }

    if (trimmedName.isEmpty) {
      DebugLogger.warning('Name is empty');
      return AuthResult.failure('Full name is required.');
    }

    if (trimmedEmail.isEmpty) {
      DebugLogger.warning('Email is empty');
      return AuthResult.failure('Email is required.');
    }

    try {
      DebugLogger.info('Signup metadata being sent: {name: "$trimmedName"}');
      
      final AuthResponse response = await _client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: <String, dynamic>{'name': trimmedName},
      );

      final User? user = response.user;
      if (user == null || user.id.isEmpty) {
        DebugLogger.error('Signup did not return a user');
        return AuthResult.failure(
          'Signup did not return a user. Please try again.',
        );
      }

      DebugLogger.info('Signup successful for user: ${user.id}');
      DebugLogger.info('User metadata: ${user.userMetadata}');
      DebugLogger.info('User email verified: ${user.emailConfirmedAt}');

      final Session? session = response.session;

      if (session == null) {
        DebugLogger.info('Email confirmation required');
        return AuthResult(
          success: true,
          message:
              'Account created. Confirm your email, then sign in to finish setup.',
          routeName: LoginPage.routeName,
          needsEmailConfirmation: true,
        );
      }

      final UserProfile? existing = await _waitForUserProfile(user.id);
      if (existing == null) {
        DebugLogger.error('Profile not created after signup');
        return AuthResult.failure(
          'Your account was created but your profile is not ready yet. '
          'Wait a moment and sign in.',
        );
      }

      final UserProfile? updated = await _updateUserProfile(
        userId: user.id,
        name: trimmedName,
        role: dbRole,
        email: trimmedEmail,
      );

      if (updated == null) {
        DebugLogger.error('Failed to update user profile');
        return AuthResult.failure(
          'Could not save your role and name. Please sign in and contact support if this continues.',
        );
      }

      DebugLogger.success('Signup complete for: $trimmedEmail');
      RoleUtils.setSession(profile: updated);

      return AuthResult.success(
        profile: updated,
        routeName: dashboardRouteForRole(updated.role),
        routeArguments: dashboardArgumentsForRole(updated.role),
        message: 'Welcome, ${updated.name}!',
      );
    } on AuthException catch (e) {
      DebugLogger.error('Auth error during signup: ${e.message}');
      DebugLogger.error('Auth error code: ${e.statusCode}');
      DebugLogger.error('Full error: $e');
      return AuthResult.failure(_mapAuthError(e));
    } on PostgrestException catch (e) {
      DebugLogger.error('Database error during signup: ${e.message}');
      DebugLogger.error('Database error code: ${e.code}');
      DebugLogger.error('Full error: $e');
      return AuthResult.failure(_mapPostgrestError(e));
    } catch (e, stackTrace) {
      DebugLogger.error('Unexpected error during signup: $e', stackTrace);
      return AuthResult.failure('Signup failed. Please try again.');
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final String trimmedEmail = email.trim();

    DebugLogger.step('Starting signin for: $trimmedEmail');

    if (trimmedEmail.isEmpty) {
      DebugLogger.warning('Email is empty');
      return AuthResult.failure('Email is required.');
    }

    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );

      final User? user = response.user;
      if (user == null || user.id.isEmpty) {
        DebugLogger.error('Login failed: No user returned');
        return AuthResult.failure('Login failed. No user returned from server.');
      }

      DebugLogger.info('Signin successful for user: ${user.id}');

      final UserProfile? profile = await _fetchUserProfile(user.id);
      if (profile == null) {
        DebugLogger.error('Profile not found for user: ${user.id}');
        return AuthResult.failure(
          'Signed in, but no profile was found. '
          'An administrator may need to complete your account setup.',
        );
      }

      DebugLogger.success('Signin complete for: ${profile.email}');
      RoleUtils.setSession(profile: profile);

      final String welcomeName =
          profile.name.isNotEmpty ? profile.name : 'there';

      return AuthResult.success(
        profile: profile,
        routeName: dashboardRouteForRole(profile.role),
        routeArguments: dashboardArgumentsForRole(profile.role),
        message: 'Welcome back, $welcomeName!',
      );
    } on AuthException catch (e) {
      DebugLogger.error('Auth error during signin: ${e.message}');
      return AuthResult.failure(_mapAuthError(e));
    } on PostgrestException catch (e) {
      DebugLogger.error('Database error during signin: ${e.message}');
      return AuthResult.failure(_mapPostgrestError(e));
    } catch (e) {
      DebugLogger.error('Unexpected error during signin: $e');
      return AuthResult.failure('Login failed. Please try again.');
    }
  }

  Future<void> signOut() async {
    DebugLogger.step('Signing out...');
    try {
      await _client.auth.signOut();
      DebugLogger.success('Signout complete');
    } catch (e) {
      DebugLogger.error('Error during signout: $e');
    } finally {
      RoleUtils.clearSession();
      DebugLogger.info('Session cleared');
    }
  }

  Future<UserProfile?> _fetchUserProfile(String userId) async {
    if (userId.isEmpty) {
      DebugLogger.warning('Attempting to fetch profile for empty user ID');
      return null;
    }

    try {
      DebugLogger.step('Fetching profile for user: $userId');
      final Map<String, dynamic>? row = await _client
          .from(usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (row == null) {
        DebugLogger.warning('No profile found in database for user: $userId');
        return null;
      }

      DebugLogger.info('Profile row fetched: $row');
      final UserProfile? profile = UserProfile.tryFromMap(row);
      if (profile == null) {
        DebugLogger.error('Failed to parse profile row: $row');
      } else {
        DebugLogger.success('Profile parsed successfully: ${profile.email}');
      }
      return profile;
    } on PostgrestException catch (e) {
      DebugLogger.error('Database error fetching profile: ${e.message}');
      DebugLogger.error('Error code: ${e.code}');
      return null;
    }
  }

  Future<UserProfile?> _waitForUserProfile(
    String userId, {
    int maxAttempts = 8,
  }) async {
    DebugLogger.step('Waiting for profile to be created (max $maxAttempts attempts)...');
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final UserProfile? profile = await _fetchUserProfile(userId);
      if (profile != null) {
        DebugLogger.success('Profile found on attempt ${attempt + 1}');
        return profile;
      }
      final int waitMs = 250 * (attempt + 1);
      DebugLogger.info('Attempt ${attempt + 1} failed, waiting ${waitMs}ms before retry...');
      await Future<void>.delayed(Duration(milliseconds: waitMs));
    }
    DebugLogger.error('Profile not created after $maxAttempts attempts');
    return null;
  }

  Future<UserProfile?> _updateUserProfile({
    required String userId,
    required String name,
    required String role,
    required String email,
  }) async {
    if (userId.isEmpty) {
      DebugLogger.warning('Cannot update profile: empty user ID');
      return null;
    }

    if (!allowedSignupRoles.contains(role)) {
      DebugLogger.warning('Cannot update profile: invalid role: $role');
      return null;
    }

    try {
      DebugLogger.step('Updating profile for user: $userId');
      DebugLogger.info('Update data: {name: "$name", role: "$role", email: "$email"}');
      
      final List<Map<String, dynamic>> rows = await _client
          .from(usersTable)
          .update(<String, dynamic>{
            'name': name,
            'role': role,
            'email': email,
          })
          .eq('id', userId)
          .select();

      if (rows.isEmpty) {
        DebugLogger.warning('Update returned no rows, refetching profile...');
        return await _fetchUserProfile(userId);
      }

      DebugLogger.success('Profile updated successfully');
      final UserProfile? updated = UserProfile.tryFromMap(rows.first);
      if (updated != null) {
        DebugLogger.info('Updated profile: ${updated.email} (role: ${updated.role})');
      }
      return updated;
    } on PostgrestException catch (e) {
      DebugLogger.error('Error updating profile: ${e.message}');
      DebugLogger.error('Error code: ${e.code}');
      return null;
    }
  }

  String dashboardRouteForRole(String dbRole) {
    switch (dbRole) {
      case 'admin':
        return AdminDashboard.routeName;
      case 'employer':
        return HomePage.routeName;
      case 'seeker':
      default:
        return HomePage.routeName;
    }
  }

  Object? dashboardArgumentsForRole(String dbRole) {
    switch (dbRole) {
      case 'admin':
        return null;
      case 'employer':
        return const HomePageArgs(initialTabKey: 'home');
      case 'seeker':
      default:
        return const HomePageArgs(initialTabKey: 'jobs');
    }
  }

  String _mapAuthError(AuthException e) {
    final String message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (message.contains('user already registered') ||
        message.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('password')) {
      return 'Password does not meet requirements.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email before signing in.';
    }
    return e.message.isNotEmpty ? e.message : 'Authentication failed.';
  }

  String _mapPostgrestError(PostgrestException e) {
    if (e.code == '23505') {
      return 'A profile for this account already exists.';
    }
    if (e.code == '42501') {
      return 'Permission denied. Check Supabase RLS policies for the users table.';
    }
    return e.message.isNotEmpty ? e.message : 'Database error. Please try again.';
  }
}

/// Arguments for [HomePage] role-based landing tab.
class HomePageArgs {
  const HomePageArgs({required this.initialTabKey});

  final String initialTabKey;
}
