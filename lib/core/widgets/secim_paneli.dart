import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme.dart';
import 'pressable.dart';

/// Uygulamadaki butun "secim" alanlarinin ortak parcalari.
///
/// Onceden ucu bir arada yasiyordu: acilir sistem menusu (ekrani kenardan
/// kenara kapliyordu), alttan acilan kutulu liste ve alttan acilan cizgili
/// liste. Ayni isi yapan alanlar farkli goruntu veriyordu; hepsi buradaki
/// tek kaliba bagli.

/// Panelde gosterilen tek secenek.
class SecimSecenegi<T> {
  const SecimSecenegi(this.deger, this.ad);

  final T deger;
  final String ad;
}

/// Alttan acilan panellerin ortak kabugu: tutamac, baslik, govde.
class SecimPaneliKabugu extends StatelessWidget {
  const SecimPaneliKabugu({
    super.key,
    required this.baslik,
    required this.govde,
    this.baslikAltina,
  });

  final String baslik;
  final Widget govde;

  /// Basligin hemen altina giren istege bagli alan (ornegin arama kutusu).
  final Widget? baslikAltina;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .6,
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        10,
        16,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: c.border2,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              baslik,
              style: TextStyle(
                fontFamily: kDisplay,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -.3,
                color: c.ink,
              ),
            ),
          ),
          if (baslikAltina != null) baslikAltina!,
          Flexible(child: govde),
        ],
      ),
    );
  }
}

/// Paneldeki tek satir. Secili olan cerceveden ve tikten belli oluyor.
class SecimSatiri extends StatelessWidget {
  const SecimSatiri({
    super.key,
    required this.ad,
    required this.secili,
    required this.onTap,
  });

  final String ad;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        decoration: BoxDecoration(
          color: secili ? c.accent.withValues(alpha: .08) : c.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: secili ? c.accent : c.border,
            width: secili ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ad,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
            ),
            if (secili) ...[
              const SizedBox(width: 10),
              Icon(LucideIcons.check, size: 20, color: c.accent),
            ],
          ],
        ),
      ),
    );
  }
}

/// Secim panelini acar, secilen degeri dondurur. Vazgecilirse null.
/// Son dokunulan secim alaninin ekrandaki yeri.
///
/// Tarayicida liste bu alanin altina yapisik aciliyor. [SeciciAlan]
/// dokunuldugunda burayi dolduruyor; baska bir yerden acilirsa (olcu
/// bilinmiyorsa) liste ekranin ustunde ortalanir.
Rect? _sonAlanKutusu;

/// [alanContext] verilince liste o alanin altina yapisik aciliyor.
///
/// [SeciciAlan] kendi yerini zaten kaydediyor; kendi satirini cizen
/// ekranlar (gunluk isler filtresi gibi) satirin context'ini buradan
/// gecirebiliyor. Verilmezse liste ekranin ustunde ortalaniyordu.
Future<T?> secimPaneliAc<T>(
  BuildContext context, {
  required String baslik,
  required List<SecimSecenegi<T>> secenekler,
  required T? secili,
  BuildContext? alanContext,
}) {
  if (alanContext != null) _alaninYeriniKaydet(alanContext);
  // Telefonda alttan panel; tarayicida alana yapisik liste. Mobil
  // davranis hic degismiyor.
  if (MediaQuery.sizeOf(context).width >= 700) {
    return _webListesiAc<T>(
      context,
      baslik: baslik,
      secenekler: secenekler,
      secili: secili,
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    // Kok navigator: aksi halde panel alt menunun ustune cikamiyor,
    // menu panelin yaninda parlak kaliyordu.
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => SecimPaneliKabugu(
      baslik: baslik,
      govde: ListView.separated(
        shrinkWrap: true,
        itemCount: secenekler.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final secenek = secenekler[i];
          return SecimSatiri(
            ad: secenek.ad,
            secili: secenek.deger == secili,
            onTap: () => Navigator.of(sheetContext).pop(secenek.deger),
          );
        },
      ),
    ),
  );
}

/// Secim panelini acan alan: formda acilir listenin durdugu yerde durur.
class SeciciAlan extends StatelessWidget {
  const SeciciAlan({
    super.key,
    required this.metin,
    required this.onTap,
    this.ipucu = 'Seçiniz',
  });

