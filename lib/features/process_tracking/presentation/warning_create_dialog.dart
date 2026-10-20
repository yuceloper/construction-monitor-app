import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/sesli_not_oynatici.dart';

class WarningDraft {
  final String text;
  final String? audioPath;

  const WarningDraft({required this.text, this.audioPath});
}

Future<WarningDraft?> showWarningCreateDialog(BuildContext context) {
  return showDialog<WarningDraft>(
    context: context,
    builder: (_) => const _UyariEklePenceresi(),
  );
}

/// Uyari ekleme penceresi.
///
/// Sesli not bolumu gunluk is eklemedekiyle ayni: kayit surerken
/// duraklatilip surdurulebiliyor, gecen sure yaziyor, kayit bitince
/// dinleme kutusuna donuyor.
class _UyariEklePenceresi extends StatefulWidget {
  const _UyariEklePenceresi();

  @override
  State<_UyariEklePenceresi> createState() => _UyariEklePenceresiState();
}

class _UyariEklePenceresiState extends State<_UyariEklePenceresi> {
  final _kayitci = AudioRecorder();
  final _oynatici = AudioPlayer();
  final _metin = TextEditingController();

  /// Sesli not en fazla bir dakika; sure dolunca kayit kendi kendine
  /// duruyor.
  static const _kayitSiniri = Duration(minutes: 1);

  bool _kaydediyor = false;
  bool _duraklatildi = false;
  bool _calmakta = false;
  Timer? _sayac;
  int _gecenSaniye = 0;
  Duration _calmaKonumu = Duration.zero;
  String? _sesYolu;
  String? _uyari;

