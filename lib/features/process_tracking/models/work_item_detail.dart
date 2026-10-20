/// Bagimli bir is kalemi.
///
/// Sunucu adin yani sira kimligi de gonderiyor; satira dokununca o isin
/// detayina gidilebilmesi icin kimlik gerekiyor.
class WorkItemDependency {
  final int id;
  final String title;

  const WorkItemDependency({required this.id, required this.title});

  factory WorkItemDependency.fromJson(Map<String, dynamic> json) =>
      WorkItemDependency(
        id: (json['id'] as num?)?.toInt() ?? 0,
        title: json['title']?.toString() ?? '',
      );
}

class WorkItemDetail {
  final int id;
  final String title;
  final List<String> dependencies;

  /// Kimlikli hali. Sunucu gondermezse bos kaliyor ve ekran yalnizca
  /// [dependencies] adlarini gosteriyor.
  final List<WorkItemDependency> dependencyItems;
  final List<WorkItemWarning> warnings;
  final List<WorkItemHistory> history;

  const WorkItemDetail({
    required this.id,
    required this.title,
    required this.dependencies,
    this.dependencyItems = const [],
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
      dependencyItems: (json['dependencyItems'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (item) =>
                WorkItemDependency.fromJson(Map<String, dynamic>.from(item)),
          )
          .where((item) => item.id > 0 && item.title.isNotEmpty)
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
  final DateTime? dueDate;
  final DateTime? createdAt;
  final String user;
  final bool hasAudio;

  const WorkItemWarning({
    required this.id,
    required this.text,
    required this.dueDate,
    required this.createdAt,
    required this.user,
    required this.hasAudio,
  });

  factory WorkItemWarning.fromJson(Map<String, dynamic> json) => WorkItemWarning(
        id: (json['id'] as num?)?.toInt() ?? 0,
        text: json['text']?.toString() ?? '',
        dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? ''),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
        user: json['user']?.toString() ?? '',
        hasAudio: json['hasAudio'] == true,
      );

  bool get isOverdue {
    final created = createdAt;
    if (created == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(created.toLocal().year, created.toLocal().month, created.toLocal().day);
    final redFrom = createdDay.add(const Duration(days: 5));
    return !today.isBefore(redFrom);
  }
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
