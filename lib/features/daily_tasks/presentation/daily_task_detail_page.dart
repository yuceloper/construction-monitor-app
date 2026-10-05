import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
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
        _status =
            const {'TODO', 'IN_PROGRESS', 'COMPLETED'}.contains(task.status)
            ? task.status
            : 'TODO';
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
      // Guncellemeden sonra listeye donuluyor ki yapilan degisiklik
      // listede goruneblisin.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      context.pop(true);
    } on DailyTaskException catch (error) {
      if (mounted) _show(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
            BreadcrumbBar(
              parent: 'Günlük İşler',
              title: 'İş Detayı',
              onBack: () => context.pop(true),
              onParentTap: () => context.pop(true),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final c = context.colors;

    if (_isLoading && _task == null) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: c.ink),
        ),
      );
    }
    if (_errorMessage != null && _task == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 16),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: _load,
              ),
            ],
          ),
        ),
      );
    }

    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );

    final task = _task!;
    return RefreshIndicator(
      color: c.ink,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
              boxShadow: kLiftShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Özet',
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.4,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryLine(
                  label: 'Blok',
                  value: '${task.typeLabel} - ${task.projectName}',
                ),
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
            Text(
              'Fotoğraflar',
              style: TextStyle(
                fontFamily: kDisplay,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
                color: c.ink,
              ),
            ),
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
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 145,
                      child: Image.network(
                        _service.photoUrl(id),
                        headers: _service.photoHeaders(),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: c.inset,
                          alignment: Alignment.center,
                          child: Icon(LucideIcons.imageOff, color: c.faint),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          if (task.audioNoteId != null) ...[
            const SizedBox(height: 14),
            // Ozet ve Durum/Not kendi kartlarindaydi, bu bolum zeminde
            // duruyordu; ucu de ayni kart olsun diye sarmalandi.
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: c.border),
                boxShadow: kLiftShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesli Not',
                    style: TextStyle(
                      fontFamily: kDisplay,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.2,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Pressable(
                    onTap: _toggleAudio,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: c.accent.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: c.accent.withValues(alpha: .22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: _isAudioLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: c.surface,
                                    ),
                                  )
                                : Icon(
                                    _isAudioPlaying
                                        ? LucideIcons.pause
                                        : LucideIcons.play,
                                    color: c.surface,
                                    size: 22,
                                  ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              _isAudioPlaying
                                  ? 'Sesli not oynatılıyor'
                                  : 'Sesli notu dinle',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: kBody,
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                                color: c.ink,
                              ),
                            ),
                          ),
                          Icon(LucideIcons.volume2, color: c.accent, size: 21),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Ozet karttaydi, hemen altindaki alanlar sayfaya serbest
          // oturuyordu. Duzenlenebilir alanlar da kendi kartinda.
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border),
              boxShadow: kLiftShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Durum',
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 9),
                DropdownButtonFormField<String>(
                  value: _status,
                  isExpanded: true,
                  icon: Icon(LucideIcons.chevronDown, size: 20, color: c.sub),
                  dropdownColor: c.surface,
                  borderRadius: BorderRadius.circular(16),
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 16,
                    color: c.ink,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'TODO',
                      child: Text(
                        'Başlanacak',
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 16,
                          color: c.ink,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'IN_PROGRESS',
                      child: Text(
                        'Devam Ediyor',
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 16,
                          color: c.ink,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'COMPLETED',
                      child: Text(
                        'Tamamlandı',
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 16,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ],
                  onChanged: _isSaving
                      ? null
                      : (value) => setState(() => _status = value ?? _status),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                    filled: true,
                    fillColor: c.surface2,
                    border: border(c.border2),
                    enabledBorder: border(c.border2),
                    focusedBorder: border(c.accent, 1.8),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Not',
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 9),
                TextField(
                  controller: _noteController,
                  enabled: !_isSaving,
                  minLines: 5,
                  maxLines: 8,
                  maxLength: 500,
                  inputFormatters: [LengthLimitingTextInputFormatter(500)],
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 16,
                    height: 1.4,
                    color: c.ink,
                  ),
                  cursorColor: c.accent,
                  decoration: InputDecoration(
                    hintText: 'Lütfen detay giriniz.',
                    hintStyle: TextStyle(
                      fontFamily: kBody,
                      fontSize: 16,
                      color: c.faint,
                    ),
                    counterStyle: TextStyle(
                      fontFamily: kBody,
                      fontSize: 12,
                      color: c.muted,
                    ),
                    filled: true,
                    fillColor: c.surface2,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: border(c.border2),
                    enabledBorder: border(c.border2),
                    disabledBorder: border(c.border),
                    focusedBorder: border(c.accent, 1.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          PrimaryButton(
            label: 'GÜNCELLE',
            busy: _isSaving,
            onPressed: _isSaving ? null : _save,
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
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
