import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import 'panel.dart';
import 'pressable.dart';

/// Shown while a screen waits for the backend. Quiet on purpose - a centred
/// indicator and nothing else, because the wait is normally short.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: context.colors.ink,
        ),
      ),
    );
  }
}

/// Shown when a request fails. Always offers a way forward: the message says
/// what went wrong and the button retries without leaving the screen.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconBox(icon: LucideIcons.cloudOff, color: c.bad, size: 48),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 13.5,
                height: 1.5,
                color: c.sub,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 18),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A whole screen with nothing to list. Not an error: the request worked,
/// there is simply no content yet.
///
/// Says what is missing ([title]), why or what happens next ([message]) and,
/// where the user can do something about it, offers that one action.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // Blok dikeyde ortalanmiyor; ekranin ust bolumunde duruyor ki
    // basligin hemen altindan okunmaya baslasin.
    return Align(
      alignment: const Alignment(0, -.45),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
        child: FadeSlideIn(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                EmptyIllustration(icon: icon),
                const SizedBox(height: 22),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: c.sub,
                  ),
                ),
                if (message != null) ...[
                  const SizedBox(height: 7),
                  Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 13,
                      height: 1.55,
                      color: c.sub,
                    ),
                  ),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 20),
                  SmallButton(
                    label: actionLabel!,
                    icon: actionIcon,
                    onTap: onAction,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The picture above an empty screen: the subject's icon on a raised disc,
/// inside two rings and a short hazard-tape arc - the same site language as
/// the login stripe, so an empty screen still looks like part of the product.
class EmptyIllustration extends StatelessWidget {
  const EmptyIllustration({super.key, required this.icon, this.size = 132});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final disc = size * .5;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _RingsPainter(ring: c.border2, fill: c.inset, stripe: c.faint),
            ),
          ),
          Container(
            width: disc,
            height: disc,
            decoration: BoxDecoration(
              color: c.surface,
              shape: BoxShape.circle,
              border: Border.all(color: c.border),
              boxShadow: kLiftShadow,
            ),
            child: Icon(icon, size: disc * .42, color: c.sub),
          ),
          // A small accent dot keeps the picture from reading as disabled.
          Positioned(
            top: size * .2,
            right: size * .2,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
                border: Border.all(color: c.bg, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.ring, required this.fill, required this.stripe});

  final Color ring;
  final Color fill;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;

    canvas.drawCircle(center, outer * .78, Paint()..color = fill);
    canvas.drawCircle(
      center,
      outer * .78,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Dashed outer ring.
    final dash = Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashes = 36;
    for (var i = 0; i < dashes; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outer * .97),
        i * 2 * math.pi / dashes,
        math.pi / dashes,
        false,
        dash,
      );
    }

    // Short hazard-tape arc along the lower left.
    final tape = Paint()
      ..color = stripe
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 5; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: outer * .88),
        math.pi * .62 + i * .13,
        .06,
        false,
        tape,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.ring != ring || old.fill != fill || old.stripe != stripe;
}

/// Liste bosken gosterilen tek satirlik mesaj: ekranin ortasinda durur ve
/// asagi cekince yenileme yine calisir.
class CenteredScrollMessage extends StatelessWidget {
  const CenteredScrollMessage({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 16,
                    height: 1.5,
                    color: c.sub,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
