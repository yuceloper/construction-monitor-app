import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/progress_stage.dart';
import '../services/progress_service.dart';

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

  bool _isLoading = true;
  String? _errorMessage;
  List<ProgressStage> _stages = const [];

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
      final stages = await _progressService.getStagesByProject(widget.projectId);
      if (!mounted) return;
      setState(() => _stages = stages);
    } on ProgressException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Süreç aşamaları yüklenirken beklenmeyen bir hata oluştu.';
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
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const _PageHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.blockName} > Güncelle',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
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

    if (_errorMessage != null) {
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
                onPressed: _loadStages,
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
      onRefresh: _loadStages,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        itemCount: _stages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final stage = _stages[index];
          return _StageUpdateCard(
            title: stage.name,
            percentage: stage.percentage,
            onTap: () => _openStage(stage),
          );
        },
      ),
    );
  }
}

class _StageUpdateCard extends StatelessWidget {
  final String title;
  final double percentage;
  final VoidCallback onTap;

  const _StageUpdateCard({
    required this.title,
    required this.percentage,
    required this.onTap,
  });

  Color get backgroundColor {
    if (percentage >= 100) return const Color(0xFFDCEED5);
    if (percentage > 0) return const Color(0xFFFFE49A);
    return const Color(0xFFEDEDED);
  }

  Icon get statusIcon {
    if (percentage >= 100) {
      return const Icon(Icons.check, color: Color(0xFF00A52B), size: 30);
    }
    return const Icon(Icons.hourglass_empty, color: Colors.black, size: 30);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              statusIcon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                ),
              ),
              Text('%${percentage.round()}'),
              const SizedBox(width: 10),
              const Icon(Icons.edit_outlined, size: 30),
            ],
          ),
        ),
      ),
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
            child: Text('LOGO', style: TextStyle(fontSize: 32, color: Colors.grey)),
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
