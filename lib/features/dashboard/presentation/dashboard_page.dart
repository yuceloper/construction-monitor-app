import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../auth/services/session_manager.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionManager.instance;
    final auth = session.auth;
    final siteName = session.selectedSiteName ?? '';
    final firstName = auth?.firstName.isNotEmpty == true ? auth!.firstName : auth?.username ?? '';
    final lastName = auth?.lastName ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => context.go('/dashboard'),
                          child: const Text(
                            'SefaTech',
                            style: TextStyle(
                              fontSize: 34,
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'TDS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: const Color(0xFFE9E9E9),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline, size: 28),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              firstName,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            if (lastName.isNotEmpty)
                              Text(
                                lastName,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            if (siteName.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                siteName,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(
                        children: [
                          Expanded(
                            child: _DashboardCard(
                              title: 'Süreç Takip',
                              icon: Icons.autorenew,
                              backgroundColor: const Color(0xFFFFF0C8),
                              onTap: () => context.go('/process'),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _DashboardCard(
                              title: 'Günlük\nİşler',
                              icon: Icons.format_list_bulleted,
                              backgroundColor: const Color(0xFFD3E4FF),
                              onTap: () => context.go('/daily-tasks'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _WideDashboardCard(
                      title: 'Paydaşlar',
                      icon: Icons.handshake_outlined,
                      backgroundColor: const Color(0xFFDCEBD5),
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),
                    _WideDashboardCard(
                      title: 'İSG Takip',
                      icon: Icons.shield_outlined,
                      backgroundColor: const Color(0xFFDED6EE),
                      onTap: () {},
                    ),
                    const SizedBox(height: 14),
                    _WideDashboardCard(
                      title: 'Bildirimler',
                      icon: Icons.notifications_none,
                      backgroundColor: const Color(0xFFECECEC),
                      badgeCount: 2,
                      onTap: () => context.go('/notifications'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 44, color: Colors.black),
              const SizedBox(height: 26),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WideDashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onTap;
  final int? badgeCount;

  const _WideDashboardCard({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: 82,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 34),
                  if (badgeCount != null)
                    Positioned(
                      right: -10,
                      top: -9,
                      child: Container(
                        width: 23,
                        height: 23,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 18),
              Text(
                title,
                style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