  @override
  void initState() {
    super.initState();
    _oynatici.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _calmakta = false;
        _calmaKonumu = Duration.zero;
      });
    });
    _oynatici.onPositionChanged.listen((konum) {
      if (mounted) setState(() => _calmaKonumu = konum);
    });
  }

  @override
  void dispose() {
    _sayac?.cancel();
    _kayitci.dispose();
    _oynatici.dispose();
    _metin.dispose();
    super.dispose();
  }

  String get _kayitSuresi {
    final dakika = _gecenSaniye ~/ 60;
    final saniye = (_gecenSaniye % 60).toString().padLeft(2, '0');
    return '$dakika:$saniye';
  }

  String get _calmaSuresi {
    final dakika = _calmaKonumu.inMinutes;
    final saniye = (_calmaKonumu.inSeconds % 60).toString().padLeft(2, '0');
    return '$dakika:$saniye';
  }

  Future<void> _kaydaBasla() async {
    try {
      if (!await _kayitci.hasPermission()) {
        setState(() => _uyari = 'Sesli not için mikrofon izni gerekli.');
        return;
      }
      final klasor = await getTemporaryDirectory();
      final yol =
          '${klasor.path}/warning-${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _kayitci.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: yol,
      );
      if (!mounted) return;
      setState(() {
        _kaydediyor = true;
        _duraklatildi = false;
        _gecenSaniye = 0;
        _sesYolu = null;
        _uyari = null;
      });
      _sayac?.cancel();
      // Sure kendi sayacimizdan ilerliyor: duraklatilan saniyeler
      // kayda girmiyor.
      _sayac = Timer.periodic(const Duration(seconds: 1), (vurus) {
        if (!mounted || !_kaydediyor) {
          vurus.cancel();
          return;
        }
        if (_duraklatildi) return;
        setState(() => _gecenSaniye += 1);
        if (_gecenSaniye >= _kayitSiniri.inSeconds) _kaydiBitir();
      });
    } catch (_) {
      if (mounted) setState(() => _uyari = 'Ses kaydı başlatılamadı.');
    }
  }

  Future<void> _duraklatVeyaDevam() async {
    if (!_kaydediyor) return;
    try {
      if (_duraklatildi) {
        await _kayitci.resume();
        if (mounted) setState(() => _duraklatildi = false);
        return;
      }
      await _kayitci.pause();
      if (mounted) setState(() => _duraklatildi = true);
    } catch (_) {
      if (mounted) setState(() => _uyari = 'Kayıt duraklatılamadı.');
    }
  }

  Future<void> _kaydiBitir() async {
    _sayac?.cancel();
    _sayac = null;
    final yol = await _kayitci.stop();
    if (!mounted) return;
    setState(() {
      _kaydediyor = false;
      _duraklatildi = false;
      _gecenSaniye = 0;
      if (yol != null) _sesYolu = yol;
    });
  }

  /// Kaydi dinletir; ikinci dokunusta duraklatir.
  Future<void> _sesiCal() async {
    final yol = _sesYolu;
    if (yol == null) return;
    try {
      if (_calmakta) {
        await _oynatici.pause();
        if (mounted) setState(() => _calmakta = false);
        return;
      }
      if (_oynatici.state == PlayerState.paused) {
        await _oynatici.resume();
      } else {
        await _oynatici.play(DeviceFileSource(yol));
      }
      if (mounted) setState(() => _calmakta = true);
    } catch (_) {
      if (mounted) setState(() => _uyari = 'Sesli not oynatılamadı.');
    }
  }

  Future<void> _sesiSil() async {
    await _oynatici.stop();
    if (!mounted) return;
    setState(() {
      _sesYolu = null;
      _calmakta = false;
      _calmaKonumu = Duration.zero;
    });
  }

  InputDecoration _alan(AppColors c) {
    OutlineInputBorder cerceve(Color renk, [double kalinlik = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: renk, width: kalinlik),
        );
    return InputDecoration(
      hintText: 'Lütfen detay giriniz.',
      hintStyle: TextStyle(fontFamily: kBody, fontSize: 15.5, color: c.faint),
      counterStyle: TextStyle(fontFamily: kBody, fontSize: 12, color: c.muted),
      isDense: true,
      filled: true,
      fillColor: c.surface2,
      contentPadding: const EdgeInsets.fromLTRB(16, 15, 22, 15),
      border: cerceve(c.border2),
      enabledBorder: cerceve(c.border2),
      disabledBorder: cerceve(c.border),
      focusedBorder: cerceve(c.accent, 1.8),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AlertDialog(
      title: const Text('Uyarı Ekle'),
      scrollable: true,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _metin,
              autofocus: true,
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              inputFormatters: [LengthLimitingTextInputFormatter(500)],
              onChanged: (_) {
                if (_uyari != null) setState(() => _uyari = null);
              },
              style: TextStyle(fontFamily: kBody, fontSize: 15.5, color: c.ink),
              cursorColor: c.accent,
              decoration: _alan(c),
            ),
            const SizedBox(height: 10),
            if (_sesYolu != null && !_kaydediyor)
              SesliNotOynatici(
                oynuyor: _calmakta,
                yukleniyor: false,
                sure: _calmakta ? _calmaSuresi : null,
                onCal: _sesiCal,
                onSil: _sesiSil,
              )
            else if (_kaydediyor)
              // Kayit surerken: soldaki duraklatip surduruyor, sagdaki
              // kaydi bitiriyor.
              Row(
                children: [
                  Expanded(
                    child: Pressable(
                      onTap: _duraklatVeyaDevam,
                      child: Container(
                        height: 52,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c.surface2,
                          borderRadius: BorderRadius.circular(Sizes.rField),
                          border: Border.all(color: c.border2, width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _duraklatildi
                                  ? LucideIcons.play
                                  : LucideIcons.pause,
                              size: 19,
                              color: c.accent,
                            ),
                            const SizedBox(width: 9),
                            Text(
                              _duraklatildi
                                  ? 'Devam Et  $_kayitSuresi'
                                  : 'Duraklat  $_kayitSuresi',
                              style: TextStyle(
                                fontFamily: kBody,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w600,
                                color: c.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Pressable(
                    onTap: _kaydiBitir,
                    child: Container(
                      height: 52,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.ink,
                        borderRadius: BorderRadius.circular(Sizes.rField),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.square, size: 17, color: c.surface),
                          const SizedBox(width: 8),
                          Text(
                            'Bitir',
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: c.surface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            else
              Pressable(
                onTap: _kaydaBasla,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surface2,
                    borderRadius: BorderRadius.circular(Sizes.rField),
                    border: Border.all(color: c.border2, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.mic, size: 19, color: c.accent),
                      const SizedBox(width: 9),
                      Text(
                        'Sesli Not Kaydet',
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: c.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_uyari != null) ...[
              const SizedBox(height: 10),
              Text(
                _uyari!,
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.bad,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_kaydediyor) await _kayitci.stop();
            if (mounted) Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () async {
            final deger = _metin.text.trim();
            if (deger.isEmpty) {
              setState(() => _uyari = 'Uyarı detayı zorunludur.');
              return;
            }
            if (_kaydediyor) await _kaydiBitir();
            if (!mounted) return;
            Navigator.of(
              context,
            ).pop(WarningDraft(text: deger, audioPath: _sesYolu));
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
