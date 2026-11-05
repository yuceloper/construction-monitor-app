import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../../notifications/services/notification_service.dart';
import '../../process_tracking/models/project_progress_summary.dart';
import '../../process_tracking/services/progress_service.dart';
import '../../site_selection/services/site_service.dart';
import '../models/report_models.dart';

/// Rapor servisi.
///
/// Sunucuda hazir bir rapor ucu yok. Blok listesi tek cagriyla
/// /projects'ten geliyor, her blogun plan karsilastirmasi surec takibin
/// kullandigi /progress/project/{id}/summary ucundan okunuyor; gecikme
/// boylece iki ekranda ayni cikiyor. Santiyenin genel bitis tarihi
/// /sites'ten, "Son Güncellemeler" ise bildirimlerden besleniyor.
/// Govde utf8.decode(bodyBytes) ile okunuyor: sunucu Content-Type'ta
/// charset bildirmiyor, http paketi boyle durumda latin1 varsayiyor.
class ReportService {
  ReportService({
    NotificationService? notificationService,
    SiteService? siteService,
    ProgressService? progressService,
  }) : _notificationService = notificationService ?? NotificationService(),
       _siteService = siteService ?? SiteService(),
       _progressService = progressService ?? ProgressService();

  final NotificationService _notificationService;
  final SiteService _siteService;
  final ProgressService _progressService;

  Future<ReportData> getReport() async {
    final token = _token();
    final siteId = _siteId();

    final hamBloklar = await _hamBloklariGetir(token, siteId);
    final ozetler = await _ozetleriGetir(hamBloklar);
    final gruplar = _grupla(_bloklariKur(hamBloklar, ozetler));

    return ReportData(
      siteName: SessionManager.instance.selectedSiteName ?? '',
      sitePlannedEnd: await _santiyeBitisi(siteId),
      groups: gruplar,
      // Guncellemeler yan bilgi: alinamazsa rapor yine aciliyor.
      updates: await _guncellemeleriGetir(),
    );
  }

  /// Santiyenin genel planlanan bitis tarihi. Rapor basliginda
  /// gosteriliyor; gecikme hesabinda kullanilmiyor, onu sunucu yapiyor.
  ///
  /// Oturumda saklanan santiye kaydinda bu alan olmayabiliyor (eski
  /// kayitlar), o yuzden listeden taze okunuyor. Alinamazsa rapor yine
  /// aciliyor; ekran tarihin girilmedigini yaziyor.
  Future<DateTime?> _santiyeBitisi(int siteId) async {
    try {
      final santiyeler = await _siteService.getSites();
      for (final s in santiyeler) {
        if (s.id == siteId) return s.plannedEndDate;
      }
    } catch (_) {
      // Santiye listesi alinamadi; tarih bilinmiyor.
    }
    return null;
  }

