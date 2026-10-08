import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/state_views.dart';
import '../models/progress_stage.dart';
import '../models/work_item_summary.dart';
import '../services/progress_service.dart';
import '../services/work_item_service.dart';

class ProcessUpdatePage extends StatefulWidget {
  final String blockName;
  final int projectId;

  const ProcessUpdatePage({
    super.key,
    required this.blockName,
    required this.projectId,
  });

  @override
  State<ProcessUpdatePage> createState() => _ProcessUpdatePageState();
}

class _ProcessUpdatePageState extends State<ProcessUpdatePage> {
  final _progressService = ProgressService();
  final _workItemService = WorkItemService();

  bool _isLoading = true;
  String? _errorMessage;
  List<ProgressStage> _stages = const [];
  Map<int, List<WorkItemSummary>> _workItemsByStage = const {};

  @override
  void initState() {
    super.initState();
    _loadStages();
  }

  Future<void> _loadStages() async {
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
      final grouped = <int, List<WorkItemSummary>>{};
      for (final item in workItems) {
        grouped.putIfAbsent(item.progressBlockId, () => []).add(item);
      }

      if (!mounted) return;
      setState(() {
        _stages = stages;
        _workItemsByStage = grouped;
      });
    } on ProgressException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } on WorkItemException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openStage(ProgressStage stage) async {
    await context.push<bool>(
      '/process/${Uri.encodeComponent(widget.blockName)}/update/${stage.id}'
      '?title=${Uri.encodeComponent(stage.name)}'
      '&projectId=${widget.projectId}',
    );

    if (!mounted) return;
    await _loadStages();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.bg,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            BreadcrumbBar(
              parent: widget.blockName,
              title: 'Güncelle',
              onBack: () => context.pop(),
              onParentTap: () => context.pop(),
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
                onTap: _loadStages,
              ),
            ],
          ),
        ),
      );
    }

    if (_stages.isEmpty) {
      return RefreshIndicator(
        color: c.ink,
        onRefresh: _loadStages,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: const [
            SizedBox(height: 28),
            EmptyView(
              title: 'Bu proje tipi için süreç tanımlanmamış.',
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: c.ink,
      onRefresh: _loadStages,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
        itemCount: _stages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final stage = _stages[index];
          final items = _workItemsByStage[stage.id] ?? const <WorkItemSummary>[];
          return _StageUpdateCard(
            title: stage.name,
            percentage: stage.percentage,
            items: items,
            status: _statusForItems(items),
            onTap: () => _openStage(stage),
          );
        },
      ),
    );
  }

  _StageStatus _statusForItems(List<WorkItemSummary> items) {
    if (items.isEmpty) return _StageStatus.waiting;
    if (items.every((item) => item.status == 'COMPLETED')) {
      return _StageStatus.completed;
    }
    if (items.every((item) => item.status == 'WAITING')) {
      return _StageStatus.waiting;
    }
    return _StageStatus.active;
  }
}

class _StageUpdateCard extends StatelessWidget {
  final String title;
  final double percentage;
  final List<WorkItemSummary> items;
  final _StageStatus status;
  final VoidCallback onTap;

  const _StageUpdateCard({
    required this.title,
    required this.percentage,
    required this.items,
    required this.status,
    required this.onTap,
  });

  Color _statusColor(AppColors c) {
    switch (status) {
      case _StageStatus.completed:
        return c.ok;
      case _StageStatus.active:
        return c.warn;
      case _StageStatus.waiting:
        return c.muted;
    }
  }

  IconData get _statusIcon {
    switch (status) {
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

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
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
                    title,
                    style: TextStyle(
                      fontFamily: kDisplay,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: -.2,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${items.length} alt iş • %${percentage.round()}',
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 13.5,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(LucideIcons.pencil, size: 22, color: c.sub),
          ],
        ),
      ),
    );
  }
}

enum _StageStatus { completed, active, waiting }
