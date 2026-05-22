import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

Future<void> main() async {
  DebugLogger.log('═════════════════════════════════════════');
  DebugLogger.log('🚀 STARTING JOB FOR ALL APP');
  DebugLogger.log('═════════════════════════════════════════');
  
  try {
    DebugLogger.step('Ensuring Flutter bindings...');
    WidgetsFlutterBinding.ensureInitialized();
    DebugLogger.success('Flutter bindings initialized');
    
    DebugLogger.step('Loading .env file...');
    await dotenv.load(fileName: '.env');
    DebugLogger.success('.env loaded successfully');
    
    DebugLogger.step('Initializing Supabase...');
    await AuthService.initialize();
    DebugLogger.success('Supabase initialized successfully');
    DebugLogger.info('Supabase URL: ${dotenv.env['SUPABASE_URL']}');
    DebugLogger.info('Supabase client initialized: ${Supabase.instance.client.toString()}');
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
      
      // Check if session is null
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
      
      // Try to restore the user profile
      final UserProfile? profile = await AuthService.instance.tryRestoreSession();
      final String sessionInfo = profile != null 
        ? 'YES (${profile.email} - ${profile.role})'
        : 'NO (null)';
      DebugLogger.lifecycle('Session restored: $sessionInfo');
      
      if (!mounted) {
        DebugLogger.warning('Widget no longer mounted, skipping setState');
        return;
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
          _errorMessage = 'Error: ${e.toString()}';
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
    DebugLogger.ui('JobForAllApp.build() - isBootstrapping=$_isBootstrapping, isLoggedIn=$_isLoggedIn');
    
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
                const Text('App Initialization Error'),
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

    DebugLogger.target('Routing to: ${_isLoggedIn ? HomePage.routeName : LandingPage.routeName}');
    
    return MaterialApp(
      title: 'Job For All',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      initialRoute: _isLoggedIn ? HomePage.routeName : LandingPage.routeName,
      onGenerateRoute: _onGenerateRoute,
      routes: <String, WidgetBuilder>{
        LandingPage.routeName: (_) {
          DebugLogger.routing('Routing to LandingPage');
          return const LandingPage();
        },
        LoginPage.routeName: (_) {
          DebugLogger.routing('Routing to LoginPage');
          return LoginPage(onLoginSuccess: () => _updateLoginStatus(true));
        },
        SignupPage.routeName: (_) {
          DebugLogger.routing('Routing to SignupPage');
          return SignupPage(
            onAuthSuccess: () => _updateLoginStatus(true),
          );
        },
        HomePage.routeName: (_) {
          DebugLogger.routing('Routing to HomePage');
          return HomePage(
            onLogout: () => _updateLoginStatus(false),
          );
        },
        JobSeekerProfile.routeName: (_) => const JobSeekerProfile(),
        EmployerProfile.routeName: (_) => const EmployerProfile(),
        JobPostingPage.routeName: (_) => const JobPostingPage(),
        JobListingPage.routeName: (_) => const JobListingPage(),
        ApplicantsPage.routeName: (_) => const ApplicantsPage(),
        AdminDashboard.routeName: (_) => const AdminDashboard(),
        PaymentPage.routeName: (_) => const PaymentPage(),
        UssdSimulationPage.routeName: (_) => const UssdSimulationPage(),
        BlogPage.routeName: (_) => const BlogPage(),
        PrivacyPage.routeName: (_) => const PrivacyPage(),
      },
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final Object? args = settings.arguments;

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

    return null;
  }
}
