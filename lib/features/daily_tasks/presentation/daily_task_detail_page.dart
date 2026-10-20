import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/secim_paneli.dart';
import '../../../core/widgets/kisa_ad.dart';
import '../../../core/widgets/sesli_not_oynatici.dart';
import '../models/daily_task_summary.dart';
import '../services/daily_task_service.dart';

class DailyTaskDetailPage extends StatefulWidget {
  final int taskId;

  const DailyTaskDetailPage({super.key, required this.taskId});

  @override
  State<DailyTaskDetailPage> createState() => _DailyTaskDetailPageState();
}

class _DailyTaskDetailPageState extends State<DailyTaskDetailPage> {
  final _service = DailyTaskService();
  final _noteController = TextEditingController();
  final _audioPlayer = AudioPlayer();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAudioLoading = false;
  bool _isAudioPlaying = false;

  /// Sesli notun calma konumu ve toplam suresi. Bir kez oynatildiktan
  /// sonra duraklatilsa da ekranda kaliyor; sure yalnizca calarken
  /// gorunup kaybolmuyor.
  Duration _calmaKonumu = Duration.zero;
  Duration? _toplamSure;
  String? _audioPath;
  String? _errorMessage;
  DailyTaskSummary? _task;
  String _status = 'IN_PROGRESS';

  /// Ekran acildigindaki hali. Guncelle dugmesi ancak bunlardan biri
  /// degisince calisiyor.
  String _ilkDurum = '';
  String _ilkNot = '';