  /// Secili degerin adi; bossa ipucu gorunur.
  final String metin;
  final String ipucu;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap == null
          ? null
          : () {
              _alaninYeriniKaydet(context);
              onTap!();
            },
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: c.surface2,
            borderRadius: BorderRadius.circular(Sizes.rField),
            border: Border.all(color: c.border2, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  metin.isEmpty ? ipucu : metin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 16,
                    fontWeight: metin.isEmpty ? FontWeight.w400 : FontWeight.w500,
                    color: metin.isEmpty ? c.muted : c.ink,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(LucideIcons.chevronDown, size: 20, color: c.sub),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dokunulan alanin ekrandaki dikdortgenini olcer.
void _alaninYeriniKaydet(BuildContext context) {
  final nesne = context.findRenderObject();
  if (nesne is! RenderBox || !nesne.hasSize) {
    _sonAlanKutusu = null;
    return;
  }
  final sol = nesne.localToGlobal(Offset.zero);
  _sonAlanKutusu = sol & nesne.size;
}

/// Tarayicidaki secim listesi: alanin altina yapisik, alanla ayni
/// genislikte, disina tiklayinca kapanan bir kart.
Future<T?> _webListesiAc<T>(
  BuildContext context, {
  required String baslik,
  required List<SecimSecenegi<T>> secenekler,
  required T? secili,
}) {
  final kutu = _sonAlanKutusu;
  return showGeneralDialog<T>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: baslik,
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 130),
    pageBuilder: (dialogContext, animasyon, ikinci) {
      final c = dialogContext.colors;
      final ekran = MediaQuery.sizeOf(dialogContext);
      const kenar = 16.0;
      const bosluk = 6.0;

      final en = kutu == null ? 340.0 : kutu.width;
      final sol = kutu == null
          ? (ekran.width - en) / 2
          : kutu.left.clamp(kenar, ekran.width - en - kenar);

      // Liste tiklanan alana yapisik duruyor: once altina, sigmazsa
      // ustune. Ikisine de sigmazsa ekranin icine cekiliyor ama yine
      // alanin yakininda kaliyor. Eskiden bos alan olcusune bakiliyor
      // ve liste alandan cok uzakta, sayfanin tepesinde aciliyordu.
      // Bir satir: 16+16 dolgu + yazi + aradaki 4 piksel bosluk.
      final gereken = (secenekler.length * 58.0 + 20).clamp(120.0, 360.0);
      final altBosluk = kutu == null
          ? ekran.height - 160
          : ekran.height - kutu.bottom - bosluk - kenar;
      final ustBosluk = kutu == null ? 0.0 : kutu.top - bosluk - kenar;
      final asagi = kutu == null || altBosluk >= gereken || altBosluk >= ustBosluk;
      final enYuksek = gereken.clamp(
        120.0,
        (asagi ? altBosluk : ustBosluk).clamp(120.0, 360.0),
      );

      // Dikey yer: alta sigiyorsa alanin hemen alti, degilse hemen ustu.
      var ust = kutu == null
          ? 120.0
          : (asagi ? kutu.bottom + bosluk : kutu.top - bosluk - enYuksek);
      final enAltSinir = ekran.height - kenar - enYuksek;
      if (ust > enAltSinir) ust = enAltSinir;
      if (ust < kenar) ust = kenar;

      final liste = Material(
        color: Colors.transparent,
        child: Container(
          width: en,
          constraints: BoxConstraints(maxHeight: enYuksek),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F101828),
                blurRadius: 26,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: secenekler.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (_, i) {
              final secenek = secenekler[i];
              return SecimSatiri(
                ad: secenek.ad,
                secili: secenek.deger == secili,
                onTap: () => Navigator.of(dialogContext).pop(secenek.deger),
              );
            },
          ),
        ),
      );

      return Stack(
        children: [
          Positioned(left: sol, top: ust, child: liste),
        ],
      );
    },
    transitionBuilder: (context, animasyon, ikinci, cocuk) {
      final egri = CurvedAnimation(parent: animasyon, curve: Curves.easeOut);
      return FadeTransition(
        opacity: egri,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -.02),
            end: Offset.zero,
          ).animate(egri),
          child: cocuk,
        ),
      );
    },
  );
}
