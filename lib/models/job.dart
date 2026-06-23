/// Model for a job listing from the Supabase 'public.jobs' table.
class Job {
  final String id;
  final String employerId;
  final String title;
  final String description;
  final String requirements;
  final String? location;
  final String? type;
  final String? company;
  final String status;
  final DateTime createdAt;

  const Job({
    required this.id,
    required this.employerId,
    required this.title,
    required this.description,
    required this.requirements,
    this.location,
    this.type,
    this.company,
    this.status = 'Pending',
    required this.createdAt,
  });

  /// Parse a job from a Supabase row map
  factory Job.fromMap(Map<String, dynamic> map) {
    return Job(
      id: map['id'] as String,
      employerId: map['employer_id'] as String,
      title: map['title'] as String? ?? 'Untitled',
      description: map['description'] as String? ?? '',
      requirements: map['requirements'] as String? ?? '',
      location: map['location'] as String?,
      type: map['type'] as String?,
      company: map['company'] as String?,
      status: map['status'] as String? ?? 'Pending',
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'] as String)
          : map['created_at'] is DateTime
          ? map['created_at'] as DateTime
          : DateTime.now(),
    );
  }

  /// Check if job is approved
  bool get isApproved => status == 'Approved';

  /// Convert to map for display
  Map<String, String> toDisplayMap() {
    return <String, String>{
      'id': id,
      'title': title,
      'company': company ?? '',
      'location': location ?? '',
      'type': type ?? 'Full-time',
      'status': status,
      'description': description,
      'requirements': requirements,
    };
  }
}
