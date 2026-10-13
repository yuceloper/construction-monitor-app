import 'package:flutter/material.dart';

/// Genis ekranlarda icerigi ortalayip makul bir genislikte tutar.
///
/// Uygulama telefon icin tasarlandi: kartlar, listeler ve formlar ekranin
/// tamamini kaplar. Masaustu tarayicida ayni duzen 1900 piksele yayilinca
/// bir panelin icinde kucucuk bir ikon ile yazi solda kaliyor, geri kalan
/// her sey bos duruyordu.
///
/// Burasi tek karar noktasi: ekran [enBoy]'dan genisse icerik ortalanip o
/// genislige sikisiyor, dar ekranda (telefon) hicbir sey degismiyor.

/// Liste ve kart sayfalari icin icerik sutunu.
const double kIcerikEniMax = 1000;

/// Tek sutunluk formlar (giris, santiye secimi) icin daha dar sutun.
const double kFormEniMax = 460;

class EkranSigdir extends StatelessWidget {
  const EkranSigdir({
    super.key,
    required this.child,
    this.enBoy = kIcerikEniMax,
  });

  final Widget child;
  final double enBoy;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, kisit) {
        final en = kisit.maxWidth > enBoy ? enBoy : kisit.maxWidth;

        // Yukseklik da aynen aktariliyor. Sadece genislik sinirlanip
        // Align ile ortalandiginda sayfa kendi dogal boyuna cekiliyor,
        // Expanded kullanan ekranlar cokuyor ve alt menu yukari
        // tirmaniyordu.
        Widget govde = SizedBox(width: en, child: child);
        if (kisit.hasBoundedHeight) {
          govde = SizedBox(height: kisit.maxHeight, child: govde);
        }
        return Center(child: govde);
      },
    );
  }
}
