import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/pressable.dart';
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

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Pressable(
                              onTap: () => context.go('/dashboard'),
                              child: const BrandLogo(height: 26, compact: true),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const UserChip(),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Üst iki kart kare dursun, seritler kalan yuksekligi
                    // esit paylassin - ekran boyu degisince de bozulmaz.
                    const gap = 14.0;
                    final available = constraints.maxHeight;

                    // Kare kartlar + uc serit ekrana tam sigsin: once tercih
                    // edilen olculer, sonra dar ekranda kuculterek duzeltme.
                    var square = ((constraints.maxWidth - gap) / 2) * 1.3;
                    var strip = (available - square - gap * 3) / 3;
                    if (strip > 152) {
                      strip = 152;
                      square = available - gap * 3 - strip * 3;
                    } else if (strip < 88) {
                      strip = 88;
                      square = available - gap * 3 - strip * 3;
                    }

                    return Column(
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
                                  title: 'Günlük İşler',
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
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        padding: const EdgeInsets.fromLTRB(16, 22, 16, 22),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: c.inset,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, size: 32, color: c.accent),
            ),
            const SizedBox(height: 18),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kDisplay,
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                  letterSpacing: -.4,
                  color: c.ink,
                ),
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
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Okunmamis sayisi ikonun kosesinde - kartin dengesi bozulmuyor.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: c.inset,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 25, color: c.accent),
                ),
                if ((badgeCount ?? 0) > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.bad,
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.surface, width: 2),
                      ),
                      child: Text(
                        badgeCount! > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          fontFamily: kBody,
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.4,
                    color: c.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
