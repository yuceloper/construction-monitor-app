import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
import '../models/work_item_summary.dart';
import '../services/work_item_service.dart';

class StageUpdatePage extends StatefulWidget {
  final String blockName;
  final int stageId;
  final String stageTitle;
  final int projectId;

  const StageUpdatePage({
    super.key,
    required this.blockName,
    required this.stageId,
    required this.stageTitle,
    required this.projectId,
  });

  @override
  State<StageUpdatePage> createState() => _StageUpdatePageState();
}

class _StageUpdatePageState extends State<StageUpdatePage> {
  final _workItemService = WorkItemService();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<_EditableWork> _works = const [];

  @override
  void initState() {
    super.initState();
    _loadWorks();
  }

  Future<void> _loadWorks() async {
    if (widget.projectId <= 0 || widget.stageId <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Proje veya süreç kimliği bulunamadı.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await _workItemService.getByProject(widget.projectId);
      final stageItems = items
          .where((item) => item.progressBlockId == widget.stageId)
          .map(_EditableWork.fromSummary)
          .toList();

      if (!mounted) return;
      setState(() => _works = stageItems);
    } on WorkItemException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Alt işler yüklenirken beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openWorkDetail(_EditableWork work) async {
    await context.push(
      '/process/${Uri.encodeComponent(widget.blockName)}/work/${work.id}'
      '?title=${Uri.encodeComponent(work.title)}',
    );

    if (mounted) await _loadWorks();
  }

  Future<void> _save() async {
    if (_isSaving) return;

    final changedWorks = _works.where((work) => work.changed).toList();
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      for (final work in changedWorks) {
        await _workItemService.updateStatus(work.id, completed: work.completed);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Değişiklikler kaydedildi.')),
      );
      context.pop(changedWorks.isNotEmpty);
    } on WorkItemException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
      await _loadWorks();
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Değişiklikler kaydedilirken beklenmeyen bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.bg,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            ScreenTitleBar(
              title: widget.stageTitle,
              onBack: () => context.pop(false),
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

    if (_errorMessage != null && _works.isEmpty) {
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
                onTap: _loadWorks,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      children: [
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            decoration: BoxDecoration(
              color: c.bad.withValues(alpha: .09),
              borderRadius: BorderRadius.circular(Sizes.rField),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.circleAlert, size: 18, color: c.bad),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(fontFamily: kBody, fontSize: 14.5, height: 1.4, color: c.bad),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.border),
            boxShadow: kLiftShadow,
          ),
          child: _works.isEmpty
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
                  child: Text(
                    'Bu süreç için alt iş bulunmuyor.',
                    style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.muted),
                  ),
                )
              : Column(
                  children: _works.asMap().entries.map((entry) {
                    final index = entry.key;
                    final work = entry.value;
                    return Container(
                      decoration: BoxDecoration(
                        border: index == 0
                            ? null
                            : Border(top: BorderSide(color: c.line)),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 10, 0, 10),
                            child: SizedBox(
                              width: 34,
                              height: 34,
                              child: Checkbox(
                                value: work.completed,
                                activeColor: c.ink,
                                checkColor: c.bg,
                                side: BorderSide(color: c.border2, width: 1.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                onChanged: _isSaving
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _works[index] = work.copy(completed: value ?? false);
                                        });
                                      },
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Pressable(
                              onTap: () => _openWorkDetail(work),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(0, 16, 14, 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        work.title,
                                        style: TextStyle(
                                          fontFamily: kBody,
                                          fontSize: 18,
                                          height: 1.3,
                                          fontWeight: FontWeight.w500,
                                          color: work.completed ? c.sub : c.ink,
                                        ),
                                      ),
                                    ),
                                    if (work.hasDependency) ...[
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: 'Bağımlı iş var',
                                        child: Icon(LucideIcons.link, size: 21, color: c.bad),
                                      ),
                                    ],
                                    if (work.hasWarning) ...[
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: 'Uyarı var',
                                        child: Icon(LucideIcons.triangleAlert, size: 21, color: c.bad),
                                      ),
                                    ],
                                    const SizedBox(width: 8),
                                    Icon(LucideIcons.chevronRight, size: 19, color: c.muted),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          label: 'KAYDET',
          busy: _isSaving,
          onPressed: _isSaving ? null : _save,
        ),
      ],
    );
  }
}

class _EditableWork {
  final int id;
  final String title;
  final bool completed;
  final bool initialCompleted;
  final bool hasDependency;
  final bool hasWarning;
  final bool hasCriticalWarning;

  const _EditableWork({
    required this.id,
    required this.title,
    required this.completed,
    required this.initialCompleted,
    required this.hasDependency,
    required this.hasWarning,
    required this.hasCriticalWarning,
  });

  factory _EditableWork.fromSummary(WorkItemSummary item) {
    return _EditableWork(
      id: item.id,
      title: item.title,
      completed: item.isCompleted,
      initialCompleted: item.isCompleted,
      hasDependency: item.hasDependency,
      hasWarning: item.hasWarning,
      hasCriticalWarning: item.hasCriticalWarning,
    );
  }

  bool get changed => completed != initialCompleted;

  _EditableWork copy({bool? completed}) {
    return _EditableWork(
      id: id,
      title: title,
      completed: completed ?? this.completed,
      initialCompleted: initialCompleted,
      hasDependency: hasDependency,
      hasWarning: hasWarning,
      hasCriticalWarning: hasCriticalWarning,
    );
  }
}
