import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models/user_profile.dart';
import 'pages/admin_dashboard.dart';
import 'pages/applicants_page.dart';
import 'pages/blog_page.dart';
import 'pages/employer_profile.dart';
import 'pages/home_page.dart';
import 'pages/job_listing_page.dart';
import 'pages/job_posting_page.dart';
import 'pages/job_seeker_profile.dart';
import 'pages/landing_page.dart';
import 'pages/login_page.dart';
import 'pages/payment_page.dart';
import 'pages/privacy_page.dart';
import 'pages/signup_page.dart';
import 'pages/ussd_simulation.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'utils/debug_logger.dart';
import 'utils/role_utils.dart';

Future<void> main() async {
  DebugLogger.log('═════════════════════════════════════════');
  DebugLogger.log('🚀 STARTING JOB FOR ALL APP');
  DebugLogger.log('═════════════════════════════════════════');

  try {
    DebugLogger.step('Ensuring Flutter bindings...');
    WidgetsFlutterBinding.ensureInitialized();
    DebugLogger.success('Flutter bindings initialized');

    // AuthService.initialize() loads .env AND initializes Supabase.
    // Do NOT call dotenv.load() here — that would load it twice and crash.
    DebugLogger.step('Initializing Supabase via AuthService...');
    await AuthService.initialize();
    DebugLogger.success('Supabase initialized successfully');
    DebugLogger.info(
      'Supabase client ready: ${Supabase.instance.client.toString()}',
    );
  } catch (e) {
    DebugLogger.error('FATAL ERROR during initialization: $e');
    rethrow;
  }

  DebugLogger.step('Starting app...');
  runApp(const JobForAllApp());
  DebugLogger.success('App widget created');
}

class JobForAllApp extends StatefulWidget {
  const JobForAllApp({super.key});

  @override
  State<JobForAllApp> createState() => _JobForAllAppState();
}

class _JobForAllAppState extends State<JobForAllApp> {
  bool _isLoggedIn = false;
  bool _isBootstrapping = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    DebugLogger.lifecycle('JobForAllApp.initState called');
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    DebugLogger.log('🚀 _bootstrap() started');

    try {
      final Session? session = Supabase.instance.client.auth.currentSession;
      DebugLogger.info('Current session: ${session?.user.id ?? 'null'}');

      if (session == null || session.user.id.isEmpty) {
        DebugLogger.warning('No active session found, routing to LandingPage');
        if (!mounted) {
          DebugLogger.warning('Widget no longer mounted, skipping setState');
          return;
        }
        setState(() {
          _isLoggedIn = false;
          _isBootstrapping = false;
          _errorMessage = '';
        });
        return;
      }

      final UserProfile? profile = await AuthService.instance
          .tryRestoreSession();
      final String sessionInfo = profile != null
          ? 'YES (${profile.email} - ${profile.role})'
          : 'NO (null)';
      DebugLogger.lifecycle('Session restored: $sessionInfo');

      if (!mounted) {
        DebugLogger.warning('Widget no longer mounted, skipping setState');
        return;
      }

      // CRITICAL: Set RoleUtils BEFORE setState so HomePage can access the role/tabs
      if (profile != null) {
        DebugLogger.info('Setting RoleUtils from profile: role=${profile.role}');
        RoleUtils.setSession(profile: profile);
      }

      setState(() {
        _isLoggedIn = profile != null;
        _isBootstrapping = false;
        _errorMessage = '';
      });

      DebugLogger.success('Bootstrap complete. Logged in: $_isLoggedIn');
    } catch (e, stackTrace) {
      DebugLogger.error('Bootstrap error: $e', stackTrace);

      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isBootstrapping = false;
          _errorMessage = 'Startup error: ${e.toString()}';
        });
      }
    }
  }

  void _updateLoginStatus(bool value) {
    DebugLogger.session('Login status changed to: $value');
    setState(() => _isLoggedIn = value);
  }

  @override
  Widget build(BuildContext context) {
    DebugLogger.ui(
      'JobForAllApp.build() - isBootstrapping=$_isBootstrapping, isLoggedIn=$_isLoggedIn',
    );

    if (_isBootstrapping) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                const Text('Initializing app...'),
                if (_errorMessage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    DebugLogger.target(
      'Routing to: ${_isLoggedIn ? 'HomePage' : 'LandingPage'}',
    );

    // Use home: instead of initialRoute to avoid Flutter Web URL conflicts.
    // When the browser reloads, Flutter Web tries to match the current URL
    // against initialRoute — if it doesn't match a named route exactly,
    // the framework crashes. Using home: bypasses URL-based routing entirely
    // and always renders the correct widget based on session state.
    return MaterialApp(
      title: 'Job For All',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: _isLoggedIn
          ? HomePage(onLogout: () => _updateLoginStatus(false))
          : const LandingPage(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final Object? args = settings.arguments;

    DebugLogger.routing('onGenerateRoute: ${settings.name}');

    if (settings.name == HomePage.routeName) {
      final String? tabKey = args is HomePageArgs ? args.initialTabKey : null;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => HomePage(
          onLogout: () => _updateLoginStatus(false),
          initialTabKey: tabKey,
        ),
      );
    }

    if (settings.name == LandingPage.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const LandingPage());
    }

    if (settings.name == LoginPage.routeName) {
      return MaterialPageRoute<void>(
        builder: (_) =>
            LoginPage(onLoginSuccess: () => _updateLoginStatus(true)),
      );
    }

    if (settings.name == SignupPage.routeName) {
      return MaterialPageRoute<void>(
        builder: (_) =>
            SignupPage(onAuthSuccess: () => _updateLoginStatus(true)),
      );
    }

    if (settings.name == JobSeekerProfile.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const JobSeekerProfile());
    }

    if (settings.name == EmployerProfile.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const EmployerProfile());
    }

    if (settings.name == JobPostingPage.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const JobPostingPage());
    }

    if (settings.name == JobListingPage.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const JobListingPage());
    }

    if (settings.name == ApplicantsPage.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const ApplicantsPage());
    }

    if (settings.name == AdminDashboard.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const AdminDashboard());
    }

    if (settings.name == PaymentPage.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const PaymentPage());
    }

    if (settings.name == UssdSimulationPage.routeName) {
      return MaterialPageRoute<void>(
        builder: (_) => const UssdSimulationPage(),
      );
    }

    if (settings.name == BlogPage.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const BlogPage());
    }

    if (settings.name == PrivacyPage.routeName) {
      return MaterialPageRoute<void>(builder: (_) => const PrivacyPage());
    }

    // Unknown route — always safe fallback
    DebugLogger.warning(
      'Unknown route "${settings.name}" — showing LandingPage',
    );
    return MaterialPageRoute<void>(builder: (_) => const LandingPage());
  }
}
