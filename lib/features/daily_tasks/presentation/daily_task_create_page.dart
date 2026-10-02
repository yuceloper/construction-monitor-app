import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:record/record.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
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

  /// Alanda gorunen metin: secim yapilmadiysa bos birakiliyor ki
  /// ipucu yazisi gorunsun.
  String get _selectedProjectLabel {
    if (_projectId == null) return '';
    for (final project in _projects) {
      if (project.id == _projectId) {
        return '${project.isShop ? 'Dükkanlar' : 'Evler'} - ${project.name}';
      }
    }
    return '';
  }

  /// Blok secimi: acilir listede butun bloklar alt alta siralaniyordu ve
  /// santiyede yuzlerce blok olabilir. Panelde once arama, altinda Evler ve
  /// Dukkanlar ayri basliklar altinda listeleniyor.
  Future<void> _openProjectPicker() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ProjectPickerSheet(
        projects: _projects,
        selectedId: _projectId,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _projectId = selected);
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
              title: 'Ekle',
              onBack: () => context.pop(false),
              onParentTap: () => context.pop(false),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(AppColors c) {
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );

    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      filled: true,
      fillColor: c.surface2,
      border: border(c.border2),
      enabledBorder: border(c.border2),
      disabledBorder: border(c.border),
      focusedBorder: border(c.accent, 1.8),
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
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kBody, fontSize: 16, height: 1.45, color: c.ink),
              ),
              const SizedBox(height: 16),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: _loadFormData,
              ),
            ],
          ),
        ),
      );
    }

    final hint = TextStyle(fontFamily: kBody, fontSize: 16, color: c.faint);
    final value = TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      children: [
        _FormRow(
          label: 'Ev/Dükkan Blok',
          child: _PickerField(
            text: _selectedProjectLabel,
            hintStyle: hint,
            valueStyle: value,
            onTap: _isSaving ? null : _openProjectPicker,
          ),
        ),
        _FormRow(
          label: 'Kritiklik Seviyesi',
          child: DropdownButtonFormField<String>(
            initialValue: _priority,
            hint: Text('Seçiniz', style: hint),
            isExpanded: true,
            icon: Icon(LucideIcons.chevronDown, size: 20, color: c.sub),
            dropdownColor: c.surface,
            borderRadius: BorderRadius.circular(16),
            style: value,
            items: [
              DropdownMenuItem(value: 'LOW', child: Text('Düşük', style: value)),
              DropdownMenuItem(value: 'MEDIUM', child: Text('Orta', style: value)),
              DropdownMenuItem(value: 'HIGH', child: Text('Yüksek', style: value)),
            ],
            onChanged: _isSaving ? null : (value) => setState(() => _priority = value),
            decoration: _fieldDecoration(c),
          ),
        ),
        _FormRow(
          label: 'İlgili Kişi',
          child: DropdownButtonFormField<int>(
            initialValue: _memberId,
            hint: Text('Seçiniz', style: hint),
            isExpanded: true,
            icon: Icon(LucideIcons.chevronDown, size: 20, color: c.sub),
            dropdownColor: c.surface,
            borderRadius: BorderRadius.circular(16),
            style: value,
            items: _members
                .map((member) => DropdownMenuItem(
                      value: member.id,
                      child: Text(member.fullName, style: value),
                    ))
                .toList(),
            onChanged: _isSaving ? null : (value) => setState(() => _memberId = value),
            decoration: _fieldDecoration(c),
          ),
        ),
        _FormRow(
          label: 'Fotoğraf',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _OutlineAction(
                icon: LucideIcons.camera,
                label: _photos.isEmpty
                    ? 'Fotoğraf ekle'
                    : '${_photos.length} fotoğraf seçildi',
                onTap: _isSaving ? null : _pickPhotos,
              ),
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _photos
                      .asMap()
                      .entries
                      .map((entry) => _FileChip(
                            name: entry.value.name,
                            onRemove: _isSaving ? null : () => _removePhoto(entry.key),
                          ))
                      .toList(),
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
              // Kayit yokken bu buton "Fotograf ekle" ile ayni agirlikta
              // duruyor; ekranin birincil eylemi KAYDET. Kayit basladiginda
              // dolu kirmiziya donuyor, cunku o an devam eden bir durum var.
              Pressable(
                onTap: _isSaving ? null : _toggleRecording,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _isRecording ? c.bad : c.surface2,
                    borderRadius: BorderRadius.circular(Sizes.rField),
                    border: _isRecording
                        ? null
                        : Border.all(color: c.border2, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isRecording ? LucideIcons.square : LucideIcons.mic,
                        size: 19,
                        color: _isRecording ? c.surface : c.accent,
                      ),
                      const SizedBox(width: 9),
                      Text(
                        _isRecording
                            ? 'Kaydı Durdur'
                            : (_audioPath == null ? 'Sesli not kaydet' : 'Yeniden kaydet'),
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: _isRecording ? c.surface : c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_audioPath != null && !_isRecording)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Sesli not hazır',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 14.5,
                            color: c.ok,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Pressable(
                        onTap: _removeAudio,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(LucideIcons.trash2, size: 19, color: c.bad),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Not',
          style: TextStyle(
            fontFamily: kDisplay,
            fontSize: 18,
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
          maxLines: 7,
          maxLength: 500,
          inputFormatters: [LengthLimitingTextInputFormatter(500)],
          style: TextStyle(fontFamily: kBody, fontSize: 16, height: 1.4, color: c.ink),
          cursorColor: c.accent,
          decoration: _fieldDecoration(c).copyWith(
            hintText: 'Lütfen detay giriniz.',
            hintStyle: hint,
            counterStyle: TextStyle(fontFamily: kBody, fontSize: 12, color: c.muted),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'KAYDET',
          busy: _isSaving,
          onPressed: _isSaving ? null : _save,
        ),
      ],
    );
  }
}

/// Alan basligi ustte, kutu altta.
/// Form alani gorunumunde duran, dokununca panel acan dugme.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.text,
    required this.hintStyle,
    required this.valueStyle,
    required this.onTap,
  });

  final String text;
  final TextStyle hintStyle;
  final TextStyle valueStyle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(Sizes.rField),
            border: Border.all(color: c.border2, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text.isEmpty ? 'Seçiniz' : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.isEmpty ? hintStyle : valueStyle,
                ),
              ),
              Icon(LucideIcons.chevronDown, size: 20, color: c.sub),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blok secme paneli: arama kutusu ve gruplu liste.
