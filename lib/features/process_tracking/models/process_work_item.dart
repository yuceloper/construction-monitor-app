class ProcessWorkItem {
  final String id;
  final String title;
  final String? description;
  final String status;

  const ProcessWorkItem({
    required this.id,
    required this.title,
    this.description,
    required this.status,
  });
}