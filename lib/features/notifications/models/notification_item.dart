class NotificationItem {
  final int id;
  final String title;
  final String message;
  final String type;
  final int? referenceId;
  final String? referenceType;
  final bool isRead;
  final int? projectId;
  final String? projectName;
  final DateTime createdAt;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.referenceId,
    required this.referenceType,
    required this.isRead,
    required this.projectId,
    required this.projectName,
    required this.createdAt,
  });

  bool get isWorkItem => referenceType == 'WORK_ITEM' || type.startsWith('WORK_ITEM_');
  bool get isDailyTask => referenceType == 'DAILY_TASK' || type.startsWith('DAILY_TASK_') || type.startsWith('TASK_');

  NotificationItem copyWith({bool? isRead}) => NotificationItem(
        id: id,
        title: title,
        message: message,
        type: type,
        referenceId: referenceId,
        referenceType: referenceType,
        isRead: isRead ?? this.isRead,
        projectId: projectId,
        projectName: projectName,
        createdAt: createdAt,
      );

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Bildirim',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? 'GENERAL',
      referenceId: (json['referenceId'] as num?)?.toInt(),
      referenceType: json['referenceType'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      projectId: (json['projectId'] as num?)?.toInt(),
      projectName: json['projectName'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
