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
Future<T?> secimPaneliAc<T>(
  BuildContext context, {
  required String baslik,
  required List<SecimSecenegi<T>> secenekler,
  required T? secili,
}) {
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
      onTap: onTap,
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
