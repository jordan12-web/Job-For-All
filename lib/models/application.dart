/// Model for a row in the Supabase `public.applications` table.
///
/// Supports flat rows and joined rows (with jobs and users data).
class Application {
  const Application({
    required this.id,
    required this.jobId,
    required this.seekerId,
    required this.status,
    required this.createdAt,
    this.cvUrl,
    this.jobTitle,
    this.seekerName,
    this.seekerEmail,
  });

  final String id;
  final String jobId;
  final String seekerId;

  /// 'pending' | 'accepted' | 'rejected'
  final String status;
  final DateTime createdAt;
  final String? cvUrl;

  /// Populated when fetched with a join on public.jobs
  final String? jobTitle;

  /// Populated when fetched with a join on public.users
  final String? seekerName;
  final String? seekerEmail;

  factory Application.fromMap(Map<String, dynamic> map) {
    // Supabase returns nested joins as maps under the table name key
    final dynamic jobsJoin  = map['jobs'];
    final dynamic usersJoin = map['users'];

    return Application(
      id:          map['id']         as String,
      jobId:       map['job_id']     as String,
      seekerId:    map['seeker_id']  as String,
      status:      map['status']     as String? ?? 'pending',
      cvUrl:       map['cv_url']     as String?,
      createdAt:   map['created_at'] is String
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      jobTitle:    jobsJoin  is Map ? jobsJoin['title']  as String? : null,
      seekerName:  usersJoin is Map ? usersJoin['name']  as String? : null,
      seekerEmail: usersJoin is Map ? usersJoin['email'] as String? : null,
    );
  }

  /// Returns a copy with updated fields — used for optimistic UI updates.
  Application copyWith({String? status}) {
    return Application(
      id:          id,
      jobId:       jobId,
      seekerId:    seekerId,
      status:      status ?? this.status,
      createdAt:   createdAt,
      cvUrl:       cvUrl,
      jobTitle:    jobTitle,
      seekerName:  seekerName,
      seekerEmail: seekerEmail,
    );
  }

  bool get isPending  => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}