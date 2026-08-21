import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProcessTrackingPage extends StatefulWidget {
  const ProcessTrackingPage({super.key});

  @override
  State<ProcessTrackingPage> createState() => _ProcessTrackingPageState();
}

class _ProcessTrackingPageState extends State<ProcessTrackingPage> {
  bool _housesExpanded = true;
  bool _shopsExpanded = false;

  final List<_ProcessItem> _houses = const [
    _ProcessItem(name: 'G1', progress: 20),
    _ProcessItem(name: 'G2', progress: 25),
    _ProcessItem(name: 'K1', progress: 35),
    _ProcessItem(name: 'K2', progress: 25),
    _ProcessItem(name: 'L1', progress: 40),
    _ProcessItem(name: 'L2', progress: 20),
    _ProcessItem(name: 'M1', progress: 80),
    _ProcessItem(name: 'M2', progress: 20),
    _ProcessItem(name: 'P1', progress: 50),
    _ProcessItem(name: 'P2', progress: 50),
  ];

  final List<_ProcessItem> _shops = const [
    _ProcessItem(name: 'D1', progress: 30),
    _ProcessItem(name: 'D2', progress: 65),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
        color: Colors.white,
        child: SafeArea(
      child: Column(
        children: [
          const _PageHeader(),

          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 14,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                  ),
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

          Expanded(
            child: ListView(
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
                  child: Column(
                    children: _houses
                        .asMap()
                        .entries
                        .map(
                        (entry) => _ProcessRow(
                            item: entry.value,
                            index: entry.key,
                        ),
                        )
                        .toList(),
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
                  child: Column(
                    children: _shops
                            .asMap()
                            .entries
                            .map(
                            (entry) => _ProcessRow(
                                item: entry.value,
                                index: entry.key,
                            ),
                            )
                            .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
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
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 32,
                  ),
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

class _ProcessRow extends StatelessWidget {
  final _ProcessItem item;
  final int index;

  const _ProcessRow({
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isEvenRow = (index + 1).isEven;

    return InkWell(
      onTap: () {
        context.push(
            '/process/${item.name}?progress=${item.progress}',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 64,
          vertical: 5,
        ),
        color: isEvenRow
            ? const Color(0xFFE9E9E9)
            : Colors.white,
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Text(
              '%${item.progress}',
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

class _ProcessItem {
  final String name;
  final int progress;

  const _ProcessItem({
    required this.name,
    required this.progress,
  });
}