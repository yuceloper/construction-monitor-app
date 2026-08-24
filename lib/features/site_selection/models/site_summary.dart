class SiteSummary {
  final int id;
  final String name;
  final String? location;

  const SiteSummary({
    required this.id,
    required this.name,
    this.location,
  });

  factory SiteSummary.fromJson(Map<String, dynamic> json) {
    return SiteSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString(),
    );
  }
}
