import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
import '../models/work_item_detail.dart';
import '../services/work_item_service.dart';

class WorkDetailPage extends StatefulWidget {
  final String blockName;
  final String workId;
  final String workTitle;

  const WorkDetailPage({
    super.key,
    required this.blockName,
    required this.workId,
    required this.workTitle,
  });

  @override
  State<WorkDetailPage> createState() => _WorkDetailPageState();
}

class _WorkDetailPageState extends State<WorkDetailPage> {
  final _service = WorkItemService();
  bool _isLoading = true;
  bool _isAddingWarning = false;
  String? _errorMessage;
  WorkItemDetail? _detail;

  int get _id => int.tryParse(widget.workId) ?? 0;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    if (_id <= 0) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'İş kimliği bulunamadı.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final detail = await _service.getDetail(_id);
      if (!mounted) return;
      setState(() => _detail = detail);
    } on WorkItemException catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addWarning() async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String draft = '';
        String? validationMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Uyarı Ekle'),
            // Klavye acilinca ya da uzun bir uyari yazilinca pencere
            // tasiyordu; icerik kendi icinde kayabiliyor.
            scrollable: true,
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScrollableField(
                    builder: (scrollController) => TextField(
                      autofocus: true,
                      scrollController: scrollController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 500,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(500),
                      ],
                      onChanged: (value) => draft = value,
                      decoration: const InputDecoration(
                        hintText: 'Lütfen detay giriniz.',
                        border: OutlineInputBorder(),
                        // Sagda kaydirma cubuguna yer birakiliyor.
                        contentPadding: EdgeInsets.fromLTRB(12, 14, 20, 14),
                      ),
                    ),
                  ),
                  if (validationMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      validationMessage!,
                      style: TextStyle(color: context.colors.bad, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  final value = draft.trim();
                  if (value.isEmpty) {
                    setDialogState(
                      () => validationMessage = 'Uyarı detayı zorunludur.',
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(value);
                },
                child: const Text('Ekle'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || !mounted) return;
    setState(() => _isAddingWarning = true);
    try {
      await _service.addWarning(_id, result);
      await _loadDetail();
    } on WorkItemException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isAddingWarning = false);
    }
  }

  /// Uyari metnini duzenler. Pencere ekleme penceresiyle ayni; alan dolu
  /// geliyor ve buton "Kaydet" yaziyor.
  Future<void> _editWarning(WorkItemWarning warning) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(text: warning.text);
        String? validationMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Uyarıyı Düzenle'),
            scrollable: true,
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScrollableField(
                    builder: (scrollController) => TextField(
                      autofocus: true,
                      controller: controller,
                      scrollController: scrollController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 500,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(500),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'Lütfen detay giriniz.',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.fromLTRB(12, 14, 20, 14),
                      ),
                    ),
                  ),
                  if (validationMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      validationMessage!,
                      style: TextStyle(color: context.colors.bad, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    setDialogState(
                      () => validationMessage = 'Uyarı detayı zorunludur.',
                    );
                    return;
                  }
                  Navigator.of(dialogContext).pop(value);
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || !mounted) return;
    if (result == warning.text) return;
    setState(() => _isAddingWarning = true);
    try {
      await _service.updateWarning(_id, warning.id, result);
      await _loadDetail();
    } on WorkItemException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isAddingWarning = false);
    }
  }

  /// Uyariyi siler. Geri alinamadigi icin once onay soruluyor.
  Future<void> _deleteWarning(WorkItemWarning warning) async {
    final onay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uyarıyı Sil'),
        content: const Text('Bu uyarı silinecek. Devam edilsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: context.colors.bad),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (onay != true || !mounted) return;
    setState(() => _isAddingWarning = true);
    try {
      await _service.deleteWarning(_id, warning.id);
      await _loadDetail();
    } on WorkItemException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isAddingWarning = false);
    }
  }

  /// Kartin ... dugmesine basilinca acilan panel.
  Future<void> _openWarningMenu(WorkItemWarning warning) async {
    final c = context.colors;
    final secim = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Sizes.rCard),
          border: Border.all(color: c.border),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border2,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 10),
              _WarningMenuItem(
                icon: LucideIcons.pencil,
                label: 'Düzenle',
                onTap: () => Navigator.of(sheetContext).pop('duzenle'),
              ),
              Divider(height: 1, color: c.line),
              _WarningMenuItem(
                icon: LucideIcons.trash2,
                label: 'Sil',
                danger: true,
                onTap: () => Navigator.of(sheetContext).pop('sil'),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );

    if (secim == 'duzenle') await _editWarning(warning);
    if (secim == 'sil') await _deleteWarning(warning);
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _date(DateTime? date) {
    if (date == null) return '-';
    return _formatDate(date.toLocal());
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
              parent: widget.blockName,
              title: _detail?.title ?? widget.workTitle,
              onBack: () => context.pop(),
              onParentTap: () => context.pop(),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final c = context.colors;

    if (_isLoading && _detail == null) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: c.ink),
        ),
      );
    }
    if (_errorMessage != null && _detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.ink),
            ),
            const SizedBox(height: 16),
            SmallButton(
              label: 'Tekrar Dene',
              icon: LucideIcons.refreshCw,
              onTap: _loadDetail,
            ),
          ],
        ),
      );
    }

    final detail = _detail!;
    return RefreshIndicator(
      color: c.ink,
      onRefresh: _loadDetail,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _Section(
            title: 'Bağımlı İşler',
            child: detail.dependencies.isEmpty
                ? const EmptyState(message: 'Bağımlı iş bulunmuyor.')
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in detail.dependencies)
                        _DependencyRow(
                          text: item,
                          last: item == detail.dependencies.last,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Uyarılar',
            action: SmallButton(
              label: 'Ekle',
              icon: LucideIcons.plus,
              busy: _isAddingWarning,
              onTap: _addWarning,
            ),
            child: detail.warnings.isEmpty
                ? const EmptyState(message: 'Bu iş için uyarı bulunmuyor.')
                : Column(
                    children: [
                      for (final item in detail.warnings)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: item == detail.warnings.last ? 0 : 10,
                          ),
                          child: _WarningCard(
                            item: item,
                            createdDate: _date(item.createdAt),
                            onMenu: () => _openWarningMenu(item),
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Tarihçe',
            child: detail.history.isEmpty
                ? const EmptyState(message: 'Henüz tarihçe kaydı bulunmuyor.')
                : Column(
                    children: [
                      for (final item in detail.history)
                        _HistoryEntry(
                          item: item,
                          date: _date(item.createdAt),
                          last: item == detail.history.last,
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Ekranin uc bolumu icin ortak kart.
///
/// Bolum dolu da olsa bos da olsa ayni kart icinde duruyor; boylece ekran
/// veri geldikce sekil degistirmiyor.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});

  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: kDisplay,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.3,
                    color: c.ink,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

/// Bagimli is satiri: kucuk bir baglanti isareti ve isin adi.
class _DependencyRow extends StatelessWidget {
  const _DependencyRow({required this.text, required this.last});

  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(LucideIcons.link, size: 16, color: c.warn),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 15.5,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarihce girdisi: solda zaman cizgisi, sagda kayit ve alti bilgisi.
class _HistoryEntry extends StatelessWidget {
  const _HistoryEntry({
    required this.item,
    required this.date,
    required this.last,
  });

  final WorkItemHistory item;
  final String date;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 10,
            child: Column(
              children: [
                const SizedBox(height: 5),
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!last)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      color: c.border2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.text,
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 15,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        date,
                        style: TextStyle(
                          fontFamily: kBody,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: c.sub,
                        ),
                      ),
                      const Spacer(),
                      Icon(LucideIcons.user, size: 15, color: c.muted),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          item.user,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 12.5,
                            color: c.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final WorkItemWarning item;
  final String createdDate;
  final VoidCallback onMenu;

  const _WarningCard({
    required this.item,
    required this.createdDate,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final overdue = item.isOverdue;
    final edge = overdue ? c.bad : c.border2;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: overdue ? c.bad.withValues(alpha: .06) : c.inset,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overdue ? c.bad.withValues(alpha: .28) : c.line,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: edge),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.text,
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 15.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: c.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Dokunma alani 40, gorsel agirlik dusuk: kart
                        // metnini bastirmasin diye soluk bir ... duruyor.
                        Pressable(
                          onTap: onMenu,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 2, 2, 8),
                            child: Icon(
                              LucideIcons.ellipsis,
                              size: 18,
                              color: c.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Text(
                          createdDate,
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: c.sub,
                          ),
                        ),
                        const Spacer(),
                        // Kisi gosterimi gunluk islerdeki ile ayni.
                        Icon(LucideIcons.user, size: 15, color: c.muted),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            item.user,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 12.5,
                              color: c.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Uyari menusundeki tek satir.
class _WarningMenuItem extends StatelessWidget {
  const _WarningMenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final renk = danger ? c.bad : c.ink;
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 19, color: renk),
            const SizedBox(width: 13),
            Text(
              label,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
                color: renk,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
