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
/// yuzdesi ve planlanan bitis tarihinden turetiliyor.
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
    required this.plannedEnd,
    required this.state,
  });

  final int id;
  final String name;
  final BlockType type;

  /// 0-100 arasi, yuvarlanmis ilerleme.
  final int progress;

  /// Planlanan bitis tarihi. Girilmemis olabilir.
  final DateTime? plannedEnd;

  final BlockState state;

  /// [bugun] disaridan veriliyor: ayni listedeki butun bloklar ayni ani
  /// referans alsin ve test edilebilsin diye.
  factory BlockReport.fromJson(
    Map<String, dynamic> json, {
    required DateTime bugun,
  }) {
    final ham = json['overallProgress'];
    final yuzde = ham is num
        ? ham.toDouble()
        : double.tryParse(ham?.toString() ?? '') ?? 0;
    final ilerleme = yuzde.clamp(0, 100).round();

    final bitis = DateTime.tryParse(json['endDate']?.toString() ?? '');
    final durum = json['status']?.toString();

    return BlockReport(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      type: BlockTypeLabel.fromApi(json['projectType']?.toString()),
      progress: ilerleme,
      plannedEnd: bitis,
      state: _durumHesapla(
        ilerleme: ilerleme,
        bitis: bitis,
        sunucuDurumu: durum,
        bugun: bugun,
      ),
    );
  }

  /// Sirasi onemli: tamamlanan blok, tarihi gecmis olsa da geciken
  /// sayilmiyor.
  static BlockState _durumHesapla({
    required int ilerleme,
    required DateTime? bitis,
    required String? sunucuDurumu,
    required DateTime bugun,
  }) {
    if (ilerleme >= 100 || sunucuDurumu == 'COMPLETED') {
      return BlockState.completed;
    }
    if (bitis != null && bitis.isBefore(DateTime(bugun.year, bugun.month, bugun.day))) {
      return BlockState.delayed;
    }
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

  /// Hic blokta planlanan bitis tarihi yoksa ekranda bunu soyluyoruz;
  /// aksi halde gecikme hesabi yokmus gibi gorunuyor.
  bool get hasPlannedEnd => blocks.any((b) => b.plannedEnd != null);
}

/// "Son Güncellemeler" kartindaki tek satir.
class ReportUpdate {
  const ReportUpdate({
    required this.title,
    required this.detail,
    required this.blockName,
    required this.date,
  });

  final String title;
  final String detail;
  final String? blockName;
  final DateTime date;
}

class ReportData {
  const ReportData({
    required this.siteName,
    required this.groups,
    required this.updates,
  });

  final String siteName;

  /// Sadece blogu olan tipler, sabit sirada: Evler, Dükkanlar,
  /// Apartmanlar. Tek tip varsa ekranda sekme cubugu cikmiyor.
  final List<BlockGroup> groups;

  final List<ReportUpdate> updates;

  bool get isEmpty => groups.every((g) => g.blocks.isEmpty);
}
