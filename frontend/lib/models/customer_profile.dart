/// Client-side model for a customer profile (mirrors gateway JSON).
class CustomerProfile {
  final int? id; // running id (display/order)
  final String ssoId;
  final String title; // mr | mrs | ms | unspecified
  final String username;
  final String firstName;
  final String lastName;
  final String? avatarBase64;
  final String? status;
  final String? birthDate; // ISO yyyy-mm-dd

  CustomerProfile({
    this.id,
    required this.ssoId,
    this.title = 'unspecified',
    required this.username,
    required this.firstName,
    required this.lastName,
    this.avatarBase64,
    this.status,
    this.birthDate,
  });

  String get fullName => [firstName, lastName]
      .where((s) => s.trim().isNotEmpty)
      .join(' ')
      .trim();

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: (json['id'] as num?)?.toInt(),
      ssoId: json['ssoId'] as String,
      title: (json['title'] ?? 'unspecified') as String,
      username: (json['username'] ?? '') as String,
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      avatarBase64: json['avatarBase64'] as String?,
      status: json['status'] as String?,
      birthDate: json['birthDate'] != null
          ? (json['birthDate'] as String).substring(0, 10)
          : null,
    );
  }
}
