import 'package:flutter/material.dart';

class SiteSelectionPage extends StatelessWidget {
  const SiteSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text(
          'Şantiye Seçimi',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          _SiteCard(
            title: 'SEFA PARK',
            location: 'İstanbul',
            progress: 0.72,
          ),
          SizedBox(height: 16),
          _SiteCard(
            title: 'SEFA RESIDENCE',
            location: 'İstanbul',
            progress: 0.38,
          ),
        ],
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  final String title;
  final String location;
  final double progress;

  const _SiteCard({
    required this.title,
    required this.location,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Bir sonraki adımda dashboard'a bağlayacağız.
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.apartment,
                      color: Color(0xFFF4A300),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          location,
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(20),
                backgroundColor: const Color(0xFFE6E6E6),
                valueColor: const AlwaysStoppedAnimation(
                  Color(0xFFF4A300),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'İlerleme %${(progress * 100).round()}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}