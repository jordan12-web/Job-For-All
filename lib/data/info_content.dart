/// Static copy for footer and info pages.
class InfoContent {
  InfoContent._();

  static const Map<String, InfoPageData> pages = <String, InfoPageData>{
    'Blog': InfoPageData(
      title: 'Blog',
      subtitle: 'Stories from Ethiopia\'s job market',
      body:
          'Our blog shares hiring tips, success stories from job seekers and employers, '
          'and updates on new features like USSD job search and verified credentials.\n\n'
          'New articles are published regularly. Check back soon for the latest posts.',
    ),
    'Careers': InfoPageData(
      title: 'Careers at Job For All',
      subtitle: 'Help us connect talent with opportunity',
      body:
          'We are building Ethiopia\'s most trusted job marketplace. We look for people who care '
          'about local access, trust, and inclusive hiring.\n\n'
          'Open roles will be listed here as we grow. Send your CV to careers@jobforall.et '
          'if you would like to be considered for future openings.',
    ),
    'Help Center': InfoPageData(
      title: 'Help Center',
      subtitle: 'Answers to common questions',
      body:
          '• How do I create an account? Tap Register on the home page and choose Job Seeker or Employer.\n\n'
          '• Can I use USSD? Yes — dial our USSD code from any phone to browse jobs without data.\n\n'
          '• How are credentials verified? Our team reviews education and experience documents before profiles go live.\n\n'
          '• Payment issues? Visit the Payment page after login or contact support below.',
    ),
    'Report Issue': InfoPageData(
      title: 'Report an Issue',
      subtitle: 'We take safety and trust seriously',
      body:
          'If you see suspicious listings, harassment, or payment problems, report them to '
          'support@jobforall.et with the job title and any screenshots.\n\n'
          'For urgent safety concerns, include your phone number so our team can reach you quickly.',
    ),
    'Privacy Policy': InfoPageData(
      title: 'Privacy Policy',
      subtitle: 'How we handle your data',
      body:
          'Job For All collects only the information needed to match job seekers with employers: '
          'profile details, contact information, and application history.\n\n'
          'We do not sell personal data. Data is stored securely and used only to operate the platform. '
          'You may request deletion of your account by contacting support@jobforall.et.',
    ),
    'Terms of Service': InfoPageData(
      title: 'Terms of Service',
      subtitle: 'Rules for using Job For All',
      body:
          'By using Job For All you agree to provide accurate profile information, respect other users, '
          'and use the platform only for legitimate hiring or job seeking.\n\n'
          'Employers must post real opportunities. Job seekers must apply in good faith. '
          'We may suspend accounts that violate these terms.',
    ),
    'Cookie Policy': InfoPageData(
      title: 'Cookie Policy',
      subtitle: 'Web and app usage data',
      body:
          'Our web app may use local storage and session data to keep you signed in and remember preferences.\n\n'
          'We use minimal analytics to improve performance. You can clear site data in your browser settings at any time.',
    ),
  };
}

class InfoPageData {
  const InfoPageData({
    required this.title,
    required this.subtitle,
    required this.body,
  });

  final String title;
  final String subtitle;
  final String body;
}
