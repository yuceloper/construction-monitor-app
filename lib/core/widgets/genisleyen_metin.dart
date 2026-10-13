import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../app/theme.dart';
import 'pressable.dart';

/// Belli bir satir sayisindan uzun metni kisaltan, dokununca acilan metin.
///
/// Sadece kisaltma yapmak yetmiyor: uc nokta tek basina "devami var ve
/// dokununca acilir" demiyor, kullanici gorup gecip gidiyor. Bu yuzden
/// metin gercekten tasiyorsa altinda "Devamini oku" baglantisi duruyor.
///
/// Tasma, yazinin kendi render nesnesinden okunuyor. LayoutBuilder ile
/// olcmek daha kisa olurdu ama IntrinsicHeight icinde calismiyor; uyari
/// karti oyle bir kutunun icinde ve sayfanin tamami bos kaliyordu.
class GenisleyenMetin extends StatefulWidget {
  const GenisleyenMetin({
    super.key,
    required this.metin,
    required this.bicim,
    this.satir = 3,
  });

  final String metin;
  final TextStyle bicim;

  /// Kapaliyken gosterilecek en fazla satir sayisi.
  final int satir;

  @override
  State<GenisleyenMetin> createState() => _GenisleyenMetinState();
}

class _GenisleyenMetinState extends State<GenisleyenMetin> {
  final GlobalKey _yaziAnahtari = GlobalKey();
  bool _acik = false;
  bool _tasiyor = false;

  @override
  void didUpdateWidget(GenisleyenMetin oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.metin != widget.metin) _acik = false;
  }

  /// Yazi yerlestikten sonra gercekten tasip tasmadigina bakiyor.
  /// Metin acikken olculmuyor: o halde satir siniri yok, her seferinde
  /// "tasmiyor" cikar ve kapatma baglantisi kaybolurdu.
  void _tasmayiOlc() {
    if (_acik) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final nesne = _yaziAnahtari.currentContext?.findRenderObject();
      if (nesne is! RenderParagraph) return;
      if (nesne.didExceedMaxLines != _tasiyor) {
        setState(() => _tasiyor = nesne.didExceedMaxLines);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    _tasmayiOlc();
    return Pressable(
      onTap: _tasiyor ? () => setState(() => _acik = !_acik) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.metin,
            key: _yaziAnahtari,
            maxLines: _acik ? null : widget.satir,
            overflow: _acik ? TextOverflow.visible : TextOverflow.ellipsis,
            style: widget.bicim,
          ),
          if (_tasiyor) ...[
            const SizedBox(height: 4),
            Text(
              _acik ? 'Daha az göster' : 'Devamını oku',
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: c.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
