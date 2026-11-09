import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/state_views.dart';
import '../../auth/services/session_manager.dart';
import '../models/report_models.dart';
import '../services/report_pdf_service.dart';
import 'report_pdf_page.dart';
import '../services/report_service.dart';

/// Blok bazli rapor ekrani.
///
/// Ust kisimda secili tipin koyu ozet karti, altinda duruma gore suzme
/// cipleri ve blok listesi var. Tip (Evler / Dükkanlar / Apartmanlar)
/// birden fazlaysa ustte sekme cubugu cikiyor; tek tipte hic cikmiyor.
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final _service = ReportService();
  final _pdfService = ReportPdfService();

  ReportData? _data;
  bool _isLoading = true;
  bool _isExportingPdf = false;
  String? _errorMessage;

  /// Secili sekme ve suzgec. Sekme degisince suzgec sifirlaniyor, yoksa
  /// "Geciken" secili kalip yeni tipte bos liste gorunuyor.
  int _groupIndex = 0;
  BlockState? _filter;

  /// Uzun listede once ilk [_ilkGosterim] blok, sonra tamami.
  static const _ilkGosterim = 7;
  bool _hepsiAcik = false;

  bool get _canViewReports =>
      SessionManager.instance.auth?.canViewReports ?? false;

  @override
  void initState() {
    super.initState();
    if (_canViewReports) {
      _load();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.getReport();
      if (!mounted) return;
      setState(() {
        _data = data;
        _groupIndex = 0;
        _filter = null;
        _hepsiAcik = false;
      });
    } on ReportException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (error) {
      // Beklenmeyen hatada ekran bos kalmasin: ne oldugunu soyluyoruz.
      if (!mounted) return;
      setState(() => _errorMessage = 'Rapor hazırlanamadı: $error');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _sekmeSec(int index) {
    setState(() {
      _groupIndex = index;
      _filter = null;
      _hepsiAcik = false;
    });
  }

  void _suzgecSec(BlockState? durum) {
    setState(() {
      _filter = _filter == durum ? null : durum;
      _hepsiAcik = false;
    });
  }

  void _blogaGit(BlockReport blok) {
    context.go(
      '/process/${Uri.encodeComponent(blok.name)}'
      '?progress=${blok.progress}&projectId=${blok.id}',
    );
  }

  /// Raporu PDF'e cevirip onizlemede aciyor. Paylasma orada, belge
  /// gorulduktten sonra yapiliyor.
  Future<void> _pdfOlarakAktar() async {
    final data = _data;
    if (data == null || _isExportingPdf) return;

    setState(() => _isExportingPdf = true);
    try {
      final bytes = await _pdfService.build(data);
      if (!mounted) return;

      final now = DateTime.now();
      final fileName =
          'sahada_surec_raporu_${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}.pdf';

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReportPdfPage(bytes: bytes, fileName: fileName),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF raporu oluşturulamadı: $error'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExportingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(),
            ScreenTitleBar(
              title: 'Rapor',
              onBack: () => context.go('/dashboard'),
            ),
            Expanded(child: _govde()),
          ],
        ),
      ),
    );
  }

  Widget _govde() {
    if (!_canViewReports) return const PermissionView();
    if (_isLoading) return const LoadingView();
    if (_errorMessage != null) {
      return ErrorView(message: _errorMessage!, onRetry: _load);
    }

    final data = _data;
    if (data == null) return const SizedBox.shrink();

    final gruplar = data.groups;
    final grup = gruplar[_groupIndex.clamp(0, gruplar.length - 1)];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 22),
        children: [
          _SantiyeSatiri(
            ad: data.siteName,
            trailing: SmallButton(
              label: MediaQuery.sizeOf(context).width >= 430
                  ? 'PDF Olarak Aktar'
                  : 'PDF',
              icon: LucideIcons.fileText,
              busy: _isExportingPdf,
              onTap: _pdfOlarakAktar,
            ),
          ),
          const SizedBox(height: 10),
          _PlanSeridi(bitis: data.sitePlannedEnd),
          const SizedBox(height: 12),
          if (gruplar.length > 1) ...[
            _TipSekmeleri(
              gruplar: gruplar,
              secili: _groupIndex,
              onSec: _sekmeSec,
            ),
            const SizedBox(height: 14),
          ],
          _OzetKarti(grup: grup),
          const SizedBox(height: 12),
          if (grup.blocks.isNotEmpty) ...[
            _SuzgecCipleri(grup: grup, secili: _filter, onSec: _suzgecSec),
            const SizedBox(height: 12),
          ],
          _BlokListesi(
            grup: grup,
            filtre: _filter,
            hepsiAcik: _hepsiAcik,
            ilkGosterim: _ilkGosterim,
            onHepsiniGoster: () => setState(() => _hepsiAcik = true),
            onBlok: _blogaGit,
          ),
          const SizedBox(height: 12),
          _SonGuncellemeler(grup: grup, kayitlar: _data!.updates),
        ],
      ),
    );
  }
}

