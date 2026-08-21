import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProcessUpdatePage extends StatelessWidget {
  final String blockName;

  const ProcessUpdatePage({
    super.key,
    required this.blockName,
  });

  static const _stages = [
    ('project-preparation', 'Proje & Hazırlık', 'completed'),
    ('excavation-foundation', 'Hafriyat & Temel', 'completed'),
    ('structural-system', 'Taşıyıcı Sistem', 'completed'),
    ('wall-works', 'Duvar İşleri', 'active'),
    ('mep-infrastructure', 'Tesisat Alt Yapı', 'waiting'),
    ('plaster-screed', 'Sıva & Şap', 'waiting'),
    ('joinery-roof', 'Doğrama & Çatı', 'waiting'),
    ('fine-works', 'İnce İşler', 'waiting'),
    ('installation', 'Montaj', 'waiting'),
    ('landscape', 'Peyzaj', 'waiting'),
    ('handover', 'Teslim', 'waiting'),
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
                    child: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$blockName > Güncelle',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
                itemCount: _stages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final stage = _stages[index];
                  return _StageUpdateCard(
                    title: stage.$2,
                    status: stage.$3,
                    onTap: () {
                      context.push(
                        '/process/$blockName/update/${stage.$1}'
                        '?title=${Uri.encodeComponent(stage.$2)}',
                      );
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

class _StageUpdateCard extends StatelessWidget {
  final String title;
  final String status;
  final VoidCallback onTap;

  const _StageUpdateCard({
    required this.title,
    required this.status,
    required this.onTap,
  });

  Color get backgroundColor {
    switch (status) {
      case 'completed':
        return const Color(0xFFDCEED5);
      case 'active':
        return const Color(0xFFFFE49A);
      default:
        return const Color(0xFFEDEDED);
    }
  }

  Icon get statusIcon {
    if (status == 'completed') {
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
