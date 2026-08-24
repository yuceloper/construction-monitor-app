import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/project_summary.dart';
import '../services/project_service.dart';

class ProcessTrackingPage extends StatefulWidget {
  const ProcessTrackingPage({super.key});

  @override
  State<ProcessTrackingPage> createState() => _ProcessTrackingPageState();
}

class _ProcessTrackingPageState extends State<ProcessTrackingPage> {
  final _projectService = ProjectService();

  bool _housesExpanded = true;
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

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const _PageHeader(),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Icon(Icons.arrow_back_ios_new, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Süreç Takibi',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
      return const Center(
        child: CircularProgressIndicator(color: Colors.black),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 42, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loadProjects,
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

    return RefreshIndicator(
      onRefresh: _loadProjects,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Evler',
            icon: Icons.home_outlined,
            expanded: _housesExpanded,
            onTap: () {
              setState(() {
                _housesExpanded = !_housesExpanded;
              });
            },
            child: _buildProjectList(
              projects: _houses,
              emptyMessage: 'Henüz ev projesi bulunmuyor.',
            ),
          ),
          const SizedBox(height: 18),
          _SectionCard(
            title: 'Dükkanlar',
            icon: Icons.storefront_outlined,
            expanded: _shopsExpanded,
            onTap: () {
              setState(() {
                _shopsExpanded = !_shopsExpanded;
              });
            },
            child: _buildProjectList(
              projects: _shops,
              emptyMessage: 'Henüz dükkan projesi bulunmuyor.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList({
    required List<ProjectSummary> projects,
    required String emptyMessage,
  }) {
    if (projects.isEmpty) {
      return _EmptySection(message: emptyMessage);
    }

    return Column(
      children: projects
          .asMap()
          .entries
          .map(
            (entry) => _ProjectRow(
              project: entry.value,
              index: entry.key,
            ),
          )
          .toList(),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              'LOGO',
              style: TextStyle(
                fontSize: 32,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: const Color(0xFFE9E9E9),
            child: const Row(
              children: [
                Icon(Icons.person_outline, size: 26),
                SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deniz', style: TextStyle(fontSize: 12)),
                    Text('Özdemir', style: TextStyle(fontSize: 12)),
                    Text(
                      'Konacık',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool expanded;
  final VoidCallback onTap;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.expanded,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, size: 32),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 36,
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Container(
              color: Colors.white,
              child: child,
            ),
        ],
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final ProjectSummary project;
  final int index;

  const _ProjectRow({
    required this.project,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isEvenRow = (index + 1).isEven;

    return InkWell(
      onTap: () {
        context.push(
          '/process/${Uri.encodeComponent(project.name)}'
          '?progress=${project.roundedProgress}'
          '&projectId=${project.id}',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 7),
        color: isEvenRow ? const Color(0xFFE9E9E9) : Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              '%${project.roundedProgress}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          message,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
      ),
    );
  }
}
