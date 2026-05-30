/// Model for a row in the Supabase `public.applications` table.
class Application {
  const Application({
    required this.id,
    required this.jobId,
    required this.seekerId,
    required this.status,
    required this.createdAt,
    this.cvUrl,
  });

  final String id;
  final String jobId;
  final String seekerId;
  final String status; // 'pending' | 'accepted' | 'rejected'
  final DateTime createdAt;
  final String? cvUrl;

  factory Application.fromMap(Map<String, dynamic> map) {
    return Application(
      id: map['id'] as String,
      jobId: map['job_id'] as String,
      seekerId: map['seeker_id'] as String,
      status: map['status'] as String? ?? 'pending',
      cvUrl: map['cv_url'] as String?,
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
}