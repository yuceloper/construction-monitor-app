import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/process_work_item.dart';
import '../models/progress_stage.dart';
import '../services/progress_service.dart';

class ProcessDetailPage extends StatefulWidget {
  final String blockName;
  final int progress;
  final int projectId;

  const ProcessDetailPage({
    super.key,
    required this.blockName,
    required this.progress,
    required this.projectId,
  });

  @override
  State<ProcessDetailPage> createState() => _ProcessDetailPageState();
}

class _ProcessDetailPageState extends State<ProcessDetailPage> {
  final _progressService = ProgressService();

  int? _expandedIndex;
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
      setState(() {
        _stages = stages;
      });
    } on ProgressException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Süreç aşamaları yüklenirken beklenmeyen bir hata oluştu.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<ProcessWorkItem> _itemsForStage(String stageName) {
    switch (stageName) {
      case 'Proje & Hazırlık':
        return const [
          ProcessWorkItem(id: 'project', title: 'Proje', status: 'completed'),
          ProcessWorkItem(id: 'permit', title: 'Ruhsat', status: 'completed'),
          ProcessWorkItem(
            id: 'site-preparation',
            title: 'Şantiye Hazırlığı',
            status: 'completed',
          ),
        ];
      case 'Hafriyat & Temel':
        return const [
          ProcessWorkItem(id: 'excavation', title: 'Kazı', status: 'completed'),
          ProcessWorkItem(id: 'lean-concrete', title: 'Grobeton', status: 'completed'),
          ProcessWorkItem(
            id: 'foundation',
            title: 'Temel Donatı + Beton',
            status: 'completed',
          ),
          ProcessWorkItem(
            id: 'insulation',
            title: 'İzolasyon & Drenaj',
            status: 'completed',
          ),
        ];
      case 'Duvar İşleri':
        return const [
          ProcessWorkItem(id: 'exterior-wall', title: 'Dış Duvar', status: 'active'),
          ProcessWorkItem(id: 'interior-wall', title: 'İç Bölme', status: 'waiting'),
        ];
      default:
        return const [];
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.blockName,
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Genel İlerleme',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: widget.progress / 100,
                                minHeight: 11,
                                backgroundColor: const Color(0xFFAECBE1),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF0066A6),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '%${widget.progress}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  SizedBox(
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/process/${Uri.encodeComponent(widget.blockName)}/update'
                          '?projectId=${widget.projectId}',
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066A6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Güncelle', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildStageContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildStageContent() {
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

    if (_stages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadStages,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Bu proje için süreç aşaması bulunmuyor.')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStages,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        itemCount: _stages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final progressStage = _stages[index];
          final stage = _ProcessStage(
            title: progressStage.name,
            status: _statusForPercentage(progressStage.percentage),
            items: _itemsForStage(progressStage.name),
          );
          final expanded = _expandedIndex == index;

          return _StageCard(
            stage: stage,
            expanded: expanded,
            onTap: () {
              setState(() {
                _expandedIndex = expanded ? null : index;
              });
            },
          );
        },
      ),
    );
  }

  _StageStatus _statusForPercentage(double percentage) {
    if (percentage >= 100) return _StageStatus.completed;
    if (percentage > 0) return _StageStatus.active;
    return _StageStatus.waiting;
  }
}

class _StageCard extends StatelessWidget {
  final _ProcessStage stage;
  final bool expanded;
  final VoidCallback onTap;

  const _StageCard({
    required this.stage,
    required this.expanded,
    required this.onTap,
  });

  Color get backgroundColor {
    switch (stage.status) {
      case _StageStatus.completed:
        return const Color(0xFFDCEED5);
      case _StageStatus.active:
        return const Color(0xFFFFE49A);
      case _StageStatus.waiting:
        return const Color(0xFFEDEDED);
    }
  }

  Widget get statusIcon {
    switch (stage.status) {
      case _StageStatus.completed:
        return const Icon(Icons.check, color: Color(0xFF00A52B), size: 30);
      case _StageStatus.active:
      case _StageStatus.waiting:
        return const Icon(Icons.hourglass_empty, color: Colors.black, size: 30);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          InkWell(
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
                      stage.title,
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(
                    expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 38,
                  ),
                ],
              ),
            ),
          ),
          if (expanded && stage.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 56, right: 20, bottom: 18),
              child: Column(
                children: stage.items.map((item) {
                  final completed = item.status == 'completed';
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          completed
                              ? Icons.check_box_outlined
                              : Icons.check_box_outline_blank,
                          color: completed ? const Color(0xFF00A52B) : Colors.black,
                          size: 26,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
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

enum _StageStatus { completed, active, waiting }

class _ProcessStage {
  final String title;
  final _StageStatus status;
  final List<ProcessWorkItem> items;

  const _ProcessStage({
    required this.title,
    required this.status,
    required this.items,
  });
}
