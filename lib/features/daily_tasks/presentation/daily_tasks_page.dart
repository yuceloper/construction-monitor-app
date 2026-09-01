import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_header.dart';
import '../models/daily_task_summary.dart';
import '../services/daily_task_service.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  final _service = DailyTaskService();

  bool _showAll = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<DailyTaskSummary> _tasks = const [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _service.getTasks(includeCompleted: _showAll);
      if (!mounted) return;
      setState(() => _tasks = tasks);
    } on DailyTaskException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Günlük işler yüklenirken beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTab(bool showAll) async {
    if (_showAll == showAll) return;
    setState(() => _showAll = showAll);
    await _loadTasks();
  }

  Future<void> _openCreate() async {
    final created = await context.push<bool>('/daily-tasks/create');
    if (!mounted || created != true) return;
    await _loadTasks();
  }

  Future<void> _openTask(DailyTaskSummary task) async {
    await context.push<bool>('/daily-tasks/${task.id}');
    if (!mounted) return;
    await _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.go('/dashboard'),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Günlük İşler',
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                    ),
                  ),
                  SizedBox(
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _openCreate,
                      icon: const Icon(Icons.add, size: 25),
                      label: const Text('Ekle', style: TextStyle(fontSize: 17)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066A6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _TabButton(
                      label: 'AKTİF İŞLER',
                      selected: !_showAll,
                      onTap: () => _selectTab(false),
                    ),
                  ),
                  Expanded(
                    child: _TabButton(
                      label: 'TÜM İŞLER',
                      selected: _showAll,
                      onTap: () => _selectTab(true),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 42),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: _loadTasks, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadTasks,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(_showAll ? 'Henüz günlük iş bulunmuyor.' : 'Aktif günlük iş bulunmuyor.'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _TaskCard(
          task: _tasks[index],
          onTap: () => _openTask(_tasks[index]),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE7F0F3) : const Color(0xFFE4E4E4),
          border: Border.all(color: Colors.black54),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w700 : FontWeight.w500),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTaskSummary task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  Color get badgeColor {
    switch (task.priority) {
      case 'HIGH':
      case 'CRITICAL':
        return const Color(0xFFE84949);
      case 'LOW':
        return const Color(0xFFBDBDBD);
      default:
        return const Color(0xFFF2C94C);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEDEDED),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${task.typeLabel} - ${task.projectName}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A1111),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      task.notes.isNotEmpty ? task.notes : task.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.account_box_outlined, size: 23),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(task.assignedToName, style: const TextStyle(fontSize: 14)),
                        ),
                        if (task.photoIds.isNotEmpty) ...[
                          const Icon(Icons.photo_library_outlined, size: 19),
                          const SizedBox(width: 4),
                          Text('${task.photoIds.length}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          constraints: const BoxConstraints(minWidth: 88),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(18)),
                          child: Text(
                            task.priorityLabel,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right, size: 46, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }
}
