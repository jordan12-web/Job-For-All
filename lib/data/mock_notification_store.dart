import '../utils/matching_utils.dart';
import 'mock_profile_store.dart';

class MockNotificationStore {
  MockNotificationStore._();

  static final List<Map<String, String>> notifications =
      <Map<String, String>>[];

  static int get unreadCount {
    return notifications
        .where(
          (Map<String, String> notification) => notification['read'] != 'true',
        )
        .length;
  }

  static void addNotification({
    required String title,
    required String message,
  }) {
    final String signature = '$title|$message';
    final bool alreadyExists = notifications.any(
      (Map<String, String> notification) =>
          notification['signature'] == signature,
    );

    if (alreadyExists) {
      return;
    }

    notifications.insert(0, <String, String>{
      'title': title,
      'message': message,
      'date': DateTime.now().toIso8601String().split('T').first,
      'read': 'false',
      'signature': signature,
    });
  }

  static void notifyIfJobMatches(Map<String, String> job) {
    final String skills = MockProfileStore.jobSeekerProfile['Skills'] ?? '';
    if (!MatchingUtils.isJobMatch(seekerSkills: skills, job: job)) {
      return;
    }

    addNotification(
      title: 'New matching job',
      message:
          '${job['title'] ?? 'A job'} at ${job['company'] ?? 'an employer'} matches your skills.',
    );
  }

  static void markAllRead() {
    for (final Map<String, String> notification in notifications) {
      notification['read'] = 'true';
    }
  }
}
