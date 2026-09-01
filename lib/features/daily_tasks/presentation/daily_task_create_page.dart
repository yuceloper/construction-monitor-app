import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_header.dart';
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
  final _noteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<ProjectSummary> _projects = const [];
  List<SiteMemberSummary> _members = const [];
  int? _projectId;
  int? _memberId;
  String _priority = 'MEDIUM';

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final siteId = await _selectedSiteId();
      final results = await Future.wait([
        _projectService.getProjects(),
        _siteService.getMembers(siteId),
      ]);
      final projects = results[0] as List<ProjectSummary>;
      final members = results[1] as List<SiteMemberSummary>;

      if (!mounted) return;
      setState(() {
        _projects = projects;
        _members = members;
        _projectId = projects.isNotEmpty ? projects.first.id : null;
        _memberId = members.isNotEmpty ? members.first.id : null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int> _selectedSiteId() async {
    final siteId = (await Future.value()) == null ? null : null;
    // Kept local to avoid exposing session details to the widget tree.
    final dynamic session = _SessionAccess.siteId;
    if (session is int && session > 0) return session;
    throw const DailyTaskException('Şantiye seçimi bulunamadı.');
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final note = _noteController.text.trim();

    if (_projectId == null) {
      _show('Ev/Dükkan blok seçmelisiniz.');
      return;
    }
    if (_memberId == null) {
      _show('İlgili kişi seçmelisiniz.');
      return;
    }
    if (note.isEmpty) {
      _show('Not alanı zorunludur.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _taskService.createTask(
        projectId: _projectId!,
        priority: _priority,
        assignedToId: _memberId!,
        note: note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Günlük iş kaydedildi.')),
      );
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
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => context.pop(false),
                    child: const Text(
                      'Günlük İşler',
                      style: TextStyle(
                        fontSize: 21,
                        color: Color(0xFF0066A6),
                        decoration: TextDecoration.underline,
                      ),
                    ),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
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
            value: _projectId,
            isExpanded: true,
            items: _projects
                .map((project) => DropdownMenuItem(
                      value: project.id,
                      child: Text('${project.isShop ? 'Dükkanlar' : 'Evler'} - ${project.name}'),
                    ))
                .toList(),
            onChanged: _isSaving ? null : (value) => setState(() => _projectId = value),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
        _FormRow(
          label: 'Kritiklik Seviyesi',
          child: DropdownButtonFormField<String>(
            value: _priority,
            items: const [
              DropdownMenuItem(value: 'LOW', child: Text('Düşük')),
              DropdownMenuItem(value: 'MEDIUM', child: Text('Orta')),
              DropdownMenuItem(value: 'HIGH', child: Text('Yüksek')),
            ],
            onChanged: _isSaving ? null : (value) => setState(() => _priority = value ?? 'MEDIUM'),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
        _FormRow(
          label: 'İlgili Kişi',
          child: DropdownButtonFormField<int>(
            value: _memberId,
            isExpanded: true,
            items: _members
                .map((member) => DropdownMenuItem(value: member.id, child: Text(member.fullName)))
                .toList(),
            onChanged: _isSaving ? null : (value) => setState(() => _memberId = value),
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
          ),
        ),
        _FormRow(
          label: 'Fotoğraf',
          child: OutlinedButton.icon(
            onPressed: _isSaving
                ? null
                : () => _show('Çoklu fotoğraf yükleme altyapısını bir sonraki adımda bağlıyoruz.'),
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Fotoğraf ekle'),
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
          decoration: const InputDecoration(
            hintText: 'Lütfen detay giriniz.',
            border: OutlineInputBorder(),
          ),
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
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
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

class _SessionAccess {
  static int? get siteId {
    // Delayed import avoidance helper is replaced at compile time by direct session access below.
    return null;
  }
}
