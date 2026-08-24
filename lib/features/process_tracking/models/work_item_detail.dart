class WorkItemDetail {
  final int id;
  final String title;
  final List<String> dependencies;
  final List<WorkItemWarning> warnings;
  final List<WorkItemHistory> history;

  const WorkItemDetail({
    required this.id,
    required this.title,
    required this.dependencies,
    required this.warnings,
    required this.history,
  });

  factory WorkItemDetail.fromJson(Map<String, dynamic> json) {
    return WorkItemDetail(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      dependencies: (json['dependencies'] as List? ?? const [])
          .map((item) => item.toString())
          .toList(),
      warnings: (json['warnings'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => WorkItemWarning.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      history: (json['history'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => WorkItemHistory.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}

class WorkItemWarning {
  final int id;
  final String text;
  final bool critical;
  final DateTime? createdAt;
  final String user;

  const WorkItemWarning({
    required this.id,
    required this.text,
    required this.critical,
    required this.createdAt,
    required this.user,
  });

  factory WorkItemWarning.fromJson(Map<String, dynamic> json) => WorkItemWarning(
        id: (json['id'] as num?)?.toInt() ?? 0,
        text: json['text']?.toString() ?? '',
        critical: json['critical'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        user: json['user']?.toString() ?? '',
      );
}

class WorkItemHistory {
  final int id;
  final String text;
  final DateTime? createdAt;
  final String user;

  const WorkItemHistory({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.user,
  });

  factory WorkItemHistory.fromJson(Map<String, dynamic> json) => WorkItemHistory(
        id: (json['id'] as num?)?.toInt() ?? 0,
        text: json['text']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        user: json['user']?.toString() ?? '',
      );
}
