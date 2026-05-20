class MockApplicationStore {
  MockApplicationStore._();

  // In-memory applications act as a mock database for the employer view.
  static final List<Map<String, String>> applications = <Map<String, String>>[];

  static void addApplication({
    required String jobTitle,
    required String company,
    required String applicantName,
    required String contact,
    required String source,
    required String summary,
  }) {
    applications.add(<String, String>{
      'jobTitle': jobTitle,
      'company': company,
      'applicantName': applicantName,
      'contact': contact,
      'source': source,
      'summary': summary,
    });
  }
}
