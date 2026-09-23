import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';

import '../../../core/widgets/app_header.dart';
import '../../auth/services/session_manager.dart';
import '../../process_tracking/models/project_summary.dart';
import '../../process_tracking/services/project_service.dart';
import '../../site_selection/models/site_member_summary.dart';
import '../../site_selection/services/site_service.dart';
import '../services/daily_task_service.dart';

class DailyTaskCreatePage extends StatefulWidget {
  const DailyTaskCreatePage({super.key});

  @override
  State<DailyTaskCreatePage> createState() => _DailyTaskCreatePageState();
}

class _DailyTaskCreatePageState extends State<DailyTaskCreatePage> {
  final _projectService = ProjectService();
  final _siteService = SiteService();
  final _taskService = DailyTaskService();
  final _imagePicker = ImagePicker();
  final _recorder = AudioRecorder();
  final _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isRecording = false;
  String? _errorMessage;
  List<ProjectSummary> _projects = const [];
  List<SiteMemberSummary> _members = const [];
  List<XFile> _photos = const [];
  int? _projectId;
  int? _memberId;
  String? _priority;
  String? _audioPath;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final siteId = SessionManager.instance.selectedSiteId;
      if (siteId == null || siteId <= 0) throw const DailyTaskException('Şantiye seçimi bulunamadı.');
      final results = await Future.wait([
        _projectService.getProjects(),
        _siteService.getMembers(siteId),
      ]);
      if (!mounted) return;
      setState(() {
        _projects = results[0] as List<ProjectSummary>;
        _members = results[1] as List<SiteMemberSummary>;
        _projectId = null;
        _memberId = null;
        _priority = null;
      });
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickPhotos() async {
    if (_isSaving) return;
    try {
      final picked = await _imagePicker.pickMultiImage(imageQuality: 85, maxWidth: 2400);
      if (!mounted || picked.isEmpty) return;
      final unique = <String, XFile>{};
      for (final photo in [..._photos, ...picked]) {
        unique[photo.path] = photo;
      }
      setState(() => _photos = unique.values.take(10).toList());
      if (unique.length > 10) _show('En fazla 10 fotoğraf ekleyebilirsiniz. İlk 10 fotoğraf seçildi.');
    } catch (_) {
      if (mounted) _show('Fotoğraflar seçilemedi.');
    }
  }

  void _removePhoto(int index) {
    if (_isSaving) return;
    setState(() {
      final copy = [..._photos]..removeAt(index);
      _photos = copy;
    });
  }