/// Basligin altindaki santiye satiri.
class _SantiyeSatiri extends StatelessWidget {
  const _SantiyeSatiri({required this.ad, this.trailing});

  final String ad;

  /// Satirin sagindaki aksiyon. Rapor aksiyonu burada duruyor: ekran
  /// adiyla ayni hizada degil, icerigin basladigi satirda.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return LayoutBuilder(
      builder: (context, kisit) {
        // Tarayicida sutun 1000 piksele kadar aciliyor. Ad Expanded
        // kalinca ad solda, aksiyon sagda, aralarinda avuc dolusu
        // bosluk duruyordu; ikisi ayni seyin parcasi olduklari halde
        // birbirine ait gorunmuyorlardi. Genis ekranda ad kendi
        // genisliginde duruyor ve aksiyon hemen yanina geliyor.
        // Telefonda hicbir sey degismiyor: orada satir zaten dolu.
        final genis = kisit.maxWidth >= 600;
        final adYazisi = Text(
          ad,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: kBody,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: c.sub,
          ),
        );

        return Row(
          children: [
            if (ad.isEmpty)
              const Spacer()
            else ...[
              Icon(LucideIcons.mapPin, size: 15, color: c.muted),
              const SizedBox(width: 7),
              if (genis)
                Flexible(child: adYazisi)
              else
                Expanded(child: adYazisi),
            ],
            if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          ],
        );
      },
    );
  }
}

/// Blok tipinin ikonu. Hem sekmelerde hem ozet kartinin basliginda
/// ayni ikon kullaniliyor.
IconData tipIkonu(BlockType tip) => switch (tip) {
  BlockType.house => LucideIcons.house,
  BlockType.shop => LucideIcons.store,
  BlockType.apartment => LucideIcons.building2,
  BlockType.other => LucideIcons.layoutGrid,
};

/// Tip sekmeleri. Iki ya da uc tip olabiliyor (Evler / Dükkanlar /
/// Apartmanlar); tek tipte bu bilesen hic cizilmiyor.
/// Tip sekmeleri. Iki ya da uc tip olabiliyor (Evler / Dükkanlar /
/// Apartmanlar); tek tipte bu bilesen hic cizilmiyor.
class _TipSekmeleri extends StatelessWidget {
  const _TipSekmeleri({
    required this.gruplar,
    required this.secili,
    required this.onSec,
  });

  final List<BlockGroup> gruplar;
  final int secili;
  final ValueChanged<int> onSec;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    // IntrinsicHeight: sekmeler esit boyda olsun. Duz "stretch" liste
    // icinde yuksekligi belirsiz biraktigi icin cizim patliyordu.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        for (var i = 0; i < gruplar.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: Pressable(
              onTap: () => onSec(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: i == secili ? c.surface : c.inset,
                  borderRadius: BorderRadius.circular(Sizes.rField),
                  border: Border.all(
                    color: i == secili ? c.accent : c.border,
                    width: i == secili ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tipIkonu(gruplar[i].type),
                          size: 15,
                          color: i == secili ? c.accent : c.muted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            gruplar[i].label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: i == secili ? c.ink : c.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${gruplar[i].total} Blok',
                      style: TextStyle(
                        fontFamily: kBody,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: i == secili ? c.sub : c.faint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        ],
      ),
    );
  }
}

/// Ozet karti: baslik, dort rakam kutusu ve dagilim seridi.
///
/// Duzeni gelen referans fotograftan: sayi durum renginde, orani hemen
/// altinda. Dar ekranda kutular 2x2 diziliyor, genis ekranda dordu yan
/// yana; telefonda tek sirada "Tamamlanan" gibi etiketler kirpiliyordu.
class _OzetKarti extends StatelessWidget {
  const _OzetKarti({required this.grup});
  final BlockGroup grup;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final toplam = grup.total;

