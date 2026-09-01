class SiteMemberSummary {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String fullName;

  const SiteMemberSummary({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.fullName,
  });

  factory SiteMemberSummary.fromJson(Map<String, dynamic> json) {
    return SiteMemberSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
    );
  }
}
