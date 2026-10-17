class ProjectProgressSummary {
  final double actualProgress;
  final double? plannedProgress;
  final double? variance;
  final DateTime? plannedEndDate;

  const ProjectProgressSummary({
    required this.actualProgress,
    required this.plannedProgress,
    required this.variance,
    required this.plannedEndDate,
  });

  factory ProjectProgressSummary.fromJson(Map<String, dynamic> json) {
    double? parseNumber(Object? value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '');
    }

    return ProjectProgressSummary(
      actualProgress: (parseNumber(json['actualProgress']) ?? 0).clamp(0, 100),
      plannedProgress: parseNumber(json['plannedProgress'])?.clamp(0, 100),
      variance: parseNumber(json['variance']),
      plannedEndDate: DateTime.tryParse(json['plannedEndDate']?.toString() ?? ''),
    );
  }
}
