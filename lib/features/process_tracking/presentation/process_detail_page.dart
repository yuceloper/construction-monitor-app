import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/pressable.dart';
import '../models/progress_stage.dart';
import '../models/project_progress_summary.dart';
import '../models/work_item_summary.dart';
import '../services/progress_service.dart';
import '../services/work_item_service.dart';

class ProcessDetailPage extends StatefulWidget {
  final String blockName;
  final int progress;
  final int projectId;

  const ProcessDetailPage({
    super.key,
    required this.blockName,
    required this.progress,
    required this.projectId,
  });

  @override
  State<ProcessDetailPage> createState() => _ProcessDetailPageState();
}

class _ProcessDetailPageState extends State<ProcessDetailPage> {
  final _progressService = ProgressService();
  final _workItemService = WorkItemService();

  int? _expandedIndex;
  bool _isLoading = true;
  String? _errorMessage;
  List<ProgressStage> _stages = const [];
  Map<int, List<WorkItemSummary>> _workItemsByStage = const {};
  late double _overallProgress;
  ProjectProgressSummary? _progressSummary;

  @override
  void initState() {
    super.initState();
    _overallProgress = widget.progress.toDouble();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.projectId <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Proje kimliği bulunamadı.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _progressService.getStagesByProject(widget.projectId),
        _workItemService.getByProject(widget.projectId),
      ]);

      final stages = results[0] as List<ProgressStage>;
      final workItems = results[1] as List<WorkItemSummary>;

      // Planlanan ilerleme ayri isteniyor ve alinamazsa ekran yine
      // aciliyor. Ucu birden tek Future.wait icinde gidince bu servis
      // hata verdiginde butun ekran "Surec bilgileri alinamadi"ya
      // dusuyor, surec takibi hic acilmiyordu.
      ProjectProgressSummary? progressSummary;
      double? gerceklesenIlerleme;
      try {
        progressSummary = await _progressService.getProgressSummary(
          widget.projectId,
        );
        gerceklesenIlerleme = progressSummary.actualProgress;
      } catch (_) {
        try {
          gerceklesenIlerleme = await _progressService.getOverallProgress(
            widget.projectId,
          );
        } catch (_) {
          // Yuzde de alinamazsa listeden gelen deger korunuyor.
        }
      }

      final grouped = <int, List<WorkItemSummary>>{};

      for (final item in workItems) {
        grouped.putIfAbsent(item.progressBlockId, () => []).add(item);
      }
      for (final items in grouped.values) {
        items.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      }

      if (!mounted) return;
      setState(() {
        _stages = stages;
        _workItemsByStage = grouped;
        _overallProgress = gerceklesenIlerleme ?? _overallProgress;
        _progressSummary = progressSummary;
      });
    } on ProgressException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on WorkItemException catch (error) {
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

  bool get _isYok =>
      _stages.isEmpty ||
      _stages.every(
        (asama) => (_workItemsByStage[asama.id] ?? const []).isEmpty,
      );

  Future<void> _openWorkDetail(WorkItemSummary item) async {
    await context.push(
      '/process/${Uri.encodeComponent(widget.blockName)}/work/${item.id}'
      '?title=${Uri.encodeComponent(item.title)}',
    );
    if (!mounted) return;
    await _loadData();
  }

  Future<void> _openUpdate() async {
    await context.push(
      '/process/${Uri.encodeComponent(widget.blockName)}/update?projectId=${widget.projectId}',
    );
    if (!mounted) return;
    await _loadData();
  }

  String _plannedEndLabel(DateTime? value) {
    if (value == null) return '';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}.${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final roundedProgress = _overallProgress.round();
    final planned = _progressSummary?.plannedProgress?.round();
    final variance = _progressSummary?.variance?.round();
    final behind = variance != null && variance < 0;
    final ahead = variance != null && variance > 0;

    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            ScreenTitleBar(
              title: widget.blockName,
              onBack: () => context.pop(true),
            ),
            if (!_isLoading && _errorMessage == null && !_isYok)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [c.anchorTop, c.anchorMid, c.anchorBottom],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: c.anchorMid.withValues(alpha: .30),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Genel İlerleme',
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .3,
                              color: Colors.white.withValues(alpha: .62),
                            ),
                          ),
                          const Spacer(),
                          SmallButton(
                            label: 'Güncelle',
                            onTap: _openUpdate,
                            onDark: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: _ProgressMetric(
                              value: '%$roundedProgress',
                              label: 'GERÇEKLEŞEN',
                              dotColor: c.anchorAccent,
                            ),
                          ),
                          if (planned != null) ...[
                            Container(
                              width: 1,
                              height: 48,
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              color: Colors.white.withValues(alpha: .16),
                            ),
                            Expanded(
                              child: _ProgressMetric(
                                value: '%$planned',
                                label: 'PLANLANAN',
                                dotColor: Colors.white.withValues(alpha: .42),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      _PlannedProgressRail(
                        actual: roundedProgress,
                        planned: planned,
                        color: c.anchorAccent,
                      ),
                      // Durum bandi barin altinda: once ne kadar
                      // ilerledigi goruluyor, sonra plana gore nerede
                      // oldugu yaziyor.
                      if (planned != null && variance != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: behind
                                ? c.bad.withValues(alpha: .24)
                                : ahead
                                ? c.ok.withValues(alpha: .22)
                                : Colors.white.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                behind
                                    ? LucideIcons.arrowDown
                                    : ahead
                                    ? LucideIcons.arrowUp
                                    : LucideIcons.minus,
                                size: 17,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  behind
                                      ? '%${variance.abs()} GERİDE · PLANDAN DAHA YAVAŞ'
                                      : ahead
                                      ? '%$variance ÖNDE · PLANDAN DAHA HIZLI'
                                      : 'PLAN İLE AYNI SEVİYEDE',
                                  style: const TextStyle(
                                    fontFamily: kBody,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: .4,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (_progressSummary?.plannedEndDate != null) ...[
                        const SizedBox(height: 9),
                        Text(
                          'Planlanan bitiş: ${_plannedEndLabel(_progressSummary!.plannedEndDate)}',
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: .62),
                          ),
                        ),
                      ],
                    ],
                  ),
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
              Icon(LucideIcons.circleAlert, size: 42, color: c.bad),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kBody, fontSize: 16, height: 1.45, color: c.ink),
              ),
              const SizedBox(height: 18),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: _loadData,
              ),
            ],
          ),
        ),
      );
    }

    if (_isYok) {
      return RefreshIndicator(
        color: c.ink,
        onRefresh: _loadData,
        child: const CenteredScrollMessage(
          message: 'Bu blok için henüz iş eklenmemiştir.',
        ),
      );
    }

    return RefreshIndicator(
      color: c.ink,
      onRefresh: _loadData,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        itemCount: _stages.length,
        separatorBuilder: (_, __) => const SizedBox(height: Sizes.gap),
        itemBuilder: (context, index) {
          final progressStage = _stages[index];
          final items = _workItemsByStage[progressStage.id] ?? const <WorkItemSummary>[];
          final stage = _ProcessStage(
            title: progressStage.name,
            status: _statusForItems(items),
            items: items,
          );
          final expanded = _expandedIndex == index;
          return _StageCard(
            stage: stage,
            expanded: expanded,
            onTap: () => setState(() => _expandedIndex = expanded ? null : index),
            onItemTap: _openWorkDetail,
          );
        },
      ),
    );
  }

  _StageStatus _statusForItems(List<WorkItemSummary> items) {
    if (items.isEmpty) return _StageStatus.waiting;
    if (items.every((item) => item.status == 'COMPLETED')) return _StageStatus.completed;
    if (items.every((item) => item.status == 'WAITING')) return _StageStatus.waiting;
    return _StageStatus.active;
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.value, required this.label, required this.dotColor});
  final String value;
  final String label;
  final Color dotColor;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: kDisplay,
              fontSize: 36,
              fontWeight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
              const SizedBox(width: 7),
              Text(label, style: TextStyle(fontFamily: kBody, fontSize: 13.5, color: Colors.white.withValues(alpha: .72))),
            ],
          ),
        ],
      );
}

