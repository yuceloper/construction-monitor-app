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
                      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
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
            Container(
              padding: const EdgeInsets.fromLTRB(14, 6, 20, 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.border)),
              ),
              child: Row(
                children: [
                  Pressable(
                    onTap: () => context.pop(),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(LucideIcons.chevronLeft, size: 24, color: c.ink),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.blockName,
                    style: TextStyle(
                      fontFamily: kBody,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: c.accent,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Icon(LucideIcons.chevronRight, size: 15, color: c.muted),
                  ),
                  Expanded(
                    child: Text(
                      _detail?.title ?? widget.workTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kDisplay,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.3,
                        color: c.ink,
                      ),
                    ),
                  ),
                ],
              ),
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
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _SectionTitle(icon: LucideIcons.paperclip, title: 'Bağımlı İşler'),
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 10, 0, 22),
            child: detail.dependencies.isEmpty
                ? Text(
                    'Bağımlı iş bulunmuyor.',
                    style: TextStyle(fontFamily: kBody, fontSize: 17, color: c.muted),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detail.dependencies
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                item,
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 18,
                                  height: 1.35,
                                  color: c.ink,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: _SectionTitle(icon: LucideIcons.triangleAlert, title: 'Uyarılar'),
              ),
              SmallButton(
                label: 'Ekle',
                icon: LucideIcons.plus,
                busy: _isAddingWarning,
                onTap: _addWarning,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (detail.warnings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Bu iş için uyarı bulunmuyor.',
                style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.muted),
              ),
            )
          else
            ...detail.warnings.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WarningCard(
                    item: item,
                    createdDate: _date(item.createdAt),
                  ),
                )),
          const SizedBox(height: 18),
          _SectionTitle(icon: LucideIcons.history, title: 'Tarihçe'),
          const SizedBox(height: 14),
          if (detail.history.isEmpty)
            Text(
              'Henüz tarihçe kaydı bulunmuyor.',
              style: TextStyle(fontFamily: kBody, fontSize: 16, color: c.muted),
            )
          else
            ...detail.history.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _HistoryCard(item: item, date: _date(item.createdAt)),
                )),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Icon(icon, size: 28, color: c.ink),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontFamily: kDisplay,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -.5,
            color: c.ink,
          ),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  final WorkItemWarning item;
  final String createdDate;

  const _WarningCard({
    required this.item,
    required this.createdDate,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final overdue = item.isOverdue;

    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: overdue ? c.bad.withValues(alpha: .08) : c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: overdue ? c.bad.withValues(alpha: .35) : c.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              item.text,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w500,
                color: c.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Eklenme: $createdDate',
                style: TextStyle(fontFamily: kBody, fontSize: 12.5, color: c.muted),
              ),
              const SizedBox(height: 8),
              Text(
                item.user,
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: c.sub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final WorkItemHistory item;
  final String date;
  const _HistoryCard({required this.item, required this.date});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border),
      ),
      child: Row(
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
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.user,
                style: TextStyle(fontFamily: kBody, fontSize: 14, color: c.sub),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
