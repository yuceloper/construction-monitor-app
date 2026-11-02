// Rapor ekraninin veri tipleri.
//
// Sunucuda ayri bir rapor ucu yok; veriler /projects ucundan gelen blok
// listesinden türetiliyor. Hesaplar burada toplandi ki ekran sadece
// gostermekle ugrassin.

/// Sunucunun gonderdigi blok tipi: HOUSE / SHOP / APARTMENT.
enum BlockType { house, shop, apartment, other }

extension BlockTypeLabel on BlockType {
  /// Sekme ve liste basliginda gorunen ad.
  String get label => switch (this) {
    BlockType.house => 'Evler',
    BlockType.shop => 'Dükkanlar',
    BlockType.apartment => 'Apartmanlar',
    BlockType.other => 'Bloklar',
  };

  /// Tek bir blogu anlatirken kullanilan ad ("3 Ev" gibi).
  String get singular => switch (this) {
    BlockType.house => 'Ev',
    BlockType.shop => 'Dükkan',
    BlockType.apartment => 'Apartman',
    BlockType.other => 'Blok',
  };

  static BlockType fromApi(String? raw) => switch (raw) {
    'HOUSE' => BlockType.house,
    'SHOP' => BlockType.shop,
    'APARTMENT' => BlockType.apartment,
    _ => BlockType.other,
  };
}

/// Blogun rapordaki durumu. Sunucu COMPLETED gondermedigi icin ilerleme
/// yuzdesi ile santiyenin genel takviminden turetiliyor.
enum BlockState { completed, delayed, inProgress, notStarted }

extension BlockStateLabel on BlockState {
  String get label => switch (this) {
    BlockState.completed => 'Tamamlandı',
    BlockState.delayed => 'Gecikme',
    BlockState.inProgress => 'Devam ediyor',
    BlockState.notStarted => 'Başlanmadı',
  };
}

class BlockReport {
  const BlockReport({
    required this.id,
    required this.name,
    required this.type,
    required this.progress,
    required this.expectedProgress,
    required this.state,
  });

  final int id;
  final String name;
  final BlockType type;

  /// 0-100 arasi, yuvarlanmis ilerleme.
  final int progress;

  /// Takvime gore bugun beklenen ilerleme. Blogun baslangici ya da
  /// santiyenin genel bitis tarihi girilmemisse hesaplanamiyor.
  final int? expectedProgress;

  final BlockState state;