  /// Blok listesinin ham kayitlari. BlockReport'a cevirmeden once her
  /// blogun ozeti de cekilecegi icin bu adim sadece okuyor.
  Future<List<Map<String, dynamic>>> _hamBloklariGetir(
    String token,
    int siteId,
  ) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/projects',
      ).replace(queryParameters: {'siteId': '$siteId'});
      final response = await http.get(uri, headers: _headers(token));
      final body = utf8.decode(response.bodyBytes);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(body);
        final data = decoded is Map<String, dynamic> ? decoded['data'] : null;
        if (decoded is! Map<String, dynamic> ||
            decoded['success'] != true ||
            data is! List) {
          throw const ReportException('Rapor verisi alınamadı.');
        }

        return data
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
      _throwForResponse(response.statusCode, body);
    } on http.ClientException {
      throw const ReportException(
        'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edip tekrar deneyin.',
      );
    } on FormatException {
      throw const ReportException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
  }

  /// Her blogun plan karsilastirmasi, surec takip ekraninin kullandigi
  /// ucun aynisindan okunuyor: boylece iki ekran ayni blokta ayni
  /// gecikmeyi gosteriyor.
  ///
  /// Sunucu toplu bir uc sunmadigi icin blok basina bir cagri gidiyor;
  /// cagrilar paralel yapiliyor. Tek bir blogun ozeti alinamazsa (yetki
  /// yok, uc hata verdi) o blok plansiz kaliyor ve geciken sayilmiyor;
  /// rapor yine aciliyor.
  Future<Map<int, ProjectProgressSummary>> _ozetleriGetir(
    List<Map<String, dynamic>> hamBloklar,
  ) async {
    final idler = hamBloklar
        .map((b) => (b['id'] as num?)?.toInt() ?? 0)
        .where((id) => id > 0)
        .toList();

    final sonuclar = await Future.wait<MapEntry<int, ProjectProgressSummary>?>(
      idler.map((id) async {
        try {
          return MapEntry(id, await _progressService.getProgressSummary(id));
        } catch (_) {
          return null;
        }
      }),
    );

    return {
      for (final kayit in sonuclar)
        if (kayit != null) kayit.key: kayit.value,
    };
  }

  /// Ham kayitlari ozetleriyle birlestirip rapor bloklarini kuruyor.
  List<BlockReport> _bloklariKur(
    List<Map<String, dynamic>> hamBloklar,
    Map<int, ProjectProgressSummary> ozetler,
  ) {
    return hamBloklar
        .map((item) {
          final ozet = ozetler[(item['id'] as num?)?.toInt() ?? 0];
          final sapma = ozet?.variance;
          return BlockReport.fromJson(
            item,
            beklenen: ozet?.plannedProgress?.round(),
            geride: sapma == null ? null : sapma < 0,
            gerceklesen: ozet?.actualProgress.round(),
          );
        })
        .where((b) => b.id > 0 && b.name.isNotEmpty)
        .toList();
  }

  /// Tipler sabit sirada diziliyor; blogu olmayan tip hic gosterilmiyor.
  List<BlockGroup> _grupla(List<BlockReport> bloklar) {
    const sira = [
      BlockType.house,
      BlockType.shop,
      BlockType.apartment,
      BlockType.other,
    ];

    final gruplar = <BlockGroup>[];
    for (final tip in sira) {
      final liste = bloklar.where((b) => b.type == tip).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      if (liste.isNotEmpty) gruplar.add(BlockGroup(type: tip, blocks: liste));
    }

    // Hic blok yoksa ekranin bos durumunu gosterebilmek icin tek bos
    // grup. Tipi bilinmedigi icin basligi notr: "Bloklar (0)".
    if (gruplar.isEmpty) {
      return const [BlockGroup(type: BlockType.other, blocks: [])];
    }
    return gruplar;
  }

  Future<List<ReportUpdate>> _guncellemeleriGetir() async {
    try {
      // Santiye suzgecini bildirim servisi kendi uyguluyor.
      // Tipe bolunecegi icin genis cekiliyor: 5 kayitta tek bir tipe
      // hic guncelleme dusmeyebiliyordu.
      final sayfa = await _notificationService.getNotificationPage(
        sayfa: 0,
        adet: 30,
      );
      return sayfa.kayitlar
          .map(
            (b) => ReportUpdate(
              title: b.title,
              detail: b.message,
              blockId: b.projectId,
              blockName: b.projectName,
              date: b.createdAt,
            ),
          )
          .toList();
    } catch (_) {
      // Bildirim ucu calismazsa rapor yine aciliyor, kart bos kaliyor.
      return const [];
    }
  }

  String _token() {
    final token = SessionManager.instance.accessToken;
    if (token == null || token.isEmpty) {
      throw const ReportException(
        'Oturum bulunamadı. Lütfen tekrar giriş yapın.',
      );
    }
    return token;
  }

  int _siteId() {
    final siteId = SessionManager.instance.selectedSiteId;
    if (siteId == null || siteId <= 0) {
      throw const ReportException('Şantiye seçimi bulunamadı.');
    }
    return siteId;
  }

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/json',
  };

  Never _throwForResponse(int statusCode, String body) {
    if (statusCode == 401) {
      throw const ReportException(
        'Oturum süresi dolmuş olabilir. Lütfen tekrar giriş yapın.',
      );
    }
    if (statusCode == 403) {
      throw const ReportException(
        'Teknik bir hata bulunuyor. Lütfen daha sonra tekrar deneyiniz.',
      );
    }
    String? mesaj;
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        mesaj = decoded['message']?.toString();
      }
    } catch (_) {
      // Sunucu okunabilir mesaj dondurmediyse asagidaki metin kullaniliyor.
    }
    throw ReportException(
      mesaj != null && mesaj.trim().isNotEmpty
          ? mesaj.trim()
          : 'Rapor alınamadı. Lütfen daha sonra tekrar deneyiniz.',
    );
  }
}

class ReportException implements Exception {
  final String message;

  const ReportException(this.message);

  @override
  String toString() => message;
}
