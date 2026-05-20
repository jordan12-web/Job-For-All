class MockProfileStore {
  MockProfileStore._();

  // In-memory maps act as a mock database until real persistence is introduced.
  static final Map<String, String> jobSeekerProfile = <String, String>{};
  static final Map<String, String> employerProfile = <String, String>{};

  static void saveJobSeekerProfile({
    required String name,
    required String contact,
    required String skills,
    required String education,
    required String verificationDocument,
  }) {
    final String verified = jobSeekerProfile['Verified'] ?? 'false';
    final String flagged = jobSeekerProfile['Flagged'] ?? 'false';

    jobSeekerProfile
      ..clear()
      ..addAll(<String, String>{
        'Name': name,
        'Contact': contact,
        'Skills': skills,
        'Education': education,
        'Verification Document': verificationDocument,
        'Verified': verified,
        'Flagged': flagged,
      });
  }

  static void markJobSeekerVerified() {
    if (jobSeekerProfile.isEmpty) {
      return;
    }
    jobSeekerProfile['Verified'] = 'true';
  }

  static void flagJobSeekerAccount() {
    if (jobSeekerProfile.isEmpty) {
      return;
    }
    jobSeekerProfile['Flagged'] = 'true';
  }

  static void saveEmployerProfile({
    required String companyName,
    required String contact,
    required String description,
  }) {
    final String flagged = employerProfile['Flagged'] ?? 'false';

    employerProfile
      ..clear()
      ..addAll(<String, String>{
        'Company Name': companyName,
        'Contact': contact,
        'Description': description,
        'Flagged': flagged,
      });
  }

  static void flagEmployerAccount() {
    if (employerProfile.isEmpty) {
      return;
    }
    employerProfile['Flagged'] = 'true';
  }
}
