import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Kisi adinin kutuya sigacak hali.
///
/// Ad soyad verilen genislige sigiyorsa oldugu gibi doner; sigmiyorsa ilk
/// ad ve soyadin bas harfi kalir ("Muhammed Abdulrezzak Admin" ->
/// "Muhammed A."). Ayni kural hem ust kosedeki kullanici kutusunda hem de
/// listelerde kullaniliyor; boylece ayni kisi her yerde ayni yaziliyor.
///
/// [enBoy] yazinin kullanabilecegi genislik, [olcu] yazi puntosu.
String kisaKisiAdi(
  BuildContext context,
  String adSoyad, {
  required double enBoy,
  double olcu = 14,
}) {
  final parcalar = adSoyad.split(' ').where((p) => p.isNotEmpty).toList();
  if (parcalar.length < 2) return adSoyad;

  final olcek = MediaQuery.textScalerOf(context);
  double genislik(String metin) {
    final painter = TextPainter(
      text: TextSpan(
        text: metin,
        style: TextStyle(
          fontFamily: kBody,
          fontSize: olcu,
          fontWeight: FontWeight.w600,
        ),
      ),
      textScaler: olcek,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  if (genislik(adSoyad) <= enBoy) return adSoyad;
  return '${parcalar.first} ${parcalar.last.characters.first}.';
}
