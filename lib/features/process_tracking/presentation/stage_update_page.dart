import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StageUpdatePage extends StatefulWidget {
  final String blockName;
  final String stageId;
  final String stageTitle;

  const StageUpdatePage({
    super.key,
    required this.blockName,
    required this.stageId,
    required this.stageTitle,
  });

  @override
  State<StageUpdatePage> createState() => _StageUpdatePageState();
}

class _StageUpdatePageState extends State<StageUpdatePage> {
  late final List<_EditableWork> _works;

  @override
  void initState() {
    super.initState();
    _works = _itemsForStage(widget.stageId)
        .map((item) => item.copy())
        .toList();
  }

  List<_EditableWork> _itemsForStage(String stageId) {
    switch (stageId) {
      case 'excavation-foundation':
        return const [
          _EditableWork(id: 'excavation', title: 'Kazı', completed: true),
          _EditableWork(id: 'lean-concrete', title: 'Grobeton', completed: true),
          _EditableWork(id: 'foundation', title: 'Temel Donatı + Beton', completed: true),
          _EditableWork(id: 'insulation', title: 'İzolasyon & Drenaj', completed: true),
        ];
      case 'wall-works':
        return const [
          _EditableWork(id: 'exterior-wall', title: 'Dış Duvar', completed: true),
          _EditableWork(id: 'interior-wall', title: 'İç Bölme', completed: false),
        ];
      default:
        return const [
          _EditableWork(id: 'work-1', title: 'İş 1', completed: false),
          _EditableWork(id: 'work-2', title: 'İş 2', completed: false),
        ];
    }
  }

  void _openWorkDetail(_EditableWork work) {
    context.push(
      '/process/${widget.blockName}/work/${work.id}'
      '?title=${Uri.encodeComponent(work.title)}',
    );
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
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
                                  onChanged: (value) {
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
                                    child: Text(
                                      work.title,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w500,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (work.id == 'exterior-wall') ...[
                                const Icon(Icons.link, color: Colors.red, size: 25),
                                const SizedBox(width: 10),
                                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 26),
                              ],
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
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Değişiklikler kaydedildi.')),
                        );
                        context.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('KAYDET', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditableWork {
  final String id;
  final String title;
  final bool completed;

  const _EditableWork({
    required this.id,
    required this.title,
    required this.completed,
  });

  _EditableWork copy({bool? completed}) {
    return _EditableWork(
      id: id,
      title: title,
      completed: completed ?? this.completed,
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
