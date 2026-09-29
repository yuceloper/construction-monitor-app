import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/pressable.dart';
import '../models/project_summary.dart';
import '../services/project_service.dart';

class ProcessTrackingPage extends StatefulWidget {
  const ProcessTrackingPage({super.key});

  @override
  State<ProcessTrackingPage> createState() => _ProcessTrackingPageState();
}

class _ProcessTrackingPageState extends State<ProcessTrackingPage> {
  final _projectService = ProjectService();

  bool _housesExpanded = false;
  bool _shopsExpanded = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<ProjectSummary> _projects = const [];

  List<ProjectSummary> get _houses =>
      _projects.where((project) => project.isHouse).toList();

  List<ProjectSummary> get _shops =>
      _projects.where((project) => project.isShop).toList();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final projects = await _projectService.getProjects();

      if (!mounted) return;
      setState(() {
        _projects = projects;
      });
    } on ProjectException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Projeler yüklenirken beklenmeyen bir hata oluştu.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openProject(ProjectSummary project) async {
    await context.push(
      '/process/${Uri.encodeComponent(project.name)}'
      '?progress=${project.roundedProgress}'
      '&projectId=${project.id}',
    );

    if (!mounted) return;
    await _loadProjects();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.bg,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            ScreenTitleBar(
              title: 'Süreç Takibi',
              onBack: () => context.go('/dashboard'),
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
                onTap: _loadProjects,
              ),
            ],
          ),
        ),
      );
    }

    // Grubu olmayan basliklar hic cizilmiyor; hicbiri yoksa tek satirlik
    // aciklama kaliyor.
    final sections = <Widget>[
      if (_houses.isNotEmpty)
        _SectionCard(
          title: 'Evler',
          countLabel: '${_houses.length} Ev',
          icon: LucideIcons.house,
          expanded: _housesExpanded,
          onTap: () {
            // Ayni anda tek panel acik kalsin.
            setState(() {
              _housesExpanded = !_housesExpanded;
              if (_housesExpanded) _shopsExpanded = false;
            });
          },
          child: _buildProjectList(projects: _houses),
        ),
      if (_shops.isNotEmpty)
        _SectionCard(
          title: 'Dükkanlar',
          countLabel: '${_shops.length} Dükkan',
          icon: LucideIcons.store,
          expanded: _shopsExpanded,
          onTap: () {
            setState(() {
              _shopsExpanded = !_shopsExpanded;
              if (_shopsExpanded) _housesExpanded = false;
            });
          },
          child: _buildProjectList(projects: _shops),
        ),
    ];

    return RefreshIndicator(
      color: c.ink,
      onRefresh: _loadProjects,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (sections.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: EmptyView(
                icon: LucideIcons.house,
                title: 'Bu şantiyede tanımlı blok bulunmamaktadır.',
              ),
            )
          else
            for (var i = 0; i < sections.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              sections[i],
            ],
        ],
      ),
    );
  }

  Widget _buildProjectList({required List<ProjectSummary> projects}) {
    return Column(
      children: projects
          .asMap()
          .entries
          .map(
            (entry) => _ProjectRow(
              project: entry.value,
              first: entry.key == 0,
              onTap: () => _openProject(entry.value),
            ),
          )
          .toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String countLabel;
  final IconData icon;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.countLabel,
    required this.icon,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20),
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
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c.inset,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, size: 25, color: c.accent),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: kDisplay,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -.4,
                            color: c.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          countLabel,
                          style: TextStyle(fontFamily: kBody, fontSize: 14, color: c.muted),
                        ),
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
            child: expanded
                ? SizedBox(width: double.infinity, child: child)
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final ProjectSummary project;
  final bool first;
  final VoidCallback onTap;

  const _ProjectRow({
    required this.project,
    required this.first,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 15, 16, 15),
        decoration: BoxDecoration(
          color: c.surface2,
          border: Border(top: BorderSide(color: first ? c.border : c.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: TextStyle(
                  fontFamily: kDisplay,
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
            Text(
              '%${project.roundedProgress}',
              style: TextStyle(
                fontFamily: kDisplay,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: c.ink,
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 20, color: c.muted),
          ],
        ),
      ),
    );
  }
}
