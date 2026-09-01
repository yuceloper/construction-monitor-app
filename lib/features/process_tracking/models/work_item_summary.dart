class WorkItemSummary {
  final int id;
  final int progressBlockId;
  final String title;
  final String status;
  final double percentage;
  final double weight;
  final int orderIndex;
  final bool hasDependency;
  final bool hasWarning;
  final bool hasCriticalWarning;

  const WorkItemSummary({
    required this.id,
    required this.progressBlockId,
    required this.title,
    required this.status,
    required this.percentage,
    required this.weight,
    required this.orderIndex,
    required this.hasDependency,
    required this.hasWarning,
    required this.hasCriticalWarning,
  });

  factory WorkItemSummary.fromJson(Map<String, dynamic> json) {
    final rawPercentage = json['percentage'];
    final percentage = rawPercentage is num
        ? rawPercentage.toDouble()
        : double.tryParse(rawPercentage?.toString() ?? '') ?? 0;
    final rawWeight = json['weight'];
    final weight = rawWeight is num
        ? rawWeight.toDouble()
        : double.tryParse(rawWeight?.toString() ?? '') ?? 1;

    return WorkItemSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      progressBlockId: (json['progressBlockId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'WAITING',
      percentage: percentage.clamp(0.0, 100.0).toDouble(),
      weight: weight <= 0 ? 1 : weight,
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      hasDependency: json['hasDependency'] == true,
      hasWarning: json['hasWarning'] == true,
      hasCriticalWarning: json['hasCriticalWarning'] == true,
    );
  }

  bool get isCompleted => status == 'COMPLETED';
}
