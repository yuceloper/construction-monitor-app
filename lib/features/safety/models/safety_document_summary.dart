class SafetyDocumentSummary {
  final int id;
  final int siteId;
  final String documentType;
  final String title;
  final String originalName;
  final int sizeBytes;
  final DateTime? documentDate;

  const SafetyDocumentSummary({
    required this.id,
    required this.siteId,
    required this.documentType,
    required this.title,
    required this.originalName,
    required this.sizeBytes,
    required this.documentDate,
  });

  factory SafetyDocumentSummary.fromJson(Map<String, dynamic> json) {
    return SafetyDocumentSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      siteId: (json['siteId'] as num?)?.toInt() ?? 0,
      documentType: json['documentType']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      originalName: json['originalName']?.toString() ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      documentDate: DateTime.tryParse(json['documentDate']?.toString() ?? ''),
    );
  }
}