  Future<void> _toggleRecording() async {
    if (_isSaving) return;
    try {
      if (_isRecording) {
        final path = await _recorder.stop();
        if (!mounted) return;
        setState(() {
          _isRecording = false;
          if (path != null) _audioPath = path;
        });
        return;
      }

      if (!await _recorder.hasPermission()) {
        _show('Sesli not için mikrofon izni gerekli.');
        return;
      }
      final path = '${Directory.systemTemp.path}/daily-task-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000, sampleRate: 44100),
        path: path,
      );
      if (mounted) setState(() => _isRecording = true);
    } catch (_) {
      if (mounted) _show('Ses kaydı başlatılamadı.');
    }
  }

  Future<void> _removeAudio() async {
    if (_isRecording) await _recorder.stop();
    final path = _audioPath;
    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {}
    }
    if (mounted) setState(() {
      _isRecording = false;
      _audioPath = null;
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (_isRecording) {
      _show('Önce ses kaydını durdurun.');
      return;
    }
    final note = _noteController.text.trim();
    if (_projectId == null) return _show('Ev/Dükkan blok seçmelisiniz.');
    if (_priority == null) return _show('Kritiklik seviyesi seçmelisiniz.');
    if (_memberId == null) return _show('İlgili kişi seçmelisiniz.');
    if (note.isEmpty) return _show('Not alanı zorunludur.');

    setState(() => _isSaving = true);
    try {
      final task = await _taskService.createTask(
        projectId: _projectId!,
        priority: _priority!,
        assignedToId: _memberId!,
        note: note,
      );
      if (_photos.isNotEmpty) await _taskService.uploadPhotos(task.id, _photos);
      if (_audioPath != null) await _taskService.uploadAudioNote(task.id, _audioPath!);

      if (!mounted) return;
      _show('Günlük iş kaydedildi.');
      context.pop(true);
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
                    onTap: () => context.pop(false),
                    child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.arrow_back_ios_new, size: 20)),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.pop(false),
                    child: const Text('Günlük İşler', style: TextStyle(fontSize: 21, color: Color(0xFF0066A6), decoration: TextDecoration.underline)),
                  ),
                  const Text(' > ', style: TextStyle(fontSize: 20)),
                  const Text('Ekle', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w600)),
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
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Colors.black));
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadFormData, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
      children: [
        _FormRow(
          label: 'Ev/Dükkan Blok',
          child: DropdownButtonFormField<int>(
            initialValue: _projectId,
            hint: const Text('Seçiniz'),
            isExpanded: true,
            items: _projects.map((project) => DropdownMenuItem(
              value: project.id,
              child: Text('${project.isShop ? 'Dükkanlar' : 'Evler'} - ${project.name}'),
            )).toList(),
            onChanged: _isSaving ? null : (value) => setState(() => _projectId = value),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
        _FormRow(
          label: 'Kritiklik Seviyesi',
          child: DropdownButtonFormField<String>(
            initialValue: _priority,
            hint: const Text('Seçiniz'),
            items: const [
              DropdownMenuItem(value: 'LOW', child: Text('Düşük')),
              DropdownMenuItem(value: 'MEDIUM', child: Text('Orta')),
              DropdownMenuItem(value: 'HIGH', child: Text('Yüksek')),
            ],
            onChanged: _isSaving ? null : (value) => setState(() => _priority = value),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
        _FormRow(
          label: 'İlgili Kişi',
          child: DropdownButtonFormField<int>(
            initialValue: _memberId,
            hint: const Text('Seçiniz'),
            isExpanded: true,
            items: _members.map((member) => DropdownMenuItem(value: member.id, child: Text(member.fullName))).toList(),
            onChanged: _isSaving ? null : (value) => setState(() => _memberId = value),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
        _FormRow(
          label: 'Fotoğraf',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _pickPhotos,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(_photos.isEmpty ? 'Fotoğraf ekle' : '${_photos.length} fotoğraf seçildi'),
              ),
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _photos.asMap().entries.map((entry) => Chip(
                    avatar: const Icon(Icons.image_outlined, size: 18),
                    label: SizedBox(width: 92, child: Text(entry.value.name, overflow: TextOverflow.ellipsis)),
                    onDeleted: _isSaving ? null : () => _removePhoto(entry.key),
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
        _FormRow(
          label: 'Sesli Not',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _toggleRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isRecording ? Colors.red : const Color(0xFF0066A6),
                  foregroundColor: Colors.white,
                ),
                icon: Icon(_isRecording ? Icons.stop_rounded : Icons.mic_rounded),
                label: Text(_isRecording ? 'Kaydı Durdur' : (_audioPath == null ? 'Sesli not kaydet' : 'Yeniden kaydet')),
              ),
              if (_audioPath != null && !_isRecording)
                Row(
                  children: [
                    const Expanded(child: Text('Sesli not hazır', style: TextStyle(color: Color(0xFF11875D), fontWeight: FontWeight.w600))),
                    IconButton(onPressed: _removeAudio, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Not', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _noteController,
          enabled: !_isSaving,
          minLines: 5,
          maxLines: 7,
          maxLength: 500,
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          decoration: const InputDecoration(hintText: 'Lütfen detay giriniz.', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 58,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: _isSaving
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('KAYDET', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
          ),
        ),
      ],
    );
  }
}

class _FormRow extends StatelessWidget {
  final String label;
  final Widget child;
  const _FormRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 142,
            child: Text(label, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }
}
