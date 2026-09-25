import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/pressable.dart';
import '../../auth/services/session_manager.dart';
import '../../notifications/services/notification_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
  }

  Future<void> _refreshUnreadCount() async {
    try {
      await _notificationService.getUnreadCount();
    } catch (_) {
      // Keep the current badge value if the backend is temporarily unavailable.
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final session = SessionManager.instance;
    final auth = session.auth;
    final siteName = session.selectedSiteName ?? '';
    final firstName = auth?.firstName.isNotEmpty == true ? auth!.firstName : auth?.username ?? '';
    final lastName = auth?.lastName ?? '';

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Pressable(
                    onTap: () => context.go('/dashboard'),
                    child: const BrandLogo(height: 34),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: c.ink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'TDS',
                      style: TextStyle(
                        fontFamily: kBody,
                        color: c.bg,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  _UserChip(
                    firstName: firstName,
                    lastName: lastName,
                    siteName: siteName,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Üst iki kart kare dursun, seritler kalan yuksekligi
                    // esit paylassin - ekran boyu degisince de bozulmaz.
                    const gap = 14.0;
                    final square = (constraints.maxWidth - gap) / 2;
                    final rest = constraints.maxHeight - square - gap;
                    final strip = ((rest - gap * 2) / 3).clamp(86.0, 132.0);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: square,
                          child: Row(
                            children: [
                              Expanded(
                                child: _DashboardCard(
                                  title: 'Süreç Takip',
                                  icon: LucideIcons.refreshCw,
                                  onTap: () => context.go('/process'),
                                ),
                              ),
                              const SizedBox(width: gap),
                              Expanded(
                                child: _DashboardCard(
                                  title: 'Günlük\nİşler',
                                  icon: LucideIcons.list,
                                  onTap: () => context.go('/daily-tasks'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: gap),
                        SizedBox(
                          height: strip,
                          child: _WideDashboardCard(
                            title: 'Paydaşlar',
                            icon: LucideIcons.handshake,
                            onTap: () => context.go('/stakeholders'),
                          ),
                        ),
                        const SizedBox(height: gap),
                        SizedBox(
                          height: strip,
                          child: _WideDashboardCard(
                            title: 'İSG Takip',
                            icon: LucideIcons.shield,
                            onTap: () => context.go('/safety'),
                          ),
                        ),
                        const SizedBox(height: gap),
                        SizedBox(
                          height: strip,
                          child: ValueListenableBuilder<int>(
                            valueListenable: NotificationUnreadCount.value,
                            builder: (context, unreadCount, _) {
                              return _WideDashboardCard(
                                title: 'Bildirimler',
                                icon: LucideIcons.bell,
                                badgeCount: unreadCount,
                                onTap: () => context.go('/notifications'),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Signed-in user: initials, name, and the site being worked on.
class _UserChip extends StatelessWidget {
  const _UserChip({
    required this.firstName,
    required this.lastName,
    required this.siteName,
  });

  final String firstName;
  final String lastName;
  final String siteName;

  String get _initials {
    final first = firstName.trim();
    final last = lastName.trim();
    final letters = [
      if (first.isNotEmpty) first[0],
      if (last.isNotEmpty) last[0],
    ].join();
    return letters.isEmpty ? '?' : letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fullName = [firstName, lastName]
        .where((part) => part.trim().isNotEmpty)
        .join(' ');

    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.fromLTRB(6, 6, 13, 6),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
        boxShadow: kLiftShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.ink, shape: BoxShape.circle),
            child: Text(
              _initials,
              style: TextStyle(
                fontFamily: kDisplay,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: .3,
                color: c.bg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                    color: c.ink,
                  ),
                ),
                if (siteName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.mapPin, size: 11, color: c.accent),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          siteName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .2,
                            color: c.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: c.inset,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, size: 30, color: c.accent),
            ),
            const Spacer(),
            Text(
              title,
              style: TextStyle(
                fontFamily: kDisplay,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.1,
                letterSpacing: -.5,
                color: c.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideDashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;

  const _WideDashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 0, 18, 0),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: c.inset,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, size: 25, color: c.accent),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: kDisplay,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.4,
                  color: c.ink,
                ),
              ),
            ),
            if ((badgeCount ?? 0) > 0) ...[
              Container(
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.bad,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  badgeCount! > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    fontFamily: kBody,
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Icon(LucideIcons.chevronRight, size: 20, color: c.muted),
          ],
        ),
      ),
    );
  }
}
