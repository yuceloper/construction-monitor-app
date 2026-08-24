class WorkItemSummary {
  final int id;
  final int progressBlockId;
  final String title;
  final String status;
  final double percentage;
  final int orderIndex;
  final bool hasDependency;
  final bool hasCriticalWarning;

  const WorkItemSummary({
    required this.id,
    required this.progressBlockId,
    required this.title,
    required this.status,
    required this.percentage,
    required this.orderIndex,
    required this.hasDependency,
    required this.hasCriticalWarning,
  });

  factory WorkItemSummary.fromJson(Map<String, dynamic> json) {
    final rawPercentage = json['percentage'];
    final percentage = rawPercentage is num
        ? rawPercentage.toDouble()
        : double.tryParse(rawPercentage?.toString() ?? '') ?? 0;

    return WorkItemSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      progressBlockId: (json['progressBlockId'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      status: json['status']?.toString() ?? 'WAITING',
      percentage: percentage.clamp(0, 100),
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      hasDependency: json['hasDependency'] == true,
      hasCriticalWarning: json['hasCriticalWarning'] == true,
    );
  }

  bool get isCompleted => status == 'COMPLETED';
}
