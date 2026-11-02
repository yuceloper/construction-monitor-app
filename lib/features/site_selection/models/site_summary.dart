class SiteSummary {
  final int id;
  final String name;
  final String? location;

  /// Santiyenin genel planlanan bitis tarihi. Bloklar paralel
  /// ilerledigi icin gecikme hesabi ve ekranda gosterilen tarih
  /// bloklarin kendi tarihleri yerine bunu kullaniyor.
  final DateTime? plannedEndDate;

  const SiteSummary({
    required this.id,
    required this.name,
    this.location,
    this.plannedEndDate,
  });

  factory SiteSummary.fromJson(Map<String, dynamic> json) {
    return SiteSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      location: json['location']?.toString(),
      plannedEndDate: DateTime.tryParse(
        json['plannedEndDate']?.toString() ?? '',
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location,
        'plannedEndDate': plannedEndDate?.toIso8601String(),
      };
}
