import 'package:flutter/material.dart';

import '../../app/theme.dart';
import 'brand_logo.dart';

/// The branded opening screen, drawn over the app while it starts.
///
/// [BrandSplash] wraps the whole app: it shows the logo on the page colour,
/// holds for a moment and then fades away, so the first thing a user sees is
/// the brand rather than a blank white window. It never blocks navigation -
/// the app underneath is already built and takes over as soon as the fade
/// finishes.
class BrandSplash extends StatefulWidget {
  const BrandSplash({super.key, required this.child});

  final Widget child;

  @override
  State<BrandSplash> createState() => _BrandSplashState();
}

class _BrandSplashState extends State<BrandSplash>
    with TickerProviderStateMixin {
  /// The sweeping line under the logo, looping while the splash is up.
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat();

  /// The logo settling into place as the screen appears.
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  )..forward();

  /// The fade that hands the screen over to the app.
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
    value: 1,
  );

  bool _done = false;

  @override
  void initState() {
    super.initState();
    // Counted from the first painted frame, not from when the widget is
    // created: Android draws its own launch screen on top until then, and a
    // timer started earlier would spend itself behind it.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    await Future<void>.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    await _fade.reverse();
    if (!mounted) return;
    setState(() => _done = true);
    _sweep.stop();
  }

  @override
  void dispose() {
    _sweep.dispose();
    _enter.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;

    final c = context.colors;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _fade,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.surface2, c.bg, c.track],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: -60,
                      bottom: 120,
                      width: 700,
                      height: 420,
                      child: CustomPaint(
                        painter: _SplashArcPainter(
                          color: c.accent.withValues(alpha: .10),
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _enter,
                              curve: const Interval(0, .7, curve: Curves.easeOut),
                            ),
                            child: ScaleTransition(
                              scale: Tween<double>(begin: .94, end: 1).animate(
                                CurvedAnimation(
                                  parent: _enter,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                              child: const BrandLogo(height: 74),
                            ),
                          ),
                          const SizedBox(height: 40),
                          FadeTransition(
                            opacity: CurvedAnimation(
                              parent: _enter,
                              curve: const Interval(.45, 1, curve: Curves.easeOut),
                            ),
                            child: SizedBox(
                              width: 120,
                              height: 3,
                              child: AnimatedBuilder(
                                animation: _sweep,
                                builder: (context, _) => Stack(
                                  children: [
                                    Container(color: c.track),
                                    Align(
                                      alignment: Alignment(
                                        _sweep.value * 2 - 1,
                                        0,
                                      ),
                                      child: Container(
                                        width: 44,
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: c.accent,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                  ],
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
          ),
        ),
      ],
    );
  }
}

/// The brand arc, laid down faintly behind the logo.
class _SplashArcPainter extends CustomPainter {
  _SplashArcPainter({required this.color});

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
      canvas.drawPath(
        Path()
          ..moveTo(size.width * .02 + inset, size.height * .86)
          ..quadraticBezierTo(
            size.width * .52,
            size.height * .42 + inset * .7,
            size.width * 1.02,
            size.height * .86,
          ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SplashArcPainter old) => old.color != color;
}
