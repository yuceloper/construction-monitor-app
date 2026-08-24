class ProgressStage {
  final int id;
  final int blockNumber;
  final String name;
  final double percentage;
  final String? description;

  const ProgressStage({
    required this.id,
    required this.blockNumber,
    required this.name,
    required this.percentage,
    this.description,
  });

  factory ProgressStage.fromJson(Map<String, dynamic> json) {
    final rawPercentage = json['percentage'];
    final percentage = rawPercentage is num
        ? rawPercentage.toDouble()
        : double.tryParse(rawPercentage?.toString() ?? '') ?? 0;

    return ProgressStage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      blockNumber: (json['blockNumber'] as num?)?.toInt() ?? 0,
      name: json['blockName']?.toString() ?? '',
      percentage: percentage.clamp(0, 100),
      description: json['description']?.toString(),
    );
  }
}
