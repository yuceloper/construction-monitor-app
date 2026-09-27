import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/pressable.dart';
import '../models/progress_stage.dart';
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
        _progressService.getOverallProgress(widget.projectId),
      ]);

      final stages = results[0] as List<ProgressStage>;
      final workItems = results[1] as List<WorkItemSummary>;
      final overallProgress = results[2] as double;
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
        _overallProgress = overallProgress;
      });
    } on ProgressException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on WorkItemException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Süreç detayları yüklenirken beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openUpdate() async {
    await context.push(
      '/process/${Uri.encodeComponent(widget.blockName)}/update?projectId=${widget.projectId}',
    );
    if (!mounted) return;
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final roundedProgress = _overallProgress.round();

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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: c.border),
                  boxShadow: kLiftShadow,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Genel İlerleme',
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: c.ink,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ProgressRail(percent: roundedProgress, height: 9),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '%$roundedProgress',
                                style: TextStyle(
                                  fontFamily: kDisplay,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  color: c.ink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    SmallButton(
                      label: 'Güncelle',
                      icon: LucideIcons.refreshCw,
                      onTap: _openUpdate,
                    ),
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

    if (_stages.isEmpty) {
      return RefreshIndicator(
        color: c.ink,
        onRefresh: _loadData,
        child: const CenteredScrollMessage(
          message: 'Bu proje için süreç aşaması bulunmuyor.',
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
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final progressStage = _stages[index];
          final items = _workItemsByStage[progressStage.id] ?? const <WorkItemSummary>[];
          final stage = _ProcessStage(title: progressStage.name, status: _statusForItems(items), items: items);
          final expanded = _expandedIndex == index;
          return _StageCard(
            stage: stage,
            expanded: expanded,
            onTap: () => setState(() => _expandedIndex = expanded ? null : index),
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

class _StageCard extends StatelessWidget {
  final _ProcessStage stage;
  final bool expanded;
  final VoidCallback onTap;

  const _StageCard({required this.stage, required this.expanded, required this.onTap});

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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border),
        boxShadow: kLiftShadow,
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
                            '$done / ${stage.items.length} iş kalemi tamamlandı',
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
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 26,
                                      child: item.isCompleted
                                          ? Icon(LucideIcons.check, color: c.ok, size: 22)
                                          : const SizedBox.shrink(),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontFamily: kBody,
                                          fontSize: 16,
                                          height: 1.35,
                                          color: item.isCompleted ? c.sub : c.ink,
                                        ),
                                      ),
                                    ),
                                    if (item.hasWarning) ...[
                                      const SizedBox(width: 8),
                                      Icon(LucideIcons.triangleAlert, color: c.bad, size: 21),
                                    ],
                                    if (item.hasDependency) ...[
                                      const SizedBox(width: 8),
                                      Icon(LucideIcons.link, color: c.bad, size: 21),
                                    ],
                                  ],
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

  const _ProcessStage({required this.title, required this.status, required this.items});
}
