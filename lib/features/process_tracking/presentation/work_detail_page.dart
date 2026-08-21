import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkDetailPage extends StatefulWidget {
  final String blockName;
  final String workId;
  final String workTitle;

  const WorkDetailPage({
    super.key,
    required this.blockName,
    required this.workId,
    required this.workTitle,
  });

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  late final List<_WarningItem> _warnings;

  @override
  void initState() {
    super.initState();
    _warnings = [..._initialWarnings(widget.workId)];
  }

  List<String> _dependencies(String workId) {
    switch (workId) {
      case 'exterior-wall':
        return const ['Kaba İnşaat'];
      case 'interior-wall':
        return const ['Dış Duvar'];
      case 'lean-concrete':
        return const ['Kazı'];
      case 'foundation':
        return const ['Grobeton'];
      case 'insulation':
        return const ['Temel Donatı + Beton'];
      default:
        return const [];
    }
  }

  List<_WarningItem> _initialWarnings(String workId) {
    if (workId == 'exterior-wall') {
      return const [
        _WarningItem(
          text: 'Dış duvarın arasındaki boşluklar düzeltilmeli',
          date: '27.03.2026',
          user: 'Ali Reis',
          critical: true,
        ),
        _WarningItem(
          text: 'Düzeltme için sıvacı bekleniyor.',
          date: '03.04.2026',
          user: 'Sefa Özdem',
        ),
      ];
    }
    return const [];
  }

  List<_HistoryItem> _history(String workId) {
    if (workId == 'exterior-wall') {
      return const [
        _HistoryItem(
          text: 'Dış Duvar "tamamlandı" olarak işaretlendi.',
          date: '26.03.2026',
          user: 'Sefa Özdem',
        ),
        _HistoryItem(
          text: 'Dış Duvar "tamamlanmadı" olarak işaretlendi.',
          date: '27.03.2026',
          user: 'Ali Reis',
        ),
      ];
    }
    return [
      _HistoryItem(
        text: '${widget.workTitle} görüntülendi.',
        date: '22.08.2026',
        user: 'Deniz Özdemir',
      ),
    ];
  }

  Future<void> _addWarning() async {
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Uyarı Ekle'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Uyarı açıklaması',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.of(dialogContext).pop(value);
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (text == null || !mounted) return;

    setState(() {
      _warnings.insert(
        0,
        _WarningItem(
          text: text,
          date: '22.08.2026',
          user: 'Deniz Özdemir',
          critical: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dependencies = _dependencies(widget.workId);
    final history = _history(widget.workId);

    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const _PageHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.blockName,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF0066A6),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('>'),
                  ),
                  Expanded(
                    child: Text(
                      widget.workTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const Row(
                    children: [
                      Icon(Icons.attach_file, size: 34),
                      SizedBox(width: 6),
                      Text(
                        'Bağımlı İşler',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(46, 8, 0, 20),
                    child: dependencies.isEmpty
                        ? const Text('Bağımlı iş bulunmuyor.', style: TextStyle(fontSize: 17, color: Colors.black54))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: dependencies
                                .map((item) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Text(item, style: const TextStyle(fontSize: 19)),
                                    ))
                                .toList(),
                          ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 34),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'Uyarılar',
                          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        width: 145,
                        child: ElevatedButton.icon(
                          onPressed: _addWarning,
                          icon: const Icon(Icons.add, size: 26),
                          label: const Text('Ekle', style: TextStyle(fontSize: 17)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0066A6),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_warnings.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Bu iş için uyarı bulunmuyor.', style: TextStyle(color: Colors.black54)),
                    )
                  else
                    ..._warnings.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _WarningCard(item: entry.value),
                      );
                    }),
                  const SizedBox(height: 14),
                  const Row(
                    children: [
                      Icon(Icons.history, size: 32),
                      SizedBox(width: 6),
                      Text(
                        'Tarihçe',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...history.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _HistoryCard(item: item),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final _WarningItem item;

  const _WarningCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: item.critical ? const Color(0xFFFFE1E1) : const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(item.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.date, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.account_box_outlined, size: 22),
                  const SizedBox(width: 4),
                  Text(item.user, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final _HistoryItem item;

  const _HistoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(item.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(item.date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.account_box_outlined, size: 21),
                  const SizedBox(width: 4),
                  Text(item.user, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarningItem {
  final String text;
  final String date;
  final String user;
  final bool critical;

  const _WarningItem({
    required this.text,
    required this.date,
    required this.user,
    this.critical = false,
  });
}

class _HistoryItem {
  final String text;
  final String date;
  final String user;

  const _HistoryItem({
    required this.text,
    required this.date,
    required this.user,
  });
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
