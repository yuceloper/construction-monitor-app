import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/active_site.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/genisleyen_metin.dart';
import '../../../core/widgets/kisa_ad.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/secim_paneli.dart';
import '../models/daily_task_summary.dart';
import '../../auth/services/session_manager.dart';
import '../../site_selection/models/site_member_summary.dart';
import '../../site_selection/services/site_service.dart';
import '../services/daily_task_service.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage>
    with WidgetsBindingObserver {
  final _service = DailyTaskService();
  final _siteService = SiteService();

  /// Kisi filtresinin secenekleri. Listedeki islerin kisilerinden degil,
  /// is eklerken "Ilgili Kisi" alaninda cikan santiye calisanlarindan
  /// geliyor: henuz isi olmayan kisi de filtrede duruyor.
  List<SiteMemberSummary> _santiyeKisileri = const [];

  bool _showAll = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<DailyTaskSummary> _tasks = const [];

  /// Filtre olcutleri istemcide uygulaniyor: kritiklik, kisi ve
  /// tarihe gore siralama.
  String? _filtreOncelik;
  String? _filtreKisi;

  /// 'yeni' en yeniden eskiye, 'eski' tersine. Filtrede "Varsayilan"
  /// diye bir secenek yok; liste her zaman bir yone gore siralaniyor ve
  /// yeniden eskiye basliyor.
  String _siralama = 'yeni';

  List<DailyTaskSummary> get _gosterilen {
    final liste = _tasks.where((task) {
      if (_filtreOncelik != null && task.priority != _filtreOncelik) {
        return false;
      }
      if (_filtreKisi != null && task.assignedToName != _filtreKisi) {
        return false;
      }
      return true;
    }).toList();

    liste.sort((a, b) {
      final at = a.tarih;
      final bt = b.tarih;
      if (at == null && bt == null) return 0;
      if (at == null) return 1;
      if (bt == null) return -1;
      return _siralama == 'yeni' ? bt.compareTo(at) : at.compareTo(bt);
    });
    return liste;
  }

  /// Secili butun olcutleri kaldiriyor.
  void _filtreyiTemizle() {
    setState(() {
      _filtreOncelik = null;
      _filtreKisi = null;
      _siralama = 'yeni';
    });
  }

  /// Kac olcut secili? Filtre dugmesinin yanindaki sayi bu.
  int get _filtreSayisi => [
    _filtreOncelik != null,
    _filtreKisi != null,
    _siralama != 'yeni',
  ].where((secili) => secili).length;

  bool get _filtreVar =>
      _filtreOncelik != null || _filtreKisi != null || _siralama != 'yeni';

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _kisileriYukle();
    // Santiye degisince ve uygulama one gelince liste tazeleniyor;
    // ekranda eski santiyenin ya da eskimis bir listenin kalmasi
    // "veri yok" gibi gorunuyordu.
    ActiveSite.revision.addListener(_santiyeDegisti);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    ActiveSite.revision.removeListener(_santiyeDegisti);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _santiyeDegisti() {
    if (!mounted) return;
    setState(() {
      _tasks = const [];
      _filtreOncelik = null;
      _filtreKisi = null;
      _siralama = 'yeni';
      _santiyeKisileri = const [];
    });
    _loadTasks();
    _kisileriYukle();
  }

  /// Kisi filtresinin seceneklerini santiye calisanlarindan dolduruyor.
  /// Liste alinamazsa filtre islerdeki isimlerle calismaya devam ediyor.
  Future<void> _kisileriYukle() async {
    final siteId = SessionManager.instance.selectedSiteId;
    if (siteId == null || siteId <= 0) return;
    try {
      final kisiler = await _siteService.getMembers(siteId);
      if (!mounted) return;
      setState(() => _santiyeKisileri = kisiler);
    } catch (_) {
      // Sessiz gecildi: filtre yine aciliyor.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState durum) {
    if (durum == AppLifecycleState.resumed && mounted) {
      _loadTasks(sessiz: _tasks.isNotEmpty);
    }
  }

  /// Iki sekmede de hic is yok. Sekme serisi bu durumda gizleniyor.
  bool _hicIsYok = false;

  /// Ekranda gosterilecek is yoksa ustteki sekmeler de gorunmuyor.
  /// Aktif liste bosken tamamlanmislar varsa, bos durumdaki dugme
  /// onlara goturuyor; boylece sekme gizlense de veri kaybolmuyor.
  /// Yuklenirken de gizli: bos ekran yuklenirken sekmeler bir an
  /// gorunup kayboluyordu.
  bool get _listeBos => _tasks.isEmpty && _errorMessage == null;
  bool _tamamlanmisVar = false;

  /// [sessiz] verildiginde ekranda ne varsa duruyor: spinner ya da bos
  /// durum arada bir an gorunup kaybolmuyor, liste gelince degisiyor.
  Future<void> _loadTasks({bool sessiz = false}) async {
    if (!sessiz) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final tasks = await _service.getTasks(includeCompleted: _showAll);
      if (!mounted) return;
      // Aktif liste bossa, tamamlanmislar dahil de bos mu diye bir kez
      // bakiliyor; sadece bu durumda ek istek atiliyor.
      var hicYok = tasks.isEmpty;
      var tamamlanmisVar = false;
      if (hicYok && !_showAll) {
        final tumu = await _service.getTasks(includeCompleted: true);
        hicYok = tumu.isEmpty;
        tamamlanmisVar = tumu.isNotEmpty;
      }
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _hicIsYok = hicYok;
        _tamamlanmisVar = tamamlanmisVar;
      });
    } on DailyTaskException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectTab(bool showAll) async {
    if (_showAll == showAll) return;
    setState(() => _showAll = showAll);
    await _loadTasks();
  }

  /// Filtre paneli. Olcutler istemcide uygulaniyor.
  Future<void> _filtrePaneliniAc() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final c = sheetContext.colors;

          // Satirin kendi context'i gerekiyor: tarayicida secim listesi
          // bu satirin altina yapisik aciliyor, yoksa ekranin tepesinde
          // beliriyordu.
          Widget satir(
            String baslik,
            String? deger,
            IconData ikon,
            void Function(BuildContext satirContext) onTap,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Builder(
                builder: (satirContext) => Pressable(
                onTap: () => onTap(satirContext),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 15, 14, 15),
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(Sizes.rField),
                    border: Border.all(
                      color: deger == null ? c.border2 : c.accent,
                      width: deger == null ? 1 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(ikon, size: 18, color: c.sub),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          baslik,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: c.ink,
                          ),
                        ),
                      ),
                      if (deger != null) ...[
                        Text(
                          deger,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(LucideIcons.chevronRight, size: 19, color: c.muted),
                    ],
                  ),
                ),
              ),
              ),
            );
          }

          final kisiler =
              <String>{
                for (final kisi in _santiyeKisileri)
                  if (kisi.fullName.trim().isNotEmpty) kisi.fullName,
                for (final task in _tasks)
                  if (task.assignedToName.trim().isNotEmpty)
                    task.assignedToName,
              }.toList()
              ..sort();

          return SecimPaneliKabugu(
            baslik: 'Filtrele',
            govde: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                satir(
                  'Kritiklik',
                  _filtreOncelik == null ? null : _oncelikAdi(_filtreOncelik!),
                  LucideIcons.triangleAlert,
                  (satirContext) async {
                    final secim = await secimPaneliAc<String>(
                      sheetContext,
                      alanContext: satirContext,
                      baslik: 'Kritiklik',
                      secili: _filtreOncelik ?? '',
                      secenekler: const [
                        SecimSecenegi('', 'Tümü'),
                        SecimSecenegi('HIGH', 'Yüksek'),
                        SecimSecenegi('MEDIUM', 'Orta'),
                        SecimSecenegi('LOW', 'Düşük'),
                      ],
                    );
                    if (secim == null) return;
                    setState(
                      () => _filtreOncelik = secim.isEmpty ? null : secim,
                    );
                    setSheetState(() {});
                  },
                ),
                satir(
                  'Tarihe Göre Sırala',
                  _siralama == 'yeni' ? 'Yeniden Eskiye' : 'Eskiden Yeniye',
                  LucideIcons.calendarDays,
                  (satirContext) async {
                    final secim = await secimPaneliAc<String>(
                      sheetContext,
                      alanContext: satirContext,
                      baslik: 'Tarihe Göre Sırala',
                      secili: _siralama,
                      secenekler: const [
                        SecimSecenegi('yeni', 'Yeniden Eskiye'),
                        SecimSecenegi('eski', 'Eskiden Yeniye'),
                      ],
                    );
                    if (secim == null || secim.isEmpty) return;
                    setState(() => _siralama = secim);
                    setSheetState(() {});
                  },
                ),
                satir('Kişi', _filtreKisi, LucideIcons.user, (
                  satirContext,
                ) async {
                  final secim = await secimPaneliAc<String>(
                    sheetContext,
                    alanContext: satirContext,
                    baslik: 'Kişi',
                    secili: _filtreKisi ?? '',
                    secenekler: [
                      const SecimSecenegi('', 'Tümü'),
                      for (final kisi in kisiler) SecimSecenegi(kisi, kisi),
                    ],
                  );
                  if (secim == null) return;
                  setState(() => _filtreKisi = secim.isEmpty ? null : secim);
                  setSheetState(() {});
                }),
                if (_filtreVar)
                  Pressable(
                    onTap: () {
                      _filtreyiTemizle();
                      Navigator.of(sheetContext).pop();
                    },
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
                      child: Row(
                        children: [
                          Icon(LucideIcons.x, size: 17, color: c.sub),
                          const SizedBox(width: 8),
                          Text(
                            'Filtreyi Temizle',
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: c.sub,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Kritiklik kodunun ekranda gorunen adi.
  static String _oncelikAdi(String kod) {
    switch (kod) {
      case 'HIGH':
        return 'Yüksek';
      case 'LOW':
        return 'Düşük';
      default:
        return 'Orta';
    }
  }

  Future<void> _openCreate() async {
    final created = await context.push<bool>('/daily-tasks/create');
    if (!mounted || created != true) return;
    await _loadTasks(sessiz: _tasks.isNotEmpty);
  }

  Future<void> _openTask(DailyTaskSummary task) async {
    await context.push<bool>('/daily-tasks/${task.id}');
    if (!mounted) return;
    await _loadTasks(sessiz: _tasks.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            ScreenTitleBar(
              title: 'Günlük İşler',
              onBack: () => context.go('/dashboard'),
            ),
            if (!_listeBos)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TabButton(
                          label: 'AKTİF İŞLER',
                          selected: !_showAll,
                          onTap: () => _selectTab(false),
                        ),
                      ),
                      Expanded(
                        child: _TabButton(
                          label: 'TÜM İŞLER',
                          selected: _showAll,
                          onTap: () => _selectTab(true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Ekle tek basina bir kutu degil; solda kac is oldugunu
            // soyleyen satirin sag ucu. Bosta asili durmuyor, yer
            // kaplamasi en az ve ustelik bilgi de tasiyor.
            if (!_listeBos)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 18, 8),
                child: Row(
                  children: [
                    // Filtre, is sayisinin solunda duruyor. Secim
                    // varken dolu bir rozete donuyor: rengi degistirmek
                    // tek basina fark edilmiyordu.
                    Pressable(
                      onTap: _filtrePaneliniAc,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 12, 4),
                        child: Container(
                          padding: _filtreVar
                              ? const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                )
                              : const EdgeInsets.symmetric(vertical: 2),
                          decoration: _filtreVar
                              ? BoxDecoration(
                                  color: c.accent,
                                  borderRadius: BorderRadius.circular(9),
                                )
                              : null,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.slidersHorizontal,
                                size: 18,
                                color: _filtreVar ? c.surface : c.sub,
                              ),
                              if (_filtreVar) ...[
                                const SizedBox(width: 6),
                                Text(
                                  '$_filtreSayisi',
                                  style: TextStyle(
                                    fontFamily: kBody,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: c.surface,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Text(
                      _showAll
                          ? '${_gosterilen.length} İş'
                          : '${_gosterilen.length} Aktif İş',
                      style: TextStyle(
                        fontFamily: kBody,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: .2,
                        color: c.muted,
                      ),
                    ),
                    const Spacer(),
                    Pressable(
                      onTap: _openCreate,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 6, 2, 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(LucideIcons.plus, size: 18, color: c.accent),
                            const SizedBox(width: 6),
                            Text(
                              'Ekle',
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: c.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final c = context.colors;

    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: c.ink),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.circleAlert, color: c.bad, size: 42),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 16,
                  height: 1.45,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 18),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: _loadTasks,
              ),
            ],
          ),
        ),
      );
    }

    if (_gosterilen.isEmpty) {
      // Hic is yokken sekme serisi ve ustteki "Ekle" satiri gizleniyor.
      // Ekleme yolu da onlarla birlikte kaybolmasin diye bos durumun
      // kendisi "Ekle" sunuyor: yoksa yeni bir santiyede ilk is hic
      // olusturulamiyor.
      return RefreshIndicator(
        color: c.ink,
        onRefresh: _loadTasks,
        child: LayoutBuilder(
          builder: (context, constraints) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: constraints.maxHeight,
                // Liste dolu ama secili olcutlere uyan is yoksa neden
                // bos oldugu yaziyor ve filtre temizlenebiliyor; "is
                // bulunmuyor" demek yaniltiyordu.
                child: _filtreVar && _tasks.isNotEmpty
                    ? EmptyView(
                        title:
                            'Aradığınız kriterlere göre kayıt bulunmamaktadır.',
                        actionLabel: 'Filtreyi Temizle',
                        actionIcon: LucideIcons.filterX,
                        onAction: _filtreyiTemizle,
                      )
                    : EmptyView(
                        title: _showAll
                            ? 'Henüz günlük iş bulunmuyor.'
                            : 'Aktif günlük iş bulunmuyor.',
                        // Hic is yoksa dogrudan ekleme; aktif liste bos
                        // ama tamamlanmis is varsa onlara gecis.
                        actionLabel: _hicIsYok
                            ? 'Ekle'
                            : (_tamamlanmisVar && !_showAll
                                  ? 'Tümünü Göster'
                                  : null),
                        actionIcon: _hicIsYok
                            ? LucideIcons.plus
                            : (_tamamlanmisVar && !_showAll
                                  ? LucideIcons.listChecks
                                  : null),
                        onAction: _hicIsYok
                            ? _openCreate
                            : (_tamamlanmisVar && !_showAll
                                  ? () => _selectTab(true)
                                  : null),
                      ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: c.ink,
      onRefresh: _loadTasks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        itemCount: _gosterilen.length,
        separatorBuilder: (_, __) => const SizedBox(height: Sizes.gap),
        // Durum her iki sekmede de gorunuyor: aktif listede de isin
        // baslanacak mi devam mi oldugu karttan okunabiliyor.
        itemBuilder: (_, index) => _TaskCard(
          task: _gosterilen[index],
          onTap: () => _openTask(_gosterilen[index]),
          showStatus: true,
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: kBody,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: .3,
            color: selected ? c.bg : c.sub,
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final DailyTaskSummary task;
  final VoidCallback onTap;

  /// Isin durumu karttan okunabiliyor: Baslanacak, Devam Ediyor,
  /// Tamamlandi.
  final bool showStatus;

  const _TaskCard({
    required this.task,
    required this.onTap,
    this.showStatus = false,
  });

  Color badgeColor(AppColors c) {
    switch (task.priority) {
      case 'HIGH':
      case 'CRITICAL':
        return c.bad;
      case 'LOW':
        return c.muted;
      default:
        return c.priorityMid;
    }
  }

  /// Sari zeminde beyaz yazi okunmuyor; olculdu, kontrast 3.0'a dusuyor.
  /// Orta oncelikte yazi koyu, digerlerinde beyaz kaliyor.
  Color badgeTextColor(AppColors c) {
    switch (task.priority) {
      case 'HIGH':
      case 'CRITICAL':
        return c.surface;
      default:
        // Gri ve sari zeminde beyaz yazi okunmuyordu: olculdu, kontrast
        // 3.1'e dusuyor, erisilebilirlik siniri 4.5. Koyu yaziyla 6.0.
        return c.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final badge = badgeColor(c);
    final badgeText = badgeTextColor(c);

    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Sizes.rCard),
          border: Border.all(color: c.border),
          boxShadow: kartGolgesi(context),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statu blok adiyla ayni satirda: alt satirda kisi
                  // adiyla oncelik rozeti arasinda sikisiyordu.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${task.typeLabel} - ${task.projectName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: c.accent,
                          ),
                        ),
                      ),
                      if (showStatus) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: c.inset,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: c.border2),
                          ),
                          child: Text(
                            task.statusLabel,
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: c.sub,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 7),
                  // Uzun metin kartta tasmiyor; iki satirdan sonra
                  // "Daha Fazla Göster" ile aciliyor.
                  GenisleyenMetin(
                    metin: task.notes.isNotEmpty ? task.notes : task.title,
                    satir: 2,
                    bicim: TextStyle(
                      fontFamily: kDisplay,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(LucideIcons.user, size: 17, color: c.muted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          // Ust kosedeki kullanici kutusuyla ayni kural:
                          // ayni kisi her yerde ayni yaziliyor.
                          kisaKisiAdi(context, task.assignedToName, enBoy: 150),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 14,
                            color: c.sub,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 88),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badge,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          task.priorityLabel,
                          style: TextStyle(
                            fontFamily: kBody,
                            color: badgeText,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 26, color: c.muted),
          ],
        ),
      ),
    );
  }
}