  @override
  void initState() {
    super.initState();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isAudioPlaying = false;
        _calmaKonumu = Duration.zero;
      });
    });
    _audioPlayer.onPositionChanged.listen((konum) {
      if (mounted) setState(() => _calmaKonumu = konum);
    });
    _audioPlayer.onDurationChanged.listen((sure) {
      if (mounted) setState(() => _toplamSure = sure);
    });
    _load();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final task = await _service.getTask(widget.taskId);
      if (!mounted) return;
      setState(() {
        _task = task;
        _noteController.text = task.notes.isNotEmpty ? task.notes : task.title;
        _status =
            const {'TODO', 'IN_PROGRESS', 'COMPLETED'}.contains(task.status)
            ? task.status
            : 'TODO';
        _ilkNot = _noteController.text.trim();
        _ilkDurum = _status;
      });
    } on DailyTaskException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Fotografi tam ekran acar; parmakla yakinlastirilabiliyor ve
  /// birden fazla fotograf varsa yana kaydirilabiliyor.
  Future<void> _fotografiAc(List<int> fotograflar, int baslangic) async {
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'Fotoğraf',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (sayfaContext, animasyon, ikinci) => _FotografOnizleme(
        fotograflar: fotograflar,
        baslangic: baslangic,
        adres: _service.photoUrl,
        basliklar: _service.photoHeaders(),
      ),
      transitionBuilder: (context, animasyon, ikinci, cocuk) {
        final egri = CurvedAnimation(parent: animasyon, curve: Curves.easeOut);
        return FadeTransition(opacity: egri, child: cocuk);
      },
    );
  }

  /// Oynaticinin yanindaki sure, "0:05 / 0:12" bicinde. Toplam sure
  /// dosya acilmadan bilinmiyor; o ana kadar yalnizca gecen sure
  /// yaziliyor.
  String? get _sesSuresi {
    if (_toplamSure == null && !_isAudioPlaying) return null;
    final gecen = _sureMetni(_calmaKonumu);
    final toplam = _toplamSure;
    if (toplam == null || toplam.inSeconds == 0) return gecen;
    return '$gecen / ${_sureMetni(toplam)}';
  }

  String _sureMetni(Duration sure) {
    final dakika = sure.inMinutes;
    final saniye = (sure.inSeconds % 60).toString().padLeft(2, '0');
    return '$dakika:$saniye';
  }

  Future<void> _toggleAudio() async {
    final audioId = _task?.audioNoteId;
    if (audioId == null || _isAudioLoading) return;

    try {
      if (_isAudioPlaying) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isAudioPlaying = false);
        return;
      }

      if (_audioPath == null) {
        setState(() => _isAudioLoading = true);
        _audioPath = await _service.downloadAudioNote(audioId);
      }

      if (_audioPlayer.state == PlayerState.paused) {
        await _audioPlayer.resume();
      } else {
        // Tarayicida dosya sistemi yok; servis sesi data adresi olarak
        // donuyor, oynatici onu URL gibi aliyor.
        final kaynak = _audioPath!.startsWith('data:')
            ? UrlSource(_audioPath!)
            : DeviceFileSource(_audioPath!);
        await _audioPlayer.play(kaynak);
      }
      if (mounted) setState(() => _isAudioPlaying = true);
    } on DailyTaskException catch (error) {
      if (mounted) _show(error.message);
    } catch (_) {
      if (mounted) _show('Sesli not oynatılamadı.');
    } finally {
      if (mounted) setState(() => _isAudioLoading = false);
    }
  }

  /// Ekran acildigindan beri bir sey degisti mi?
  bool get _degisiklikVar =>
      _status != _ilkDurum || _noteController.text.trim() != _ilkNot;

  Future<void> _save() async {
    if (_isSaving) return;
    final note = _noteController.text.trim();
    if (note.isEmpty) {
      _show('Not alanı zorunludur.');
      return;
    }
    if (!_degisiklikVar) {
      _show('Herhangi bir değişiklik yapılmadı.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final task = await _service.updateTask(
        taskId: widget.taskId,
        status: _status,
        note: note,
      );
      if (!mounted) return;
      setState(() {
        _task = task;
        _ilkNot = note;
        _ilkDurum = _status;
      });
      _show('Günlük iş güncellendi.');
      // Guncellemeden sonra listeye donuluyor ki yapilan degisiklik
      // listede goruneblisin.
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      context.pop(true);
    } on DailyTaskException catch (error) {
      if (mounted) _show(error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _show(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  /// Durum kodunun ekranda gorunen adi.
  String _durumAdi(String kod) {
    switch (kod) {
      case 'TODO':
        return 'Başlanacak';
      case 'IN_PROGRESS':
        return 'Devam Ediyor';
      case 'COMPLETED':
        return 'Tamamlandı';
      default:
        return '';
    }
  }

  Future<void> _durumSec() async {
    final secim = await secimPaneliAc<String>(
      context,
      baslik: 'Durum',
      secenekler: const [
        SecimSecenegi('TODO', 'Başlanacak'),
        SecimSecenegi('IN_PROGRESS', 'Devam Ediyor'),
        SecimSecenegi('COMPLETED', 'Tamamlandı'),
      ],
      secili: _status,
    );
    if (secim != null && mounted) setState(() => _status = secim);
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
            BreadcrumbBar(
              parent: 'Günlük İşler',
              title: 'İş Detayı',
              onBack: () => context.pop(true),
              onParentTap: () => context.pop(true),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final c = context.colors;

    if (_isLoading && _task == null) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: c.ink),
        ),
      );
    }
    if (_errorMessage != null && _task == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 16),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: _load,
              ),
            ],
          ),
        ),
      );
    }

    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );

    final task = _task!;
    return RefreshIndicator(
      color: c.ink,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Sizes.rCard),
              border: Border.all(color: c.border),
              boxShadow: kartGolgesi(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Özet',
                  // Panel basliklari uygulamada 19: is detayindaki uc kardes
                  // panel 22, 20 ve 19 ile yaziliyordu.
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.4,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 14),
                _SummaryLine(
                  label: 'Blok',
                  value: '${task.typeLabel} - ${task.projectName}',
                ),
                _SummaryLine(
                  label: 'İlgili Kişi',
                  // Listede ve uyarilarda oldugu gibi: sigmiyorsa
                  // "Muhammed A." Iki satira sarkip "Admin" tek basina
                  // alt satirda kaliyordu.
                  value: kisaKisiAdi(
                    context,
                    task.assignedToName,
                    enBoy: 209,
                    olcu: 15,
                  ),
                ),
                _SummaryLine(label: 'Kritiklik', value: task.priorityLabel),
                _SummaryLine(
                  label: 'Mevcut Durum',
                  value: task.status == 'COMPLETED'
                      ? 'Tamamlandı'
                      : task.status == 'IN_PROGRESS'
                      ? 'Devam Ediyor'
                      : 'Başlanacak',
                ),
              ],
            ),
          ),
          if (task.photoIds.isNotEmpty) ...[
            const SizedBox(height: 14),
            // Bolum artik panelin icinde: ekrandaki diger her bolum
            // beyaz kartin icindeyken fotograflar disarida duruyordu.
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Sizes.rCard),
                border: Border.all(color: c.border),
                boxShadow: kartGolgesi(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fotoğraflar',
                    style: TextStyle(
                      fontFamily: kDisplay,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.3,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 125,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: task.photoIds.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, index) {
                        final id = task.photoIds[index];
                        return Pressable(
                          // Kucuk resme dokununca fotograf tam ekran
                          // aciliyor; daha once dokunulamiyordu.
                          onTap: () => _fotografiAc(task.photoIds, index),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              width: 145,
                              child: Image.network(
                                _service.photoUrl(id),
                                headers: _service.photoHeaders(),
                                fit: BoxFit.cover,
                                errorBuilder: (_, hata, __) {
                                  // Sunucudaki bazi fotograflar bozuk geliyor
                                  // (yarida kesilmis PNG). Bos gri kutu yerine
                                  // ne oldugu yaziyor; kullanici yuklenmesini
                                  // beklemesin.
                                  debugPrint(
                                    'Fotograf yuklenemedi ($id): $hata',
                                  );
                                  return Container(
                                    color: c.inset,
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.imageOff,
                                          size: 22,
                                          color: c.faint,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Görsel açılamadı',
                                          style: TextStyle(
                                            fontFamily: kBody,
                                            fontSize: 12.5,
                                            color: c.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (task.audioNoteId != null) ...[
            const SizedBox(height: 14),
            // Ozet ve Durum/Not kendi kartlarindaydi, bu bolum zeminde
            // duruyordu; ucu de ayni kart olsun diye sarmalandi.
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Sizes.rCard),
                border: Border.all(color: c.border),
                boxShadow: kartGolgesi(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesli Not',
                    style: TextStyle(
                      fontFamily: kDisplay,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.2,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SesliNotOynatici(
                    oynuyor: _isAudioPlaying,
                    yukleniyor: _isAudioLoading,
                    sure: _sesSuresi,
                    onCal: _toggleAudio,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Ozet karttaydi, hemen altindaki alanlar sayfaya serbest
          // oturuyordu. Duzenlenebilir alanlar da kendi kartinda.
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Sizes.rCard),
              border: Border.all(color: c.border),
              boxShadow: kartGolgesi(context),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Durum',
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 9),
                SeciciAlan(
                  metin: _durumAdi(_status),
                  onTap: _isSaving ? null : _durumSec,
                ),
                const SizedBox(height: 20),
                Text(
                  'Not',
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.2,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 9),
                ScrollableField(
                  builder: (scrollController) => TextField(
                    controller: _noteController,
                    scrollController: scrollController,
                    enabled: !_isSaving,
                    // Yazi degisince Guncelle dugmesi canlaniyor.
                    onChanged: (_) => setState(() {}),
                    minLines: 5,
                    maxLines: 8,
                    maxLength: 500,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 16,
                      height: 1.4,
                      color: c.ink,
                    ),
                    cursorColor: c.accent,
                    decoration: InputDecoration(
                      hintText: 'Lütfen detay giriniz.',
                      hintStyle: TextStyle(
                        fontFamily: kBody,
                        fontSize: 16,
                        color: c.faint,
                      ),
                      counterStyle: TextStyle(
                        fontFamily: kBody,
                        fontSize: 12,
                        color: c.muted,
                      ),
                      filled: true,
                      fillColor: c.surface2,
                      // Sagda kaydirma cubuguna yer birakiliyor.
                      contentPadding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
                      border: border(c.border2),
                      enabledBorder: border(c.border2),
                      disabledBorder: border(c.border),
                      focusedBorder: border(c.accent, 1.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          // Degisiklik yokken dugme sonuk; yine de dokunulabiliyor ve
          // neden calismadigini soyleyen bir uyari veriyor.
          Opacity(
            opacity: _degisiklikVar ? 1 : .55,
            child: PrimaryButton(
              label: 'GÜNCELLE',
              busy: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: c.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.35,
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fotograflarin tam ekran hali: koyu zemin, ustte kapatma ve sayac.
class _FotografOnizleme extends StatefulWidget {
  const _FotografOnizleme({
    required this.fotograflar,
    required this.baslangic,
    required this.adres,
    required this.basliklar,
  });

  final List<int> fotograflar;
  final int baslangic;
  final String Function(int) adres;
  final Map<String, String> basliklar;

  @override
  State<_FotografOnizleme> createState() => _FotografOnizlemeState();
}

class _FotografOnizlemeState extends State<_FotografOnizleme> {
  late final PageController _sayfa = PageController(
    initialPage: widget.baslangic,
  );
  late int _sira = widget.baslangic;

  @override
  void dispose() {
    _sayfa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const zemin = Color(0xFF0E141C);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: zemin,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 14, 6),
                child: Row(
                  children: [
                    Pressable(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          LucideIcons.x,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (widget.fotograflar.length > 1)
                      Text(
                        '${_sira + 1} / ${widget.fotograflar.length}',
                        style: const TextStyle(
                          fontFamily: kBody,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _sayfa,
                  itemCount: widget.fotograflar.length,
                  onPageChanged: (i) => setState(() => _sira = i),
                  itemBuilder: (_, index) {
                    return InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: Center(
                        child: Image.network(
                          widget.adres(widget.fotograflar[index]),
                          headers: widget.basliklar,
                          fit: BoxFit.contain,
                          errorBuilder: (hataContext, hata, iz) => const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.imageOff,
                                size: 36,
                                color: Colors.white38,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Görsel açılamadı',
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 14,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