  /// [bugun] disaridan veriliyor: ayni listedeki butun bloklar ayni ani
  /// referans alsin ve test edilebilsin diye.
  factory BlockReport.fromJson(
    Map<String, dynamic> json, {
    required DateTime bugun,
    required DateTime? santiyeBitisi,
  }) {
    final ham = json['overallProgress'];
    final yuzde = ham is num
        ? ham.toDouble()
        : double.tryParse(ham?.toString() ?? '') ?? 0;
    final ilerleme = yuzde.clamp(0, 100).round();

    // Blogun kendi endDate'i okunmuyor: bloklar paralel ilerledigi
    // icin gecikme santiyenin genel takvimine gore hesaplaniyor.
    final baslangic = DateTime.tryParse(json['startDate']?.toString() ?? '');
    final durum = json['status']?.toString();

    final beklenen = _beklenenIlerleme(
      baslangic: baslangic,
      santiyeBitisi: santiyeBitisi,
      bugun: bugun,
    );

    return BlockReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      type: BlockTypeLabel.fromApi(json['projectType']?.toString()),
      progress: ilerleme,
      expectedProgress: beklenen,
      state: _durumHesapla(
        ilerleme: ilerleme,
        beklenen: beklenen,
        sunucuDurumu: durum,
      ),
    );
  }

  /// Takvime gore bugun beklenen ilerleme yuzdesi.
  ///
  /// Surec takip ekranindaki plan-gerceklesen karsilastirmasinin ayni
  /// mantigi: gecen sure, toplam surenin ne kadarini kapsiyorsa
  /// ilerlemenin de o kadar olmasi bekleniyor. Bitis tarihi olarak
  /// blogun kendi tarihi degil santiyenin genel tarihi kullaniliyor.
  static int? _beklenenIlerleme({
    required DateTime? baslangic,
    required DateTime? santiyeBitisi,
    required DateTime bugun,
  }) {
    if (baslangic == null || santiyeBitisi == null) return null;

    DateTime gun(DateTime t) => DateTime(t.year, t.month, t.day);
    final bas = gun(baslangic);
    final son = gun(santiyeBitisi);
    final simdi = gun(bugun);

    // Takvim tutarsizsa (bitis baslangictan once) hesap yapilmiyor.
    if (!son.isAfter(bas)) return null;

    // Blok henuz baslamadi: beklenen ilerleme yok.
    if (simdi.isBefore(bas)) return 0;

    // Santiyenin genel bitis tarihi gecti: blogun bitmis olmasi
    // bekleniyor.
    if (!simdi.isBefore(son)) return 100;

    final toplamGun = son.difference(bas).inDays;
    final gecenGun = simdi.difference(bas).inDays;
    return (gecenGun * 100 / toplamGun).round().clamp(0, 100);
  }

  /// Sirasi onemli: tamamlanan blok, takvimi gecmis olsa da geciken
  /// sayilmiyor. Beklenen ilerleme hesaplanamadiginda (takvim
  /// girilmemis) hicbir blok geciken sayilmiyor.
  static BlockState _durumHesapla({
    required int ilerleme,
    required int? beklenen,
    required String? sunucuDurumu,
  }) {
    if (ilerleme >= 100 || sunucuDurumu == 'COMPLETED') {
      return BlockState.completed;
    }
    if (beklenen != null && ilerleme < beklenen) return BlockState.delayed;
    if (ilerleme > 0) return BlockState.inProgress;
    return BlockState.notStarted;
  }
}

/// Tek bir tipin (Evler / Dükkanlar / Apartmanlar) rapor ozeti.
class BlockGroup {
  const BlockGroup({required this.type, required this.blocks});

  final BlockType type;
  final List<BlockReport> blocks;

  String get label => type.label;
  int get total => blocks.length;

  int get completed => _say(BlockState.completed);
  int get delayed => _say(BlockState.delayed);
  int get inProgress => _say(BlockState.inProgress);
  int get notStarted => _say(BlockState.notStarted);

  int _say(BlockState d) => blocks.where((b) => b.state == d).length;

  /// Tipin genel ilerlemesi: bloklarin ortalamasi.
  int get averageProgress {
    if (blocks.isEmpty) return 0;
    final toplam = blocks.fold<int>(0, (t, b) => t + b.progress);
    return (toplam / blocks.length).round();
  }

}

/// "Son Güncellemeler" kartindaki tek satir.
class ReportUpdate {
  const ReportUpdate({
    required this.title,
    required this.detail,
    required this.blockId,
    required this.blockName,
    required this.date,
  });

  final String title;
  final String detail;

  /// Guncellemenin ait oldugu blok. Sunucu her bildirimde vermiyor;
  /// bos oldugunda guncelleme bir tipe yazilamiyor.
  final int? blockId;

  final String? blockName;
  final DateTime date;
}

class ReportData {
  const ReportData({
    required this.siteName,
    required this.sitePlannedEnd,
    required this.groups,
    required this.updates,
  });

  final String siteName;

  /// Santiyenin genel planlanan bitis tarihi; girilmemis olabilir.
  final DateTime? sitePlannedEnd;

  /// Sadece blogu olan tipler, sabit sirada: Evler, Dükkanlar,
  /// Apartmanlar. Tek tip varsa ekranda sekme cubugu cikmiyor.
  final List<BlockGroup> groups;

  final List<ReportUpdate> updates;

  bool get isEmpty => groups.every((g) => g.blocks.isEmpty);
}
