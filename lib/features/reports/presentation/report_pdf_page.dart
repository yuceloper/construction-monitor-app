import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/pressable.dart';

/// Rapor PDF'inin onizlemesi.
///
/// Dosya once burada gorunuyor, paylasma ikinci adim: kullanici neyi
/// gonderdigini gormeden gondermek zorunda kalmiyor.
///
/// Belge bellekte duruyor ve disari yazilmiyor; ISG belgelerinden farkli
/// olarak gecici dosya kullanilmadigi icin web'de de ayni sekilde
/// calisiyor.
class ReportPdfPage extends StatefulWidget {
  const ReportPdfPage({
    super.key,
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;

  @override
  State<ReportPdfPage> createState() => _ReportPdfPageState();
}

class _ReportPdfPageState extends State<ReportPdfPage> {
  bool _paylasiliyor = false;

  Future<void> _paylas(BuildContext anchorContext) async {
    if (_paylasiliyor) return;
    setState(() => _paylasiliyor = true);
    try {
      // Mail ile gonderildiginde konu satirinda once uygulamanin adi
      // duruyor: gelen kutusunda belgenin nereden geldigi anlasiliyor.
      const konu = 'SAHADA Süreç Takip Raporu';
      final renderBox = anchorContext.findRenderObject() as RenderBox?;

      await SharePlus.instance.share(
        ShareParams(
          title: konu,
          subject: konu,
          text: konu,
          files: [
            XFile.fromData(widget.bytes, mimeType: 'application/pdf'),
          ],
          fileNameOverrides: [widget.fileName],
          downloadFallbackEnabled: true,
          sharePositionOrigin: renderBox == null
              ? null
              : renderBox.localToGlobal(Offset.zero) & renderBox.size,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rapor paylaşılamadı.')),
      );
    } finally {
      if (mounted) setState(() => _paylasiliyor = false);
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
              title: 'Rapor PDF',
              onBack: () => Navigator.of(context).pop(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: c.border),
                    boxShadow: kartGolgesi(context),
                  ),
                  child: PdfViewer.data(
                    widget.bytes,
                    sourceName: widget.fileName,
                    params: PdfViewerParams(
                      backgroundColor: c.surface,
                      margin: 0,
                      pageDropShadow: const BoxShadow(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Paylas sayfanin birincil eylemi: altta, tam genislikte ve
            // diger ekranlardaki birincil dugmelerle ayni agirlikta.
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                0,
                16,
                12 + MediaQuery.paddingOf(context).bottom,
              ),
              child: Builder(
                builder: (buttonContext) => Pressable(
                  onTap: _paylasiliyor ? null : () => _paylas(buttonContext),
                  child: Opacity(
                    opacity: _paylasiliyor ? .55 : 1,
                    child: Container(
                      height: Sizes.tapTarget,
                      width: double.infinity,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.ink,
                        borderRadius: BorderRadius.circular(Sizes.rBtn),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(LucideIcons.share2, size: 17, color: c.bg),
                          const SizedBox(width: 9),
                          Text(
                            'Paylaş',
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: .2,
                              color: c.bg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
