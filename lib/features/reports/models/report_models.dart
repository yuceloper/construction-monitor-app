// Rapor ekraninin veri tipleri.
//
// Sunucuda ayri bir rapor ucu yok; blok listesi /projects'ten, her
// blogun plan karsilastirmasi ise surec takibin kullandigi
// /progress/project/{id}/summary ucundan geliyor. Veriler burada
// toplandi ki ekran sadece gostermekle ugrassin.

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

/// Blogun rapordaki durumu. Gecikme sunucunun plan karsilastirmasindan
/// geliyor, tamamlanma ise ilerleme yuzdesinden turetiliyor.
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

  /// Sunucunun bugun icin bekledigi ilerleme (plannedProgress).
  /// Surec takip ekrani da ayni degeri gosteriyor. Ozet alinamazsa
  /// null kaliyor ve ekranda plan karsilastirmasi yazilmiyor.
  final int? expectedProgress;

  final BlockState state;

  /// Plan karsilastirmasi sunucudan geliyor: [beklenen] sunucunun bugun
  /// icin bekledigi ilerleme, [geride] ise sunucunun hesapladigi
  /// sapmanin eksi olup olmadigi. Surec takip ekrani da ayni iki degeri
  /// kullaniyor; ikisi tek kaynaktan beslendigi icin rapor ile surec
  /// takip ayni blokta ayni gecikmeyi gosteriyor.
  ///
  /// [gerceklesen] de ozetten geliyor; ozet alinamazsa blok listesinin
  /// kendi yuzdesi kullaniliyor.
  factory BlockReport.fromJson(
    Map<String, dynamic> json, {
    required int? beklenen,
    required bool? geride,
    int? gerceklesen,
  }) {
    final ham = json['overallProgress'];
    final yuzde = ham is num
        ? ham.toDouble()
        : double.tryParse(ham?.toString() ?? '') ?? 0;
    final ilerleme = gerceklesen ?? yuzde.clamp(0, 100).round();
    final durum = json['status']?.toString();

    return BlockReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      type: BlockTypeLabel.fromApi(json['projectType']?.toString()),
      progress: ilerleme,
      expectedProgress: beklenen,
      state: _durumHesapla(
        ilerleme: ilerleme,
        geride: geride,
        sunucuDurumu: durum,
      ),
    );
  }

  /// Sirasi onemli: tamamlanan blok, planin gerisinde olsa da geciken
  /// sayilmiyor. Sapma sunucudan alinamadiginda blok geciken
  /// sayilmiyor: rapor olmayan bir gecikmeyi uydurmaktansa plan
  /// karsilastirmasini hic yazmiyor.
  static BlockState _durumHesapla({
    required int ilerleme,
    required bool? geride,
    required String? sunucuDurumu,
  }) {
    if (ilerleme >= 100 || sunucuDurumu == 'COMPLETED') {
      return BlockState.completed;
    }
    if (geride == true) return BlockState.delayed;
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
