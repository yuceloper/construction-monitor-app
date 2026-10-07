import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Ustten birakilan bosluk. Bos ekranlarin hepsi ayni yerden basliyor.
const double kEmptyTopGap = 40;

/// Butun bos durumlarda gorulen tek isaret: acik, bos bir kutu.
///
/// Daha once her ekran kendi konusunun ikonunu gosteriyordu (zil, kalkan,
/// atas, saat...). Bos olan her yerde ayni seyin gorulmesi icin ekrana ozel
/// ikon kaldirildi.
class EmptyIllustration extends StatelessWidget {
  const EmptyIllustration({super.key, this.size = 118});

  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmptyBoxPainter(
          stroke: c.faint,
          body: c.inset,
          lid: c.surface,
          detail: c.border2,
        ),
      ),
    );
  }
}

class _EmptyBoxPainter extends CustomPainter {
  _EmptyBoxPainter({
    required this.stroke,
    required this.body,
    required this.lid,
    required this.detail,
  });

  final Color stroke;
  final Color body;
  final Color lid;
  final Color detail;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cizgi = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .028
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = stroke;

    final govde = Rect.fromLTWH(w * .20, w * .42, w * .60, w * .34);
    final govdeR = RRect.fromRectAndRadius(govde, Radius.circular(w * .04));
    canvas.drawRRect(govdeR, Paint()..color = body);
    canvas.drawRRect(govdeR, cizgi);

    final sol = Path()
      ..moveTo(w * .20, w * .42)
      ..lineTo(w * .10, w * .28)
      ..lineTo(w * .38, w * .22)
      ..lineTo(w * .50, w * .42);
    final sag = Path()
      ..moveTo(w * .80, w * .42)
      ..lineTo(w * .90, w * .28)
      ..lineTo(w * .62, w * .22)
      ..lineTo(w * .50, w * .42);
    canvas.drawPath(sol, Paint()..color = lid);
    canvas.drawPath(sag, Paint()..color = lid);
    canvas.drawPath(sol, cizgi);
    canvas.drawPath(sag, cizgi);

    canvas.drawLine(
      Offset(w * .42, w * .56),
      Offset(w * .58, w * .56),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * .022
        ..strokeCap = StrokeCap.round
        ..color = detail,
    );
  }

  @override
  bool shouldRepaint(_EmptyBoxPainter old) =>
      old.stroke != stroke ||
      old.body != body ||
      old.lid != lid ||
      old.detail != detail;
}
