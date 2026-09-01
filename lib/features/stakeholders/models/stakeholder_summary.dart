class StakeholderSummary {
  final int id;
  final int siteId;
  final String companyName;
  final String detail;
  final String contactPerson;
  final String phoneNumber;

  const StakeholderSummary({
    required this.id,
    required this.siteId,
    required this.companyName,
    required this.detail,
    required this.contactPerson,
    required this.phoneNumber,
  });

  factory StakeholderSummary.fromJson(Map<String, dynamic> json) {
    return StakeholderSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      companyName: json['companyName']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
      contactPerson: json['contactPerson']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
    );
  }
}
