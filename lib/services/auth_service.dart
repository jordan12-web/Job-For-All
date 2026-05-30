import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../pages/admin_dashboard.dart';
import '../pages/employer_profile.dart';
import '../pages/job_listing_page.dart';
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
      throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY in .env');
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
    final UserProfile? profile = await _fetchUserProfile(
      user.id,
      accessToken: session.accessToken,
    );

    if (profile == null) {
      DebugLogger.error('Profile not found during session restore: ${user.id}');
      await signOut();
      return null;
    }

    DebugLogger.success('Session restored: ${profile.email} (${profile.role})');
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
    String? companyName,
    String? contactInfo,
  }) async {
    final String trimmedEmail = email.trim().toLowerCase();
    final String trimmedName = name.trim();
    final String dbRole = dbRoleFromDisplay(displayRole);

    DebugLogger.step('Starting signup: $trimmedEmail (role: $dbRole)');

    if (!allowedSignupRoles.contains(dbRole)) {
      return AuthResult.failure(
        'Invalid role. Only job seekers and employers can register.',
      );
    }
    if (trimmedName.isEmpty) {
      return AuthResult.failure('Full name is required.');
    }
    if (trimmedEmail.isEmpty) {
      return AuthResult.failure('Email is required.');
    }
    if (dbRole == 'employer') {
      if ((companyName ?? '').trim().isEmpty) {
        return AuthResult.failure('Company name is required for employers.');
      }
      if ((contactInfo ?? '').trim().isEmpty) {
        return AuthResult.failure(
          'Contact information is required for employers.',
        );
      }
    }

    try {
      final Map<String, dynamic> metadata = <String, dynamic>{
        'name': trimmedName,
        'role': dbRole,
        if (dbRole == 'employer') 'company_name': (companyName ?? '').trim(),
        if (dbRole == 'employer') 'contact_info': (contactInfo ?? '').trim(),
      };

      DebugLogger.info('Signup metadata: $metadata');

      final AuthResponse response = await _client.auth.signUp(
        email: trimmedEmail,
        password: password,
        data: metadata,
      );

      final User? user = response.user;
      if (user == null || user.id.isEmpty) {
        return AuthResult.failure(
          'Signup did not return a user. Please try again.',
        );
      }

      DebugLogger.info('Signup auth OK: ${user.id}');
      DebugLogger.info('Metadata confirmed: ${user.userMetadata}');

      // Email confirmation is ON — no session yet, send to login
      if (response.session == null) {
        DebugLogger.info('Email confirmation required');
        return AuthResult(
          success: true,
          message:
              'Account created! Please check your email to verify, then sign in.',
          routeName: LoginPage.routeName,
          needsEmailConfirmation: true,
        );
      }

      // Email confirmation is OFF — session exists, wait for trigger
      DebugLogger.info(
        'Session exists — waiting for trigger to create profile...',
      );
      final UserProfile? profile = await _waitForUserProfile(user.id);

      if (profile == null) {
        return AuthResult.failure(
          'Account created but profile setup is pending. Please sign in.',
        );
      }

      DebugLogger.success(
        'Signup complete: ${profile.email} (${profile.role})',
      );
      RoleUtils.setSession(profile: profile);

      return AuthResult.success(
        profile: profile,
        routeName: dashboardRouteForRole(profile.role),
        message: 'Welcome, ${profile.name}!',
      );
    } on AuthException catch (e) {
      DebugLogger.error('Auth error: ${e.message}');
      return AuthResult.failure(_mapAuthError(e));
    } on PostgrestException catch (e) {
      DebugLogger.error('DB error: ${e.message} (${e.code})');
      return AuthResult.failure(_mapPostgrestError(e));
    } catch (e, s) {
      DebugLogger.error('Unexpected signup error: $e', s);
      return AuthResult.failure('Signup failed. Please try again.');
    }
  }

  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final String trimmedEmail = email.trim();
    DebugLogger.step('Starting signin: $trimmedEmail');

    if (trimmedEmail.isEmpty) {
      return AuthResult.failure('Email is required.');
    }

    try {
      final AuthResponse response = await _client.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );

      final User? user = response.user;
      if (user == null || user.id.isEmpty) {
        return AuthResult.failure(
          'Login failed. No user returned from server.',
        );
      }

      if (response.session == null) {
        return AuthResult.failure(
          'Login failed. No session returned from server.',
        );
      }

      final String accessToken = response.session!.accessToken;
      DebugLogger.info('Auth OK: ${user.id}');
      DebugLogger.info('Access token obtained: ${accessToken.substring(0, 20)}...');
      DebugLogger.step('Fetching profile with explicit token...');

      final UserProfile? profile = await _fetchUserProfile(
        user.id,
        accessToken: accessToken,
      );

      if (profile == null) {
        DebugLogger.error('No profile row found for: ${user.id}');
        return AuthResult.failure(
          'Signed in, but no profile was found. '
          'An administrator may need to complete your account setup.',
        );
      }

      DebugLogger.success('Profile: ${profile.email} (${profile.role})');
      RoleUtils.setSession(profile: profile);

      return AuthResult.success(
        profile: profile,
        routeName: dashboardRouteForRole(profile.role),
        routeArguments: dashboardArgumentsForRole(profile.role),
        message:
            'Welcome back, ${profile.name.isNotEmpty ? profile.name : 'there'}!',
      );
    } on AuthException catch (e) {
      DebugLogger.error('Auth error: ${e.message}');
      return AuthResult.failure(_mapAuthError(e));
    } on PostgrestException catch (e) {
      DebugLogger.error('DB error: ${e.message} (${e.code})');
      return AuthResult.failure(_mapPostgrestError(e));
    } catch (e) {
      DebugLogger.error('Unexpected signin error: $e');
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
    }
  }

  // ── Private helpers ────────────────────────────────────────

  Future<UserProfile?> _fetchUserProfile(
    String userId, {
    String? accessToken,
  }) async {
    if (userId.isEmpty) {
      DebugLogger.warning('Empty userId passed to _fetchUserProfile');
      return null;
    }

    // Use provided token or fall back to current session token.
    // Passing the token explicitly in the Authorization header guarantees
    // RLS can resolve auth.uid() on Flutter Web, where the internal HTTP
    // client may not have propagated the new session yet.
    final String? token =
        accessToken ?? _client.auth.currentSession?.accessToken;

    try {
      DebugLogger.step('DB fetch: users WHERE id=$userId');
      final String tokenPreview = token != null ? '${token.substring(0, 20)}...' : 'NULL — RLS will block!';
      DebugLogger.info('Using token: $tokenPreview');

      final Map<String, dynamic>? row = await _client
          .from(usersTable)
          .select('id, email, name, role')
          .eq('id', userId)
          .maybeSingle();

      // If the above still returns null due to Web header timing,
      // retry once using a raw HTTP fetch with explicit Authorization header
      if (row == null && token != null) {
        DebugLogger.warning('First attempt null — retrying with explicit auth header...');
        return await _fetchUserProfileWithToken(userId, token);
      }

      if (row == null) {
        DebugLogger.warning('maybeSingle() returned null for id=$userId');
        return null;
      }

      DebugLogger.info('Raw row: $row');
      final UserProfile? profile = UserProfile.tryFromMap(row);
      if (profile == null) {
        DebugLogger.error('tryFromMap failed for row: $row');
      } else {
        DebugLogger.success('Parsed: ${profile.email} (${profile.role})');
      }
      return profile;
    } on PostgrestException catch (e) {
      DebugLogger.error(
        'PostgrestException: ${e.message} | code: ${e.code} | hint: ${e.hint}',
      );
      return null;
    }
  }

  /// Fallback fetch using a fresh SupabaseClient with the token
  /// injected directly — bypasses any internal session-state timing issue.
  Future<UserProfile?> _fetchUserProfileWithToken(
    String userId,
    String token,
  ) async {
    try {
      DebugLogger.step('Fallback fetch with explicit token for: $userId');

      // Use dotenv values (already loaded) to create a one-shot client
      // with the Bearer token baked into its default headers.
      final String url = dotenv.env['SUPABASE_URL'] ?? '';
      final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

      if (url.isEmpty || anonKey.isEmpty) {
        DebugLogger.error('Cannot create fallback client: missing env vars');
        return null;
      }

      final SupabaseClient tokenClient = SupabaseClient(
        url,
        anonKey,
        headers: <String, String>{'Authorization': 'Bearer $token'},
      );

      final Map<String, dynamic>? row = await tokenClient
          .from(usersTable)
          .select('id, email, name, role')
          .eq('id', userId)
          .maybeSingle();

      await tokenClient.dispose();

      if (row == null) {
        DebugLogger.error('Fallback fetch also returned null — RLS or missing row');
        return null;
      }

      DebugLogger.success('Fallback fetch succeeded: $row');
      return UserProfile.tryFromMap(row);
    } on PostgrestException catch (e) {
      DebugLogger.error('Fallback fetch PostgrestException: ${e.message}');
      return null;
    } catch (e) {
      DebugLogger.error('Fallback fetch unexpected error: $e');
      return null;
    }
  }

  Future<UserProfile?> _waitForUserProfile(
    String userId, {
    int maxAttempts = 8,
  }) async {
    DebugLogger.step(
      'Waiting for trigger to write profile (max $maxAttempts)...',
    );
    for (int i = 0; i < maxAttempts; i++) {
      final UserProfile? p = await _fetchUserProfile(userId);
      if (p != null) {
        DebugLogger.success('Profile ready on attempt ${i + 1}');
        return p;
      }
      final int ms = 300 * (i + 1);
      DebugLogger.info('Attempt ${i + 1}: not ready, waiting ${ms}ms...');
      await Future<void>.delayed(Duration(milliseconds: ms));
    }
    DebugLogger.error('Profile never appeared after $maxAttempts attempts');
    return null;
  }

  String dashboardRouteForRole(String dbRole) {
    final String route = switch (dbRole) {
      'admin' => AdminDashboard.routeName,
      'employer' => EmployerProfile.routeName,
      _ => JobListingPage.routeName,
    };
    DebugLogger.info('Route for "$dbRole": $route');
    return route;
  }

  Object? dashboardArgumentsForRole(String dbRole) => null;

  String _mapAuthError(AuthException e) {
    final String msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return 'Invalid email or password.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'An account with this email already exists.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Please verify your email before signing in.';
    }
    if (msg.contains('password')) {
      return 'Password does not meet requirements.';
    }
    return e.message.isNotEmpty ? e.message : 'Authentication failed.';
  }

  String _mapPostgrestError(PostgrestException e) {
    if (e.code == '23505') {
      return 'A profile for this account already exists.';
    }
    if (e.code == '42501') {
      return 'Permission denied. Check Supabase RLS policies.';
    }
    return e.message.isNotEmpty
        ? e.message
        : 'Database error. Please try again.';
  }
}

/// Arguments for [HomePage] role-based landing tab.
class HomePageArgs {
  const HomePageArgs({required this.initialTabKey});
  final String initialTabKey;
}