class _PlannedProgressRail extends StatelessWidget {
  const _PlannedProgressRail({required this.actual, required this.planned, required this.color});
  final int actual;
  final int? planned;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final actualValue = actual.clamp(0, 100).toDouble() / 100.0;
    final plannedValue = planned == null ? null : planned!.clamp(0, 100).toDouble() / 100.0;
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 10,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)),
          ),
          // Planlanan kisim soluk mavi dolgu: gerceklesen sifirken bile
          // bar mavi gorunuyor ve iki deger yan yana okunuyor.
          if (plannedValue != null)
            FractionallySizedBox(
              widthFactor: plannedValue,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .38),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          FractionallySizedBox(
            widthFactor: actualValue,
            child: Container(height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(99))),
          ),
          // Planlanan sinirini belirten ince cizgi.
          if (plannedValue != null)
            Positioned(
              left: (constraints.maxWidth * plannedValue - 1)
                  .clamp(0.0, constraints.maxWidth - 2)
                  .toDouble(),
              top: -4,
              child: Container(width: 2, height: 18, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _StageCard extends StatelessWidget {
  final _ProcessStage stage;
  final bool expanded;
  final VoidCallback onTap;
  final ValueChanged<WorkItemSummary> onItemTap;

  const _StageCard({
    required this.stage,
    required this.expanded,
    required this.onTap,
    required this.onItemTap,
  });

  Color _statusColor(AppColors c) {
    switch (stage.status) {
      case _StageStatus.completed:
        return c.ok;
      case _StageStatus.active:
        return c.warn;
      case _StageStatus.waiting:
        return c.muted;
    }
  }

  IconData get _statusIcon {
    switch (stage.status) {
      case _StageStatus.completed:
        return LucideIcons.check;
      case _StageStatus.active:
        return LucideIcons.refreshCw;
      case _StageStatus.waiting:
        return LucideIcons.clock;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final color = _statusColor(c);
    final done = stage.items.where((item) => item.isCompleted).length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(Sizes.rCard),
        border: Border.all(color: c.border),
        boxShadow: kartGolgesi(context),
      ),
      child: Column(
        children: [
          Pressable(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .13),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_statusIcon, size: 22, color: color),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.title,
                          style: TextStyle(
                            fontFamily: kDisplay,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            letterSpacing: -.2,
                            color: c.ink,
                          ),
                        ),
                        if (stage.items.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            '$done / ${stage.items.length}',
                            style: TextStyle(fontFamily: kBody, fontSize: 14, color: c.muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? .5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    child: Icon(LucideIcons.chevronDown, size: 26, color: c.sub),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Container(
                    width: double.infinity,
                    color: c.surface2,
                    padding: const EdgeInsets.fromLTRB(20, 4, 18, 14),
                    child: stage.items.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Text(
                              'Bu aşama için alt iş bulunmuyor.',
                              style: TextStyle(fontFamily: kBody, fontSize: 15, color: c.muted),
                            ),
                          )
                        : Column(
                            children: stage.items.map((item) {
                              return Pressable(
                                onTap: () => onItemTap(item),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 26,
                                        child: Center(
                                          child: item.isCompleted
                                              ? Icon(LucideIcons.check, color: c.ok, size: 22)
                                              : Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: BoxDecoration(color: c.muted, shape: BoxShape.circle),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.title,
                                          maxLines: 3,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontFamily: kBody,
                                            fontSize: 16,
                                            height: 1.35,
                                            color: item.isCompleted ? c.sub : c.ink,
                                          ),
                                        ),
                                      ),
                                      // Tamamlanan iste uyari rozeti
                                      // gosterilmiyor; is kapandi.
                                      if (item.hasWarning &&
                                          !item.isCompleted) ...[
                                        const SizedBox(width: 8),
                                        StatusBadge(icon: LucideIcons.triangleAlert, color: c.bad),
                                      ],
                                      if (item.hasDependency) ...[
                                        const SizedBox(width: 6),
                                        StatusBadge(icon: LucideIcons.link, color: c.warn),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

enum _StageStatus { completed, active, waiting }

class _ProcessStage {
  final String title;
  final _StageStatus status;
  final List<WorkItemSummary> items;

  const _ProcessStage({
    required this.title,
    required this.status,
    required this.items,
  });
}
