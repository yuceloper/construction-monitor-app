import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/state_views.dart';
import '../models/report_models.dart';
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

  ReportData? _data;
  bool _isLoading = true;
  String? _errorMessage;

  /// Secili sekme ve suzgec. Sekme degisince suzgec sifirlaniyor, yoksa
  /// "Geciken" secili kalip yeni tipte bos liste gorunuyor.
  int _groupIndex = 0;
  BlockState? _filter;

  /// Uzun listede once ilk [_ilkGosterim] blok, sonra tamami.
  static const _ilkGosterim = 7;
  bool _hepsiAcik = false;

  @override
  void initState() {
    super.initState();
    _load();
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
            ScreenTitleBar(title: 'Rapor', onBack: () => context.go('/dashboard')),
            Expanded(child: _govde()),
          ],
        ),
      ),
    );
  }

  Widget _govde() {
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
          if (data.siteName.isNotEmpty) ...[
            _SantiyeSatiri(ad: data.siteName),
            const SizedBox(height: 12),
          ],
          if (gruplar.length > 1) ...[
            _TipSekmeleri(
              gruplar: gruplar,
              secili: _groupIndex,
              onSec: _sekmeSec,
            ),
            const SizedBox(height: 14),
          ],
          _OzetKarti(grup: grup),
          if (grup.blocks.isNotEmpty && !grup.hasPlannedEnd) ...[
            const SizedBox(height: 12),
            const _PlanYokSeridi(),
          ],
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
          _SonGuncellemeler(kayitlar: _data!.updates),
        ],
      ),
    );
  }
}

/// Basligin altindaki santiye satiri.
class _SantiyeSatiri extends StatelessWidget {
  const _SantiyeSatiri({required this.ad});
  final String ad;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(LucideIcons.mapPin, size: 15, color: c.muted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            ad,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: kBody,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.sub,
            ),
          ),
        ),
      ],
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

    final kutular = <Widget>[
      _OzetKutusu(
        icon: LucideIcons.building2,
        label: 'Toplam Blok',
        adet: toplam,
        yuzde: toplam == 0 ? 0 : 100,
        renk: c.ink,
        oranRenk: c.sub,
      ),
      _OzetKutusu(
        icon: LucideIcons.circleCheck,
        label: 'Tamamlanan',
        adet: grup.completed,
        yuzde: _oran(grup.completed, toplam),
        renk: c.ok,
      ),
      _OzetKutusu(
        icon: LucideIcons.clock,
        label: 'Devam Eden',
        adet: grup.inProgress,
        yuzde: _oran(grup.inProgress, toplam),
        renk: c.warn,
      ),
      _OzetKutusu(
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
          const SizedBox(height: 14),
          _DagilimSeridi(grup: grup),
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
    required this.yuzde,
    required this.renk,
    this.oranRenk,
  });

  final IconData icon;
  final String label;
  final int adet;
  final int yuzde;
  final Color renk;

  /// Toplam kutusunda oran notr renkte duruyor; digerlerinde sayiyla
  /// ayni renk.
  final Color? oranRenk;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: renk),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.sub,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Center(
            child: Text(
              '$adet',
              style: TextStyle(
                fontFamily: kDisplay,
                fontSize: 26,
                height: 1.05,
                fontWeight: FontWeight.w700,
                letterSpacing: -.8,
                color: renk,
              ),
            ),
          ),
          Center(
            child: Text(
              '%$yuzde',
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: oranRenk ?? renk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tamamlanan / devam eden / geciken / baslanmamis paylari tek seritte,
/// altinda her payin yuzdesi kendi renginde.
///
/// Cok ince paylarin etiketi yazilmiyor: 50 blokluk santiyede tek blok
/// %2 ediyor ve yazi komsu paya tasiyor.
class _DagilimSeridi extends StatelessWidget {
  const _DagilimSeridi({required this.grup});
  final BlockGroup grup;

  /// Etiket yazilacak en kucuk pay.
  static const _etiketEsigi = .08;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    if (grup.total == 0) {
      return Container(
        height: 12,
        decoration: BoxDecoration(
          color: c.track,
          borderRadius: BorderRadius.circular(99),
        ),
      );
    }

    final paylar = <(int, Color, Color)>[
      (grup.completed, c.ok, c.ok),
      (grup.inProgress, c.warn, c.warn),
      (grup.delayed, c.bad, c.bad),
      (grup.notStarted, c.track, c.muted),
    ].where((p) => p.$1 > 0).toList();

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 12,
            child: Row(
              // Varsayilan hiza ortalama; dolgularin kendi yuksekligi
              // olmadigi icin cizilmiyordu.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final p in paylar)
                  Expanded(flex: p.$1, child: ColoredBox(color: p.$2)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            for (final p in paylar)
              Expanded(
                flex: p.$1,
                child: p.$1 / grup.total >= _etiketEsigi
                    ? Text(
                        '%${(p.$1 * 100 / grup.total).round()}',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: p.$3,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlanYokSeridi extends StatelessWidget {
  const _PlanYokSeridi();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.inset,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.calendarOff, size: 15, color: c.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Planlanan bitiş tarihi girilmemiş',
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
      ('Geciken', grup.delayed, BlockState.delayed),
      ('Devam eden', grup.inProgress, BlockState.inProgress),
      ('Tamamlanan', grup.completed, BlockState.completed),
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
                for (final blok in gosterilen) ...[
                  _BlokSatiri(blok: blok, onTap: () => onBlok(blok)),
                  if (blok != gosterilen.last)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Container(height: 1, color: c.line),
                    ),
                ],
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
                        'Kalan ${tumu.length - gosterilen.length} bloğu göster',
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        blok.plannedEnd == null
                            ? 'Bitiş tarihi girilmemiş'
                            : 'Bitiş: ${_tarih(blok.plannedEnd!)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 12,
                          color: blok.plannedEnd == null ? c.faint : c.muted,
                        ),
                      ),
                    ),
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

  static String _tarih(DateTime t) =>
      '${t.day.toString().padLeft(2, '0')}.${t.month.toString().padLeft(2, '0')}.${t.year}';
}

class _SonGuncellemeler extends StatelessWidget {
  const _SonGuncellemeler({required this.kayitlar});
  final List<ReportUpdate> kayitlar;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final gosterilen = kayitlar.take(3).toList();

    return SectionCard(
      icon: LucideIcons.history,
      title: 'Son Güncellemeler',
      child: gosterilen.isEmpty
          ? const EmptyState(message: 'Henüz güncelleme yok.')
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
