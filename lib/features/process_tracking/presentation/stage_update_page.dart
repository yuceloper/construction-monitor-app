import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_header.dart';
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

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(false),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.stageTitle,
                      style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
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

    if (_errorMessage != null && _works.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loadWorks,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      children: [
        if (_errorMessage != null) ...[
          Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
          decoration: BoxDecoration(
            color: const Color(0xFFEDEDED),
            borderRadius: BorderRadius.circular(18),
          ),
          child: _works.isEmpty
              ? const Text('Bu süreç için alt iş bulunmuyor.')
              : Column(
                  children: _works.asMap().entries.map((entry) {
                    final index = entry.key;
                    final work = entry.value;
                    return Padding(
                      padding: EdgeInsets.only(bottom: index == _works.length - 1 ? 0 : 16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 34,
                            height: 34,
                            child: Checkbox(
                              value: work.completed,
                              activeColor: Colors.black,
                              onChanged: _isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _works[index] = work.copy(completed: value ?? false);
                                      });
                                    },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _openWorkDetail(work),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        work.title,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w500,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    if (work.hasDependency) ...[
                                      const SizedBox(width: 8),
                                      const Tooltip(
                                        message: 'Bağımlı iş var',
                                        child: Icon(
                                          Icons.link_rounded,
                                          size: 24,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                    if (work.hasWarning) ...[
                                      const SizedBox(width: 8),
                                      Tooltip(
                                        message: 'Uyarı var',
                                        child: Icon(
                                          Icons.warning_amber_rounded,
                                          size: 25,
                                          color: work.hasCriticalWarning
                                              ? Colors.red
                                              : const Color(0xFFE0A800),
                                        ),
                                      ),
                                    ],
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
        const SizedBox(height: 42),
        SizedBox(
          height: 58,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.black38,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'KAYDET',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
                  ),
          ),
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
