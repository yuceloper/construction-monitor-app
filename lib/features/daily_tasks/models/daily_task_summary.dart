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
  final int? createdById;
  final String createdByName;
  final List<int> photoIds;
  final int? audioNoteId;

  /// Isin tarihi. Sunucu once taskDate, yoksa dueDate ya da createdAt
  /// gonderiyor; siralama bunun uzerinden yapiliyor.
  final DateTime? tarih;

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
    required this.createdById,
    required this.createdByName,
    required this.photoIds,
    required this.audioNoteId,
    this.tarih,
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
      createdById: (json['createdById'] as num?)?.toInt(),
      createdByName: json['createdByName']?.toString() ?? '',
      photoIds: rawPhotoIds is List
          ? rawPhotoIds
                .whereType<num>()
                .map((id) => id.toInt())
                .where((id) => id > 0)
                .toList()
          : const [],
      audioNoteId: (json['audioNoteId'] as num?)?.toInt(),
      tarih:
          _tarihOku(json['taskDate']) ??
          _tarihOku(json['dueDate']) ??
          _tarihOku(json['createdAt']),
    );
  }

  static DateTime? _tarihOku(Object? deger) {
    if (deger == null) return null;
    return DateTime.tryParse(deger.toString());
  }

  bool get isCompleted => status == 'COMPLETED';
  String get typeLabel => projectType == 'SHOP' ? 'Dükkanlar' : 'Evler';

  String get statusLabel {
    switch (status) {
      case 'COMPLETED':
        return 'Tamamlandı';
      case 'IN_PROGRESS':
        return 'Devam Ediyor';
      default:
        return 'Başlanacak';
    }
  }

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
