import 'package:flutter/material.dart';

import '../data/info_content.dart';
import '../theme/app_colors.dart';
import '../utils/debug_logger.dart';
import '../widgets/about_section.dart';
import '../widgets/contact_section.dart';
import '../widgets/hero_section_premium.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/job_preview_section.dart';
import '../widgets/landing_footer.dart';
import '../widgets/top_nav_bar.dart';
import 'blog_page.dart';
import 'job_listing_page.dart';
import 'login_page.dart';
import 'privacy_page.dart';
import 'signup_page.dart';
import 'static_info_page.dart';

/// Public landing page with scrollable sections and working navigation.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  static const String routeName = '/landing';

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _jobsKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  String _activeSection = 'home';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateTo(String route) {
    Navigator.of(context).pushNamed(route);
  }

  void _scrollToTop() {
    if (!_scrollController.hasClients) {
      return;
    }
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  void _scrollToKey(GlobalKey key, String section) {
    setState(() => _activeSection = section);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final BuildContext? target = key.currentContext;
      if (target == null || !target.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        target,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.05,
      );
    });
  }

  void _onGuestNavigate(String section) {
    switch (section) {
      case 'home':
        setState(() => _activeSection = 'home');
        _scrollToTop();
      case 'jobs':
        _scrollToKey(_jobsKey, 'jobs');
      case 'about':
        _scrollToKey(_aboutKey, 'about');
      case 'howItWorks':
        _scrollToKey(_howItWorksKey, 'howItWorks');
      case 'contact':
        _scrollToKey(_contactKey, 'contact');
      case 'browseJobs':
        _navigateTo(JobListingPage.routeName);
      case 'profile':
        _navigateTo(LoginPage.routeName);
    }
  }

  void _openStaticPage(String link) {
    switch (link) {
      case 'Blog':
        _navigateTo(BlogPage.routeName);
      case 'Privacy Policy':
        _navigateTo(PrivacyPage.routeName);
      default:
        final InfoPageData? data = StaticInfoPage.dataForLink(link);
        if (data == null) {
          return;
        }
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => StaticInfoPage(data: data),
          ),
        );
    }
  }

  void _onFooterLink(String link) {
    switch (link) {
      case 'About':
        _onGuestNavigate('about');
      case 'Contact':
        _onGuestNavigate('contact');
      default:
        _openStaticPage(link);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      DebugLogger.page('LandingPage.build() - Building UI with sections');
      return Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: <Widget>[
            TopNavBar(
              isGuestMode: true,
              guestSelectedSection: _activeSection,
              onGuestNavigate: _onGuestNavigate,
              onSignIn: () => _navigateTo(LoginPage.routeName),
              onRegister: () => _navigateTo(SignupPage.routeName),
            ),
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      KeyedSubtree(
                        key: _heroKey,
                        child: PremiumHeroSection(
                          onBrowseJobs: () => _scrollToKey(_jobsKey, 'jobs'),
                          onGetStarted: () => _navigateTo(SignupPage.routeName),
                        ),
                      ),
                      KeyedSubtree(
                        key: _jobsKey,
                        child: JobPreviewSection(
                          onViewAllJobs: () => _navigateTo(JobListingPage.routeName),
                        ),
                      ),
                      KeyedSubtree(
                        key: _aboutKey,
                        child: const AboutSection(),
                      ),
                      KeyedSubtree(
                        key: _howItWorksKey,
                        child: const HowItWorksSection(),
                      ),
                      KeyedSubtree(
                        key: _contactKey,
                        child: const ContactSection(),
                      ),
                      LandingFooter(onLinkTap: _onFooterLink),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      DebugLogger.error('ERROR building LandingPage: $e', stackTrace);
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error Building Landing Page'),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
