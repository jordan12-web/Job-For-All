import 'package:flutter/material.dart';

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
import 'theme/app_theme.dart';
import 'utils/role_utils.dart';

void main() {
  RoleUtils.ensureDemoAccounts();
  runApp(const JobForAllApp());
}

class JobForAllApp extends StatefulWidget {
  const JobForAllApp({super.key});

  @override
  State<JobForAllApp> createState() => _JobForAllAppState();
}

class _JobForAllAppState extends State<JobForAllApp> {
  bool _isLoggedIn = false;

  void _updateLoginStatus(bool value) {
    setState(() => _isLoggedIn = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Job For All',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      initialRoute: _isLoggedIn ? HomePage.routeName : LandingPage.routeName,
      routes: <String, WidgetBuilder>{
        LandingPage.routeName: (_) => const LandingPage(),
        LoginPage.routeName: (_) =>
            LoginPage(onLoginSuccess: () => _updateLoginStatus(true)),
        SignupPage.routeName: (_) => const SignupPage(),
        HomePage.routeName: (_) =>
            HomePage(onLogout: () => _updateLoginStatus(false)),
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
}
