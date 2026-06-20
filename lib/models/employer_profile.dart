/// Model for a row in the Supabase `public.employers` table.
class EmployerProfile {
  const EmployerProfile({
    required this.id,
    required this.companyName,
    required this.contactInfo,
    required this.businessRegistrationNumber,
    required this.isVerified,
    required this.subscriptionPlan,
    required this.createdAt,
    this.ownerName,
    this.ownerEmail,
  });

  final String id;
  final String companyName;
  final String contactInfo;
  final String? businessRegistrationNumber;
  final bool isVerified;

  /// 'None' | 'starter' | 'growth' | 'enterprise'
  final String subscriptionPlan;
  final DateTime createdAt;

  /// Populated when fetched with a join on public.users (admin queue)
  final String? ownerName;
  final String? ownerEmail;

  factory EmployerProfile.fromMap(Map<String, dynamic> map) {
    final dynamic usersJoin = map['users'];

    return EmployerProfile(
      id:          map['id']            as String,
      companyName: map['company_name']  as String? ?? '',
      contactInfo: map['contact_info']  as String? ?? '',
      businessRegistrationNumber:
          map['business_registration_number'] as String?,
      isVerified:  map['is_verified']   as bool?   ?? false,
      subscriptionPlan: map['subscription_plan'] as String? ?? 'None',
      createdAt: map['created_at'] is String
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      ownerName:  usersJoin is Map ? usersJoin['name']  as String? : null,
      ownerEmail: usersJoin is Map ? usersJoin['email'] as String? : null,
    );
  }

  bool get hasActivePlan => subscriptionPlan != 'None';
  bool get hasPendingVerification =>
      !isVerified &&
      businessRegistrationNumber != null &&
      businessRegistrationNumber!.isNotEmpty;
}