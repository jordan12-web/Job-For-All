/// Profile row from Supabase `users` table linked to `auth.users`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
  });

  final String id;
  final String email;
  final String name;

  /// Database role: `seeker`, `employer`, or `admin`.
  final String role;

  /// Parses a Supabase row safely; returns null if required fields are missing.
  static UserProfile? tryFromMap(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final Map<String, dynamic> map = Map<String, dynamic>.from(raw);
    final String? id = _stringOrNull(map['id']);
    if (id == null || id.isEmpty) {
      return null;
    }

    return UserProfile(
      id: id,
      email: _stringOrNull(map['email']) ?? '',
      name: _stringOrNull(map['name']) ?? '',
      role: _stringOrNull(map['role']) ?? 'seeker',
    );
  }

  static String? _stringOrNull(dynamic value) {
    if (value == null) {
      return null;
    }
    final String text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  Map<String, dynamic> toUpdateMap({
    String? name,
    String? email,
    String? role,
  }) {
    return <String, dynamic>{
      if (name case final String n) 'name': n,
      if (email case final String e) 'email': e,
      if (role case final String r) 'role': r,
    };
  }

  bool get isSeeker => role == 'seeker';
  bool get isEmployer => role == 'employer';
  bool get isAdmin => role == 'admin';
}
