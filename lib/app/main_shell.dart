import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({
    super.key,
    required this.child,
  });

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

  @override
  Widget build(BuildContext context) {
    final location = _location(context);
    final isDashboard = location == '/dashboard';
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: isDashboard
          ? null
          : BottomNavigationBar(
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
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none),
                      Positioned(
                        right: -8,
                        top: -7,
                        child: Container(
                          width: 19,
                          height: 19,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '2',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  activeIcon: const Icon(Icons.notifications, size: 30),
                  label: 'Bildirimler',
                ),
              ],
            ),
    );
  }
}
