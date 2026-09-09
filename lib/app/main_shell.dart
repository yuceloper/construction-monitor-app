import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/notifications/services/notification_service.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _notificationService = NotificationService();
  String? _lastLocation;

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

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: isDashboard
          ? null
          : ValueListenableBuilder<int>(
              valueListenable: NotificationUnreadCount.value,
              builder: (context, unreadCount, _) {
                return BottomNavigationBar(
                  currentIndex: currentIndex,
                  onTap: (index) => _onTap(context, index),
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: const Color(0xFF0066A6),
                  unselectedItemColor: Colors.black54,
                  backgroundColor: Colors.white,
                  selectedFontSize: 13,
                  unselectedFontSize: 12,
                  selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Ana Sayfa',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.autorenew),
                      activeIcon: Icon(Icons.autorenew, size: 30),
                      label: 'Süreç Takip',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.format_list_bulleted),
                      activeIcon: Icon(Icons.format_list_bulleted, size: 30),
                      label: 'Günlük İşler',
                    ),
                    BottomNavigationBarItem(
                      icon: _NotificationNavIcon(
                        count: unreadCount,
                        active: false,
                      ),
                      activeIcon: _NotificationNavIcon(
                        count: unreadCount,
                        active: true,
                      ),
                      label: 'Bildirimler',
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _NotificationNavIcon extends StatelessWidget {
  final int count;
  final bool active;

  const _NotificationNavIcon({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          active ? Icons.notifications : Icons.notifications_none,
          size: active ? 30 : 24,
        ),
        if (count > 0)
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
