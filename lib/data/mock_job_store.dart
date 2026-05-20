import 'mock_notification_store.dart';

class MockJobStore {
  MockJobStore._();

  static final List<Map<String, String>> jobs = <Map<String, String>>[
    <String, String>{
      'title': 'Frontend Developer',
      'company': 'BrightPath Tech',
      'location': 'Addis Ababa',
      'type': 'Full-time',
      'status': 'Approved',
      'description':
          'Build responsive Flutter Web interfaces for job seekers and employers.',
      'requirements':
          'Flutter, Dart, REST APIs, and a strong eye for usable UI.',
    },
    <String, String>{
      'title': 'Mobile App Developer',
      'company': 'Horizon Digital',
      'location': 'Addis Ababa',
      'type': 'Full-time',
      'status': 'Approved',
      'description':
          'Develop cross-platform mobile features for our hiring platform.',
      'requirements': 'Flutter, Firebase, and API integration experience.',
    },
    <String, String>{
      'title': 'Data Entry Clerk',
      'company': 'GreenField Logistics',
      'location': 'Bahir Dar',
      'type': 'Part-time',
      'status': 'Approved',
      'description': 'Maintain accurate records and support operations teams.',
      'requirements': 'Attention to detail and basic spreadsheet skills.',
    },
    <String, String>{
      'title': 'Sales Representative',
      'company': 'Abyssinia Trade',
      'location': 'Hawassa',
      'type': 'Full-time',
      'status': 'Approved',
      'description': 'Grow B2B partnerships and onboard new employer accounts.',
      'requirements': 'Communication skills and CRM familiarity.',
    },
    <String, String>{
      'title': 'UX Designer',
      'company': 'Studio Nine',
      'location': 'Addis Ababa',
      'type': 'Full-time',
      'status': 'Approved',
      'description': 'Design accessible flows for job seekers and employers.',
      'requirements': 'Figma, user research, and design systems.',
    },
    <String, String>{
      'title': 'Customer Support Assistant',
      'company': 'TalentBridge Services',
      'location': 'Dire Dawa',
      'type': 'Part-time',
      'status': 'Pending',
      'description':
          'Support applicants, answer employer questions, and maintain service quality.',
      'requirements':
          'Clear communication, basic CRM knowledge, and availability on weekends.',
    },
  ];

  static const List<String> jobTypes = <String>['Full-time', 'Part-time'];
  static const List<String> moderationStatuses = <String>[
    'Pending',
    'Approved',
    'Rejected',
  ];

  static List<Map<String, String>> get approvedJobs => jobs
      .where((Map<String, String> j) => (j['status'] ?? '') == 'Approved')
      .toList();

  static List<Map<String, String>> searchSuggestions(String query, {int limit = 8}) {
    final String keyword = query.trim().toLowerCase();
    if (keyword.isEmpty) {
      return <Map<String, String>>[];
    }

    return approvedJobs
        .where((Map<String, String> job) {
          final String haystack =
              '${job['title']} ${job['company']} ${job['location']} ${job['description']}'
                  .toLowerCase();
          return haystack.contains(keyword);
        })
        .take(limit)
        .toList();
  }

  static void addJob({
    required String title,
    required String company,
    required String location,
    required String type,
    required String description,
    required String requirements,
  }) {
    final Map<String, String> job = <String, String>{
      'title': title,
      'company': company,
      'location': location,
      'type': type,
      'status': 'Pending',
      'description': description,
      'requirements': requirements,
    };

    jobs.add(job);
    MockNotificationStore.notifyIfJobMatches(job);
  }

  static void updateJobStatus(Map<String, String> job, String status) {
    if (!moderationStatuses.contains(status)) {
      return;
    }
    job['status'] = status;
  }

  static void deleteJob(Map<String, String> job) {
    jobs.remove(job);
  }
}
