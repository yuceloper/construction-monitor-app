import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/app_header.dart';
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
    final result = await showDialog<_WarningDraft>(
      context: context,
      builder: (dialogContext) {
        String draft = '';
        DateTime? dueDate;
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
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final now = DateTime.now();
                      final selected = await showDatePicker(
                        context: dialogContext,
                        initialDate: dueDate ?? now,
                        firstDate: DateTime(now.year - 1),
                        lastDate: DateTime(now.year + 5),
                      );
                      if (selected != null) {
                        setDialogState(() {
                          dueDate = selected;
                          validationMessage = null;
                        });
                      }
                    },
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      dueDate == null
                          ? 'Termin tarihi seç'
                          : 'Termin: ${_formatDate(dueDate!)}',
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
                  if (dueDate == null) {
                    setDialogState(() => validationMessage = 'Termin tarihi seçilmelidir.');
                    return;
                  }
                  Navigator.of(dialogContext).pop(
                    _WarningDraft(text: value, dueDate: dueDate!),
                  );
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
      await _service.addWarning(_id, result.text, result.dueDate);
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
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.blockName,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF0066A6),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text('>'),
                  ),
                  Expanded(
                    child: Text(
                      _detail?.title ?? widget.workTitle,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _detail == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.black));
    }
    if (_errorMessage != null && _detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadDetail, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    final detail = _detail!;
    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Row(
            children: [
              Icon(Icons.attach_file, size: 34),
              SizedBox(width: 6),
              Text('Bağımlı İşler', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(46, 8, 0, 20),
            child: detail.dependencies.isEmpty
                ? const Text('Bağımlı iş bulunmuyor.', style: TextStyle(fontSize: 17, color: Colors.black54))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: detail.dependencies
                        .map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(item, style: const TextStyle(fontSize: 19)),
                            ))
                        .toList(),
                  ),
          ),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, size: 34),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Uyarılar', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
              ),
              SizedBox(
                height: 44,
                width: 145,
                child: ElevatedButton.icon(
                  onPressed: _isAddingWarning ? null : _addWarning,
                  icon: const Icon(Icons.add, size: 26),
                  label: const Text('Ekle', style: TextStyle(fontSize: 17)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (detail.warnings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Bu iş için uyarı bulunmuyor.', style: TextStyle(color: Colors.black54)),
            )
          else
            ...detail.warnings.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _WarningCard(
                    item: item,
                    createdDate: _date(item.createdAt),
                    dueDate: _date(item.dueDate),
                  ),
                )),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.history, size: 32),
              SizedBox(width: 6),
              Text('Tarihçe', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          if (detail.history.isEmpty)
            const Text('Henüz tarihçe kaydı bulunmuyor.', style: TextStyle(color: Colors.black54))
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

class _WarningCard extends StatelessWidget {
  final WorkItemWarning item;
  final String createdDate;
  final String dueDate;

  const _WarningCard({
    required this.item,
    required this.createdDate,
    required this.dueDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: item.isOverdue ? const Color(0xFFFFE1E1) : const Color(0xFFEDEDED),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(item.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Termin: $dueDate',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: item.isOverdue ? Colors.red : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text('Eklenme: $createdDate', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Text(item.user, style: const TextStyle(fontSize: 15)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFEDEDED), borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(item.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(date, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(item.user, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _WarningDraft {
  final String text;
  final DateTime dueDate;

  const _WarningDraft({required this.text, required this.dueDate});
}
