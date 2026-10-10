import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/genisleyen_metin.dart';
import '../../../core/widgets/kisa_ad.dart';
import '../../../core/widgets/panel.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/pressable.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _service = NotificationService();
  List<NotificationItem> _items = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final all = await _service.getNotifications();
      final cutoff = DateTime.now().subtract(const Duration(days: 15));
      final items = all
          .where((item) => !item.createdAt.toLocal().isBefore(cutoff))
          .where((item) => item.type == 'WORK_ITEM_UPDATED' || item.isDailyTask)
          .toList();
      if (!mounted) return;
      setState(() => _items = items);
    } on NotificationException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _open(NotificationItem item) async {
    if (!item.isRead) {
      try {
        await _service.markAsRead(item.id);
        if (mounted) {
          setState(() {
            _items = _items
                .map((current) => current.id == item.id ? current.copyWith(isRead: true) : current)
                .toList();
          });
        }
      } catch (_) {}
    }

    if (!mounted || item.referenceId == null) return;
    if (item.isDailyTask) {
      context.push('/daily-tasks/${item.referenceId}');
    } else if (item.type == 'WORK_ITEM_UPDATED') {
      context.push(
        '/process/Bildirimler/work/${item.referenceId}'
        '?title=${Uri.encodeQueryComponent(item.title)}',
      );
    }
  }

  Widget build(BuildContext context) {
    final c = context.colors;
    final unreadCount = _items.where((item) => !item.isRead).length;

    return ColoredBox(
      color: c.bg,
      child: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            ScreenTitleBar(
              title: 'Bildirimler',
              onBack: () => context.go('/dashboard'),
              trailing: unreadCount > 0
                  ? Container(
                      constraints: const BoxConstraints(minWidth: 29, minHeight: 29),
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.bad,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          fontFamily: kBody,
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final c = context.colors;

    if (_loading && _items.isEmpty) {
      return Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.6, color: c.ink),
        ),
      );
    }
    if (_error != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.cloudOff, size: 52, color: c.muted),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: kBody, fontSize: 16, height: 1.45, color: c.ink),
              ),
              const SizedBox(height: 16),
              SmallButton(
                label: 'Tekrar Dene',
                icon: LucideIcons.refreshCw,
                onTap: _load,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: c.ink,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        itemCount: _items.isEmpty ? 1 : _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: Sizes.gap),
        itemBuilder: (_, index) {
          if (_items.isEmpty) {
            return const Padding(
              padding: EdgeInsets.only(top: 40),
              child: EmptyView(
                title: 'Son 15 günde bildirim bulunmuyor.',
              ),
            );
          }
          final item = _items[index];
          return _NotificationCard(item: item, onTap: () => _open(item));
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDaily = item.isDailyTask;
    // Sol serit: gunluk is mi, is kalemi uyarisi mi - renk ayrimi onlarin
    // ekranindaki gibi duruyor.
    final accent = isDaily ? c.accent : c.warn;
    final content = _NotificationContent.fromItem(item);

    return Pressable(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(Sizes.rCard),
          border: Border.all(color: c.border),
          boxShadow: kLiftShadow,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              content.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: kDisplay,
                                fontSize: 16,
                                height: 1.2,
                                fontWeight: isDaily ? FontWeight.w600 : FontWeight.w700,
                                color: c.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _formatDate(item.createdAt),
                            style: TextStyle(
                              fontFamily: kBody,
                              fontSize: 12,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                      if (content.detail.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        // Bildirim metni de uzun olabiliyor; kesilince
                        // devaminin oldugu anlasilmiyordu.
                        GenisleyenMetin(
                          metin: content.detail,
                          satir: 2,
                          bicim: TextStyle(
                            fontFamily: kBody,
                            fontSize: 13.5,
                            height: 1.35,
                            fontWeight: FontWeight.w400,
                            color: c.sub,
                          ),
                        ),
                      ],
                      if (isDaily && (content.block.isNotEmpty || content.person.isNotEmpty)) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                content.block,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 13,
                                  height: 1.25,
                                  color: c.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (content.person.isNotEmpty) ...[
                              const SizedBox(width: 10),
                              // Kisi gosterimi gunluk is kartiyla ayni:
                              // ikon + soluk gri. Burada mavi ve kalindi,
                              // blok adiyla ayni agirliktaydi; blok bir yer
                              // etiketi, kisi degil.
                              Icon(LucideIcons.user, size: 15, color: c.muted),
                              const SizedBox(width: 6),
                              Text(
                                kisaKisiAdi(
                                  context,
                                  content.person,
                                  enBoy: 120,
                                  olcu: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: kBody,
                                  fontSize: 13,
                                  height: 1.25,
                                  color: c.muted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }
}


class _NotificationContent {
  final String title;
  final String detail;
  final String block;
  final String person;

  const _NotificationContent({
    required this.title,
    required this.detail,
    required this.block,
    required this.person,
  });

  factory _NotificationContent.fromItem(NotificationItem item) {
    if (!item.isDailyTask) {
      return _NotificationContent(
        title: item.title,
        detail: item.message,
        block: '',
        person: '',
      );
    }

    final lines = item.message
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    var detail = lines.isNotEmpty ? lines.first : '';
    var block = item.projectName ?? '';
    var person = '';

    for (final line in lines.skip(1)) {
      if (line.toLowerCase().startsWith('blok:')) {
        final value = line.substring(line.indexOf(':') + 1).trim();
        block = value.isEmpty ? block : 'Evler - $value';
      } else if (line.toLowerCase().startsWith('kişi:') || line.toLowerCase().startsWith('kisi:')) {
        person = line.substring(line.indexOf(':') + 1).trim();
      } else if (!line.toLowerCase().startsWith('tarih:') && detail.isEmpty) {
        detail = line;
      }
    }

    if (block.isNotEmpty && !block.contains(' - ')) {
      block = 'Evler - $block';
    }

    return _NotificationContent(
      title: item.title,
      detail: detail,
      block: block,
      person: person,
    );
  }
}
