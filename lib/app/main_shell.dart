import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/widgets/ekran_sigdir.dart';
import '../features/notifications/services/notification_service.dart';
import 'active_site.dart';
import 'theme.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _notificationService = NotificationService();
  String? _lastLocation;

  @override
  void initState() {
    super.initState();
    // Santiye degisince rozet yeniden sayiliyor. Sayi yalnizca sayfa
    // degistiginde yenileniyordu: baska bir santiyeye gecilince eski
    // santiyenin sayisi rozette kaliyor, liste bos olsa bile rozet
    // dolu gorunuyordu.
    ActiveSite.revision.addListener(_santiyeDegisti);
  }

  @override
  void dispose() {
    ActiveSite.revision.removeListener(_santiyeDegisti);
    super.dispose();
  }

  void _santiyeDegisti() {
    if (!mounted) return;
    _lastLocation = null;
    _notificationService.getUnreadCount().catchError((_) => 0);
  }

  String _location(BuildContext context) {
    return GoRouterState.of(context).uri.toString();
  }

  int _currentIndex(BuildContext context) {
    final location = _location(context);

    if (location.startsWith('/process')) return 1;
    if (location.startsWith('/daily-tasks')) return 2;
    if (location.startsWith('/notifications')) return 3;

    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/process');
        break;
      case 2:
        context.go('/daily-tasks');
        break;
      case 3:
        context.go('/notifications');
        break;
    }
  }

  void _refreshUnreadCount(String location) {
    if (_lastLocation == location) return;
    _lastLocation = location;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _notificationService.getUnreadCount();
      } catch (_) {
        // Existing badge value remains visible if the backend is temporarily unavailable.
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = _location(context);
    final isDashboard = location == '/dashboard';
    final currentIndex = _currentIndex(context);
    _refreshUnreadCount(location);

    final c = context.colors;

    final rootSection = const {
      '/daily-tasks',
      '/process',
      '/notifications',
      '/stakeholders',
      '/safety',
      '/reports',
    }.contains(location);

    return PopScope(
      canPop: !rootSection,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (rootSection) context.go('/dashboard');
      },
      child: Scaffold(
      backgroundColor: c.bg,
      // Genis ekranda icerik ortalanip makul bir sutunda tutuluyor;
      // telefonda hicbir sey degismiyor.
      body: EkranSigdir(child: widget.child),
      bottomNavigationBar: isDashboard
          ? null
          : ValueListenableBuilder<int>(
              valueListenable: NotificationUnreadCount.value,
              builder: (context, unreadCount, _) {
                // Tarayicida dort sekme butun pencereye yayiliyordu;
                // cizgi kenardan kenara gidiyor ama menu icerikle ayni
                // genislikte, ortali duruyor. Olcu icerik sutunuyla ayni:
                // menu daha dar kalinca ustteki panelle hizasizdi.
                final en = MediaQuery.sizeOf(context).width;
                final yanPay = en > kIcerikEniMax
                    ? (en - kIcerikEniMax) / 2
                    : 0.0;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: c.border)),
                  ),
                  // Center/ConstrainedBox menuyu dikeyde de buyutuyor;
                  // genislik yandan bosluk vererek daraltiliyor.
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: yanPay),
                    child: BottomNavigationBar(
                      currentIndex: currentIndex,
                      onTap: (index) => _onTap(context, index),
                      type: BottomNavigationBarType.fixed,
                      elevation: 0,
                      selectedItemColor: c.accent,
                      unselectedItemColor: c.muted,
                      backgroundColor: c.surface,
                      selectedFontSize: 13,
                      unselectedFontSize: 12.5,
                      selectedLabelStyle: const TextStyle(
                        fontFamily: kBody,
                        fontWeight: FontWeight.w700,
                      ),
                      unselectedLabelStyle: const TextStyle(
                        fontFamily: kBody,
                        fontWeight: FontWeight.w500,
                      ),
                      items: [
                        const BottomNavigationBarItem(
                          icon: Icon(LucideIcons.house, size: 24),
                          label: 'Ana Sayfa',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(LucideIcons.chartGantt, size: 24),
                          label: 'Süreç Takip',
                        ),
                        const BottomNavigationBarItem(
                          icon: Icon(LucideIcons.clipboardList, size: 24),
                          label: 'Günlük İşler',
                        ),
                        BottomNavigationBarItem(
                          icon: _NotificationNavIcon(count: unreadCount),
                          label: 'Bildirimler',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}

class _NotificationNavIcon extends StatelessWidget {
  final int count;

  const _NotificationNavIcon({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(LucideIcons.bellRing, size: 24),
        if (count > 0)
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.bad,
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  fontFamily: kBody,
                  color: Colors.white,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
