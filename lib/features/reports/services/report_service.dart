import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/constants/api_config.dart';
import '../../auth/services/session_manager.dart';
import '../../notifications/services/notification_service.dart';
import '../models/report_models.dart';

/// Rapor servisi.
///
/// Sunucuda hazir bir rapor ucu yok. Blok listesi tek cagriyla
/// /projects'ten geliyor (tip, durum, ilerleme ve planlanan bitis tarihi
/// o yanitta var); "Son Güncellemeler" ise bildirimlerden besleniyor.
/// Govde utf8.decode(bodyBytes) ile okunuyor: sunucu Content-Type'ta
/// charset bildirmiyor, http paketi boyle durumda latin1 varsayiyor.
class ReportService {
  ReportService({NotificationService? notificationService})
    : _notificationService = notificationService ?? NotificationService();

  final NotificationService _notificationService;

  Future<ReportData> getReport() async {
    final token = _token();
    final siteId = _siteId();

    final bloklar = await _bloklariGetir(token, siteId);
    final gruplar = _grupla(bloklar);

    return ReportData(
      siteName: SessionManager.instance.selectedSiteName ?? '',
      groups: gruplar,
      // Guncellemeler yan bilgi: alinamazsa rapor yine aciliyor.
      updates: await _guncellemeleriGetir(),
    );
  }

  Future<List<BlockReport>> _bloklariGetir(String token, int siteId) async {
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

        final bugun = DateTime.now();
        return data
            .whereType<Map>()
            .map(
              (item) => BlockReport.fromJson(
                Map<String, dynamic>.from(item),
                bugun: bugun,
              ),
            )
            .where((b) => b.id > 0 && b.name.isNotEmpty)
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
      final sayfa = await _notificationService.getNotificationPage(
        sayfa: 0,
        adet: 5,
      );
      return sayfa.kayitlar
          .map(
            (b) => ReportUpdate(
              title: b.title,
              detail: b.message,
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
