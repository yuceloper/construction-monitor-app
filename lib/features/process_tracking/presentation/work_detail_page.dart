import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/panel.dart';
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
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    autofocus: true,
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 500,
                    inputFormatters: [LengthLimitingTextInputFormatter(500)],
                    onChanged: (value) => draft = value,
                    decoration: const InputDecoration(
                      hintText: 'Lütfen detay giriniz.',
                      border: OutlineInputBorder(),
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
                    setDialogState(() => validationMessage = 'Uyarı detayı zorunludur.');
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isAddingWarning = false);
    }
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
            icon: LucideIcons.paperclip,
            title: 'Bağımlı İşler',
            color: c.warn,
            child: detail.dependencies.isEmpty
                ? const EmptyState(
                    message: 'Bağımlı iş bulunmuyor.',
                    icon: LucideIcons.paperclip,
                  )
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
            icon: LucideIcons.triangleAlert,
            title: 'Uyarılar',
            color: c.bad,
            action: SmallButton(
              label: 'Ekle',
              icon: LucideIcons.plus,
              busy: _isAddingWarning,
              onTap: _addWarning,
            ),
            child: detail.warnings.isEmpty
                ? const EmptyState(
                    message: 'Bu iş için uyarı bulunmuyor.',
                    icon: LucideIcons.triangleAlert,
                  )
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
                          ),
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _Section(
            icon: LucideIcons.history,
            title: 'Tarihçe',
            color: c.accent,
            child: detail.history.isEmpty
                ? const EmptyState(
                    message: 'Henüz tarihçe kaydı bulunmuyor.',
                    icon: LucideIcons.history,
                  )
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
  const _Section({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
    this.action,
  });

  final IconData icon;
  final String title;
  final Color color;
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
              IconBox(icon: icon, color: color, size: 34),
              const SizedBox(width: 11),
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
                      const SizedBox(width: 12),
                      Expanded(
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

  const _WarningCard({required this.item, required this.createdDate});

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
        border: Border.all(color: overdue ? c.bad.withValues(alpha: .28) : c.line),
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
                    Text(
                      item.text,
                      style: TextStyle(
                        fontFamily: kBody,
                        fontSize: 15.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: c.ink,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        Text(
                          'Eklenme: $createdDate',
                          style: TextStyle(
                            fontFamily: kBody,
                            fontSize: 12.5,
                            color: c.muted,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.user,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: c.sub,
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
