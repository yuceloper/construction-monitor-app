import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ust serit her ekranda ayni bilesen: logo boyutu ve kenar
            // bosluklari sayfadan sayfaya degismiyor.
            _entering(0, const AppHeader()),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Iki buyuk kartin icinde bir ikon ve bir baslik var;
                    // uzadikca ortalari bosaliyordu. Ekranin %30'u kadarlar,
                    // en fazla 250dp. Artan pay alt panellere ve aralarindaki
                    // bosluga gidiyor, kartlari sismiyor.
                    const row = 88.0;
                    var primary = constraints.maxHeight * .30;
                    if (primary > 250) primary = 250;
                    if (primary < 180) primary = 180;

                    var gap = (constraints.maxHeight - primary - row * 3) / 5;
                    if (gap < 14) gap = 14;
                    if (gap > 32) gap = 32;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: primary,
                          child: Row(
                            children: [
                              Expanded(
                                child: _entering(
                                  1,
                                  _PrimaryCard(
                                    title: 'Süreç Takip',
                                    icon: LucideIcons.chartGantt,
                                    color: c.accent,
                                    onTap: () => context.go('/process'),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _entering(
                                  2,
                                  _PrimaryCard(
                                    title: 'Günlük İşler',
                                    icon: LucideIcons.clipboardList,
                                    color: c.teal,
                                    onTap: () => context.go('/daily-tasks'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: gap),
                        // Her giris kendi panelinde duruyor.
                        _entering(
                          3,
                          SizedBox(
                            height: row,
                            child: _SecondaryCard(
                              title: 'Paydaşlar',
                              icon: LucideIcons.users,
                              color: c.violet,
                              onTap: () => context.go('/stakeholders'),
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        _entering(
                          4,
                          SizedBox(
                            height: row,
                            child: _SecondaryCard(
                              title: 'İSG Takip',
                              icon: LucideIcons.shieldCheck,
                              color: c.warn,
                              onTap: () => context.go('/safety'),
                            ),
                          ),
                        ),
                        SizedBox(height: gap),
                        _entering(
                          5,
                          SizedBox(
                            height: row,
                            child: ValueListenableBuilder<int>(
                              valueListenable: NotificationUnreadCount.value,
                              builder: (context, unreadCount, _) =>
                                  _SecondaryCard(
                                    title: 'Bildirimler',
                                    icon: LucideIcons.bellRing,
                                    color: c.bad,
                                    badgeCount: unreadCount,
                                    onTap: () => context.go('/notifications'),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
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
  const _ArcMotif({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ArcPainter(color: color.withValues(alpha: .11)),
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

/// Ana giris: beyaz kart, arkasinda kendi renginde bir raf.
///
/// Raf kartin altindan gorunuyor; derinlik renkle degil katmanla veriliyor,
/// boylece kart beyaz kalirken asagidaki listeden ayrilabiliyor.
class _PrimaryCard extends StatelessWidget {
  const _PrimaryCard({
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
      child: Stack(
        children: [
          Positioned(
            left: 10,
            right: 10,
            bottom: 0,
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(color, c.surface, .62),
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 20,
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: c.border),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: .24),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    bottom: -26,
                    width: 190,
                    height: 118,
                    child: _ArcMotif(color: color),
                  ),
                  Positioned.fill(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Color.lerp(c.surface, color, .14),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(icon, size: 30, color: color),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              title,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.visible,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: kDisplay,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                height: 1.05,
                                letterSpacing: -.5,
                                color: c.ink,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ikincil giris: kendi panelinde, ana kartlarla ayni ikon yapisiyla.
///
/// Ikon ana kartlardaki gibi tonlu bir karenin icinde; aradaki tek fark
/// olculer, boylece bes giris ayni dili konusuyor.
class _SecondaryCard extends StatelessWidget {
  const _SecondaryCard({
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
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Color.lerp(c.surface, color, .14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 21, color: color),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kDisplay,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.3,
                  color: c.ink,
                ),
              ),
            ),
            if ((badgeCount ?? 0) > 0)
              Container(
                height: 26,
                constraints: const BoxConstraints(minWidth: 26),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: c.bad,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  badgeCount! > 99 ? '99+' : '$badgeCount',
                  style: TextStyle(
                    fontFamily: kBody,
                    color: c.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
