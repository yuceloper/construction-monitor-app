import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkDetailPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
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
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$blockName > $workTitle',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InfoCard(
                    title: 'Bağımlı İşler',
                    child: Column(
                      children: const [
                        _DependencyRow(
                          title: 'Duvar Aplikasyonu',
                          completed: true,
                        ),
                        _DependencyRow(
                          title: 'Malzeme Temini',
                          completed: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _SectionTitle(
                    title: 'Uyarılar',
                    actionText: 'Ekle',
                    onTap: () {
                      // Sonraki adımda uyarı ekleme formu.
                    },
                  ),

                  const SizedBox(height: 10),

                  const _WarningCard(
                    title: 'Malzeme gecikmesi',
                    description:
                        'Gazbeton sevkiyatında gecikme yaşanıyor.',
                    date: '20.08.2026',
                    user: 'Deniz Özdemir',
                  ),

                  const SizedBox(height: 10),

                  const _WarningCard(
                    title: 'Kontrol gerekli',
                    description:
                        'Dış cephe duvar kotları tekrar kontrol edilmeli.',
                    date: '21.08.2026',
                    user: 'Ali Yılmaz',
                  ),

                  const SizedBox(height: 20),

                  const _SectionTitle(
                    title: 'Tarihçe',
                  ),

                  const SizedBox(height: 10),

                  const _HistoryCard(
                    title: 'İş durumu güncellendi',
                    description: 'Durum: Devam Ediyor',
                    date: '21.08.2026 15:40',
                    user: 'Deniz Özdemir',
                  ),

                  const SizedBox(height: 10),

                  const _HistoryCard(
                    title: 'Uyarı eklendi',
                    description: 'Malzeme gecikmesi',
                    date: '20.08.2026 10:15',
                    user: 'Deniz Özdemir',
                  ),

                  const SizedBox(height: 10),

                  const _HistoryCard(
                    title: 'İş başlatıldı',
                    description: 'Dış Duvar çalışması başlatıldı.',
                    date: '18.08.2026 08:30',
                    user: 'Ali Yılmaz',
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

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onTap;

  const _SectionTitle({
    required this.title,
    this.actionText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (actionText != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              actionText!,
              style: const TextStyle(
                fontSize: 16,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({
    required this.title,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _DependencyRow extends StatelessWidget {
  final String title;
  final bool completed;

  const _DependencyRow({
    required this.title,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(
            completed
                ? Icons.check_box_outlined
                : Icons.check_box_outline_blank,
            size: 24,
            color: completed
                ? const Color(0xFF00A52B)
                : Colors.black54,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String user;

  const _WarningCard({
    required this.title,
    required this.description,
    required this.date,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7A8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 28,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$user • $date',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String user;

  const _HistoryCard({
    required this.title,
    required this.description,
    required this.date,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.history,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$user • $date',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black45,
                  ),
                ),
              ],
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