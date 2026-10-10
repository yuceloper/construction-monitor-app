import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/kisa_ad.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/pressable.dart';
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

  /// Iki sekmede de hic is yok. Sekme serisi bu durumda gizleniyor.
  bool _hicIsYok = false;

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tasks = await _service.getTasks(includeCompleted: _showAll);
      if (!mounted) return;
      // Aktif liste bossa, tamamlanmislar dahil de bos mu diye bir kez
      // bakiliyor; sadece bu durumda ek istek atiliyor.
      var hicYok = tasks.isEmpty;
      if (hicYok && !_showAll) {
        final tumu = await _service.getTasks(includeCompleted: true);
        hicYok = tumu.isEmpty;
      }
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _hicIsYok = hicYok;
      });
    } on DailyTaskException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
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
    final c = context.colors;

    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            ScreenTitleBar(
              title: 'Günlük İşler',
              onBack: () => context.go('/dashboard'),
            ),
            if (!_hicIsYok)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
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
              ),
            // Ekle tek basina bir kutu degil; solda kac is oldugunu
            // soyleyen satirin sag ucu. Bosta asili durmuyor, yer
            // kaplamasi en az ve ustelik bilgi de tasiyor.
            if (!_hicIsYok && _errorMessage == null && !_isLoading)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 18, 8),
                child: Row(
                  children: [
                    Text(
                      _showAll
                          ? '${_tasks.length} iş'
                          : '${_tasks.length} aktif iş',
                      style: TextStyle(
                        fontFamily: kBody,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                        color: c.muted,
                      ),
                    ),
                    const Spacer(),
                    Pressable(
                      onTap: _openCreate,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus, size: 18, color: c.accent),
                            const SizedBox(width: 6),
                            Text(
                              'Ekle',
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: c.accent,
                              ),
                            ),
                          ],
                        ),
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
    final c = context.colors;

    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: c.ink),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.circleAlert, color: c.bad, size: 42),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 16,
                  height: 1.45,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 18),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: _loadTasks,
              ),
            ],
          ),
        ),
      );
    }

    if (_tasks.isEmpty) {
      return RefreshIndicator(
        color: c.ink,
        onRefresh: _loadTasks,
        child: CenteredScrollMessage(
          message: _showAll
              ? 'Henüz günlük iş bulunmuyor.'
              : 'Aktif günlük iş bulunmuyor.',
        ),
      );
    }

    return RefreshIndicator(
      color: c.ink,
      onRefresh: _loadTasks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        itemCount: _tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) => _TaskCard(
          task: _tasks[index],
          onTap: () => _openTask(_tasks[index]),
          showStatus: _showAll,
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kBody,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
            color: selected ? c.bg : c.sub,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTaskSummary task;
  final VoidCallback onTap;

  /// Tum Isler sekmesinde tamamlanmis isler de listelendigi icin
  /// karttan hangi durumda oldugu okunabiliyor.
  final bool showStatus;

  const _TaskCard({
    required this.task,
    required this.onTap,
    this.showStatus = false,
  });

  Color badgeColor(AppColors c) {
    switch (task.priority) {
      case 'HIGH':
      case 'CRITICAL':
        return c.bad;
      case 'LOW':
        return c.muted;
      default:
        return c.priorityMid;
    }
  }

  /// Sari zeminde beyaz yazi okunmuyor; olculdu, kontrast 3.0'a dusuyor.
  /// Orta oncelikte yazi koyu, digerlerinde beyaz kaliyor.
  Color badgeTextColor(AppColors c) {
    switch (task.priority) {
      case 'HIGH':
      case 'CRITICAL':
        return c.surface;
      default:
        // Gri ve sari zeminde beyaz yazi okunmuyordu: olculdu, kontrast
        // 3.1'e dusuyor, erisilebilirlik siniri 4.5. Koyu yaziyla 6.0.
        return c.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final badge = badgeColor(c);
    final badgeText = badgeTextColor(c);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statu blok adiyla ayni satirda: alt satirda kisi
                  // adiyla oncelik rozeti arasinda sikisiyordu.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${task.typeLabel} - ${task.projectName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                      ),
                      if (showStatus) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: c.inset,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: c.border2),
                          ),
                          child: Text(
                            task.statusLabel,
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: c.sub,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  Text(
                    task.notes.isNotEmpty ? task.notes : task.title,
                    style: TextStyle(
                      fontFamily: kDisplay,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(LucideIcons.user, size: 17, color: c.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          // Ust kosedeki kullanici kutusuyla ayni kural:
                          // ayni kisi her yerde ayni yaziliyor.
                          kisaKisiAdi(context, task.assignedToName, enBoy: 150),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 14,
                            color: c.sub,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 88),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badge,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          task.priorityLabel,
                          style: TextStyle(
                            fontFamily: kBody,
                            color: badgeText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 26, color: c.muted),
          ],
        ),
      ),
    );
  }
}
