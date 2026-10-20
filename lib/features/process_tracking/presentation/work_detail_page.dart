import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/genisleyen_metin.dart';
import '../../../core/widgets/kisa_ad.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/state_views.dart';
import '../models/work_item_detail.dart';
import '../services/work_item_service.dart';
import 'warning_create_dialog.dart';

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
  final _warningAudioPlayer = AudioPlayer();

  bool _isLoading = true;
  bool _isAddingWarning = false;
  int? _audioLoadingWarningId;
  int? _playingWarningId;
  String? _errorMessage;
  WorkItemDetail? _detail;

  int get _id => int.tryParse(widget.workId) ?? 0;

  /// Bagimli isin kendi detayini aciyor. Ayni ekran yeniden yuklendigi
  /// icin oradan geri donunce bu is kalemi geri geliyor.
  Future<void> _bagimliIseGit(WorkItemDependency bagimli) async {
    await context.push(
      '/process/${Uri.encodeComponent(widget.blockName)}/work/${bagimli.id}'
      '?title=${Uri.encodeQueryComponent(bagimli.title)}',
    );
    if (!mounted) return;
    await _loadDetail();
  }

  @override
  void initState() {
    super.initState();
    _warningAudioPlayer.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() => _playingWarningId = null);
    });
    _loadDetail();
  }

  @override
  void dispose() {
    _warningAudioPlayer.dispose();
    super.dispose();
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

  InputDecoration _warningFieldDecoration() {
    final c = context.colors;
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(Sizes.rField),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      hintText: 'Lütfen detay giriniz.',
      hintStyle: TextStyle(fontFamily: kBody, fontSize: 15.5, color: c.faint),
      counterStyle: TextStyle(fontFamily: kBody, fontSize: 12, color: c.muted),
      isDense: true,
      filled: true,
      fillColor: c.surface2,
      contentPadding: const EdgeInsets.fromLTRB(16, 15, 22, 15),
      border: border(c.border2),
      enabledBorder: border(c.border2),
      disabledBorder: border(c.border),
      focusedBorder: border(c.accent, 1.8),
    );
  }

  Future<void> _addWarning() async {
    final draft = await showWarningCreateDialog(context);
    if (draft == null || !mounted) return;

    setState(() => _isAddingWarning = true);
    try {
      final warning = await _service.addWarning(_id, draft.text);
      if (draft.audioPath != null) {
        await _service.uploadWarningAudio(_id, warning.id, draft.audioPath!);
      }
      await _loadDetail();
    } on WorkItemException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _isAddingWarning = false);
    }
  }

  Future<void> _playWarningAudio(WorkItemWarning warning) async {
    if (!warning.hasAudio || _audioLoadingWarningId != null) return;

    try {
      if (_playingWarningId == warning.id) {
        await _warningAudioPlayer.stop();
        if (mounted) setState(() => _playingWarningId = null);
        return;
      }

      await _warningAudioPlayer.stop();
      setState(() => _audioLoadingWarningId = warning.id);
      final source = await _service.downloadWarningAudio(_id, warning.id);
      await _warningAudioPlayer.play(UrlSource(source));
      if (mounted) setState(() => _playingWarningId = warning.id);
    } on WorkItemException catch (error) {
      if (mounted) _bildir(error.message);
    } catch (_) {
      if (mounted) _bildir('Sesli not oynatılamadı.');
    } finally {
      if (mounted) setState(() => _audioLoadingWarningId = null);
    }
  }

  Future<void> _editWarning(WorkItemWarning warning) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(text: warning.text);
        String? validationMessage;

        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Uyarıyı Güncelle'),
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
                      inputFormatters: [LengthLimitingTextInputFormatter(500)],
                      style: TextStyle(
                        fontFamily: kBody,
                        fontSize: 15.5,
                        color: context.colors.ink,
                      ),
                      cursorColor: context.colors.accent,
                      decoration: _warningFieldDecoration(),
                    ),
                  ),
                  if (validationMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      validationMessage!,
                      style: TextStyle(
                        fontFamily: kBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colors.bad,
                      ),
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
                child: const Text('Güncelle'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || !mounted || result == warning.text) return;
    setState(() => _isAddingWarning = true);
    try {
      await _service.updateWarning(_id, warning.id, result);
      await _loadDetail();
      if (mounted) _bildir('Uyarı güncellendi.');
    } on WorkItemException catch (error) {
      if (mounted) _bildir(error.message);
    } finally {
      if (mounted) setState(() => _isAddingWarning = false);
    }
  }

  Future<void> _deleteWarning(WorkItemWarning warning) async {
    final c = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uyarıyı Sil'),
        scrollable: true,
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bu uyarı silinecek. Devam edilsin mi?',
                style: TextStyle(
                  fontFamily: kBody,
                  fontSize: 15.5,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                decoration: BoxDecoration(
                  color: c.inset,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border),
                ),
                child: Text(
                  warning.text,
                  style: TextStyle(
                    fontFamily: kBody,
                    fontSize: 14.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: c.sub,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    setState(() => _isAddingWarning = true);
    try {
      if (_playingWarningId == warning.id) {
        await _warningAudioPlayer.stop();
        _playingWarningId = null;
      }
      await _service.deleteWarning(_id, warning.id);
      await _loadDetail();
      if (mounted) _bildir('Uyarı silindi.');
    } on WorkItemException catch (error) {
      if (mounted) _bildir(error.message);
    } finally {
      if (mounted) setState(() => _isAddingWarning = false);
    }
  }

  void _bildir(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
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
      return ErrorView(message: _errorMessage!, onRetry: _loadDetail);
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
                      // Kimlikli liste varsa satira dokununca o isin
                      // detayina gidiliyor; sunucu kimlik gondermezse
                      // adlar eskisi gibi duz yaziyla duruyor.
                      if (detail.dependencyItems.isNotEmpty)
                        for (final item in detail.dependencyItems)
                          _DependencyRow(
                            text: item.title,
                            last: item == detail.dependencyItems.last,
                            onTap: () => _bagimliIseGit(item),
                          )
                      else
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
                            audioLoading: _audioLoadingWarningId == item.id,
                            audioPlaying: _playingWarningId == item.id,
                            onPlayAudio: () => _playWarningAudio(item),
                            onUpdate: () => _editWarning(item),
                            onDelete: () => _deleteWarning(item),
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

class _DependencyRow extends StatelessWidget {
  const _DependencyRow({required this.text, required this.last, this.onTap});

  final String text;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final satir = Padding(
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
            child: onTap == null
                ? GenisleyenMetin(
                    metin: text,
                    bicim: TextStyle(
                      fontFamily: kBody,
                      fontSize: 15.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: c.ink,
                    ),
                  )
                // Dokunulabilen satirda metin acilir kapanir degil:
                // acma dokunusu satirin kendi dokunusunu yutuyor.
                : Text(
                    text,
                    maxLines: 2,
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
          // Ok, satirin o ise gittigini belli ediyor.
          if (onTap != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 1),
              child: Icon(
                LucideIcons.chevronRight,
                size: 19,
                color: c.muted,
              ),
            ),
        ],
      ),
    );

    if (onTap == null) return satir;
    return Pressable(onTap: onTap, child: satir);
  }
}

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
                  GenisleyenMetin(
                    metin: item.text,
                    satir: 2,
                    bicim: TextStyle(
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
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 170),
                        child: Text(
                          kisaKisiAdi(
                            context,
                            item.user,
                            enBoy: 130,
                            olcu: 12.5,
                          ),
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
  final bool audioLoading;
  final bool audioPlaying;
  final VoidCallback onPlayAudio;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _WarningCard({
    required this.item,
    required this.createdDate,
    required this.audioLoading,
    required this.audioPlaying,
    required this.onPlayAudio,
    required this.onUpdate,
    required this.onDelete,
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
                          child: GenisleyenMetin(
                            metin: item.text,
                            bicim: TextStyle(
                              fontFamily: kBody,
                              fontSize: 15.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: c.ink,
                            ),
                          ),
                        ),
                        if (item.hasAudio) ...[
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              tooltip: audioPlaying ? 'Durdur' : 'Sesli notu dinle',
                              onPressed: audioLoading ? null : onPlayAudio,
                              icon: audioLoading
                                  ? SizedBox(
                                      width: 17,
                                      height: 17,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: c.accent,
                                      ),
                                    )
                                  : Icon(
                                      audioPlaying
                                          ? Icons.stop_rounded
                                          : Icons.volume_up_rounded,
                                      size: 22,
                                      color: c.accent,
                                    ),
                            ),
                          ),
                        ],
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
                        Icon(LucideIcons.user, size: 15, color: c.muted),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 170),
                          child: Text(
                            kisaKisiAdi(
                              context,
                              item.user,
                              enBoy: 130,
                              olcu: 12.5,
                            ),
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
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _WarningActionButton(
                          icon: LucideIcons.pencil,
                          label: 'Güncelle',
                          onTap: onUpdate,
                        ),
                        const SizedBox(width: 10),
                        _WarningActionButton(
                          icon: LucideIcons.trash2,
                          label: 'Sil',
                          onTap: onDelete,
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

class _WarningActionButton extends StatelessWidget {
  const _WarningActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(11, 9, 12, 9),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: c.ink),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: kBody,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: c.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