    List<Widget> kutulariKur(bool yatay) => <Widget>[
      _OzetKutusu(
        yatay: yatay,
        icon: LucideIcons.building2,
        label: 'Toplam Blok',
        adet: toplam,
        renk: c.ink,
      ),
      _OzetKutusu(
        yatay: yatay,
        icon: LucideIcons.circleCheck,
        label: 'Tamamlanan',
        adet: grup.completed,
        yuzde: _oran(grup.completed, toplam),
        renk: c.ok,
      ),
      _OzetKutusu(
        yatay: yatay,
        icon: LucideIcons.clock,
        label: 'Devam Eden',
        adet: grup.inProgress,
        yuzde: _oran(grup.inProgress, toplam),
        renk: c.warn,
      ),
      _OzetKutusu(
        yatay: yatay,
        icon: LucideIcons.circleAlert,
        label: 'Geciken',
        adet: grup.delayed,
        yuzde: _oran(grup.delayed, toplam),
        renk: c.bad,
      ),
    ];

    return Panel(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(tipIkonu(grup.type), size: 17, color: c.ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  grup.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.ink,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '($toplam Blok)',
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.sub,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, kisit) {
              final tekSira = kisit.maxWidth >= 520;
              // Kutunun eni burada biliniyor: tek sirada dort kutu ve
              // aralarinda 10'ar piksel, iki sirada iki kutu. Genis
              // kutuda etiket solda sayi sagda duruyor; olcumu kutunun
              // kendisi yapamiyor, cunku asagidaki IntrinsicHeight
              // icinde LayoutBuilder calismiyor.
              final kutuEni = tekSira
                  ? (kisit.maxWidth - 30) / 4
                  : (kisit.maxWidth - 10) / 2;
              final kutular = kutulariKur(kutuEni >= 190);
              if (tekSira) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < kutular.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: kutular[i]),
                      ],
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (var sira = 0; sira < 2; sira++) ...[
                    if (sira > 0) const SizedBox(height: 10),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: kutular[sira * 2]),
                          const SizedBox(width: 10),
                          Expanded(child: kutular[sira * 2 + 1]),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  static int _oran(int adet, int toplam) =>
      toplam == 0 ? 0 : (adet * 100 / toplam).round();
}

/// Tek rakam kutusu: ustte ikon ve etiket, altinda sayi ve orani.
class _OzetKutusu extends StatelessWidget {
  const _OzetKutusu({
    required this.icon,
    required this.label,
    required this.adet,
    required this.renk,
    required this.yatay,
    this.yuzde,
  });

  /// Kutu genisse etiket solda, sayi sagda duruyor. Karari ustteki
  /// kart veriyor: kutunun eni orada belli.
  final bool yatay;

  final IconData icon;
  final String label;
  final int adet;
  final Color renk;

  /// Toplam blok kutusunda oran yazilmiyor: toplamin kendi icindeki
  /// payi her zaman %100 ve bir sey anlatmiyor.
  final int? yuzde;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 11),
      decoration: BoxDecoration(
        color: c.inset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Builder(
        builder: (context) {
          final etiket = Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: kBody,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: c.sub,
            ),
          );
          final sayi = Text(
            '$adet',
            style: TextStyle(
              fontFamily: kDisplay,
              fontSize: 26,
              height: 1.05,
              fontWeight: FontWeight.w700,
              letterSpacing: -.8,
              color: renk,
            ),
          );
          final oran = yuzde == null
              ? null
              : Text(
                  '%$yuzde',
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: renk,
                  ),
                );

          // Telefonda kutu dar: etiket ustte, sayi altinda ortada.
          // Tarayicida ayni kutu 240 piksele aciliyor ve o duzende
          // ortada tek bir rakamla kocaman bir bosluk kaliyordu.
          // Genis kutuda etiket solda, sayi sagda duruyor.
          if (yatay) {
            return Row(
              children: [
                Icon(icon, size: 14, color: renk),
                const SizedBox(width: 6),
                Expanded(child: etiket),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [sayi, ?oran],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: renk),
                  const SizedBox(width: 6),
                  Expanded(child: etiket),
                ],
              ),
              const SizedBox(height: 7),
              Center(child: sayi),
              if (oran != null) Center(child: oran),
            ],
          );
        },
      ),
    );
  }
}

