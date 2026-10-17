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

    double? clampPercent(Object? value) {
      final parsed = parseNumber(value);
      return parsed?.clamp(0.0, 100.0).toDouble();
    }

    return ProjectProgressSummary(
      actualProgress: clampPercent(json['actualProgress']) ?? 0.0,
      plannedProgress: clampPercent(json['plannedProgress']),
      variance: parseNumber(json['variance']),
      plannedEndDate: DateTime.tryParse(json['plannedEndDate']?.toString() ?? ''),
    );
  }
}
