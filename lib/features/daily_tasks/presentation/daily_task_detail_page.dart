import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_header.dart';
import '../models/daily_task_summary.dart';
import '../services/daily_task_service.dart';

class DailyTaskDetailPage extends StatefulWidget {
  final int taskId;

  const DailyTaskDetailPage({super.key, required this.taskId});

  @override
  State<DailyTaskDetailPage> createState() => _DailyTaskDetailPageState();
}

class _DailyTaskDetailPageState extends State<DailyTaskDetailPage> {
  final _service = DailyTaskService();
  final _noteController = TextEditingController();
  final _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAudioLoading = false;
  bool _isAudioPlaying = false;
  String? _audioPath;
  String? _errorMessage;
  DailyTaskSummary? _task;
  String _status = 'IN_PROGRESS';

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isAudioPlaying = false);
    });
    _load();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final task = await _service.getTask(widget.taskId);
      if (!mounted) return;
      setState(() {
        _task = task;
        _noteController.text = task.notes.isNotEmpty ? task.notes : task.title;
        _status = task.status == 'COMPLETED' ? 'COMPLETED' : 'IN_PROGRESS';
      });
    } on DailyTaskException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAudio() async {
    final audioId = _task?.audioNoteId;
    if (audioId == null || _isAudioLoading) return;

    try {
      if (_isAudioPlaying) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isAudioPlaying = false);
        return;
      }

      if (_audioPath == null) {
        setState(() => _isAudioLoading = true);
        _audioPath = await _service.downloadAudioNote(audioId);
      }

      if (_audioPlayer.state == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        await _audioPlayer.play(DeviceFileSource(_audioPath!));
      }
      if (mounted) setState(() => _isAudioPlaying = true);
    } on DailyTaskException catch (error) {
      if (mounted) _show(error.message);
    } catch (_) {
      if (mounted) _show('Sesli not oynatılamadı.');
    } finally {
      if (mounted) setState(() => _isAudioLoading = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      _show('Not alanı zorunludur.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final task = await _service.updateTask(
        taskId: widget.taskId,
        status: _status,
        note: note,
      );
      if (!mounted) return;
      setState(() => _task = task);
      _show('Günlük iş güncellendi.');
    } on DailyTaskException catch (error) {
      if (mounted) _show(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
                    onTap: () => context.pop(true),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.pop(true),
                    child: const Text(
                      'Günlük İşler',
                      style: TextStyle(
                        fontSize: 20,
                        color: Color(0xFF0066A6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Text(' > ', style: TextStyle(fontSize: 20)),
                  const Expanded(
                    child: Text(
                      'İş Detayı',
                      style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
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
    if (_isLoading && _task == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    if (_errorMessage != null && _task == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _load, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    final task = _task!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDED),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Özet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 14),
                _SummaryLine(label: 'Blok', value: '${task.typeLabel} - ${task.projectName}'),
                _SummaryLine(label: 'İlgili Kişi', value: task.assignedToName),
                _SummaryLine(label: 'Kritiklik', value: task.priorityLabel),
                _SummaryLine(
                  label: 'Mevcut Durum',
                  value: task.status == 'COMPLETED'
                      ? 'Tamamlandı'
                      : task.status == 'IN_PROGRESS'
                          ? 'Devam Ediyor'
                          : 'Başlanacak',
                ),
              ],
            ),
          ),
          if (task.photoIds.isNotEmpty) ...[
            const SizedBox(height: 22),
            const Text('Fotoğraflar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            SizedBox(
              height: 125,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: task.photoIds.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) {
                  final id = task.photoIds[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 145,
                      child: Image.network(
                        _service.photoUrl(id),
                        headers: _service.photoHeaders(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFEDEDED),
                          alignment: Alignment.center,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (task.audioNoteId != null) ...[
            const SizedBox(height: 22),
            const Text('Sesli Not', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFFEAF4FA),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _toggleAudio,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0066A6),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: _isAudioLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(
                                _isAudioPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isAudioPlaying ? 'Sesli not oynatılıyor' : 'Sesli notu dinle',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ),
                      const Icon(Icons.volume_up_outlined, color: Color(0xFF0066A6)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Durum', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _status,
            items: const [
              DropdownMenuItem(value: 'IN_PROGRESS', child: Text('Devam Ediyor')),
              DropdownMenuItem(value: 'COMPLETED', child: Text('Tamamlandı')),
            ],
            onChanged: _isSaving ? null : (value) => setState(() => _status = value ?? 'IN_PROGRESS'),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 18),
          const Text('Not', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            enabled: !_isSaving,
            minLines: 5,
            maxLines: 8,
            maxLength: 500,
            inputFormatters: [LengthLimitingTextInputFormatter(500)],
            decoration: const InputDecoration(
              hintText: 'Lütfen detay giriniz.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('GÜNCELLE', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
