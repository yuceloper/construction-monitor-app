import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/secim_paneli.dart';
import '../../../core/widgets/state_views.dart';
import '../models/safety_document_summary.dart';
import '../services/safety_document_service.dart';

class SafetyPdfPage extends StatefulWidget {
  final int documentId;
  final String title;

  const SafetyPdfPage({
    super.key,
    required this.documentId,
    required this.title,
  });

  @override
  State<SafetyPdfPage> createState() => _SafetyPdfPageState();
}

class _SafetyPdfPageState extends State<SafetyPdfPage> {
  final _service = SafetyDocumentService();

  Uint8List? _pdfBytes;
  String? _errorMessage;
  List<SafetyDocumentSummary> _monthlyDocuments = const [];
  int? _selectedDocumentId;
  bool _isMonthlyReport = false;

  @override
  void initState() {
    super.initState();
    _selectedDocumentId = widget.documentId;
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() {
      _pdfBytes = null;
      _errorMessage = null;
    });

    try {
      final documents = await _service.getDocuments();
      final current = documents
          .where((document) => document.id == widget.documentId)
          .firstOrNull;
      final isMonthly = current?.documentType == 'MONTHLY_SITE_REPORT';

      final monthlyByKey = <String, SafetyDocumentSummary>{};
      if (isMonthly) {
        final monthly =
            documents
                .where(
                  (document) =>
                      document.documentType == 'MONTHLY_SITE_REPORT' &&
                      document.documentDate != null,
                )
                .toList()
              ..sort((a, b) => b.documentDate!.compareTo(a.documentDate!));

        for (final document in monthly) {
          final date = document.documentDate!;
          final key = '${date.year}-${date.month}';
          monthlyByKey.putIfAbsent(key, () => document);
        }
      }

      if (!mounted) return;
      setState(() {
        _isMonthlyReport = isMonthly;
        _monthlyDocuments = monthlyByKey.values.toList();
        if (_isMonthlyReport &&
            !_monthlyDocuments.any(
              (document) => document.id == _selectedDocumentId,
            ) &&
            _monthlyDocuments.isNotEmpty) {
          _selectedDocumentId = _monthlyDocuments.first.id;
        }
      });

      await _loadPdf(_selectedDocumentId ?? widget.documentId);
    } on SafetyDocumentException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted)
        setState(
          () => _errorMessage =
              'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
        );
    }
  }

  Future<void> _loadPdf(int documentId) async {
    setState(() {
      _selectedDocumentId = documentId;
      _pdfBytes = null;
      _errorMessage = null;
    });

    try {
      final bytes = await _service.getPdfBytes(documentId);
      if (!mounted) return;
      setState(() => _pdfBytes = bytes);
    } on SafetyDocumentException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted)
        setState(
          () => _errorMessage =
              'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
        );
    }
  }

  String _monthLabel(SafetyDocumentSummary document) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final date = document.documentDate!;
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Secili belgenin ay adi; yoksa bos.
  String get _seciliAyAdi {
    for (final document in _monthlyDocuments) {
      if (document.id == _selectedDocumentId) return _monthLabel(document);
    }
    return '';
  }

  Future<void> _ayPaneliniAc() async {
    final secim = await secimPaneliAc<int>(
      context,
      baslik: 'Ay seçiniz',
      secenekler: [
        for (final document in _monthlyDocuments)
          SecimSecenegi(document.id, _monthLabel(document)),
      ],
      secili: _selectedDocumentId,
    );
    if (secim != null && mounted && secim != _selectedDocumentId) {
      _loadPdf(secim);
    }
  }

  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Butun alt ekranlarla ayni serit: marka + breadcrumb.
            // Bu ekran kendi basligini ciziyordu, uygulamadan kopuktu.
            const AppHeader(),
            BreadcrumbBar(
              title: widget.title,
              parent: 'İSG Takip',
              onBack: () => context.pop(),
              onParentTap: () => context.pop(),
            ),
            if (_isMonthlyReport && _monthlyDocuments.isNotEmpty)
              // Ustundeki "Ay seciniz" etiketi kaldirildi; alanin
              // icinde zaten secili ay yaziyor.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SeciciAlan(metin: _seciliAyAdi, onTap: _ayPaneliniAc),
              ),
            // Belge, secim alaninin hemen altina kenardan kenara biniyordu.
            // Artik kendi panelinde duruyor: ustte ince ayrac, icerde cukur
            // zemin; sayfa bu zeminin uzerinde ayri bir kagit gibi.
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.inset,
                  border: Border(top: BorderSide(color: c.border)),
                ),
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Paylasilan dosyanin adi.
  ///
  /// Turkce harfler once ASCII karsiligina cevriliyor: dogrudan
  /// temizlenince "Aylik" yerine "Aylk" gibi eksik bir ad cikiyordu.
  static String _dosyaAdi(String baslik) {
    const karsilik = {
      'ç': 'c', 'Ç': 'C', 'ğ': 'g', 'Ğ': 'G', 'ı': 'i', 'İ': 'I',
      'ö': 'o', 'Ö': 'O', 'ş': 's', 'Ş': 'S', 'ü': 'u', 'Ü': 'U',
    };
    final tampon = StringBuffer();
    for (final harf in baslik.split('')) {
      tampon.write(karsilik[harf] ?? harf);
    }
    final temiz = tampon
        .toString()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return '${temiz.isEmpty ? 'belge' : temiz}.pdf';
  }

  /// Belgeyi paylasir: dosyanin kendisi gider, cihazin paylas menusu
  /// WhatsApp, e-posta ve digerlerini listeler.
  Future<void> _paylas(Uint8List bytes) async {
    try {
      final klasor = await getTemporaryDirectory();
      final dosya = File('${klasor.path}/${_dosyaAdi(widget.title)}');
      await dosya.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(dosya.path, mimeType: 'application/pdf')],
          subject: widget.title,
          text: widget.title,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Belge paylaşılamadı.')));
    }
  }

  /// Belgeyi tam ekran acar. Onizleme cercevesinde A4 bir sayfanin
  /// yazisi okunmuyordu; burada ekranin tamami belgenin ve parmakla
  /// yakinlastirilabiliyor.
  Future<void> _tamEkranAc(Uint8List bytes) async {
    await showGeneralDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierLabel: 'Belge',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (sayfaContext, animasyon, ikinci) => _TamEkranBelge(
        bytes: bytes,
        baslik: widget.title,
        kaynakAdi:
            'safety_document_${_selectedDocumentId ?? widget.documentId}.pdf',
      ),
      transitionBuilder: (context, animasyon, _, cocuk) {
        final egri = CurvedAnimation(
          parent: animasyon,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: egri,
          child: ScaleTransition(
            scale: Tween<double>(begin: .97, end: 1).animate(egri),
            child: cocuk,
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    final c = context.colors;

    if (_errorMessage != null) {
      // Diger ekranlardaki hata gorunumuyle ayni.
      return ErrorView(
        message: _errorMessage!,
        onRetry: () => _loadPdf(_selectedDocumentId ?? widget.documentId),
      );
    }

    final bytes = _pdfBytes;

    // Belge hazir olunca birden belirip goz yoruyordu; iskelet sayfa ile
    // ayni cercevede duruyor ve yerini yumusak bir gecisle biraktiriyor.
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: bytes == null
          ? const _BelgeIskeleti(key: ValueKey('iskelet'))
          : Padding(
              key: ValueKey(
                'belge-${_selectedDocumentId ?? widget.documentId}',
              ),
              padding: const EdgeInsets.all(14),
              // pdfrx'in kendi margin'i sayfayla birlikte olceklendigi icin
              // gorunmuyordu; cerceve disaridan kuruluyor. Belge boylece
              // cukur zeminin uzerinde kendi kagidinda duruyor.
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.border),
                        boxShadow: kartGolgesi(context),
                      ),
                      child: PdfViewer.data(
                        bytes,
                        sourceName:
                            'safety_document_${_selectedDocumentId ?? widget.documentId}.pdf',
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
                  // Onizleme cercevesinde A4 sayfa kucuk kaliyor; bu
                  // dugme belgeyi tam ekran aciyor.
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Row(
                      children: [
                        Pressable(
                          onTap: () => _paylas(bytes),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
                            decoration: BoxDecoration(
                              color: c.ink.withValues(alpha: .88),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.share2,
                                  size: 15,
                                  color: c.surface,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Paylaş',
                                  style: TextStyle(
                                    fontFamily: kBody,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: c.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Pressable(
                          onTap: () => _tamEkranAc(bytes),
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 9, 14, 9),
                            decoration: BoxDecoration(
                              color: c.ink.withValues(alpha: .88),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.expand,
                                  size: 15,
                                  color: c.surface,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Tam Ekran',
                                  style: TextStyle(
                                    fontFamily: kBody,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: c.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Belge yuklenirken gosterilen bos sayfa. Gercek sayfayla ayni yerde,
/// ayni olcude duruyor; icerik gelince sadece ustune yazilmis gibi oluyor.
class _BelgeIskeleti extends StatefulWidget {
  const _BelgeIskeleti({super.key});

  @override
  State<_BelgeIskeleti> createState() => _BelgeIskeletiState();
}

class _BelgeIskeletiState extends State<_BelgeIskeleti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nabiz = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _nabiz.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: SizedBox.expand(
        child: Container(
          padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.border),
            boxShadow: kartGolgesi(context),
          ),
          child: FadeTransition(
            opacity: Tween<double>(begin: .45, end: .9).animate(_nabiz),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cizgi(c.inset, 160, 14),
                const SizedBox(height: 18),
                for (var i = 0; i < 7; i++) ...[
                  _cizgi(c.inset, double.infinity, 9),
                  const SizedBox(height: 11),
                ],
                _cizgi(c.inset, 190, 9),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cizgi(Color renk, double en, double boy) => Container(
    width: en,
    height: boy,
    decoration: BoxDecoration(
      color: renk,
      borderRadius: BorderRadius.circular(boy / 2),
    ),
  );
}

extension _FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Belgenin tam ekran hali: koyu zemin, ustte kapatma ve belge adi.
class _TamEkranBelge extends StatelessWidget {
  const _TamEkranBelge({
    required this.bytes,
    required this.baslik,
    required this.kaynakAdi,
  });

  final Uint8List bytes;
  final String baslik;
  final String kaynakAdi;

  @override
  Widget build(BuildContext context) {
    const zemin = Color(0xFF0E141C);
    // Uygulama genelinde durum cubugu simgeleri koyu; bu ekranin zemini
    // koyu oldugu icin saat ve sinyal gorunmuyordu.
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
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        baslik,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: kDisplay,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -.2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PdfViewer.data(
                  bytes,
                  sourceName: kaynakAdi,
                  params: const PdfViewerParams(
                    backgroundColor: zemin,
                    margin: 10,
                    pageDropShadow: BoxShadow(
                      color: Colors.black54,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