class _ProjectPickerSheet extends StatefulWidget {
  const _ProjectPickerSheet({required this.projects, required this.selectedId});

  final List<ProjectSummary> projects;
  final int? selectedId;

  @override
  State<_ProjectPickerSheet> createState() => _ProjectPickerSheetState();
}

class _ProjectPickerSheetState extends State<_ProjectPickerSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProjectSummary> _filtre(bool dukkan) {
    final q = _query.trim().toLowerCase();
    return widget.projects
        .where((p) => p.isShop == dukkan)
        .where((p) => q.isEmpty || p.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final evler = _filtre(false);
    final dukkanlar = _filtre(true);
    final bosmu = evler.isEmpty && dukkanlar.isEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .78,
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          10,
          16,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border2,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 12),
              child: Text(
                'Ev/Dükkan Blok',
                style: TextStyle(
                  fontFamily: kDisplay,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.3,
                  color: c.ink,
                ),
              ),
            ),
            TextField(
              controller: _searchController,
              autofocus: false,
              onChanged: (v) => setState(() => _query = v),
              style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink),
              cursorColor: c.accent,
              decoration: InputDecoration(
                hintText: 'Blok ara',
                hintStyle:
                    TextStyle(fontFamily: kBody, fontSize: 16, color: c.faint),
                prefixIcon:
                    Icon(LucideIcons.search, size: 20, color: c.muted),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: Icon(LucideIcons.x, size: 19, color: c.sub),
                      ),
                filled: true,
                fillColor: c.surface2,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sizes.rField),
                  borderSide: BorderSide(color: c.border2, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sizes.rField),
                  borderSide: BorderSide(color: c.border2, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(Sizes.rField),
                  borderSide: BorderSide(color: c.accent, width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: bosmu
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: EmptyState(
                        message: 'Aramanıza uygun blok bulunamadı.',
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        if (evler.isNotEmpty) ...[
                          _GrupBasligi(metin: 'Evler'),
                          for (final p in evler)
                            _BlokSatiri(
                              project: p,
                              secili: p.id == widget.selectedId,
                            ),
                        ],
                        if (dukkanlar.isNotEmpty) ...[
                          if (evler.isNotEmpty) const SizedBox(height: 6),
                          _GrupBasligi(metin: 'Dükkanlar'),
                          for (final p in dukkanlar)
                            _BlokSatiri(
                              project: p,
                              secili: p.id == widget.selectedId,
                            ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GrupBasligi extends StatelessWidget {
  const _GrupBasligi({required this.metin});

  final String metin;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        metin,
        style: TextStyle(
          fontFamily: kBody,
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
          letterSpacing: .6,
          color: c.muted,
        ),
      ),
    );
  }
}

class _BlokSatiri extends StatelessWidget {
  const _BlokSatiri({required this.project, required this.secili});

  final ProjectSummary project;
  final bool secili;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        onTap: () => Navigator.of(context).pop(project.id),
        child: Container(
          height: 52,
          padding: const EdgeInsets.fromLTRB(16, 0, 14, 0),
          decoration: BoxDecoration(
            color: secili ? c.accent.withValues(alpha: .08) : c.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: secili ? c.accent : c.border,
              width: secili ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  project.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
              ),
              if (secili) Icon(LucideIcons.check, size: 20, color: c.accent),
            ],
          ),
        ),
      ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: kBody,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
              color: context.colors.ink,
            ),
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(Sizes.rField),
            border: Border.all(color: c.border2, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: c.accent),
              const SizedBox(width: 9),
              Text(
                label,
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FileChip extends StatelessWidget {
  const _FileChip({required this.name, required this.onRemove});

  final String name;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 8, 6, 8),
      decoration: BoxDecoration(
        color: c.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.image, size: 17, color: c.muted),
          const SizedBox(width: 7),
          SizedBox(
            width: 92,
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontFamily: kBody, fontSize: 13.5, color: c.ink),
            ),
          ),
          Pressable(
            onTap: onRemove,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Icon(LucideIcons.x, size: 16, color: c.sub),
            ),
          ),
        ],
      ),
    );
  }
}
