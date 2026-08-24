class ProjectSummary {
  final int id;
  final String name;
  final double overallProgress;
  final String status;
  final String projectType;

  const ProjectSummary({
    required this.id,
    required this.name,
    required this.overallProgress,
    required this.status,
    required this.projectType,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    final rawProgress = json['overallProgress'];

    double progress;
    if (rawProgress is num) {
      progress = rawProgress.toDouble();
    } else {
      progress = double.tryParse(rawProgress?.toString() ?? '') ?? 0;
    }

    return ProjectSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      overallProgress: progress.clamp(0, 100),
      status: json['status']?.toString() ?? '',
      projectType: json['projectType']?.toString() ?? 'HOUSE',
    );
  }

  int get roundedProgress => overallProgress.round();
  bool get isHouse => projectType == 'HOUSE';
  bool get isShop => projectType == 'SHOP';
}
