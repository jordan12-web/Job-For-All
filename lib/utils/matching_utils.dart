class MatchingUtils {
  MatchingUtils._();

  static List<String> keywordsFromText(String value) {
    return value
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9+#]+'))
        .map((String keyword) => keyword.trim())
        .where((String keyword) => keyword.length >= 2)
        .toSet()
        .toList();
  }

  // Rule-based matching: a job matches when any seeker skill appears in the
  // requirements, description, or title text.
  static bool isJobMatch({
    required String seekerSkills,
    required Map<String, String> job,
  }) {
    final List<String> skills = keywordsFromText(seekerSkills);
    if (skills.isEmpty) {
      return false;
    }

    final String searchableJobText = <String>[
      job['title'] ?? '',
      job['description'] ?? '',
      job['requirements'] ?? '',
    ].join(' ').toLowerCase();

    return skills.any((String skill) => searchableJobText.contains(skill));
  }

  static List<Map<String, String>> matchedJobs({
    required String seekerSkills,
    required List<Map<String, String>> jobs,
  }) {
    return jobs.where((Map<String, String> job) {
      final String status = job['status'] ?? 'Pending';
      return status != 'Rejected' &&
          isJobMatch(seekerSkills: seekerSkills, job: job);
    }).toList();
  }
}
