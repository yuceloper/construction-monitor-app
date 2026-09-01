class DailyTaskSummary {
  final int id;
  final int projectId;
  final String projectName;
  final String projectType;
  final String title;
  final String notes;
  final String status;
  final String priority;
  final int? assignedToId;
  final String assignedToName;
  final List<int> photoIds;

  const DailyTaskSummary({
    required this.id,
    required this.projectId,
    required this.projectName,
    required this.projectType,
    required this.title,
    required this.notes,
    required this.status,
    required this.priority,
    required this.assignedToId,
    required this.assignedToName,
    required this.photoIds,
  });

  factory DailyTaskSummary.fromJson(Map<String, dynamic> json) {
    final rawPhotoIds = json['photoIds'];
    return DailyTaskSummary(
      id: (json['id'] as num?)?.toInt() ?? 0,
      projectId: (json['projectId'] as num?)?.toInt() ?? 0,
      projectName: json['projectName']?.toString() ?? '',
      projectType: json['projectType']?.toString() ?? 'HOUSE',
      title: json['title']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'TODO',
      priority: json['priority']?.toString() ?? 'MEDIUM',
      assignedToId: (json['assignedToId'] as num?)?.toInt(),
      assignedToName: json['assignedToName']?.toString() ?? 'Atanmamış',
      photoIds: rawPhotoIds is List
          ? rawPhotoIds.whereType<num>().map((id) => id.toInt()).where((id) => id > 0).toList()
          : const [],
    );
  }

  bool get isCompleted => status == 'COMPLETED';
  String get typeLabel => projectType == 'SHOP' ? 'Dükkanlar' : 'Evler';

  String get priorityLabel {
    switch (priority) {
      case 'HIGH':
      case 'CRITICAL':
        return 'Yüksek';
      case 'LOW':
        return 'Düşük';
      default:
        return 'Orta';
    }
  }
}