/// Santiyenin genel planlanan bitis tarihi.
///
/// Bloklar paralel ilerledigi icin bloklarin kendi bitis tarihleri
/// raporda gosterilmiyor; tarih tek yerde, santiye seviyesinde duruyor.
/// Gecikmeyi bu tarih belirlemiyor: onu sunucu blok blok hesapliyor.
class _PlanSeridi extends StatelessWidget {
  const _PlanSeridi({required this.bitis});

  final DateTime? bitis;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final yok = bitis == null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(
            yok ? LucideIcons.calendarOff : LucideIcons.calendarCheck,
            size: 15,
            color: c.muted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              yok
                  ? 'Şantiyenin planlanan bitiş tarihi girilmemiş'
                  : 'Şantiye planlanan bitiş: ${tarihYaz(bitis!)}',
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.sub,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// gg.aa.yyyy. Rapor ekraninda tek bicim kullaniliyor.
String tarihYaz(DateTime t) =>
    '${t.day.toString().padLeft(2, '0')}.'
    '${t.month.toString().padLeft(2, '0')}.${t.year}';

class _SuzgecCipleri extends StatelessWidget {
  const _SuzgecCipleri({
    required this.grup,
    required this.secili,
    required this.onSec,
  });

  final BlockGroup grup;
  final BlockState? secili;
  final ValueChanged<BlockState?> onSec;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ogeler = <(String, int, BlockState?)>[
      ('Tümü', grup.total, null),
      ('Tamamlanan', grup.completed, BlockState.completed),
      ('Devam Eden', grup.inProgress, BlockState.inProgress),
      ('Geciken', grup.delayed, BlockState.delayed),
      if (grup.notStarted > 0)
        ('Başlanmadı', grup.notStarted, BlockState.notStarted),
    ];

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final o in ogeler)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Pressable(
                onTap: () => onSec(o.$3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: o.$3 == secili ? c.ink : c.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: o.$3 == secili ? c.ink : c.border,
                    ),
                  ),
                  child: Text(
                    '${o.$1} ${o.$2}',
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: o.$3 == secili ? c.bg : c.sub,
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

class _BlokListesi extends StatelessWidget {
  const _BlokListesi({
    required this.grup,
    required this.filtre,
    required this.hepsiAcik,
    required this.ilkGosterim,
    required this.onHepsiniGoster,
    required this.onBlok,
  });

  final BlockGroup grup;
  final BlockState? filtre;
  final bool hepsiAcik;
  final int ilkGosterim;
  final VoidCallback onHepsiniGoster;
  final ValueChanged<BlockReport> onBlok;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tumu = filtre == null
        ? grup.blocks
        : grup.blocks.where((b) => b.state == filtre).toList();
    final gosterilen = hepsiAcik ? tumu : tumu.take(ilkGosterim).toList();

    return SectionCard(
      icon: LucideIcons.layoutList,
      title: '${grup.label} (${tumu.length})',
      child: grup.blocks.isEmpty
          ? const EmptyState(
              message: 'Bu şantiyede henüz blok tanımlanmamış.',
            )
          : tumu.isEmpty
          ? const EmptyState(message: 'Bu durumda blok bulunmuyor.')
          : Column(
              children: [
                _Bloklar(
                  bloklar: gosterilen,
                  onBlok: onBlok,
                  cizgi: c.line,
                ),
                if (!hepsiAcik && tumu.length > gosterilen.length) ...[
                  const SizedBox(height: 12),
                  Pressable(
                    onTap: onHepsiniGoster,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.inset,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        'Daha Fazla Göster',
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: c.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}

/// Blok satirlarini ekranin enine gore diziyor.
///
/// Bir blok satiri telefonda sayfanin enini hakkiyla dolduruyor.
/// Tarayicida ayni satir 1000 piksele yayilinca ad ile yuzdesi
/// ekranin iki ucuna dusuyor, aradaki ilerleme cubugu da saca
/// benziyordu. Genis ekranda satirlar ikiserli diziliyor: hem yazilar
/// birbirine yakin kaliyor hem de ayni anda iki kat blok goruluyor.
class _Bloklar extends StatelessWidget {
  const _Bloklar({
    required this.bloklar,
    required this.onBlok,
    required this.cizgi,
  });

  final List<BlockReport> bloklar;
  final ValueChanged<BlockReport> onBlok;
  final Color cizgi;

  Widget _ayrac() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(height: 1, color: cizgi),
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, kisit) {
        if (kisit.maxWidth < 700) {
          return Column(
            children: [
              for (final blok in bloklar) ...[
                _BlokSatiri(blok: blok, onTap: () => onBlok(blok)),
                if (blok != bloklar.last) _ayrac(),
              ],
            ],
          );
        }

        return Column(
          children: [
            for (var i = 0; i < bloklar.length; i += 2) ...[
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _BlokSatiri(
                        blok: bloklar[i],
                        onTap: () => onBlok(bloklar[i]),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      // Tek sayida blok kalinca son satirin ikinci
                      // yeri bos duruyor; kalan blok tam ene
                      // yayilip digerlerinden farkli gorunmesin.
                      child: i + 1 < bloklar.length
                          ? _BlokSatiri(
                              blok: bloklar[i + 1],
                              onTap: () => onBlok(bloklar[i + 1]),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              if (i + 2 < bloklar.length) _ayrac(),
            ],
          ],
        );
      },
    );
  }
}

class _BlokSatiri extends StatelessWidget {
  const _BlokSatiri({required this.blok, required this.onTap});
  final BlockReport blok;
  final VoidCallback onTap;

  Color _renk(AppColors c) => switch (blok.state) {
    BlockState.completed => c.ok,
    BlockState.inProgress => c.accent,
    BlockState.delayed => c.bad,
    BlockState.notStarted => c.muted,
  };

  IconData get _ikon => switch (blok.state) {
    BlockState.completed => LucideIcons.check,
    BlockState.inProgress => LucideIcons.refreshCw,
    BlockState.delayed => LucideIcons.triangleAlert,
    BlockState.notStarted => LucideIcons.clock,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final renk = _renk(c);

    // Blok adi basligin yerinde duruyor: sunucudaki adlar "a block",
    // "TEST-EV-01" gibi uzun olabiliyor ve kucuk bir rozete sigmiyordu.
    // Durum, rengi tasiyan ikon ve alt satirdaki yazi ile veriliyor.
    return Pressable(
      onTap: onTap,
      child: Row(
        children: [
          StatusBadge(icon: _ikon, color: renk),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        blok.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kDisplay,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.1,
                          color: c.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '%${blok.progress}',
                      style: TextStyle(
                        fontFamily: kDisplay,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                ProgressRail(percent: blok.progress, height: 6, color: renk),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      blok.state.label,
                      style: TextStyle(
                        fontFamily: kBody,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: renk,
                      ),
                    ),
                    if (blok.state == BlockState.delayed &&
                        blok.expectedProgress != null) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'bugün beklenen %${blok.expectedProgress}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 12,
                            color: c.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(LucideIcons.chevronRight, size: 18, color: c.faint),
        ],
      ),
    );
  }

}

/// Secili tipin son guncellemeleri.
///
/// Bildirim ucunda tip suzgeci yok; gelen kayitlar blok kimligine gore
/// gruba ayriliyor. Blok kimligi olmayan kayit bir tipe yazilamadigi
/// icin gosterilmiyor.
class _SonGuncellemeler extends StatelessWidget {
  const _SonGuncellemeler({required this.grup, required this.kayitlar});

  final BlockGroup grup;
  final List<ReportUpdate> kayitlar;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final kimlikler = {for (final b in grup.blocks) b.id};
    final gosterilen = kayitlar
        .where((g) => g.blockId != null && kimlikler.contains(g.blockId))
        .take(3)
        .toList();

    return SectionCard(
      icon: LucideIcons.history,
      title: 'Son Güncellemeler',
      child: gosterilen.isEmpty
          ? EmptyState(
              message: '${grup.label} için henüz güncelleme yok.',
            )
          : Column(
              children: [
                for (final g in gosterilen) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(top: 6),
                        decoration: BoxDecoration(
                          color: c.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g.detail.isEmpty ? g.title : g.detail,
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                                color: c.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (g.blockName != null &&
                                    g.blockName!.isNotEmpty)
                                  g.blockName!,
                                _tarih(g.date),
                              ].join(' · '),
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 12.5,
                                color: c.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (g != gosterilen.last)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      child: Container(height: 1, color: c.line),
                    ),
                ],
              ],
            ),
    );
  }

  static String _tarih(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
}
