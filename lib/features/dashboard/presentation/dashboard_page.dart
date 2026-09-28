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

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  final _notificationService = NotificationService();

  /// Drives the opening sequence: the cards rise into place one after the
  /// other instead of all appearing at once.
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  )..forward();

  @override
  void initState() {
    super.initState();
    _refreshUnreadCount();
  }

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  /// Wraps [child] so it fades and rises in; [order] places it in the queue.
  Widget _entering(int order, Widget child) =>
      _Entering(controller: _entrance, order: order, child: child);

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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _entering(
                0,
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Pressable(
                            onTap: () => context.go('/dashboard'),
                            child: const BrandLogo(height: 28, compact: true),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const UserChip(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const gap = 13.0;
                    final available = constraints.maxHeight;

                    // Ustteki genis kart ile alttaki dortlu izgara ekrana
                    // birlikte sigsin; dar ekranda oranlar korunarak kuculur.
                    var hero = available * .28;
                    if (hero > 190) hero = 190;
                    if (hero < 140) hero = 140;
                    final tile = (available - hero - gap * 2) / 2;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _entering(
                          1,
                          SizedBox(
                            height: hero,
                            child: _HeroModuleCard(
                              title: 'Süreç Takip',
                              icon: LucideIcons.workflow,
                              color: c.accent,
                              onTap: () => context.go('/process'),
                            ),
                          ),
                        ),
                        const SizedBox(height: gap),
                        SizedBox(
                          height: tile,
                          child: Row(
                            children: [
                              Expanded(
                                child: _entering(
                                  2,
                                  _ModuleCard(
                                    title: 'Günlük İşler',
                                    icon: LucideIcons.clipboardList,
                                    color: c.teal,
                                    onTap: () => context.go('/daily-tasks'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: gap),
                              Expanded(
                                child: _entering(
                                  3,
                                  _ModuleCard(
                                    title: 'Paydaşlar',
                                    icon: LucideIcons.users,
                                    color: c.violet,
                                    onTap: () => context.go('/stakeholders'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: gap),
                        SizedBox(
                          height: tile,
                          child: Row(
                            children: [
                              Expanded(
                                child: _entering(
                                  4,
                                  _ModuleCard(
                                    title: 'İSG Takip',
                                    icon: LucideIcons.hardHat,
                                    color: c.warn,
                                    onTap: () => context.go('/safety'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: gap),
                              Expanded(
                                child: _entering(
                                  5,
                                  ValueListenableBuilder<int>(
                                    valueListenable:
                                        NotificationUnreadCount.value,
                                    builder: (context, unreadCount, _) =>
                                        _ModuleCard(
                                          title: 'Bildirimler',
                                          icon: LucideIcons.bellRing,
                                          color: c.bad,
                                          badgeCount: unreadCount,
                                          onTap: () =>
                                              context.go('/notifications'),
                                        ),
                                  ),
                                ),
                              ),
                            ],
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

/// One item of the opening sequence: fades in while rising into place.
///
/// [order] is its place in the queue - each item starts 90ms after the one
/// before it, so the screen assembles itself rather than snapping into view.
class _Entering extends StatelessWidget {
  const _Entering({
    required this.controller,
    required this.order,
    required this.child,
  });

  final AnimationController controller;
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = (order * .09).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        begin,
        (begin + .55).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: animation,
      builder: (context, inner) => Opacity(
        opacity: animation.value,
        child: Transform.translate(
          offset: Offset(0, 26 * (1 - animation.value)),
          child: inner,
        ),
      ),
      child: child,
    );
  }
}

/// Markanin mavi yayindan tureyen dekoratif cizgi - kartlarin kosesinde
/// hafif bir doku birakiyor.
class _ArcMotif extends StatelessWidget {
  const _ArcMotif({required this.color, this.opacity = .13});

  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArcPainter(color: color.withValues(alpha: opacity)),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      paint.strokeWidth = 3.5 - i * .8;
      final inset = i * 16.0;
      final path = Path()
        ..moveTo(size.width * .02 + inset, size.height * .86)
        ..quadraticBezierTo(
          size.width * .52,
          size.height * .42 + inset * .7,
          size.width * 1.02,
          size.height * .86,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.color != color;
}

/// Ikon plakasi: renk gecisli kare, ustunde beyaz ikon.
class _IconPlate extends StatelessWidget {
  const _IconPlate({
    required this.icon,
    required this.color,
    required this.size,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(color, Colors.white, .18)!,
            Color.lerp(color, Colors.black, .12)!,
          ],
        ),
        borderRadius: BorderRadius.circular(size * .3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .32),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Icon(icon, size: size * .46, color: Colors.white),
    );
  }
}

/// Ana giris: genis kart, sol tarafta plaka ve baslik, sagda yay motifi.
class _HeroModuleCard extends StatelessWidget {
  const _HeroModuleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.surface, Color.lerp(c.surface, color, .07)!],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              bottom: -30,
              width: 230,
              height: 150,
              child: _ArcMotif(color: color, opacity: .16),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _IconPlate(icon: icon, color: color, size: 64),
                    const SizedBox(height: 16),
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
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          letterSpacing: -.7,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alttaki dort modul: plaka ustte, baslik altta, kosede yay motifi.
class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badgeCount,
  });

  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final int? badgeCount;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.surface, Color.lerp(c.surface, color, .06)!],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -26,
              width: 170,
              height: 110,
              child: _ArcMotif(color: color),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _IconPlate(icon: icon, color: color, size: 54),
                    const SizedBox(height: 14),
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
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          letterSpacing: -.35,
                          color: c.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if ((badgeCount ?? 0) > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.bad,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    badgeCount! > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      fontFamily: kBody,
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
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
