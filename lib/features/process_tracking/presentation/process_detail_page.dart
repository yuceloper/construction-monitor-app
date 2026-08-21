import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProcessDetailPage extends StatefulWidget {
  final String blockName;
  final int progress;

  const ProcessDetailPage({
    super.key,
    required this.blockName,
    required this.progress,
  });

  @override
  State<ProcessDetailPage> createState() => _ProcessDetailPageState();
}

class _ProcessDetailPageState extends State<ProcessDetailPage> {
  int? _expandedIndex;

  final List<_ProcessStage> _stages = const [
    _ProcessStage(
      title: 'Proje & Hazırlık',
      status: _StageStatus.completed,
      items: [
        'Proje',
        'Ruhsat',
        'Şantiye Hazırlığı',
      ],
    ),
    _ProcessStage(
      title: 'Hafriyat & Temel',
      status: _StageStatus.completed,
      items: [
        'Kazı',
        'Grobeton',
        'Temel Donatı + Beton',
        'İzolasyon & Drenaj',
      ],
    ),
    _ProcessStage(
      title: 'Taşıyıcı Sistem',
      status: _StageStatus.completed,
      items: [
        'Kolon',
        'Kiriş',
        'Döşeme',
      ],
    ),
    _ProcessStage(
      title: 'Duvar İşleri',
      status: _StageStatus.active,
      items: [
        'Dış Duvar',
        'İç Bölme',
      ],
    ),
    _ProcessStage(
      title: 'Tesisat Alt Yapı',
      status: _StageStatus.waiting,
      items: [
        'Elektrik',
        'Mekanik',
      ],
    ),
    _ProcessStage(
      title: 'Sıva & Şap',
      status: _StageStatus.waiting,
      items: [
        'Sıva',
        'Şap',
      ],
    ),
    _ProcessStage(
      title: 'Doğrama & Çatı',
      status: _StageStatus.waiting,
      items: [],
    ),
    _ProcessStage(
      title: 'İnce İşler',
      status: _StageStatus.waiting,
      items: [],
    ),
    _ProcessStage(
      title: 'Montaj',
      status: _StageStatus.waiting,
      items: [],
    ),
    _ProcessStage(
      title: 'Peyzaj',
      status: _StageStatus.waiting,
      items: [],
    ),
    _ProcessStage(
      title: 'Teslim',
      status: _StageStatus.waiting,
      items: [],
    ),
  ];

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
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 20,
                    ),
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
                                backgroundColor:
                                    const Color(0xFFAECBE1),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
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
                        // Sonraki adımda güncelleme ekranı.
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066A6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Güncelle',
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
                itemCount: _stages.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final stage = _stages[index];
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
            ),
          ],
        ),
      ),
    );
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
        return const Icon(
          Icons.check,
          color: Color(0xFF00A52B),
          size: 30,
        );

      case _StageStatus.active:
      case _StageStatus.waiting:
        return const Icon(
          Icons.hourglass_empty,
          color: Colors.black,
          size: 30,
        );
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 17,
              ),
              child: Row(
                children: [
                  statusIcon,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      stage.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 38,
                  ),
                ],
              ),
            ),
          ),

          if (expanded && stage.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(
                left: 56,
                right: 20,
                bottom: 18,
              ),
              child: Column(
                children: stage.items
                    .map(
                      (item) => Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Icon(
                              stage.status ==
                                      _StageStatus.completed
                                  ? Icons.check_box_outlined
                                  : Icons.check_box_outline_blank,
                              color: stage.status ==
                                      _StageStatus.completed
                                  ? const Color(0xFF00A52B)
                                  : Colors.black,
                              size: 26,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item,
                              style: const TextStyle(
                                fontSize: 16,
                                decoration:
                                    TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
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
            child: Text(
              'LOGO',
              style: TextStyle(
                fontSize: 32,
                color: Colors.grey,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            color: const Color(0xFFE9E9E9),
            child: const Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 26,
                ),
                SizedBox(width: 7),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deniz',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Özdemir',
                      style: TextStyle(fontSize: 12),
                    ),
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

enum _StageStatus {
  completed,
  active,
  waiting,
}

class _ProcessStage {
  final String title;
  final _StageStatus status;
  final List<String> items;

  const _ProcessStage({
    required this.title,
    required this.status,
    required this.items,
  });
}